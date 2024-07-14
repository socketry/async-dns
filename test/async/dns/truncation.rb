#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns'
require 'async/dns/extensions/string'

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
	include Sus::Fixtures::Async::ReactorContext
	
	let(:server) {TestServer.new(SERVER_PORTS)}
	
	it "should use tcp because of large response" do
		task = server.run
		
		sleep 0.1
		
		resolver = Async::DNS::Resolver.new(SERVER_PORTS)
		
		response = resolver.query("truncation", IN::TXT)
		
		text = response.answer.first
		
		expect(text[2].strings.join).to be == ("Hello World! " * 100)
		
		task.stop
	end
end
