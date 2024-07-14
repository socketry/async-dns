# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.
# Copyright, 2021, by Mike Perham.

require_relative 'transport'

module Async::DNS
	class GenericHandler
		def initialize(server, socket)
			@server = server
			@socket = socket
		end
		
		attr :server
		attr :socket
		
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
			Console.debug "<> Receiving incoming query (#{data.bytesize} bytes) to #{self.class.name}..."
			query = nil

			begin
				query = Async::DNS::decode_message(data)
				
				return @server.process_query(query, options)
			rescue StandardError => error
				Console.error(self) { error }
				
				return error_response(query)
			end
		end
	end
	
	# Handling incoming UDP requests, which are single data packets, and pass them on to the given server.
	class DatagramHandler < GenericHandler
		def run(task: Async::Task.current)
			while true
				input_data, remote_address = @socket.recvmsg(UDP_TRUNCATION_SIZE)
				
				task.async do
					respond(@socket, input_data, remote_address)
				end
			end
		end
		
		def respond(socket, input_data, remote_address)
			response = process_query(input_data, remote_address: remote_address)
			
			output_data = response.encode
			
			Console.debug "<#{response.id}> Writing #{output_data.bytesize} bytes response to client via UDP..."
			
			if output_data.bytesize > UDP_TRUNCATION_SIZE
				Console.warn "<#{response.id}> Response via UDP was larger than #{UDP_TRUNCATION_SIZE}!"
				
				# Reencode data with truncation flag marked as true:
				truncation_error = Resolv::DNS::Message.new(response.id)
				truncation_error.tc = 1
				
				output_data = truncation_error.encode
			end
			
			socket.sendmsg(output_data, 0, remote_address)
		rescue IOError => error
			Console.warn "<> UDP response failed: #{error.inspect}!"
		rescue EOFError => error
			Console.warn "<> UDP session ended prematurely: #{error.inspect}!"
		rescue DecodeError
			Console.warn "<> Could not decode incoming UDP data!"
		end
	end
	
	class StreamHandler < GenericHandler
		def run(wrapper = ::IO::Endpoint::Wrapper.default, **options)
			wrapper.accept(@socket, **options) do |peer|
				handle_connection(peer)
			end
		end
		
		def handle_connection(socket)
			transport = Transport.new(socket)
			
			while input_data = transport.read_chunk
				response = process_query(input_data, remote_address: socket.remote_address)
				length = transport.write_message(response)
				
				Console.debug "<#{response.id}> Wrote #{length} bytes via TCP..."
			end
		rescue EOFError => error
			Console.warn "<> Error: TCP session ended prematurely!"
		rescue Errno::ECONNRESET => error
			Console.warn "<> Error: TCP connection reset by peer!"
		rescue Errno::EPIPE
			Console.warn "<> Error: TCP session failed due to broken pipe!"
		rescue DecodeError
			Console.warn "<> Error: Could not decode incoming TCP data!"
		end
	end
end
