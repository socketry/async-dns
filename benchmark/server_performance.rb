#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns'
require 'benchmark'
require 'process/daemon'

module Async::DNS::ServerPerformanceSpec
	class MillionServer < Async::DNS::Server
		def initialize(*)
			super
			
			@domains = {}
			
			(1..5_000).each do |i|
				domain = "domain#{i}.local"

				@domains[domain] = "#{69}.#{(i >> 16)%256}.#{(i >> 8)%256}.#{i%256}"
			end
		end
		
		attr :domains
		
		def process(name, resource_class, transaction)
			transaction.respond!(@domains[name])
		end
	end
	
	RSpec.describe MillionServer do
		# include_context "profile"
		include Sus::Fixtures::Async::ReactorContext
		
		let(:interfaces) {[[:udp, '127.0.0.1', 8899]]}
		let(:server) {MillionServer.new(interfaces)}
		let(:resolver) {Async::DNS::Resolver.new(interfaces)}
		
		it "should be fast" do
			task = server.run
			
			server.domains.each do |name, address|
				resolved = resolver.addresses_for(name)
			end
			
			task.stop
		end
	end
	
	RSpec.describe Async::DNS::Server do
		include Sus::Fixtures::Async::ReactorContext
		
		context 'benchmark' do
			class AsyncServerDaemon < Process::Daemon
				def working_directory
					File.expand_path("../tmp", __FILE__)
				end
				
				def reactor
					@reactor ||= Async::Reactor.new
				end
				
				def startup
					puts "Starting DNS server..."
					@server = MillionServer.new([[:udp, '0.0.0.0', 5300]])
					
					reactor.async do
						@task = @server.run
					end
				end
				
				def run
					reactor.run
				end
				
				def shutdown
					@task.stop if @task
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
				@servers << ["Async::DNS::Server", 5300]
			
				@domains = (1..1000).collect do |i|
					"domain#{i}.local"
				end
			
				AsyncServerDaemon.start
			
				unless Bind9ServerDaemon.named_executable.empty?
					Bind9ServerDaemon.start
					@servers << ["Bind9", 5400]
				end
			end
		
			after(:all) do
				AsyncServerDaemon.stop
			
				unless Bind9ServerDaemon.named_executable.empty?
					Bind9ServerDaemon.stop
				end
			end
		
			it 'takes time' do
				Benchmark.bm(30) do |x|
					@servers.each do |name, port|
						resolver = Async::DNS::Resolver.new([[:udp, '127.0.0.1', port]])
					
						x.report(name) do
							Async::Reactor.run do
								# Number of requests remaining since this is an asynchronous event loop:
								5.times do
									pending = @domains.size
								
									resolved = @domains.collect{|domain| resolver.addresses_for(domain)}
									
									expect(resolved).not.to include(nil)
								end
							end
						end
					end
				end
			end
		end
	end
end
