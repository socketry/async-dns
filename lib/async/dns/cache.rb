# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

module Async
	module DNS
		# Provides a local in-memory cache for DNS resources.
		class Cache
			Entry = Struct.new(:timestamp, :name, :resource_class, :resource) do
				def age(now)
					now - timestamp
				end
				
				def fresh?(now = Async::Clock.now)
					self.age(now) <= resource.ttl
				end
			end
			
			# Create a new cache.
			def initialize
				@store = {}
			end
			
			# Fetch a resource from the cache, or if it is not present, yield to the block to fetch it.
			#
			# @parameter name [String] The name of the resource.
			# @parameter resource_classes [Array(Class(Resolv::DNS::Resource))] The classes of the resources to fetch.
			# @yields {|name, resource_class| ...} The block to fetch the resource, it should call {#store} to store the resource in the cache.
			def fetch(name, resource_classes)
				now = Async::Clock.now
				
				resource_classes.map do |resource_class|
					key = [name, resource_class]
					
					if entries = @store[key]
						entries.delete_if do |entry|
							!entry.fresh?(now)
						end
					else
						entries = (@store[key] = [])
					end
					
					if entries.empty?
						yield(name, resource_class)
					end
					
					entries
				end.flatten.map(&:resource)
			end
			
			# Store a resource in the cache.
			#
			# @parameter name [String] The name of the resource.
			# @parameter resource_class [Class(Resolv::DNS::Resource)] The class of the resource.
			# @parameter resource [Resolv::DNS::Resource] The resource to store.
			def store(name, resource_class, resource)
				key = [name, resource_class]
				entries = (@store[key] ||= [])
				
				entries << Entry.new(Async::Clock.now, name, resource_class, resource)
			end
		end
	end
end
