# frozen_string_literal: true

require 'async/dns/server'
require 'async/dns/server_context'

describe Async::DNS::Server do
	include Async::DNS::ServerContext
	
	it "can resolve a domain name" do
		response = resolver.query("example.com")
		
		expect(response).to have_attributes(
			qr: be == 1,
			rcode: be == Resolv::DNS::RCode::NXDomain,
			question: have_attributes(size: be == 1),
			answer: be(:empty?)
		)
	end
end