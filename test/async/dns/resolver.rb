# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.
# Copyright, 2024, by Sean Dilda.

require 'async/dns/resolver'
require 'sus/fixtures/async'

describe Async::DNS::Resolver do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:resolver) {Async::DNS::Resolver.new}
	
	it "should result in non-existent domain" do
		response = resolver.query('foobar.example.com', Resolv::DNS::Resource::IN::A)
		
		expect(response.rcode).to be == Resolv::DNS::RCode::NXDomain
	end
	
	it "should result in some answers" do
		response = resolver.query('google.com', Resolv::DNS::Resource::IN::A)
		
		expect(response.class).to be == Resolv::DNS::Message
		expect(response.answer.size).to be > 0
	end
	
	with '#addresses_for' do
		it "should return IP addresses" do
			addresses = resolver.addresses_for('google.com')
			
			expect(addresses).to have_value(be_a Resolv::IPv4)
			expect(addresses).to have_value(be_a Resolv::IPv6)
		end
		
		it "should recursively resolve CNAME records" do
			# > dig A www.baidu.com
			#
			# ; <<>> DiG 9.18.27 <<>> A www.baidu.com
			# ;; global options: +cmd
			# ;; Got answer:
			# ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 14301
			# ;; flags: qr rd ra; QUERY: 1, ANSWER: 4, AUTHORITY: 0, ADDITIONAL: 1
			#
			# ;; OPT PSEUDOSECTION:
			# ; EDNS: version: 0, flags:; udp: 65494
			# ;; QUESTION SECTION:
			# ;www.baidu.com.			IN	A
			#
			# ;; ANSWER SECTION:
			# www.baidu.com.		1128	IN	CNAME	www.a.shifen.com.
			# www.a.shifen.com.	15	IN	CNAME	www.wshifen.com.
			# www.wshifen.com.	247	IN	A	119.63.197.139
			# www.wshifen.com.	247	IN	A	119.63.197.151
			
			addresses = resolver.addresses_for('www.baidu.com')
			
			expect(addresses.size).to be > 0
			expect(addresses).to have_value(be_a Resolv::IPv4)
		end
	end
	
	with '#fully_qualified_name' do
		let(:resolver) {Async::DNS::Resolver.new(origin: "foo.bar.")}
		
		it "should generate fully qualified domain name with specified origin" do
			fully_qualified_name = resolver.fully_qualified_name("baz")
			
			expect(fully_qualified_name).to be(:absolute?)
			expect(fully_qualified_name.to_s).to be == "baz.foo.bar."
		end
	end
end
