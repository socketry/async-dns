![Celluloid::DNS](https://github.com/celluloid/celluloid-dns/raw/master/logo.png)
=================
[![Build Status](https://secure.travis-ci.org/celluloid/celluloid-dns.png?branch=master)](http://travis-ci.org/celluloid/celluloid-dns)

Celluloid::DNS is a programmable Celluloid "cell" for answering DNS requests.
It's implemented using Celluloid::IO and is great for programatic DNS servers
which dynamically generate DNS responses, particularly within Celluloid-based
programs.

A nonblocking DNS client is already built into Celluloid::IO itself.
Celluloid::DNS is just for servers.

Installation
------------

Add this line to your application's Gemfile:

    gem 'celluloid-dns'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install celluloid-dns

Inside of your Ruby project, use:

    require 'celluloid/dns'

...to pull Celluloid::DNS in as a dependency.

Usage
-----

Start a DNS server that always resolves to `127.0.0.1`:

```ruby
require "celluloid/dns"

Celluloid::DNS::Server.new("127.0.0.1", 1234) do |request|
  request.answer request.questions.map { |q| [q, "127.0.0.1"] }
end

sleep
```

Query the server:

    $ dig @localhost -p 1234 anything.com


Contributing to Celluloid::DNS
------------------------------

* Fork this repository on github
* Make your changes and send me a pull request
* If I like them I'll merge them
* If I've accepted a patch, feel free to ask for commit access

License
-------

Copyright (c) 2012 Tony Arcieri. Distributed under the MIT License. See
LICENSE.txt for further details.
