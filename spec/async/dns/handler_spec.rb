# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'async/dns'
require 'async/dns/system'

describe Async::DNS::TCPServerHandler do
	let(:server) {Async::DNS::Server.new}
	let(:host) {'127.0.0.1'}
	let(:port) {6665}
	
	subject {described_class.new(server, host, port)}
	
	it "can rebind port" do
		2.times do
			socket = subject.send(:make_socket)
			expect(socket).to_not be_closed
			
			socket.close
			expect(socket).to be_closed
		end
	end
end

describe Async::DNS::UDPServerHandler do
	let(:server) {Async::DNS::Server.new}
	let(:host) {'127.0.0.1'}
	let(:port) {6665}
	
	subject {described_class.new(server, host, port)}
	
	it "can rebind port" do
		2.times do
			socket = subject.send(:make_socket)
			expect(socket).to_not be_closed
			
			socket.close
			expect(socket).to be_closed
		end
	end
end
