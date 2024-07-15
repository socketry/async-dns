#!/usr/bin/env ruby

# Copyright, 2009, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'cgi'
require 'json'

require 'digest/md5'

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
