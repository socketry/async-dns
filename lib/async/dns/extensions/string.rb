# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require_relative "../chunked"

# Extensions for the String class.
class String
	# Chunk a string which is required for the TEXT `resource_class`.
	def chunked(chunk_size = 255)
		Async::DNS::chunked(self)
	end
end
