# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.
# Copyright, 2024, by Sean Dilda.

require 'async/dns/client'
require 'sus/fixtures/async'

describe Async::DNS::Resolver do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:resolver) {Async::DNS::Resolver.default}
end