# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require "stringio"
require "ipaddr"

module Async
	module DNS
		# A simple DNS message stream encoder/decoder.
		class Transport
			# Create a new transport.
			#
			# @parameter socket [IO] The socket to read/write from.
			def initialize(socket)
				@socket = socket
			end
			
			# Write a message to the socket.
			#
			# @parameter message [Resolv::DNS::Message] The message to write.
			def write_message(message)
				write_chunk(message.encode)
			end
			
			# Read a chunk from the socket.
			#
			# @returns [String] The data read from the socket.
			def read_chunk
				if size_data = @socket.read(2)
					# Read in the length, the first two bytes:
					size = size_data.unpack("n")[0]
					
					return @socket.read(size)
				end
			end
			
			# Write a chunk to the socket.
			#
			# @parameter data [String] The data to write.
			def write_chunk(data)
				size_data = [data.bytesize].pack("n")
				@socket.write(size_data)
				@socket.write(data)
				@socket.flush
			end
		end
	end
end
