# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns'

require 'sus/fixtures/async'

IN = Resolv::DNS::Resource::IN

class SlowServer < Async::DNS::Server
	def process(name, resource_class, transaction)
		sleep(2) if name.end_with?('.com')
		
		transaction.fail!(:NXDomain)
	end
end

describe "Async::DNS Slow Server" do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:server_interfaces) {[[:udp, '0.0.0.0', 5330], [:tcp, '0.0.0.0', 5330]]}
	let(:server) {SlowServer.new(server_interfaces)}
	
	def before
		super
		
		@server_task = server.run
	end
	
	def after
		@server_task&.stop
		
		super
	end
	
	it "get no answer after 2 seconds" do
		
		start_time = Async::Clock.now
		
		resolver = Async::DNS::Resolver.new(server_interfaces, timeout: 10)
		
		response = resolver.query("apple.com", IN::A)
		
		expect(response.answer.length).to be == 0
		
		duration = Async::Clock.now - start_time
		
		expect(duration).to be_within(1.0).of(2.0)
	end

	it "times out after 1 second" do
		start_time = Time.now
		
		# Two server interfaces, timeout of 0.5s each:
		resolver = Async::DNS::Resolver.new(server_interfaces, timeout: 0.5)
		
		response = resolver.query("apple.com", IN::A)
		
		expect(response).to be_nil
		
		end_time = Time.now
		
		expect(end_time - start_time).to be_within(0.5).of(1.0)
	end

	it "gets no answer immediately" do
		start_time = Time.now
		
		resolver = Async::DNS::Resolver.new(server_interfaces, timeout: 0.5)
		
		response = resolver.query("oriontransfer.org", IN::A)
		
		expect(response.answer.length).to be == 0
		
		end_time = Time.now
		
		expect(end_time - start_time).to be_within(0.1).of(0.0)
	end
end
