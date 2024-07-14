#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns'
require 'async/dns/system'

IN = Resolv::DNS::Resource::IN

class TestServer < Async::DNS::Server
	def process(name, resource_class, transaction)
		@resolver ||= Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
		
		transaction.passthrough!(@resolver)
	end
end

describe Async::DNS::StreamHandler do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:server_interfaces) {[TCPServer.new('127.0.0.1', 2002)]}
	let(:server) {TestServer.new(server_interfaces)}
	
	it "should create server with existing TCP socket" do
		task = server.run
		
		resolver = Async::DNS::Resolver.new([[:tcp, '127.0.0.1', 2002]])
		response = resolver.query('google.com')
		expect(response.class).to be == Async::DNS::Message
		
		task.stop
		server_interfaces.each(&:close)
	end
end

describe Async::DNS::DatagramHandler do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:server_interfaces) {[UDPSocket.new.tap{|socket| socket.bind('127.0.0.1', 2002)}]}
	let(:server) {TestServer.new(server_interfaces)}
	
	it "should create server with existing UDP socket" do
		task = server.run
		
		resolver = Async::DNS::Resolver.new([[:udp, '127.0.0.1', 2002]])
		response = resolver.query('google.com')
		expect(response.class).to be == Async::DNS::Message
		
		task.stop
		server_interfaces.each(&:close)
	end
end
