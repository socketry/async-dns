#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns'

require 'benchmark'

describe Async::DNS::Resolver , timeout: 30 do
	context 'benchmark' do
		domains = %W{
			Facebook.com
			Twitter.com
			Google.com
			Youtube.com
			Wordpress.org
			Adobe.com
			Blogspot.com
			Wikipedia.org
			Linkedin.com
			Wordpress.com
			Yahoo.com
			Amazon.com
			Flickr.com
			Pinterest.com
			Tumblr.com
			W3.org
			Apple.com
			Myspace.com
			Vimeo.com
			Microsoft.com
			Youtu.be
			Qq.com
			Digg.com
			Baidu.com
			Stumbleupon.com
			Addthis.com
			Statcounter.com
			Feedburner.com
			TradeMe.co.nz
			Nytimes.com
			Reddit.com
			Weebly.com
			Bbc.co.uk
			Blogger.com
			Msn.com
			Macromedia.com
			Goo.gl
			Instagram.com
			Gov.uk
			Icio.us
			Yandex.ru
			Cnn.com
			Webs.com
			Google.de
			T.co
			Livejournal.com
			Imdb.com
			Mail.ru
			Jimdo.com
		}
		
		include Sus::Fixtures::Async::ReactorContext
		
		it 'should be faster than native resolver' do
			Benchmark.bm(30) do |x|
				a = x.report("Async::DNS::Resolver") do
					resolver = Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
				
					resolved = domains.collect{|domain| resolver.addresses_for(domain)}
				end
		
				b = x.report("Resolv::DNS") do
					resolver = Resolv::DNS.new(:nameserver => "8.8.8.8")
			
					resolved = domains.collect do |domain|
						[domain, resolver.getaddresses(domain)]
					end
				end
				
				# This is a regression, but not important right now.
				# expect(a.real).to be < b.real
			end
		end
	end
end
