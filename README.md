# Async::DNS

Async::DNS is a high-performance DNS client resolver and server which can be easily integrated into other projects or used as a stand-alone daemon. It was forked from [RubyDNS] which is now implemented in terms of this library.

[RubyDNS]: https://github.com/ioquatix/rubydns

[![Build Status](https://secure.travis-ci.com/socketry/async-dns.svg)](http://travis-ci.com/socketry/async-dns)
[![Code Climate](https://codeclimate.com/github/socketry/async-dns.svg)](https://codeclimate.com/github/socketry/async-dns)
[![Coverage Status](https://coveralls.io/repos/socketry/async-dns/badge.svg)](https://coveralls.io/r/socketry/async-dns)

## Installation

Add this line to your application's Gemfile:

	gem 'async-dns'

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install async-dns

## Usage

### Resolver

Here is a simple example showing how to use the resolver:

```ruby
	Async::Reactor.run do
		resolver = Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])

		addresses = resolver.addresses_for("www.google.com.")

		puts addresses.inspect
	end
	=> [#<Resolv::IPv4 202.124.127.240>, #<Resolv::IPv4 202.124.127.216>, #<Resolv::IPv4 202.124.127.223>, #<Resolv::IPv4 202.124.127.227>, #<Resolv::IPv4 202.124.127.234>, #<Resolv::IPv4 202.124.127.230>, #<Resolv::IPv4 202.124.127.208>, #<Resolv::IPv4 202.124.127.249>, #<Resolv::IPv4 202.124.127.219>, #<Resolv::IPv4 202.124.127.218>, #<Resolv::IPv4 202.124.127.212>, #<Resolv::IPv4 202.124.127.241>, #<Resolv::IPv4 202.124.127.238>, #<Resolv::IPv4 202.124.127.245>, #<Resolv::IPv4 202.124.127.251>, #<Resolv::IPv4 202.124.127.229>]
```

### Server

Here is a simple example showing how to use the server:

```ruby
	require 'async/dns'
	
	class TestServer < Async::DNS::Server
		def process(name, resource_class, transaction)
			@resolver ||= Async::DNS::Resolver.new([[:udp, '8.8.8.8', 53], [:tcp, '8.8.8.8', 53]])
			
			transaction.passthrough!(@resolver)
		end
	end
	
	server = TestServer.new([[:udp, '127.0.0.1', 2346]])
	
	server.run
```

Then to test you could use `dig` like so:

	dig @localhost -p 2346 google.com

## FAQ

### File Handle Limitations

I get the error `Errno::EMFILE: Too many open files - socket(2) - udp` when trying to run a server. What should I do?

On some platforms (e.g. Mac OS X) the number of file descriptors is relatively low by default and should be increased by calling `ulimit -n 10000` before running tests or even before starting a server which expects a large number of concurrent incoming connections.

### Server

The performance is on the same magnitude as `bind9`. Some basic benchmarks resolving 1000 names concurrently, repeated 5 times, using `Async::DNS::Resolver` gives the following:

	                              user     system      total        real
	Async::DNS::Server         4.280000   0.450000   4.730000 (  4.854862)
	Bind9                         4.970000   0.520000   5.490000 (  5.541213)

These benchmarks are included in the unit tests. To test bind9 performance, it must be installed and `which named` must return the executable.


## Performance

We welcome additional benchmarks and feedback regarding Async::DNS performance. To check the current performance results, consult the [travis build job output](https://travis-ci.org/socketry/async-dns).

### Resolver

The `Async::DNS::Resolver` is highly concurrent and can resolve individual names as fast as the built in `Resolv::DNS` resolver. Because the resolver is asynchronous, when dealing with multiple names, it can work more efficiently:

	                              user     system      total        real
	Async::DNS::Resolver       0.020000   0.010000   0.030000 (  0.030507)
	Resolv::DNS                   0.070000   0.010000   0.080000 (  1.465975)

These benchmarks are included in the unit tests.

### Server

The performance is on the same magnitude as `bind9`. Some basic benchmarks resolving 1000 names concurrently, repeated 5 times, using `Async::DNS::Resolver` gives the following:

	                              user     system      total        real
	Async::DNS::Server         4.280000   0.450000   4.730000 (  4.854862)
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
