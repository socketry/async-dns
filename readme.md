# Async::DNS

Async::DNS is a high-performance DNS client resolver and server which can be easily integrated into other projects or used as a stand-alone daemon. It was forked from [RubyDNS](https://github.com/ioquatix/rubydns) which is now implemented in terms of this library.

[![Development Status](https://github.com/socketry/async-dns/workflows/Test/badge.svg)](https://github.com/socketry/async-dns/actions?workflow=Test)

## Usage

Please see the [project documentation](https://socketry.github.io/async-dns/) for more details.

  - [Getting Started](https://socketry.github.io/async-dns/guides/getting-started/index) - This guide explains how to get started with the `async-dns` gem.

## Releases

Please see the [project releases](https://socketry.github.io/async-dns/releases/index) for all releases.

### v1.4.0

  - Minimum Ruby version is now v3.1.
  - Drop dependency on `Async::IO` and refactor internal network code to use `IO::Endpoint` and `Socket` directly.
  - Introduce `Async::DNS::Endpoint` for getting the default endpoint for a given name server.
  - Remove old hacks for IPv6 on Ruby v2.3.
  - Introduce `Async::DNS::Cache` for caching DNS lookups.
  - Remove `logger` as an option and instance variable in favour of using `Console.logger` directly. This is a breaking change.
  - Update error logging to include more details.
  - Use keyword arguments `**options` where possible. This is a breaking change.
  - `Async::DNS::StreamHandler` and `Async::DNS::DatagramHandler` have been refactored to use `IO::Endpoint` and have minor breaking interface changes.
  - `Async::DNS::Resolver.default` should be used to get a default resolver instance.
  - The resolver now supports `ndots:` when resolving names.
  - `Async::DNS::Resolver#fully_qualified_name` is replaced by `Async::DNS::Resolver#fully_qualified_names` and can yield multiple names.
  - If the host system supports IPv6, the resolver will also try to resolve IPv6 addresses.
  - `Async::DNS::Server::DEFAULT_ENDPOINTS` is removed and replaced by `Async::DNS::Server.default_endpoint(port = 53)`.
  - `Async::DNS::Server#fire` is removed with no replacement.
  - The default `Async::DNS::Server#process` fails with `NXDomain` instead of `NotImplementedError`.
  - `Async::DNS::System` implementation is updated to support IPv6 and `resolv.conf` options.

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
