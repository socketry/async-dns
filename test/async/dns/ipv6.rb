#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns'
require 'async/dns/system'

require 'sus/fixtures/async'

class IPV6TestServer < Async::DNS::Server
	def process(name, resource_class, transaction)
		@resolver ||= Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
		
		transaction.passthrough!(@resolver)
	end
end

describe Async::DNS::StreamHandler do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::IO::Endpoint.tcp('::', 2004)}
	
	it "should connect to the server using TCP via IPv6" do
		server_endpoint = Async::IO::SharedEndpoint.bound(endpoint)
		server = IPV6TestServer.new([server_endpoint])
		task = server.run
		
		resolver = Async::DNS::Resolver.new([[:tcp, '::1', 2004]])
		
		response = resolver.query('google.com')
		
		expect(response.class).to be == Async::DNS::Message
		expect(response.rcode).to be == 0
		expect(response.answer).not.to be(:empty?)
		
		task.stop
	ensure
		server_endpoint.close
	end
end

describe Async::DNS::DatagramHandler do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::IO::Endpoint.udp('::', 2006)}
	
	it "should connect to the server using UDP via IPv6" do
		server_endpoint = Async::IO::SharedEndpoint.bound(endpoint)
		server = IPV6TestServer.new([server_endpoint])
		task = server.run
		
		resolver = Async::DNS::Resolver.new([[:udp, '::1', 2006]])
		
		response = resolver.query('google.com')
		
		expect(response.class).to be == Async::DNS::Message
		expect(response.rcode).to be == 0
		expect(response.answer).not.to be(:empty?)
		
		task.stop
	ensure
		server_endpoint.close
	end
end
