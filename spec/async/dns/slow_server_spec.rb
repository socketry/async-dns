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

module Async::DNS::SlowServerSpec
	IN = Resolv::DNS::Resource::IN
	
	class SlowServer < Async::DNS::Server
		def process(name, resource_class, transaction)
			@resolver ||= Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
			
			Async::Task.current.sleep(2) if name.end_with?('.com')
			
			transaction.fail!(:NXDomain)
		end
	end
	
	describe "Async::DNS Slow Server" do
		include_context Async::RSpec::Reactor
		
		let(:server_interfaces) {[[:udp, '0.0.0.0', 5330], [:tcp, '0.0.0.0', 5330]]}
		let(:server) {SlowServer.new(listen: server_interfaces)}
		
		around(:each) do |example|
			begin
				task = server.run
				
				example.run
			ensure
				task.stop
			end
		end
		
		it "get no answer after 2 seconds" do
			start_time = Time.now
			
			resolver = Async::DNS::Resolver.new(server_interfaces, :timeout => 10)
			
			response = resolver.query("apple.com", IN::A)
			
			expect(response.answer.length).to be == 0
			
			end_time = Time.now
			
			expect(end_time - start_time).to be_within(0.1).of(2.0)
		end
	
		it "times out after 1 second" do
			start_time = Time.now
			
			# Two server interfaces, timeout of 0.5s each:
			resolver = Async::DNS::Resolver.new(server_interfaces, :timeout => 0.5)
			
			response = resolver.query("apple.com", IN::A)
			
			expect(response).to be nil
			
			end_time = Time.now
			
			expect(end_time - start_time).to be_within(0.1).of(1.0)
		end
	
		it "gets no answer immediately" do
			start_time = Time.now
			
			resolver = Async::DNS::Resolver.new(server_interfaces, :timeout => 0.5)
			
			response = resolver.query("oriontransfer.org", IN::A)
			
			expect(response.answer.length).to be 0
			
			end_time = Time.now
			
			expect(end_time - start_time).to be_within(0.1).of(0.0)
		end
	end
end
