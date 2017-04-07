require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test)

task :default => :test

task :console do
	require 'pry'
	
	require_relative 'lib/async/dns'
	
	Pry.start
end

task :server do
	require_relative 'lib/async/dns'
	
	class TestServer < Async::DNS::Server
		def process(name, resource_class, transaction)
			@resolver ||= Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
			
			transaction.passthrough!(@resolver)
		end
	end
	
	server = TestServer.new(listen: [[:udp, '127.0.0.1', 2346]])
	
	Async::Reactor.run do
		server.run
	end
end
