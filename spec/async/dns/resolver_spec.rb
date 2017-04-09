#!/usr/bin/env rspec

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

module Async::DNS::ResolverSpec
	describe Async::DNS::Resolver do
		class JunkUDPServer
			def initialize
				@socket = UDPSocket.new
				@socket.bind("0.0.0.0", 6060)
			end
		
			def stop
				@task.stop
				@socket.close
			end
	
			def run(reactor: Async::Task.current.reactor)
				@task = reactor.async(@socket) do |socket|
					data, (_, port, host) = socket.recvfrom(1024)
					socket.send("Foobar", 0, host, port)
				end
			end
		end

		class JunkTCPServer
			def initialize
				@socket = TCPServer.new("0.0.0.0", 6060)
			end
			
			def stop
				@task.stop
				@socket.close
			end
			
			def run(reactor: Async::Task.current.reactor)
				# @logger.debug "Waiting for incoming TCP connections #{@socket.inspect}..."
				@task = reactor.async(@socket) do |socket|
					reactor.with(socket.accept) do |client|
						handle_connection(client)
					end while true
				end
			end
			
			def handle_connection(socket)
				socket.write("\0\0obar")
			end
		end
		
		include_context "reactor"
		
		it "should result in non-existent domain" do
			resolver = Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
	
			response = resolver.query('foobar.oriontransfer.org')
	
			expect(response.rcode).to be == Resolv::DNS::RCode::NXDomain
		end

		it "should result in some answers" do
			resolver = Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
	
			response = resolver.query('google.com')
	
			expect(response.class).to be == Async::DNS::Message
			expect(response.answer.size).to be > 0
		end

		it "should return no results" do
			resolver = Async::DNS::Resolver.new([])
	
			response = resolver.query('google.com')
	
			expect(response).to be == nil
		end

		it "should fail to get addresses" do
			resolver = Async::DNS::Resolver.new([])
	
			expect{resolver.addresses_for('google.com')}.to raise_error(Async::DNS::ResolutionFailure)
		end
		
		let(:udp_server) {JunkUDPServer.new}
		
		it "should fail with decode error from bad udp server" do
			udp_server.run
			
			resolver = Async::DNS::Resolver.new([[:udp, "0.0.0.0", 6060]])
			
			response = resolver.query('google.com')
			
			expect(response).to be == nil
			
			udp_server.stop
		end
		
		let(:tcp_server) {JunkTCPServer.new}
		
		it "should fail with decode error from bad tcp server" do
			tcp_server.run
			
			resolver = Async::DNS::Resolver.new([[:tcp, "0.0.0.0", 6060]])
			
			response = resolver.query('google.com')
			
			expect(response).to be == nil
			
			tcp_server.stop
		end

		it "should return some IPv4 and IPv6 addresses" do
			resolver = Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
	
			addresses = resolver.addresses_for("www.google.com.")
	
			expect(addresses.size).to be > 0
	
			addresses.each do |address|
				expect(address).to be_kind_of(Resolv::IPv4) | be_kind_of(Resolv::IPv6)
			end
		end
		
		it "should recursively resolve CNAME records" do
			resolver = Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
			
			addresses = resolver.addresses_for('www.baidu.com')
			
			expect(addresses.size).to be > 0
		end
	end
end
