# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns/server_context'
require 'async/dns/extensions/string'

class TruncatedServer < Async::DNS::Server
	def process(name, resource_class, transaction)
		case [name, resource_class]
		when ["truncation-100", IN::TXT]
			text = "Hello World! " * 1000
			transaction.respond!(*text.chunked)
		else
			transaction.fail!(:NXDomain)
		end
	end
end

IN = Resolv::DNS::Resource::IN

describe Async::DNS::Server do
	include Async::DNS::ServerContext
	
	def make_server(endpoint)
		TruncatedServer.new(endpoint)
	end
	
	it "should use tcp because of large response" do
		response = resolver.query("truncation-100", IN::TXT)
		text = response.answer.first
		expect(text[2].strings.join).to be == ("Hello World! " * 1000)
	end
end
