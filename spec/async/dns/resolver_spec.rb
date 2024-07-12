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

require_relative 'junk_server_context'

RSpec.describe Async::DNS::Resolver do
	include_context Async::RSpec::Reactor
	
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
	
	context 'with junk UDP server' do
		include_context 'Junk UDP Server'
		
		it "should fail with decode error" do
			resolver = Async::DNS::Resolver.new([[:udp, "0.0.0.0", 6060]])
			
			response = resolver.query('google.com')
			
			expect(response).to be == nil
		end
	end
	
	context 'with junk TCP server' do
		include_context 'Junk TCP Server'
		
		it "should fail with decode error" do
			resolver = Async::DNS::Resolver.new([[:tcp, "0.0.0.0", 6060]])
			
			response = resolver.query('google.com')
			
			expect(response).to be == nil
		end
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

	it "should default to system resolvers" do
		resolver = Async::DNS::Resolver.new()

		response = resolver.query('google.com')

		expect(response.class).to be == Async::DNS::Message
		expect(response.answer.size).to be > 0
	end
end
