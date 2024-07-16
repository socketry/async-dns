# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'stringio'
require 'ipaddr'

module Async
	module DNS
		def self.address_family(host)
			return IPAddr.new(host).family
		end
		
		class Transport
			def initialize(socket)
				@socket = socket
			end
			
			def write_message(message)
				write_chunk(message.encode)
			end
			
			def read_chunk
				if size_data = @socket.read(2)
					# Read in the length, the first two bytes:
					size = size_data.unpack('n')[0]
					
					return @socket.read(size)
				end
			end
			
			def write_chunk(data)
				size_data = [data.bytesize].pack('n')
				@socket.write(size_data)
				@socket.write(data)
				@socket.flush
			end
		end
	end
end
