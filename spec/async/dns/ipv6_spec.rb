#!/usr/bin/env ruby

# Copyright, 2014, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

module Async::DNS::IPv6Spec
	IN = Resolv::DNS::Resource::IN
	
	class TestServer < Async::DNS::Server
		def process(name, resource_class, transaction)
			@resolver ||= Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
			
			transaction.passthrough!(@resolver)
		end
	end
	
	describe Async::DNS::TCPSocketHandler do
		let(:server_interfaces) {[[:tcp, '::', 2004]]}
		let(:server) {TestServer.new(listen: server_interfaces)}
		
		include_context "reactor"
		
		it "should connect to the server using TCP via IPv6" do
			server.run
			
			resolver = Async::DNS::Resolver.new([[:tcp, '::1', 2004]])
			
			response = resolver.query('google.com')
			
			expect(response.class).to be == Async::DNS::Message
			expect(response.rcode).to be == 0
			expect(response.answer).to_not be_empty
			
			server.stop
		end
	end
	
	describe Async::DNS::UDPSocketHandler do
		let(:server_interfaces) {[[:udp, '::', 2006]]}
		let(:server) {TestServer.new(listen: server_interfaces)}
		
		include_context "reactor"
		
		it "should connect to the server using UDP via IPv6" do
			server.run
			
			resolver = Async::DNS::Resolver.new([[:udp, '::1', 2006]])
			
			response = resolver.query('google.com')
			
			expect(response.class).to be == Async::DNS::Message
			expect(response.rcode).to be == 0
			expect(response.answer).to_not be_empty
			
			server.stop
		end
	end
end
