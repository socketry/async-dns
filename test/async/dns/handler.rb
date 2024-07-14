# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2024, by Samuel Williams.

require 'async/dns'
require 'async/dns/system'

require 'sus/fixtures/async'

describe Async::DNS::StreamHandler do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:server) {Async::DNS::Server.new}
	let(:endpoint) {Async::IO::Endpoint.tcp('127.0.0.1', 6666, reuse_port: true)}
	
	it "can rebind port" do
		2.times do
			task = reactor.async do
				endpoint.bind do |socket|
					subject.new(server, socket).run
				end
			end
			
			task.stop
		end
	end
end

describe Async::DNS::DatagramHandler do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:server) {Async::DNS::Server.new}
	let(:endpoint) {Async::IO::Endpoint.udp('127.0.0.1', 6666)}
	
	it "can rebind port" do
		2.times do
			task = reactor.async do
				endpoint.bind do |socket|
					subject.new(server, socket).run
				end
			end
			
			task.stop
		end
	end
end
