# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'stringio'
require 'ipaddr'

require_relative 'message'

module Async
	module DNS
		def self.address_family(host)
			return IPAddr.new(host).family
		end
		
		class Transport
			def initialize(socket)
				@stream = IO::Stream.new(socket)
			end
			
			def write_message(message)
				write_chunk(message.encode)
			end
			
			def read_chunk
				if size_data = @stream.read(2)
					# Read in the length, the first two bytes:
					size = size_data.unpack('n')[0]
					
					return @stream.read(size)
				end
			end
			
			def write_chunk(output_data)
				size_data = [output_data.bytesize].pack('n')
				
				@stream.write(size_data)
				@stream.write(output_data)
				
				@stream.flush
				
				return output_data.bytesize
			end
		end
	end
end
