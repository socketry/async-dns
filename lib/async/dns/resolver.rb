# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.
# Copyright, 2017, by Olle Jonsson.
# Copyright, 2024, by Sean Dilda.

require_relative 'handler'
require_relative 'system'
require_relative 'cache'

require 'securerandom'
require 'async'

require 'io/endpoint/composite_endpoint'
require 'io/endpoint/host_endpoint'

module Async::DNS
	# Represents a DNS connection which we don't know how to use.
	class InvalidProtocolError < StandardError
	end
	
	# Represents a failure to resolve a given name to an address.
	class ResolutionFailure < StandardError
	end
	
	# Resolve names to addresses using the DNS protocol.
	class Resolver
		# The default resolver for the system.
		def self.default(**options)
			System.resolver(**options)
		end
		
		# Servers are specified in the same manor as options[:listen], e.g.
		#   [:tcp/:udp, address, port]
		# In the case of multiple servers, they will be checked in sequence.
		def initialize(endpoint, ndots: 1, search: nil, origin: nil, cache: Cache.new, **options) 
			@endpoint = endpoint
			
			@ndots = ndots
			if search
				@search = search
			else
				@search = [nil]
			end
			
			if origin
				@search = [origin] + @search
			end
			
			@cache = cache
			@options = options
		end
		
		# The search domains, which are used to generate fully qualified names if required.
		attr :search
		
		# Generates a fully qualified name from a given name.
		#
		# @parameter name [String | Resolv::DNS::Name] The name to fully qualify.
		def fully_qualified_names(name)
			return to_enum(:fully_qualified_names, name) unless block_given?
			
			name = Resolv::DNS::Name.create(name)
			
			if name.absolute?
				yield name
			else
				if @ndots <= name.length - 1
					yield name
				end
				
				@search.each do |domain|
					yield name.with_origin(domain)
				end
			end
		end
		
		# Provides the next sequence identification number which is used to keep track of DNS messages.
		def next_id!
			# Using sequential numbers for the query ID is generally a bad thing because over UDP they can be spoofed. 16-bits isn't hard to guess either, but over UDP we also use a random port, so this makes effectively 32-bits of entropy to guess per request.
			SecureRandom.random_number(2**16)
		end
		
		# Query a named resource and return the response.
		#
		# Bypasses the cache and always makes a new request.
		#
		# @returns [Resolv::DNS::Message] The response from the server.
		def query(name, resource_class = Resolv::DNS::Resource::IN::A)
			response = nil
			
			self.fully_qualified_names(name) do |fully_qualified_name|
				response = self.dispatch_query(fully_qualified_name, resource_class)
				
				break if response.rcode == Resolv::DNS::RCode::NoError
			end
			
			return response
		end
		
		# Look up a named resource of the given resource_class.
		def records_for(name, resource_classes)
			Console.debug(self) {"Looking up records for #{name.inspect} with #{resource_classes.inspect}."}
			resource_classes = Array(resource_classes)
			resources = nil
			
			self.fully_qualified_names(name) do |fully_qualified_name|
				resources = @cache.fetch(fully_qualified_name, resource_classes) do |name, resource_class|
					if response = self.dispatch_query(name, resource_class)
						response.answer.each do |name, ttl, record|
							Console.debug(self) {"Caching record for #{name.inspect} with #{record.class} and TTL #{ttl}."}
							@cache.store(name, resource_class, record)
						end
					end
				end
				
				break if resources.any?
			end
			
			return resources
		end
		
		if System.ipv6?
			ADDRESS_RESOURCE_CLASSES = [Resolv::DNS::Resource::IN::A, Resolv::DNS::Resource::IN::AAAA]
		else
			ADDRESS_RESOURCE_CLASSES = [Resolv::DNS::Resource::IN::A]
		end
		
		# Yields a list of `Resolv::IPv4` and `Resolv::IPv6` addresses for the given `name` and `resource_class`. Raises a ResolutionFailure if no severs respond.
		def addresses_for(name, resource_classes = ADDRESS_RESOURCE_CLASSES)
			records = self.records_for(name, resource_classes)
			
			if records.empty?
				raise ResolutionFailure.new("Could not find any records for #{name.inspect}!")
			end
			
			addresses = []
			
			if records
				records.each do |record|
					if record.respond_to? :address
						addresses << record.address
					else
						# The most common case here is that record.class is IN::CNAME and we need to figure out the address. Usually the upstream DNS server would have replied with this too, and this will be loaded from the response if possible without requesting additional information:
						addresses += addresses_for(record.name, resource_classes)
					end
				end
			end
			
			if addresses.empty?
				raise ResolutionFailure.new("Could not find any addresses for #{name.inspect}!")
			end
			
			return addresses
		end
		
		private
		
		# In general, DNS servers are only able to handle a single question at a time. This method is used to dispatch a single query to the server and wait for a response.
		def dispatch_query(name, resource_class)
			message = Resolv::DNS::Message.new(self.next_id!)
			message.rd = 1
			
			message.add_question(name, resource_class)
			
			return dispatch_request(message)
		end
		
		# Send the message to available servers. If no servers respond correctly, nil is returned. This result indicates a failure of the resolver to correctly contact any server and get a valid response.
		def dispatch_request(message)
			request = Request.new(message, @endpoint)
			error = nil
			
			request.each do |endpoint|
				Console.debug "[#{message.id}] Sending request #{message.question.inspect} to address #{endpoint.inspect}"
				
				begin
					response = try_server(request, endpoint)
					
					if valid_response(message, response)
						return response
					end
				rescue => error
					# Try the next server.
				end
			end
			
			if error
				raise error
			end
			
			return nil
		end
		
		def try_server(request, endpoint)
			endpoint.connect do |socket|
				case socket.local_address.socktype
				when Socket::SOCK_DGRAM
					try_datagram_server(request, socket)
				when Socket::SOCK_STREAM
					try_stream_server(request, socket)
				else
					raise InvalidProtocolError.new(endpoint)
				end
			end
		end
		
		def valid_response(message, response)
			if response.tc != 0
				Console.warn "Received truncated response!", message_id: message.id
			elsif response.id != message.id
				Console.warn "Received response with incorrect message id: #{response.id}!", message_id: message.id
			else
				Console.debug "Received valid response with #{response.answer.size} answer(s).", message_id: message.id
				
				return true
			end
			
			return false
		end
		
		def try_datagram_server(request, socket)
			socket.sendmsg(request.packet, 0)
			
			data, peer = socket.recvfrom(UDP_MAXIMUM_SIZE)
			
			return ::Resolv::DNS::Message.decode(data)
		end
		
		def try_stream_server(request, socket)
			transport = Transport.new(socket)
			
			transport.write_chunk(request.packet)
			
			data = transport.read_chunk
			
			return ::Resolv::DNS::Message.decode(data)
		end
		
		# Manages a single DNS question message across one or more servers.
		class Request
			# Create a new request for the given message and endpoint.
			#
			# Encodes the message and stores it for later use.
			#
			# @parameter message [Resolv::DNS::Message] The message to send.
			# @parameter endpoint [IO::Endpoint::Generic] The endpoint to send the message to.
			def initialize(message, endpoint)
				@message = message
				@packet = message.encode
				
				@endpoint = endpoint
			end
			
			# @attribute [Resolv::DNS::Message] The message to send.
			attr :message
			
			# @attribute [String] The encoded message to send.
			attr :packet
			
			def each(&block)
				@endpoint.each(&block)
			end

			def update_id!(id)
				@message.id = id
				@packet = @message.encode
			end
		end
		
		private_constant :Request
	end
end
