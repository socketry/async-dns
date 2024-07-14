# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012, by Tony Arcieri.
# Copyright, 2015-2024, by Samuel Williams.

require 'async'
require 'async/io/tcp_socket'
require 'async/io/udp_socket'

require_relative 'dns/version'

require_relative 'dns/message'
require_relative 'dns/server'
require_relative 'dns/resolver'
require_relative 'dns/handler'

module Async
	module DNS
	end
end
