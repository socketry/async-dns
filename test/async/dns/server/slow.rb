# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2025, by Samuel Williams.

require "async/dns/server_context"
require "async/dns/extensions/string"

class SlowServer < Async::DNS::Server
	def process(name, resource_class, transaction)
		sleep(1) if name.end_with?(".com")
		
		transaction.fail!(:NXDomain)
	end
end

IN = Resolv::DNS::Resource::IN

describe Async::DNS::Server do
	include Async::DNS::ServerContext
	
	def make_server(endpoint)
		SlowServer.new(endpoint)
	end
	
	def make_resolver(endpoint)
		Async::DNS::Resolver.new(endpoint.with(timeout: 0.1))
	end
	
	it "should fail with non-existent domain" do
		response = resolver.query("example.net", IN::A)
		expect(response.rcode).to be == Resolv::DNS::RCode::NXDomain
	end
	
	it "should fail with timeout" do
		skip_unless_method_defined(:timeout, IO)
		
		expect do
			resolver.query("example.com", IN::A)
		end.to raise_exception(IO::TimeoutError)
	end
end
