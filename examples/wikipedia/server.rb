#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'cgi'
require 'json'

require 'async/http'
require 'async/dns/server'
require 'async/dns/extensions/string'

# Encapsulates the logic for fetching information from Wikipedia.
module Wikipedia
	ENDPOINT = Async::HTTP::Endpoint.parse("https://en.wikipedia.org")
	
	def self.lookup(title)
		client = Async::HTTP::Client.new(ENDPOINT)
		url = self.summary_url(title)
		
		response = client.get(url, headers: {"user-agent" => "RubyDNS"})
		
		if response.status == 301
			return lookup(response.headers['location'])
		else
			return self.extract_summary(response.body.read).force_encoding('ASCII-8BIT')
		end
	ensure
		response&.close
		client&.close
	end
	
	def self.summary_url(title)
		"/api/rest_v1/page/summary/#{CGI.escape title}"
	end

	def self.extract_summary(json_text)
		document = JSON.parse(json_text)
		
		return document['extract']
	rescue
		return 'Invalid Article.'
	end
end

# A DNS server that queries Wikipedia and returns summaries for
# specifically crafted queries.
class WikipediaDNS < Async::DNS::Server
	def process(name, resource_class, transaction)
		Console.info(self) {"Processing: #{name} #{resource_class}"}
		if name =~ /^(.+)\.wikipedia$/
			title = $1
			summary = Wikipedia.lookup(title)
			
			transaction.respond!(*summary.chunked)
		else
			transaction.fail!(:NXDomain)
		end
	end
end

Async do
	endpoint = Async::DNS::Server.default_endpoint(5300)
	WikipediaDNS.new(endpoint).run
end
