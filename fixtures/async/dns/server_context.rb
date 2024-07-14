# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require 'sus/fixtures/async/reactor_context'

require 'async/dns/server'
require 'async/dns/resolver'

require 'io/endpoint'

module Async
	module DNS
		module ServerContext
			include Sus::Fixtures::Async::ReactorContext
			
			def endpoint
				IO::Endpoint.composite(
					IO::Endpoint.udp('localhost', 0),
					IO::Endpoint.tcp('localhost', 0),
				)
			end
			
			def make_server(endpoint)
				Async::DNS::Server.new(endpoint)
			end
			
			def resolver
				@resolver ||= Async::DNS::Resolver.new(@resolver_endpoint)
			end
			
			def before
				super
				
				@bound_endpoint = endpoint.bound
				@resolver_endpoint = @bound_endpoint.local_address_endpoint
				
				@server = make_server(@bound_endpoint)
				@server_task = @server.run
				# @server_task.wait
			end
			
			def after
				@server_task&.stop
				@bound_endpoint&.close
				
				super
			end
		end
	end
end
