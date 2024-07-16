module Async
	module DNS
		# Represents a failure to resolve a given name to an address.
		class ResolutionFailure < StandardError
		end
		
		class Resolver
			RESOLUTION_FAILURE = proc do |name|
				raise ResolutionFailure.new("Could not find any addresses for #{name.inspect}!")
			end
			
			def initialize(delegate = RESOLUTION_FAILURE)
				@delegate = delegate
			end
			
			# Return addresses for the given name.
			# @returns [Array(String)] The addresses for the given name.
			def call(name)
				@delegate.call(name)
			end
		end
	end
end