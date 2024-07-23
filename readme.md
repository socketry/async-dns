# Async::DNS

Async::DNS is a high-performance DNS client resolver and server which can be easily integrated into other projects or used as a stand-alone daemon. It was forked from [RubyDNS](https://github.com/ioquatix/rubydns) which is now implemented in terms of this library.

[![Development Status](https://github.com/socketry/async-dns/workflows/Test/badge.svg)](https://github.com/socketry/async-dns/actions?workflow=Test)

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

``` ruby
Async::Reactor.run do
	resolver = Async::DNS::System.resolver

	addresses = resolver.addresses_for("www.google.com.")

	puts addresses.inspect
end
# [#<Resolv::IPv4 202.124.127.240>, #<Resolv::IPv4 202.124.127.216>, #<Resolv::IPv4 202.124.127.223>, #<Resolv::IPv4 202.124.127.227>, #<Resolv::IPv4 202.124.127.234>, #<Resolv::IPv4 202.124.127.230>, #<Resolv::IPv4 202.124.127.208>, #<Resolv::IPv4 202.124.127.249>, #<Resolv::IPv4 202.124.127.219>, #<Resolv::IPv4 202.124.127.218>, #<Resolv::IPv4 202.124.127.212>, #<Resolv::IPv4 202.124.127.241>, #<Resolv::IPv4 202.124.127.238>, #<Resolv::IPv4 202.124.127.245>, #<Resolv::IPv4 202.124.127.251>, #<Resolv::IPv4 202.124.127.229>]
```

You can also specify custom DNS servers:

``` ruby
resolver = Async::DNS::Resolver.new(Async::DNS::System.standard_connections(['8.8.8.8']))

# or

resolver = Async::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
```

### Server

Here is a simple example showing how to use the server:

``` ruby
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

``` 
                              user     system      total        real
Async::DNS::Server         4.280000   0.450000   4.730000 (  4.854862)
Bind9                         4.970000   0.520000   5.490000 (  5.541213)
```

These benchmarks are included in the unit tests. To test bind9 performance, it must be installed and `which named` must return the executable.

## Performance

We welcome additional benchmarks and feedback regarding Async::DNS performance. To check the current performance results, consult the [travis build job output](https://travis-ci.org/socketry/async-dns).

### Resolver

The `Async::DNS::Resolver` is highly concurrent and can resolve individual names as fast as the built in `Resolv::DNS` resolver. Because the resolver is asynchronous, when dealing with multiple names, it can work more efficiently:

``` 
                              user     system      total        real
Async::DNS::Resolver       0.020000   0.010000   0.030000 (  0.030507)
Resolv::DNS                   0.070000   0.010000   0.080000 (  1.465975)
```

These benchmarks are included in the unit tests.

### Server

The performance is on the same magnitude as `bind9`. Some basic benchmarks resolving 1000 names concurrently, repeated 5 times, using `Async::DNS::Resolver` gives the following:

``` 
                              user     system      total        real
Async::DNS::Server         4.280000   0.450000   4.730000 (  4.854862)
Bind9                         4.970000   0.520000   5.490000 (  5.541213)
```

These benchmarks are included in the unit tests. To test bind9 performance, it must be installed and `which named` must return the executable.

### DNSSEC support

DNSSEC is currently not supported and is [unlikely to be supported in the future](http://sockpuppet.org/blog/2015/01/15/against-dnssec/). Feel free to submit a PR.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
