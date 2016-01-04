# Copyright, 2009, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'celluloid/io'

require_relative 'transaction'
require_relative 'logger'

module Celluloid::DNS
	class UDPSocketWrapper < Celluloid::IO::UDPSocket
		def initialize(socket)
			@socket = socket
		end
	end
	
	class TCPServerWrapper < Celluloid::IO::TCPServer
		def initialize(server)
			@server = server
		end
	end
	
	class Server
		include Celluloid::IO
		
		# The default server interfaces
		DEFAULT_INTERFACES = [[:udp, "0.0.0.0", 53], [:tcp, "0.0.0.0", 53]]
		
		# Instantiate a server with a block
		#
		#	server = Server.new do
		#		match(/server.mydomain.com/, IN::A) do |transaction|
		#			transaction.respond!("1.2.3.4")
		#		end
		#	end
		#
		def initialize(options = {})
			@logger = options[:logger] || Celluloid.logger
			@interfaces = options[:listen] || DEFAULT_INTERFACES
			
			@origin = options[:origin] || '.'
		end

		# Records are relative to this origin:
		attr_accessor :origin

		attr_accessor :logger

		# Fire the named event as part of running the server.
		def fire(event_name)
		end
		
		finalizer def stop
			# Celluloid.logger.debug(self.class.name) {"-> Shutdown..."}
			
			fire(:stop)
			
			# Celluloid.logger.debug(self.class.name) {"<- Shutdown..."}
		end
		
		# Give a name and a record type, try to match a rule and use it for processing the given arguments.
		def process(name, resource_class, transaction)
			raise NotImplementedError.new
		end
		
		# Process an incoming DNS message. Returns a serialized message to be sent back to the client.
		def process_query(query, options = {}, &block)
			start_time = Time.now
			
			# Setup response
			response = Resolv::DNS::Message::new(query.id)
			response.qr = 1                 # 0 = Query, 1 = Response
			response.opcode = query.opcode  # Type of Query; copy from query
			response.aa = 1                 # Is this an authoritative response: 0 = No, 1 = Yes
			response.rd = query.rd          # Is Recursion Desired, copied from query
			response.ra = 0                 # Does name server support recursion: 0 = No, 1 = Yes
			response.rcode = 0              # Response code: 0 = No errors
			
			transaction = nil
			
			begin
				query.question.each do |question, resource_class|
					begin
						question = question.without_origin(@origin)
						
						@logger.debug {"<#{query.id}> Processing question #{question} #{resource_class}..."}
						
						transaction = Transaction.new(self, query, question, resource_class, response, options)
						
						transaction.process
					rescue Resolv::DNS::OriginError
						# This is triggered if the question is not part of the specified @origin:
						@logger.debug {"<#{query.id}> Skipping question #{question} #{resource_class} because #{$!}"}
					end
				end
			rescue StandardError => error
				@logger.error "<#{query.id}> Exception thrown while processing #{transaction}!"
				Celluloid::DNS.log_exception(@logger, error)
			
				response.rcode = Resolv::DNS::RCode::ServFail
			end
			
			end_time = Time.now
			@logger.debug {"<#{query.id}> Time to process request: #{end_time - start_time}s"}
			
			return response
		end
		
		# Setup all specified interfaces and begin accepting incoming connections.
		def run
			@logger.info "Starting Celluloid::DNS server (v#{Celluloid::DNS::VERSION})..."
			
			fire(:setup)
			
			# Setup server sockets
			@interfaces.each do |spec|
				if spec.is_a?(BasicSocket)
					spec.do_not_reverse_lookup
					protocol = spec.getsockopt(Socket::SOL_SOCKET, Socket::SO_TYPE).unpack("i")[0]
					ip = spec.local_address.ip_address
					port = spec.local_address.ip_port
					
					case protocol
					when Socket::SOCK_DGRAM
						@logger.info "<> Attaching to pre-existing UDP socket #{ip}:#{port}"
						link UDPSocketHandler.new(self, UDPSocketWrapper.new(spec))
					when Socket::SOCK_STREAM
						@logger.info "<> Attaching to pre-existing TCP socket #{ip}:#{port}"
						link TCPSocketHandler.new(self, TCPServerWrapper.new(spec))
					else
						raise ArgumentError.new("Unknown socket protocol: #{protocol}")
					end
				elsif spec[0] == :udp
					@logger.info "<> Listening on #{spec.join(':')}"
					link UDPHandler.new(self, spec[1], spec[2])
				elsif spec[0] == :tcp
					@logger.info "<> Listening on #{spec.join(':')}"
					link TCPHandler.new(self, spec[1], spec[2])
				else
					raise ArgumentError.new("Invalid connection specification: #{spec.inspect}")
				end
			end
			
			fire(:start)
		end
	end
end
