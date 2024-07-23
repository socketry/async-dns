# Getting Started

This guide explains how to get started with the `async-dns` gem.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add async-dns
~~~

## Usage

### Resolver

Here is a simple example showing how to use the resolver:

``` ruby
Async do
	resolver = Async::DNS::System.resolver
	
	addresses = resolver.addresses_for("www.google.com.")
	
	puts addresses.inspect
end
# [#<Resolv::IPv4 202.124.127.240>, #<Resolv::IPv4 202.124.127.216>, #<Resolv::IPv4 202.124.127.223>, #<Resolv::IPv4 202.124.127.227>, #<Resolv::IPv4 202.124.127.234>, #<Resolv::IPv4 202.124.127.230>, #<Resolv::IPv4 202.124.127.208>, #<Resolv::IPv4 202.124.127.249>, #<Resolv::IPv4 202.124.127.219>, #<Resolv::IPv4 202.124.127.218>, #<Resolv::IPv4 202.124.127.212>, #<Resolv::IPv4 202.124.127.241>, #<Resolv::IPv4 202.124.127.238>, #<Resolv::IPv4 202.124.127.245>, #<Resolv::IPv4 202.124.127.251>, #<Resolv::IPv4 202.124.127.229>]
```

### Server

Here is a simple example showing how to use the server:

``` ruby
require 'async/dns'

class TestServer < Async::DNS::Server
	def resolver
		@resolver ||= Async::DNS::Resolver.new(
			Async::DNS::Endpoint.for('1.1.1.1')
		)
	end
	
	def process(name, resource_class, transaction)
		transaction.passthrough!(self.resolver)
	end
end

endpoint = Async::DNS::Endpoint.for('localhost', port: 5300)
server = TestServer.new(endpoint)
server.run
```

Then to test you could use `dig` like so:

    dig @localhost -p 5300 google.com

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