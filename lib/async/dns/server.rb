# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2014, by Tony Arcieri.
# Copyright, 2013, by Greg Thornton.
# Copyright, 2014, by Hendrik Beskow.
# Copyright, 2015-2025, by Samuel Williams.
# Copyright, 2023, by Hal Brodigan.

require "async"

require "io/endpoint/composite_endpoint"
require "io/endpoint/host_endpoint"

require_relative "transaction"
require_relative "handler"

module Async::DNS
	# A DNS server which can be used to resolve queries.
	class Server
		# The default endpoint to listen on.
		#
		# @parameter port [Integer] The port to listen on, defaults to 53.
		def self.default_endpoint(port = 53)
			::IO::Endpoint.composite(
				::IO::Endpoint.udp("localhost", port),
				::IO::Endpoint.tcp("localhost", port)
			)
		end
		
		# Instantiate a server with a block.
		#
		# @param endpoints [Array<(Symbol, String, Integer)>]  The endpoints to listen on.
		# @param origin [String] The default origin to resolve domains within.
		# @param logger [Console::Logger] The logger to use.
		def initialize(endpoint = self.class.default_endpoint, origin: ".")
			@endpoint = endpoint
			@origin = origin
		end
		
		# Records are relative to this origin.
		#
		# @return [String]
		attr_accessor :origin
		
		# @deprecated Use {Console} instead.
		def logger
			Console
		end
		
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
						
						Console.debug(query) {"Processing question #{question} #{resource_class}..."}
						
						transaction = Transaction.new(self, query, question, resource_class, response, **options)
						
						transaction.process
					rescue Resolv::DNS::OriginError => error
						# This is triggered if the question is not part of the specified @origin:
						Console.error(self, "Failed to process question #{question} #{resource_class}!", error: error)
					end
				end
			rescue StandardError => error
				Console.error(query) {error}
				
				response.rcode = Resolv::DNS::RCode::ServFail
			end
			
			end_time = Time.now
			Console.debug(query) {"Time to process request: #{end_time - start_time}s"}
			
			return response
		end
		
		# Setup all specified interfaces and begin accepting incoming connections.
		def run
			Console.info "Starting Async::DNS server (v#{Async::DNS::VERSION})..."
			
			Async do |task|
				@endpoint.bind do |server|
					Console.info "<> Listening for connections on #{server.local_address.inspect}"
					case server.local_address.socktype
					when Socket::SOCK_DGRAM
						DatagramHandler.new(self, server).run
					when Socket::SOCK_STREAM
						StreamHandler.new(self, server).run
					else
						raise ArgumentError.new("Don't know how to handle #{server}")
					end
				end
			end
		end
	end
end
