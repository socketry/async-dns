# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

RSpec.shared_context "Junk UDP Server" do
	let(:server_endpoint) {Async::IO::Endpoint.udp('0.0.0.0', 6060, reuse_port: true)}
	
	let!(:server_task) do
		reactor.async do
			server_endpoint.bind do |socket|
				begin
					while true
						data, address = socket.recvfrom(1024)
						socket.send("foobar", 0, address)
					end
				rescue
					socket.close
				end
			end
		end
	end
	
	after(:each) do
		server_task.stop
	end
end

RSpec.shared_context "Junk TCP Server" do
	let(:server_endpoint) {Async::IO::Endpoint.tcp('0.0.0.0', 6060, reuse_port: true)}
	
	let!(:server_task) do
		reactor.async do
			server_endpoint.accept do |socket|
				begin
					socket.write("f\0\0bar")
				rescue
					socket.close
				end
			end
		end
	end
	
	after(:each) do
		server_task.stop
	end
end
