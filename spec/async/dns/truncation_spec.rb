#!/usr/bin/env ruby

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
require 'async/dns/extensions/string'

module Async::DNS::TruncationSpec
	SERVER_PORTS = [[:udp, '127.0.0.1', 5520], [:tcp, '127.0.0.1', 5520]]
	IN = Resolv::DNS::Resource::IN
	
	class TestServer < Async::DNS::Server
		def process(name, resource_class, transaction)
			case [name, resource_class]
			when ["truncation", IN::TXT]
				text = "Hello World! " * 100
				transaction.respond!(*text.chunked)
			else
				transaction.fail!(:NXDomain)
			end
		end
	end
	
	describe "Async::DNS Truncation Server" do
		include_context Async::RSpec::Reactor
		
		let(:server) {TestServer.new(listen: SERVER_PORTS)}
		
		it "should use tcp because of large response" do
			task = server.run
			
			resolver = Async::DNS::Resolver.new(SERVER_PORTS)
	
			response = resolver.query("truncation", IN::TXT)
	
			text = response.answer.first
	
			expect(text[2].strings.join).to be == ("Hello World! " * 100)
			
			task.stop
		end
	end
end
