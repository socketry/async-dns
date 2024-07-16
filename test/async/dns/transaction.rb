#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns'
require 'sus/fixtures/async'

IN = Resolv::DNS::Resource::IN

describe Async::DNS::Transaction do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:server) {Async::DNS::Server.new}
	let(:query) {Resolv::DNS::Message.new(0)}
	let(:question) {Resolv::DNS::Name.create("www.google.com.")}
	let(:response) {Resolv::DNS::Message.new(0)}
	let(:client) {Async::DNS::Client.new}
	
	it "should append an address" do
		transaction = Async::DNS::Transaction.new(server, query, question, IN::A, response)
		
		transaction.respond!("1.2.3.4")
		
		expect(transaction.response.answer[0][0]).to be == question
		expect(transaction.response.answer[0][2].address.to_s).to be == "1.2.3.4"
	end
	
	it "should passthrough the request" do
		transaction = Async::DNS::Transaction.new(server, query, question, IN::A, response)
		
		expect(transaction.response.answer.size).to be == 0
		
		transaction.passthrough!(client)
		
		expect(transaction.response.answer.size).to be > 0
	end
	
	it "should return a response on passthrough" do
		transaction = Async::DNS::Transaction.new(server, query, question, IN::A, response)
		
		expect(transaction.response.answer.size).to be == 0
		
		response = transaction.passthrough(client)
		
		expect(response.answer.length).to be > 0
	end
	
	it "should call the block with the response when invoking passthrough!" do
		transaction = Async::DNS::Transaction.new(server, query, question, IN::A, response)
		
		expect(transaction.response.answer.size).to be == 0
		
		passthrough_response = nil
		
		transaction.passthrough!(client) do |response|
			passthrough_response = response
		end
		
		expect(passthrough_response.answer.length).to be > 0
	end
	
	it "should fail the request" do
		transaction = Async::DNS::Transaction.new(server, query, question, IN::A, response)
		
		transaction.fail! :NXDomain
		
		expect(transaction.response.rcode).to be == Resolv::DNS::RCode::NXDomain
	end
	
	it "should return AAAA record" do
		transaction = Async::DNS::Transaction.new(server, query, question, IN::AAAA, response)
		
		expect(transaction.response.answer.size).to be == 0
		
		transaction.passthrough!(client)
		
		expect(transaction.response.answer.first[2]).to be_a IN::AAAA
	end
	
	it "should return MX record" do
		transaction = Async::DNS::Transaction.new(server,query,"google.com",IN::MX, response)
		
		expect(transaction.response.answer.size).to be == 0
		
		transaction.passthrough!(client)
		
		expect(transaction.response.answer.first[2]).to be_a IN::MX
	end
	
	it "should return NS record" do
		transaction = Async::DNS::Transaction.new(server, query, "google.com", IN::NS, response)
		
		expect(transaction.response.answer.size).to be == 0
		
		transaction.passthrough!(client)
		
		expect(transaction.response.answer.first[2]).to be_a IN::NS
	end
	
	it "should return PTR record" do
		transaction = Async::DNS::Transaction.new(server, query, "1.1.1.1.in-addr.arpa", IN::PTR, response)
		
		expect(transaction.response.answer.size).to be == 0
		
		transaction.passthrough!(client)
		
		expect(transaction.response.answer.first[2]).to be_a IN::PTR
	end
	
	it "should return SOA record" do
		transaction = Async::DNS::Transaction.new(server, query, "google.com", IN::SOA, response)
		
		expect(transaction.response.answer.size).to be == 0
		
		transaction.passthrough!(client)
		
		expect(transaction.response.answer.first[2]).to be_a IN::SOA
	end
end
