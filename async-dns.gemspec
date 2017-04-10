# -*- encoding: utf-8 -*-
require_relative 'lib/async/dns/version'

Gem::Specification.new do |spec|
	spec.name          = "async-dns"
	spec.version       = Async::DNS::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]
	spec.description   = <<-EOF
		Async::DNS provides a high-performance DNS client resolver and server
		which can be easily integrated into other projects or used as a stand-alone
		daemon.
	EOF
	spec.summary       = "An easy to use DNS client resolver and server for Ruby."
	spec.homepage      = "https://github.com/async/async-dns"
	spec.license       = "MIT"
	
	spec.files         = `git ls-files`.split($/)
	spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]
	spec.has_rdoc      = "yard"
	
	spec.add_dependency("async", "~> 0.11")
	
	spec.add_development_dependency "process-daemon", "~> 1.0.0"
	
	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rspec", "~> 3.4.0"
	spec.add_development_dependency "rake"
end
