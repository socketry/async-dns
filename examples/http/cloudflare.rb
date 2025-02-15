#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

gem "async"
gem "async-http"
gem "xrb"

require "async/reactor"
require "async/http/client"
require "async/http/endpoint"

require "xrb/uri"

endpoint = Async::HTTP::Endpoint.parse("https://1.1.1.1/dns-query")
client = Async::HTTP::Client.new(endpoint)

Sync do
	request_uri = XRB::URI(endpoint.url.request_uri, name: "cloudflare.com")
	
	response = client.get(request_uri.to_s, {accept: "application/dns-json"})
	pp JSON.parse(response.read)
ensure
	response&.close
end
