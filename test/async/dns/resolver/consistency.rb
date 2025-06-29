#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require "async/dns"
require "benchmark"
require "set"

require "sus/fixtures/async"

DOMAINS = [
	"facebook.com",
	"twitter.com",
	"google.com",
	"youtube.com",
	"wordpress.com",
	"adobe.com",
	"blogspot.com",
	"wikipedia.org",
	"linkedin.com",
	"wordpress.com",
	"yahoo.com",
	"amazon.com",
	"flickr.com",
	"pinterest.com",
	"tumblr.com",
	"w3.org",
	"apple.com",
	"myspace.com",
	"vimeo.com",
	"microsoft.com",
	"youtu.be",
	"qq.com",
	"digg.com",
	"baidu.com",
	"stumbleupon.com",
	"addthis.com",
	"statcounter.com",
	"feedburner.com",
	"trademe.co.nz",
	"nytimes.com",
	"reddit.com",
	"weebly.com",
	"bbc.co.uk",
	"blogger.com",
	"msn.com",
	"macromedia.com",
	"goo.gl",
	"instagram.com",
	"gov.uk",
	"icio.us",
	"yandex.ru",
	"cnn.com",
	"webs.com",
	"google.de",
	"t.co",
	"livejournal.com",
	"imdb.com",
	"mail.ru",
	"jimdo.com",
]

describe Async::DNS::Resolver do
	include Sus::Fixtures::Async::ReactorContext
	
	def before
		super
		
		# Ensure that the upstream DNS is warm:
		DOMAINS.each do |domain|
			Addrinfo.getaddrinfo(domain, nil)
		end
	end
	
	it "is consistent with built in resolver" do
		skip "This test is unreliable."
		
		resolved_a = resolved_b = nil
		
		async_dns_performance = Benchmark.measure do
			resolver = Async::DNS::Resolver.default
			
			resolved_a = DOMAINS.to_h do |domain|
				[domain, resolver.addresses_for(domain).sort_by(&:to_s)]
			end
		end
		
		resolv_dns_performance = Benchmark.measure do
			resolver = Resolv::DNS.new
			
			resolved_b = DOMAINS.to_h do |domain|
				[domain, resolver.getaddresses(domain).sort_by(&:to_s)]
			end
		end
			
		DOMAINS.each do |domain|
			inform "Comparing results for #{domain}..."
			expect(resolved_a[domain]).to be == resolved_b[domain]
		end
		
		inform("Async DNS: #{async_dns_performance}")
		inform("Resolv DNS: #{resolv_dns_performance}")
	end
end
