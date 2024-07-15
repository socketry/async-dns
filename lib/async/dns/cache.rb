module Async
	module DNS
		# Provides a local in-memory cache for DNS resources.
		class Cache
			Entry = Struct.new(:timestamp, :name, :resource_class, :resource) do
				def age
					Async::Clock.now - timestamp
				end
				
				def fresh?
					age <= resource.ttl
				end
			end
			
			def initialize
				@resources = {}
			end
			
			def fetch(name, resource_classes)
				if entries = @resources[name]
					# Remove stale entries:
					entries.delete_if do |resource_class, entry|
						!entry.fresh?
					end
				else
					entries = (@resources[name] = {})
				end
				
				resource_classes.filter_map do |resource_class|
					unless entry = entries[resource_class]
						yield(name, resource_class)
						entry = entries[resource_class]
					end
					
					entry&.resource
				end
			end
			
			def store(name, resource_class, resource)
				entries = (@resources[name] ||= {})
				
				entries[resource_class] = Entry.new(Async::Clock.now, name, resource_class, resource)
			end
		end
	end
end
