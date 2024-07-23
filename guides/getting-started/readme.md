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
resolver = Async::DNS::System.resolver

resolver.addresses_for("www.google.com.")
# => [#<Resolv::IPv4 172.217.167.100>, #<Resolv::IPv6 2404:6800:4006:809::2004>]
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
