
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
require "async/rspec"
require "async/dns"

begin
	require 'ruby-prof'
	
	RSpec.shared_context "profile" do
		around(:each) do |example|
			profile = RubyProf.profile(merge_fibers: true) do
				example.run
			end
			
			printer = RubyProf::FlatPrinter.new(profile)
			printer.print(STDOUT)
		end
	end
rescue LoadError
	RSpec.shared_context "profile" do
		before(:all) do
			puts "Profiling not supported on this platform."
		end
	end
end

RSpec.configure do |config|
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = ".rspec_status"

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
