# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2014, by Tony Arcieri.
# Copyright, 2013, by Greg Thornton.
# Copyright, 2014, by Hendrik Beskow.
# Copyright, 2015-2024, by Samuel Williams.
# Copyright, 2023, by Hal Brodigan.

require 'async'

require 'io/endpoint/composite_endpoint'
require 'io/endpoint/host_endpoint'

require_relative 'transaction'
require_relative 'handler'

module Async::DNS
	#
	# Base class for defining asynchronous DNS servers.
	#
	# ## Example
	#
	#     require 'async/dns'
	#     
	#     class TestServer < Async::DNS::Server
	#       def process(name, resource_class, transaction)
	#         @resolver ||= Async::DNS::Resolver.new([[:udp, '8.8.8.8', 53], [:tcp, '8.8.8.8', 53]])
	#     
	#         transaction.passthrough!(@resolver)
	#       end
	#     end
	#     
	#     server = TestServer.new([[:udp, '127.0.0.1', 2346]])
	#     server.run
	#
	class Server
		# The default server interfaces.
		DEFAULT_ENDPOINT = ::IO::Endpoint.composite(
			::IO::Endpoint.udp('0.0.0.0', 53),
			::IO::Endpoint.tcp('0.0.0.0', 53)
		)
		
		# Instantiate a server with a block.
		#
		# @param endpoints [Array<(Symbol, String, Integer)>]  The endpoints to listen on.
		# @param origin [String] The default origin to resolve domains within.
		# @param logger [Console::Logger] The logger to use.
		def initialize(endpoint = DEFAULT_ENDPOINT, origin: '.', logger: Console.logger)
			@endpoint = endpoint
			@origin = origin
			@logger = logger
		end
		
		# Records are relative to this origin.
		#
		# @return [String]
		attr_accessor :origin
		
		# The logger to use.
		#
		# @return [Console::Logger]
		attr_accessor :logger
		
		# Give a name and a record type, try to match a rule and use it for processing the given arguments.
		#
		# @param name [String] The resource name.
		# @param resource_class [Class<Resolv::DNS::Resource>] The requested resource class.
		# @param transaction [Transaction] The transaction object.
		def process(name, resource_class, transaction)
			transaction.fail!(:NXDomain)
		end
		
		# Process an incoming DNS message. Returns a serialized message to be sent back to the client.
		def process_query(query, options = {}, &block)
			start_time = Time.now
			
			# Setup response
			response = Resolv::DNS::Message::new(query.id)
			response.qr = 1                 # 0 = Query, 1 = Response
			response.opcode = query.opcode  # Type of Query; copy from query
			response.aa = 1                 # Is this an authoritative response: 0 = No, 1 = Yes
			response.rd = query.rd          # Is Recursion Desired, copied from query
			response.ra = 0                 # Does name server support recursion: 0 = No, 1 = Yes
			response.rcode = 0              # Response code: 0 = No errors
			
			transaction = nil
			
			begin
				query.question.each do |question, resource_class|
					begin
						question = question.without_origin(@origin)
						
						@logger.debug(query) {"Processing question #{question} #{resource_class}..."}
						
						transaction = Transaction.new(self, query, question, resource_class, response, options)
						
						transaction.process
					rescue Resolv::DNS::OriginError
						# This is triggered if the question is not part of the specified @origin:
						@logger.debug(query) {"Skipping question #{question} #{resource_class} because #{$!}"}
					end
				end
			rescue StandardError => error
				@logger.error(query) {error}
				
				response.rcode = Resolv::DNS::RCode::ServFail
			end
			
			end_time = Time.now
			@logger.debug(query) {"Time to process request: #{end_time - start_time}s"}
			
			return response
		end
		
		# Setup all specified interfaces and begin accepting incoming connections.
		def run
			@logger.info "Starting Async::DNS server (v#{Async::DNS::VERSION})..."
			
			Async do |task|
				@endpoint.bind do |server|
					@logger.info "<> Listening for connections on #{server.local_address.inspect}"
					case server.local_address.socktype
					when Socket::SOCK_DGRAM
						Async{DatagramHandler.new(self, server).run}
					when Socket::SOCK_STREAM
						Async{StreamHandler.new(self, server).run}
					else
						raise ArgumentError.new("Don't know how to handle #{server}")
					end
				end
			end
		end
	end
end
