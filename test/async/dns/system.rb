#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns'
require 'async/dns/system'

describe Async::DNS::System do
	include Sus::Fixtures::Async::ReactorContext
	
	it "should have at least one namesever" do
		expect(Async::DNS::System::nameservers.length).to be > 0
	end
	
	it "should respond to query for google.com" do
		resolver = Async::DNS::Resolver.new(Async::DNS::System.nameservers)
		
		response = resolver.query('google.com')
		
		expect(response.class).to be == Async::DNS::Message
		expect(response.rcode).to be == Resolv::DNS::RCode::NoError
	end
end

describe Async::DNS::System::Hosts do
	it "should parse the hosts file" do
		hosts = Async::DNS::System::Hosts.new
	
		# Load the test hosts data:
		File.open(File.expand_path("../hosts.txt", __FILE__)) do |file|
			hosts.parse_hosts(file)
		end
	
		expect(hosts.call('testing')).to be == true
		expect(hosts['testing']).to be == '1.2.3.4'
	end
end
