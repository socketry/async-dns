# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2013, by Tony Arcieri.
# Copyright, 2015-2025, by Samuel Williams.

source "https://rubygems.org"

# Specify your gem's dependencies in protocol-http1.gemspec
gemspec

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"
	gem "bake-releases"
	
	gem "utopia-project"
end

group :test do
	gem "sus"
	gem "covered"
	gem "decode"
	gem "rubocop"
	
	gem "sus-fixtures-async"
	gem "benchmark"
	
	gem "bake-test"
	gem "bake-test-external"
end
