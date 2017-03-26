#!/usr/bin/env ruby

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'celluloid/dns'
require 'benchmark'
require 'process/daemon'

module Celluloid::DNS::ServerPerformanceSpec
	describe Celluloid::DNS::Server do
		context 'benchmark' do
			class MillionServer < Celluloid::DNS::Server
				def initialize(*)
					super
					
					@million = {}
					
					(1..5_000).each do |i|
						domain = "domain#{i}.local"
	
						@million[domain] = "#{69}.#{(i >> 16)%256}.#{(i >> 8)%256}.#{i%256}"
					end
				end
				
				def process(name, resource_class, transaction)
					transaction.respond!(@million[name])
				end
			end
			
			class CelluloidServerDaemon < Process::Daemon
				IN = Resolv::DNS::Resource::IN
	
				def working_directory
					File.expand_path("../tmp", __FILE__)
				end
	
				def startup
					puts "Booting celluloid..."
					Celluloid.boot
					
					puts "Starting DNS server..."
					@server = MillionServer.new(listen: [[:udp, '0.0.0.0', 5300]])
					
					@server.async.run
				end
				
				def shutdown
					@server.terminate
				end
			end

			class Bind9ServerDaemon < Process::Daemon
				def working_directory
					File.expand_path("../server/bind9", __FILE__)
				end
	
				def run
					exec(self.class.named_executable, "-c", "named.conf", "-f", "-p", "5400", "-g")
				end
	
				def self.named_executable
					# Check if named executable is available:
					@named ||= `which named`.chomp
				end
			end
		
			before(:all) do
				@servers = []
				@servers << ["Celluloid::DNS::Server", 5300]
			
				@domains = (1..1000).collect do |i|
					"domain#{i}.local"
				end
			
				CelluloidServerDaemon.start
			
				unless Bind9ServerDaemon.named_executable.empty?
					Bind9ServerDaemon.start
					@servers << ["Bind9", 5400]
				end
			end
		
			after(:all) do
				CelluloidServerDaemon.stop
			
				unless Bind9ServerDaemon.named_executable.empty?
					Bind9ServerDaemon.stop
				end
			end
		
			it 'takes time' do
				Celluloid.logger.level = Logger::ERROR
				
				Benchmark.bm(30) do |x|
					@servers.each do |name, port|
						resolver = Celluloid::DNS::Resolver.new([[:udp, '127.0.0.1', port]])
					
						x.report(name) do
							# Number of requests remaining since this is an asynchronous event loop:
							5.times do
								pending = @domains.size
							
								futures = @domains.collect{|domain| resolver.future.addresses_for(domain)}
							
								futures.collect do |future|
									expect(future.value).to_not be nil
								end
							end
						end
					end
				end
			end
		end
	end
end
