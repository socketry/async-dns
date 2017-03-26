![Celluloid::DNS](https://github.com/celluloid/celluloid-dns/raw/master/logo.png)

**This is a work in progress as we migrate from `Celluloid` to `Socketry::Async`**

Celluloid::DNS is a high-performance DNS client resolver and server which can be easily integrated into other projects or used as a stand-alone daemon. It was forked from [RubyDNS][1] which is now implemented in terms of this library.

[1]: https://github.com/ioquatix/rubydns

[![Gem Version](https://badge.fury.io/rb/celluloid-dns.svg)](http://rubygems.org/gems/celluloid-dns)
[![Build Status](https://secure.travis-ci.org/celluloid/celluloid-dns.svg?branch=master)](http://travis-ci.org/celluloid/celluloid-dns)
[![Dependency Status](https://gemnasium.com/celluloid/celluloid-dns.svg)](https://gemnasium.com/celluloid/celluloid-dns)
[![Code Climate](https://codeclimate.com/github/celluloid/celluloid-dns.svg)](https://codeclimate.com/github/celluloid/celluloid-dns)
[![Coverage Status](https://coveralls.io/repos/celluloid/celluloid-dns/badge.svg?branch=master)](https://coveralls.io/r/celluloid/celluloid-dns)

## Installation

Add this line to your application's Gemfile:

	gem 'celluloid-dns'

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install celluloid-dns

## Usage

### Resolver

Here is a simple example showing how to use the resolver:

	resolver = Celluloid::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])

	addresses = resolver.addresses_for("www.google.com.")

	expect(addresses.size).to be > 0

	addresses.each do |address|
		expect(address).to be_kind_of(Resolv::IPv4) | be_kind_of(Resolv::IPv6)
	end

### Server

Here is a simple example showing how to use the server:

	class TestServer < Celluloid::DNS::Server
		def process(name, resource_class, transaction)
			@resolver ||= Celluloid::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
			
			transaction.passthrough!(@resolver)
		end
	end
	
	server = TestServer.new(listen: [[:udp, 'localhost', 2346]])
	server.run
	
	sleep

Then to test you could use `dig` like so:

	dig @localhost -p 2346 google.com

## FAQ

### File Handle Limitations

I get the error `Errno::EMFILE: Too many open files - socket(2) - udp` when trying to run a server. What should I do?

On some platforms (e.g. Mac OS X) the number of file descriptors is relatively low by default and should be increased by calling `ulimit -n 10000` before running tests or even before starting a server which expects a large number of concurrent incoming connections.

### Server

The performance is on the same magnitude as `bind9`. Some basic benchmarks resolving 1000 names concurrently, repeated 5 times, using `Celluloid::DNS::Resolver` gives the following:

	                              user     system      total        real
	Celluloid::DNS::Server        4.280000   0.450000   4.730000 (  4.854862)
	Bind9                         4.970000   0.520000   5.490000 (  5.541213)

These benchmarks are included in the unit tests. To test bind9 performance, it must be installed and `which named` must return the executable.


## Performance

We welcome additional benchmarks and feedback regarding Celluloid::DNS performance. To check the current performance results, consult the [travis build job output](https://travis-ci.org/celluloid/celluloid-dns).

### Resolver

The `Celluloid::DNS::Resolver` is highly concurrent and can resolve individual names as fast as the built in `Resolv::DNS` resolver. Because the resolver is asynchronous, when dealing with multiple names, it can work more efficiently:

	                              user     system      total        real
	Celluloid::DNS::Resolver      0.020000   0.010000   0.030000 (  0.030507)
	Resolv::DNS                   0.070000   0.010000   0.080000 (  1.465975)

These benchmarks are included in the unit tests.

### Server

The performance is on the same magnitude as `bind9`. Some basic benchmarks resolving 1000 names concurrently, repeated 5 times, using `Celluloid::DNS::Resolver` gives the following:

	                              user     system      total        real
	Celluloid::DNS::Server        4.280000   0.450000   4.730000 (  4.854862)
	Bind9                         4.970000   0.520000   5.490000 (  5.541213)

These benchmarks are included in the unit tests. To test bind9 performance, it must be installed and `which named` must return the executable.

### DNSSEC support

DNSSEC is currently not supported and is [unlikely to be supported in the future](http://sockpuppet.org/blog/2015/01/15/against-dnssec/). Feel free to submit a PR.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Desired Features

* Support for more features of DNS such as zone transfer.
* Some kind of system level integration, e.g. registering a DNS server with the currently running system resolver.

## License

Released under the MIT license.

Copyright, 2015, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
