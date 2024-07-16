# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.
# Copyright, 2021, by Mike Perham.

require 'resolv'
require_relative 'extensions/resolv'

require_relative 'transport'

module Async::DNS
	# The maximum size of a normal DNS packet (excluding EDNS).
	UDP_REASONABLE_SIZE = 512
	
	# The maximum size of a UDP packet.
	UDP_MAXIMUM_SIZE = 2**16
	
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
			Console.debug "Receiving incoming query (#{data.bytesize} bytes) to #{self.class.name}..."
			query = nil

			begin
				query = Resolv::DNS::Message.decode(data)
				
				return @server.process_query(query, options)
			rescue StandardError => error
				Console::Event::Failure.for(error).emit "Failed to process query!"
				
				return error_response(query)
			end
		end
	end
	
	# Handling incoming UDP requests, which are single data packets, and pass them on to the given server.
	class DatagramHandler < GenericHandler
		def run(task: Async::Task.current)
			while true
				input_data, remote_address = @socket.recvmsg(UDP_MAXIMUM_SIZE)
				
				task.async do
					respond(@socket, input_data, remote_address)
				end
			end
		end
		
		def respond(socket, input_data, remote_address)
			response = process_query(input_data, remote_address: remote_address)
			
			output_data = response.encode
			
			Console.debug "Writing #{output_data.bytesize} bytes response to client via UDP...", response_id: response.id
			
			if output_data.bytesize > UDP_REASONABLE_SIZE
				Console.warn "Response via UDP was larger than #{UDP_REASONABLE_SIZE}!", response_id: response.id
				
				# Reencode data with truncation flag marked as true:
				truncation_error = Resolv::DNS::Message.new(response.id)
				truncation_error.tc = 1
				
				output_data = truncation_error.encode
			end
			
			socket.sendmsg(output_data, 0, remote_address)
		rescue IOError => error
			Console::Event::Failure.for(error).emit "UDP response failed!"
		rescue EOFError => error
			Console::Event::Failure.for(error).emit "UDP session ended prematurely!"
		rescue Resolv::DNS::DecodeError => error
			Console::Event::Failure.for(error).emit "Could not decode incoming UDP data!"
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
				
				Console.debug "Wrote #{length} bytes via TCP...", response_id: response.id
			end
		rescue EOFError => error
			Console::Event::Failure.for(error).emit "TCP session ended prematurely!"
		rescue Errno::ECONNRESET => error
			Console::Event::Failure.for(error).emit "TCP connection reset by peer!"
		rescue Errno::EPIPE => error
			Console::Event::Failure.for(error).emit "TCP session failed due to broken pipe!"
		rescue Resolv::DNS::DecodeError => error
			Console::Event::Failure.for(error).emit "Could not decode incoming TCP data!"
		end
	end
end
