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

require 'celluloid/dns'
require 'celluloid/dns/system'

module Celluloid::DNS::SocketSpec
	IN = Resolv::DNS::Resource::IN
	
	class TestServer < Celluloid::DNS::Server
		def process(name, resource_class, transaction)
			@resolver ||= Celluloid::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
			
			transaction.passthrough!(@resolver)
		end
	end
	
	describe Celluloid::DNS::TCPSocketHandler do
		after(:each) do
			@server.terminate
		end
		
		it "should create server with existing TCP socket" do
			socket = TCPServer.new('127.0.0.1', 2002)
			
			@server = TestServer.new(listen: [socket])
			@server.run
			
			resolver = Celluloid::DNS::Resolver.new([[:tcp, '127.0.0.1', 2002]])
			response = resolver.query('google.com')
			expect(response.class).to be == Celluloid::DNS::Message
		end
	end
	
	describe Celluloid::DNS::UDPSocketHandler do
		after(:each) do
			@server.terminate
		end
		
		it "should create server with existing UDP socket" do
			socket = UDPSocket.new
			socket.bind('127.0.0.1', 2002)
			
			@server = TestServer.new(listen: [socket])
			@server.run
			
			resolver = Celluloid::DNS::Resolver.new([[:udp, '127.0.0.1', 2002]])
			response = resolver.query('google.com')
			expect(response.class).to be == Celluloid::DNS::Message
		end
	end
end
