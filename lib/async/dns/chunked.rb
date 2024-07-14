# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

module Async::DNS
	# Produces an array of arrays of binary data with each sub-array a maximum of chunk_size bytes.
	def self.chunked(string, chunk_size = 255)
		chunks = []
		
		offset = 0
		while offset < string.bytesize
			chunks << string.byteslice(offset, chunk_size)
			offset += chunk_size
		end
		
		return chunks
	end
end
