# -*- encoding: utf-8 -*-
require File.expand_path('../lib/celluloid/dns/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tony Arcieri"]
  gem.email         = ["tony.arcieri@gmail.com"]
  gem.description   = "Celluloid::IO-powered DNS server"
  gem.summary       = "Celluloid::DNS provides a DNS server implemented as a Celluloid cell"
  gem.homepage      = "https://github.com/celluloid/celluloid-dns"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "celluloid-dns"
  gem.require_paths = ["lib"]
  gem.version       = Celluloid::DNS::VERSION
  
  gem.add_runtime_dependency 'celluloid',    '>= 0.11.0'
  gem.add_runtime_dependency 'celluloid-io', '>= 0.11.0'
  
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end
