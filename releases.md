# Releases

## v1.4.0

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
