# frozen_string_literal: true

require_relative "lib/async/dns/version"

Gem::Specification.new do |spec|
	spec.name = "async-dns"
	spec.version = Async::DNS::VERSION
	
	spec.summary = "An easy to use DNS client resolver and server for Ruby."
	spec.authors = ["Samuel Williams", "Tony Arcieri", "Olle Jonsson", "Greg Thornton", "Hal Brodigan", "Hendrik Beskow", "Mike Perham", "Sean Dilda", "Stefan Wrobel"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/async-dns"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/async-dns/",
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
		"source_code_uri" => "https://github.com/socketry/async-dns.git",
	}
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "base64"
	spec.add_dependency "io-endpoint"
end
