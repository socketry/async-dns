# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.
# Copyright, 2017, by Olle Jonsson.

require 'resolv'
require 'resolv-replace'

module Async::DNS
	module Replace
		class << self
			attr_accessor :resolver
			
			def resolver?
				resolver != nil
			end
		
			def get_address(host)
				begin
					resolver.addresses_for(host).sample.to_s
				rescue ResolutionFailure
					raise SocketError, "Hostname not known: #{host}"
				end
			end
		end
	end
	
	class << IPSocket
		@@resolver = nil
		
		def getaddress(host)
			if Replace.resolver?
				Replace.get_address(host)
			else
				original_resolv_getaddress(host)
			end
		end
	end
end
