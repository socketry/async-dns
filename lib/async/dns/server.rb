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

require 'async'
require 'async/io'

require_relative 'transaction'

module Async::DNS
	#
	# Base class for defining asynchronous DNS servers.
	#
	# ## Example
	#
	#     require 'async/dns'
	#     
	#     class TestServer < Async::DNS::Server
	#       def process(name, resource_class, transaction)
	#         @resolver ||= Async::DNS::Resolver.new([[:udp, '8.8.8.8', 53], [:tcp, '8.8.8.8', 53]])
	#     
	#         transaction.passthrough!(@resolver)
	#       end
	#     end
	#     
	#     server = TestServer.new([[:udp, '127.0.0.1', 2346]])
	#     server.run
	#
	class Server
		# The default server interfaces
		DEFAULT_ENDPOINTS = [[:udp, "0.0.0.0", 53], [:tcp, "0.0.0.0", 53]]
		
		# Instantiate a server with a block
		def initialize(endpoints = DEFAULT_ENDPOINTS, origin: '.', logger: Console.logger)
			@endpoints = endpoints
			@origin = origin
			@logger = logger
		end
		
		# Records are relative to this origin:
		attr_accessor :origin
		
		attr_accessor :logger
		
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
						
						@logger.debug(query) {"Processing question #{question} #{resource_class}..."}
						
						transaction = Transaction.new(self, query, question, resource_class, response, options)
						
						transaction.process
					rescue Resolv::DNS::OriginError
						# This is triggered if the question is not part of the specified @origin:
						@logger.debug(query) {"Skipping question #{question} #{resource_class} because #{$!}"}
					end
				end
			rescue StandardError => error
				@logger.error(query) {error}
				
				response.rcode = Resolv::DNS::RCode::ServFail
			end
			
			end_time = Time.now
			@logger.debug(query) {"Time to process request: #{end_time - start_time}s"}
			
			return response
		end
		
		# Setup all specified interfaces and begin accepting incoming connections.
		def run(ready: nil)
			@logger.info "Starting Async::DNS server (v#{Async::DNS::VERSION})..."
			
			Async do |task|
				Async::IO::Endpoint.each(@endpoints) do |endpoint|
					task.async do
						endpoint.bind do |socket|
							case socket.type
							when Socket::SOCK_DGRAM
								@logger.info "<> Listening for datagrams on #{socket.local_address.inspect}"
								DatagramHandler.new(self, socket).run
							when Socket::SOCK_STREAM
								@logger.info "<> Listening for connections on #{socket.local_address.inspect}"
								StreamHandler.new(self, socket).run
							else
								raise ArgumentError.new("Don't know how to handle #{address}")
							end
						end
					end
				end
				
				ready&.signal
			end
		end
	end
end
