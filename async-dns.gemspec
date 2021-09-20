
require_relative "lib/async/dns/version"

Gem::Specification.new do |spec|
	spec.name = "async-dns"
	spec.version = Async::DNS::VERSION
	
	spec.summary = "An easy to use DNS client resolver and server for Ruby."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/async-dns"
	
	spec.files = Dir.glob('{lib}/**/*', File::FNM_DOTMATCH, base: __dir__)
	
	spec.add_dependency "async-io", "~> 1.15"
	
	spec.add_development_dependency "async-rspec", "~> 1.0"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "process-daemon", "~> 1.0"
	spec.add_development_dependency "rspec", "~> 3.0"
	spec.add_development_dependency "rspec-files", "~> 1.0"
	spec.add_development_dependency "rspec-memory", "~> 1.0"
end
