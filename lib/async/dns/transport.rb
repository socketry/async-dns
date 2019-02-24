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
