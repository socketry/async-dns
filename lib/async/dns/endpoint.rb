# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

module Async
	module DNS
		# DNS endpoint helpers.
		module Endpoint
			# Get a list of standard nameserver connections which can be used for querying any standard servers that the system has been configured with.
			def self.for(nameservers, port: 53, **options)
				connections = []
				
				Array(nameservers).each do |host|
					connections << IO::Endpoint.udp(host, port, **options)
					connections << IO::Endpoint.tcp(host, port, **options)
				end
				
				return IO::Endpoint.composite(*connections)
			end
		end
	end
end
