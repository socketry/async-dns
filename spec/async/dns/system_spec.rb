#!/usr/bin/env ruby

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'async/dns'
require 'async/dns/system'

module Async::DNS::SystemSpec
	describe Async::DNS::System do
		include_context "reactor"
		
		it "should have at least one namesever" do
			expect(Async::DNS::System::nameservers.length).to be > 0
		end
	
		it "should respond to query for google.com" do
			resolver = Async::DNS::Resolver.new(Async::DNS::System::nameservers)
		
			response = resolver.query('google.com')
		
			expect(response.class).to be == Async::DNS::Message
			expect(response.rcode).to be == Resolv::DNS::RCode::NoError
		end
	end

	describe Async::DNS::System::Hosts do
		it "should parse the hosts file" do
			hosts = Async::DNS::System::Hosts.new
		
			# Load the test hosts data:
			File.open(File.expand_path("../hosts.txt", __FILE__)) do |file|
				hosts.parse_hosts(file)
			end
		
			expect(hosts.call('testing')).to be == true
			expect(hosts['testing']).to be == '1.2.3.4'
		end
	end
end
