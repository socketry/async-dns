#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns'
require 'benchmark'

require 'stackprof'

Name = Resolv::DNS::Name
IN = Resolv::DNS::Resource::IN

# Generate a million A record "domains":

million = {}

Benchmark.bm do |x|
	x.report("Generate names") do
		(1..1_000_000).each do |i|
			domain = "domain#{i}.local"
	
			million[domain] = "#{69}.#{(i >> 16)%256}.#{(i >> 8)%256}.#{i%256}"
		end
	end
end

# Run the server:

StackProf.run(mode: :cpu, out: 'async/dns.stackprof') do
	Async::DNS::run_server(:listen => [[:udp, '0.0.0.0', 5300]]) do
		match(//, IN::A) do |transaction|
			transaction.respond!(million[transaction.name])
		end
		
		# Default DNS handler
		otherwise do |transaction|
			logger.info "Passing DNS request upstream..."
			transaction.fail!(:NXDomain)
		end
	end
end

# Expected output:
#
# > dig @localhost -p 5300 domain1000000
# 
# ; <<>> DiG 9.8.3-P1 <<>> @localhost -p 5300 domain1000000
# ; (3 servers found)
# ;; global options: +cmd
# ;; Got answer:
# ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 50336
# ;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
# ;; WARNING: recursion requested but not available
# 
# ;; QUESTION SECTION:
# ;domain1000000.			IN	A
# 
# ;; ANSWER SECTION:
# domain1000000.		86400	IN	A	69.15.66.64
# 
# ;; Query time: 1 msec
# ;; SERVER: 127.0.0.1#5300(127.0.0.1)
# ;; WHEN: Fri May 16 19:17:48 2014
# ;; MSG SIZE  rcvd: 47
# 
