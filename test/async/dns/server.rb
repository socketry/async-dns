# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'async/dns/server'
require 'async/dns/server_context'
require 'async/dns/test_server'

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
	
	with 'default resolver' do
		def make_server(endpoint)
			Async::DNS::TestServer.new(endpoint)
		end
		
		it "can resolve a domain name" do
			response = resolver.query("www.google.com")
			
			expect(response).to have_attributes(
				qr: be == 1,
				rcode: be == Resolv::DNS::RCode::NoError,
				question: have_attributes(size: be == 1),
				answer: have_attributes(size: be > 0)
			)
		end
		
		it "can resolve non-existent domain name" do
			response = resolver.query("foobar.example.com")
			
			expect(response).to have_attributes(
				qr: be == 1,
				rcode: be == Resolv::DNS::RCode::NXDomain,
				question: have_attributes(size: be == 1),
				answer: be(:empty?)
			)
		end
		
		it "should return IPv4 and IPv6 addresses" do
			response = resolver.query("www.google.com", Resolv::DNS::Resource::IN::A)
			
			expect(response).to have_attributes(
				qr: be == 1,
				rcode: be == Resolv::DNS::RCode::NoError,
				question: have_attributes(size: be == 1),
				answer: have_attributes(size: be > 0)
			)
		end
	end
	
	with 'a large response' do
		def make_server(endpoint)
			Async::DNS::TestServer.new(endpoint)
		end
	end
end
