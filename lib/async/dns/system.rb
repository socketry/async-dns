# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

begin
	require 'win32/resolv'
rescue LoadError
	# Ignore this - we aren't running on windows.
end

module Async::DNS
	# This module encapsulates system dependent name lookup functionality.
	module System
		RESOLV_CONF = "/etc/resolv.conf"
		HOSTS = "/etc/hosts"
		
		# Get the path to the hosts file.
		def self.hosts_path
			if RUBY_PLATFORM =~ /mswin32|mingw|bccwin/
				Win32::Resolv.get_hosts_path
			else
				HOSTS
			end
		end
		
		# @returns [Boolean] True if the system supports IPv6.
		def self.ipv6?
			begin
				list = Socket.ip_address_list
			rescue NotImplementedError
				return true
			end
			
			list.any? {|a| a.ipv6? && !a.ipv6_loopback? && !a.ipv6_linklocal? }
		end
		
		# An interface for querying the system's hosts file.
		class Hosts < Resolver
			# Hosts for the local system.
			def self.local
				hosts = self.new
				
				path = System.hosts_path
				
				if path and File.exist?(path)
					File.open(path) do |file|
						hosts.parse_hosts(file)
					end
				end
				
				return hosts
			end
			
			# Create a new hosts file interface.
			def initialize
				@addresses = {}
				@names = {}
			end
			
			# This is used to match names against the list of known hosts:
			def call(name)
				if addresses = @names[name]
					return addresses
				else
					return super
				end
			end
			
			# Lookup a name in the hosts file.
			def lookup(name)
				addresses = @names[name]
				
				if addresses
					addresses.last
				else
					nil
				end
			end
			
			alias [] lookup
			
			# Add a new address with the given names.
			def add(address, names)
				@addresses[address] ||= []
				@addresses[address] += names
				
				names.each do |name|
					@names[name] ||= []
					@names[name] << address
				end
			end
			
			# Parse a hosts file and add the entries.
			def parse_hosts(io)
				io.each do |line|
					line.sub!(/#.*/, '')
					address, hostname, *aliases = line.split(/\s+/)
					
					add(address, [hostname] + aliases)
				end
			end
		end
		
		# Parse the `resolv.conf` file and return a list of nameservers.
		def self.parse_resolv_configuration(path)
			nameservers = []
			File.open(path) do |file|
				file.each do |line|
					# Remove any comments:
					line.sub!(/[#;].*/, '')
					
					# Extract resolv.conf command:
					keyword, *args = line.split(/\s+/)
					
					case keyword
					when 'nameserver'
						nameservers += args
					end
				end
			end
			
			return nameservers
		end
		
		# Get a list of standard nameserver connections which can be used for querying any standard servers that the system has been configured with.
		def self.standard_connections(nameservers, **options)
			connections = []
			
			nameservers.each do |host|
				connections << IO::Endpoint.udp(host, 53, **options)
				connections << IO::Endpoint.tcp(host, 53, **options)
			end
			
			return IO::Endpoint.composite(connections)
		end
		
		# Get a list of standard nameserver connections which can be used for querying any standard servers that the system has been configured with. There is no equivalent facility to use the `hosts` file at present.
		def self.nameservers(**options)
			nameservers = []
			
			if File.exist? RESOLV_CONF
				nameservers = parse_resolv_configuration(RESOLV_CONF)
			elsif defined?(Win32::Resolv) and RUBY_PLATFORM =~ /mswin32|cygwin|mingw|bccwin/
				search, nameservers = Win32::Resolv.get_resolv_info
			end
			
			return standard_connections(nameservers, **options)
		end
		
		# Get a list of default nameservers.
		def self.default_nameservers
			self.nameservers(timeout: 5.0)
		end
	end
end
