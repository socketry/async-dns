# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

module Async
	module DNS
		class TestServer < Server
			def initialize(endpoint = DEFAULT_ENDPOINT, resolver: Resolver.new, **options)
				super(endpoint, **options)
				
				@resolver = resolver
			end
				
			def process(name, resource_class, transaction)
				# This is a simple example of how to pass the query to an upstream server:
				transaction.passthrough!(@resolver)
			end
		end
	end
end
