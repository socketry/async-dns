
if ENV['COVERAGE'] || ENV['TRAVIS']
	begin
		require 'simplecov'
		
		SimpleCov.start do
			add_filter "/spec/"
		end
		
		# Work correctly across forks:
		pid = Process.pid
		SimpleCov.at_exit do
			SimpleCov.result.format! if Process.pid == pid
		end
		
		if ENV['TRAVIS']
			require 'coveralls'
			Coveralls.wear!
		end
	rescue LoadError
		warn "Could not load simplecov: #{$!}"
	end
end

require "bundler/setup"
require "async/dns"

RSpec.shared_context "reactor" do
	let(:reactor) {Async::Reactor.new}
	
	around(:each) do |example|
		result = nil
		
		reactor.run do
			result = example.run
			
			# Force the reactor to stop running if the result was an error.
			if result.is_a? Exception
				reactor.stop
			end
		end
	end
end

# abort "Warning, ulimit is too low!" if `ulimit -n`.to_i < 10000

RSpec.configure do |config|
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = ".rspec_status"

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
