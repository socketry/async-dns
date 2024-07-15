# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'stringio'
require 'resolv'

require_relative 'extensions/resolv'

module Async::DNS
	# This is generally a good size for UDP packets that will be sent over the internet, as it is the largest size that will not require fragmentation.
	# 1500 - 20 (IP header) - 8 (UDP header) = 1472
	UDP_TRUNCATION_SIZE = 1472
	
	# The maximum size of a UDP packet.
	UDP_MAXIMUM_SIZE = 2**16
	
	# The DNS message container.
	Message = ::Resolv::DNS::Message
	DecodeError = ::Resolv::DNS::DecodeError
	
	# Decodes binary data into a {Message}.
	def self.decode_message(data)
		# Otherwise the decode process might fail with non-binary data.
		if data.respond_to? :force_encoding
			data.force_encoding("BINARY")
		end
		
		begin
			return Message.decode(data)
		rescue DecodeError
			raise
		rescue StandardError => error
			new_error = DecodeError.new(error.message)
			new_error.set_backtrace(error.backtrace)
			
			raise new_error
		end
	end
end
