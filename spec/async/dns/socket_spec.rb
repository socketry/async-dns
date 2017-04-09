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

module Async::DNS::SocketSpec
	IN = Resolv::DNS::Resource::IN
	
	class TestServer < Async::DNS::Server
		def process(name, resource_class, transaction)
			@resolver ||= Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
			
			transaction.passthrough!(@resolver)
		end
	end
	
	describe Async::DNS::TCPSocketHandler do
		include_context "reactor"
		
		let(:server_interfaces) {[TCPServer.new('127.0.0.1', 2002)]}
		let(:server) {TestServer.new(listen: server_interfaces)}
		
		it "should create server with existing TCP socket" do
			task = server.run
			
			resolver = Async::DNS::Resolver.new([[:tcp, '127.0.0.1', 2002]])
			response = resolver.query('google.com')
			expect(response.class).to be == Async::DNS::Message
			
			task.stop
		end
	end
	
	describe Async::DNS::UDPSocketHandler do
		include_context "reactor"
		
		let(:server_interfaces) {[UDPSocket.new.tap{|socket| socket.bind('127.0.0.1', 2002)}]}
		let(:server) {TestServer.new(listen: server_interfaces)}
		
		it "should create server with existing UDP socket" do
			task = server.run
			
			resolver = Async::DNS::Resolver.new([[:udp, '127.0.0.1', 2002]])
			response = resolver.query('google.com')
			expect(response.class).to be == Async::DNS::Message
			
			task.stop
		end
	end
end
