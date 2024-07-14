# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns'
require 'async/dns/replace'

describe Async::DNS::Replace do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:default_resolver) {Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])}
	
	it "should replace TCPSocket hostname lookup" do
		mock(Async::DNS::Replace) do |mock|
			mock.replace(:resolver) do
				default_resolver
			end
		end
		
		expect(default_resolver).to receive(:addresses_for).with('www.google.com')
		
		socket = TCPSocket.new('www.google.com', 80)
	end
end
