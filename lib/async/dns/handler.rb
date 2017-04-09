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

require_relative 'transport'

module Async::DNS
	class GenericHandler
		def initialize(server)
			@server = server
			@logger = @server.logger || Async.logger
		end
		
		def error_response(query = nil, code = Resolv::DNS::RCode::ServFail)
			# Encoding may fail, so we need to handle this particular case:
			server_failure = Resolv::DNS::Message::new(query ? query.id : 0)
			
			server_failure.qr = 1
			server_failure.opcode = query ? query.opcode : 0
			server_failure.aa = 1
			server_failure.rd = 0
			server_failure.ra = 0

			server_failure.rcode = code

			# We can't do anything at this point...
			return server_failure
		end
		
		def process_query(data, options)
			@logger.debug "<> Receiving incoming query (#{data.bytesize} bytes) to #{self.class.name}..."
			query = nil

			begin
				query = Async::DNS::decode_message(data)
				
				return @server.process_query(query, options)
			rescue StandardError => error
				@logger.error "<> Error processing request: #{error.inspect}!"
				Async::DNS::log_exception(@logger, error)
				
				return error_response(query)
			end
		end
	end
	
	# Handling incoming UDP requests, which are single data packets, and pass them on to the given server.
	class UDPHandler < GenericHandler
		def run(socket, reactor:)
			Async.logger.debug(self.class.name) {"-> Run on #{socket}..."}
			
			while true
				Async.logger.debug(self.class.name) {"-> socket.recvfrom"}
				input_data, (_, remote_port, remote_host) = socket.recvfrom(UDP_TRUNCATION_SIZE)
				Async.logger.debug(self.class.name) {"<- socket.recvfrom"}
				
				reactor.async do
					respond(socket, input_data, remote_host, remote_port)
				end
			end
		ensure
			Async.logger.debug(self.class.name) {"<- Run ensure... #{$!}"}
		end
		
		def respond(socket, input_data, remote_host, remote_port)
			options = {peer: remote_host, port: remote_port, proto: :udp}
			
			response = process_query(input_data, options)
			
			output_data = response.encode
			
			@logger.debug "<#{response.id}> Writing #{output_data.bytesize} bytes response to client via UDP..."
			
			if output_data.bytesize > UDP_TRUNCATION_SIZE
				@logger.warn "<#{response.id}>Response via UDP was larger than #{UDP_TRUNCATION_SIZE}!"
				
				# Reencode data with truncation flag marked as true:
				truncation_error = Resolv::DNS::Message.new(response.id)
				truncation_error.tc = 1
				
				output_data = truncation_error.encode
			end
			
			socket.send(output_data, 0, remote_host, remote_port)
		rescue IOError => error
			@logger.warn "<> UDP response failed: #{error.inspect}!"
		rescue EOFError => error
			@logger.warn "<> UDP session ended prematurely: #{error.inspect}!"
		rescue DecodeError
			@logger.warn "<> Could not decode incoming UDP data!"
		end
	end
	
	class UDPSocketHandler < UDPHandler
		def initialize(server, socket)
			@socket = socket
			
			super(server)
		end
		
		attr :socket
		
		def run(reactor: Async::Task.current.reactor)
			reactor.async(self.socket) do |socket|
				super(socket, reactor: reactor)
			end
		end
	end
	
	class UDPServerHandler < UDPHandler
		def initialize(server, host, port)
			@host = host
			@port = port
			
			super(server)
		end
		
		attr :host
		attr :port
		
		def run(reactor: Async::Task.current.reactor)
			reactor.with(make_socket) do |socket|
				super(socket, reactor: reactor)
			end
		end
		
		private
		
		def make_socket
			family ||= Async::DNS::address_family(@host)
			
			socket = ::UDPSocket.new(family)
			socket.bind(@host, @port)
			
			return socket
		end
	end
	
	class TCPHandler < GenericHandler
		def run(socket, reactor:)
			Async.logger.debug(self.class.name) {"-> Run on #{socket}..."}
			
			reactor.with(socket.accept) do |client|
				handle_connection(client)
			end while true
		ensure
			Async.logger.debug(self.class.name) {"<- Run ensure... #{$!}"}
		end
		
		def handle_connection(socket)
			context = Async::Task.current
			
			_, remote_port, remote_host = socket.io.peeraddr
			options = {peer: remote_host, port: remote_port, proto: :tcp}
			
			input_data = StreamTransport.read_chunk(socket)
			
			response = process_query(input_data, options)
			
			length = StreamTransport.write_message(socket, response)
			
			@logger.debug "<#{response.id}> Wrote #{length} bytes via TCP..."
		rescue EOFError => error
			@logger.warn "<> Error: TCP session ended prematurely!"
		rescue Errno::ECONNRESET => error
			@logger.warn "<> Error: TCP connection reset by peer!"
		rescue Errno::EPIPE
			@logger.warn "<> Error: TCP session failed due to broken pipe!"
		rescue DecodeError
			@logger.warn "<> Error: Could not decode incoming TCP data!"
		end
	end
	
	class TCPSocketHandler < TCPHandler
		def initialize(server, socket)
			@socket = socket
			
			super(server)
		end
		
		attr :socket
		
		def run(reactor: Async::Task.current.reactor)
			reactor.async(@socket) do |socket|
				super(socket, reactor: reactor)
			end
		end
	end
	
	class TCPServerHandler < TCPHandler
		def initialize(server, host, port)
			@host = host
			@port = port
			
			super(server)
		end
		
		attr :host
		attr :port
		
		def run(reactor: Async::Task.current.reactor)
			reactor.with(make_socket) do |socket|
				super(socket, reactor: reactor)
			end
		end
		
		private
		
		def make_socket
			::TCPServer.new(@host, @port)
		end
	end
end
