require 'celluloid/dns/version'
require 'celluloid/io'

require 'celluloid/dns/request'
require 'celluloid/dns/server'

module Celluloid
  module DNS
    # Default time-to-live for DNS responses
    DEFAULT_TTL = 900
  end
end
