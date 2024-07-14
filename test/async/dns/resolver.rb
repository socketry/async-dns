#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.
# Copyright, 2024, by Sean Dilda.

require 'async/dns'

require 'sus/fixtures/async'

AJunkUDPServer = Sus::Shared("a junk UDP server") do
	let(:server_endpoint) {Async::IO::Endpoint.udp('0.0.0.0', 6060, reuse_port: true)}
	
	def before
		super
		
		@server_task = reactor.async do
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
	
	def after
		@server_task&.stop
	end
end

AJunkTCPServer = Sus::Shared("a junk TCP server") do
	let(:server_endpoint) {Async::IO::Endpoint.tcp('0.0.0.0', 6060, reuse_port: true)}
	
	def before
		super
		
		@server_task = reactor.async do
			server_endpoint.accept do |socket|
				begin
					socket.write("f\0\0bar")
				rescue
					socket.close
				end
			end
		end
	end
	
	def after
		@server_task&.stop
	end
end

describe Async::DNS::Resolver do
	include Sus::Fixtures::Async::ReactorContext
	
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

		expect{resolver.addresses_for('google.com')}.to raise_exception(Async::DNS::ResolutionFailure)
	end
	
	with 'junk UDP server' do
		include_context AJunkUDPServer
		
		it "should fail with decode error" do
			resolver = Async::DNS::Resolver.new([[:udp, "0.0.0.0", 6060]])
			
			response = resolver.query('google.com')
			
			expect(response).to be == nil
		end
	end
	
	with 'junk TCP server' do
		include_context AJunkTCPServer
		
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
			expect(address).to be_a(Resolv::IPv4) | be_a(Resolv::IPv6)
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
