#!/usr/bin/env ruby

gem 'async'
gem 'async-http'
gem 'trenni'

require 'async/reactor'
require 'async/http/client'
require 'async/http/url_endpoint'

require 'trenni/uri'

endpoint = Async::HTTP::URLEndpoint.parse("https://cloudflare-dns.com/dns-query")
client = Async::HTTP::Client.new(endpoint)

Async::Reactor.run do |task|
	request_uri = Trenni::URI(endpoint.url.request_uri, ct: "application/dns-json", name: "microsoft.com", type: "MX")
	
	puts "GET #{request_uri}"
	response = client.get(request_uri.to_s, {})
	
	puts "#{response.status} #{response.version} #{response.headers.inspect}"
	puts response.read.inspect
end
