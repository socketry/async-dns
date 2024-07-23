# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'resolv'

# @namespace
class Resolv
	# @namespace
	class DNS
		# Extensions to the `Resolv::DNS::Message` class.
		class Message
			# Merge the given message with this message. A number of heuristics are applied in order to ensure that the result makes sense. For example, If the current message is not recursive but is being merged with a message that was recursive, this bit is maintained. If either message is authoritive, then the result is also authoritive.
			#
			# Modifies the current message in place.
			def merge!(other)
				# Authoritive Answer
				@aa = @aa && other.aa

				@question += other.question
				@answer += other.answer
				@authority += other.authority
				@additional += other.additional

				# Recursion Available
				@ra = @ra || other.ra

				# Result Code (Error Code)
				@rcode = other.rcode unless other.rcode == 0

				# Recursion Desired
				@rd = @rd || other.rd
			end
		end
		
		# Represents a failure to construct a fullly qualified name due to a mismatched origin.
		class OriginError < ArgumentError
		end
		
		# Extensions to the `Resolv::DNS::Name` class.
		class Name
			# Computes the name, typically absolute, with the specified origin as a suffix. If the origin is nil, don't change the name, but change it to absolute (as specified).
			#
			# @parameter origin [Array | String] The origin to append to the name.
			# @parameter absolute [Boolean] If true, the name will be made absolute.
			# @returns The name, with the origin suffix.
			def with_origin(origin, absolute = true)
				return self.class.new(@labels, absolute) if origin == nil
				
				origin = Label.split(origin) if String === origin
				
				return self.class.new(@labels + origin, absolute)
			end
			
			# Compute the name, typically relative, without the specified origin suffix. If the origin is nil, don't change the name, but change it to absolute (as specified). 
			#
			# @parameter origin [Array | String] The origin to remove from the name.
			# @parameter absolute [Boolean] If true, the name will be made absolute.
			# @returns The name, without the origin suffix.
			# @raises [OriginError] If the name does not end with the specified origin.
			def without_origin(origin, absolute = false)
				return self.class.new(@labels, absolute) if origin == nil
				
				origin = Label.split(origin) if String === origin
				
				if @labels.last(origin.length) == origin
					return self.class.new(@labels.first(@labels.length - origin.length), absolute)
				else
					raise OriginError.new("#{self} does not end with #{origin.join('.')}")
				end
			end
		end
	end
end
