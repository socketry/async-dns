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
			
			def initialize
				@store = {}
			end
			
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
			
			def store(name, resource_class, resource)
				key = [name, resource_class]
				entries = (@store[key] ||= [])
				
				entries << Entry.new(Async::Clock.now, name, resource_class, resource)
			end
		end
	end
end
