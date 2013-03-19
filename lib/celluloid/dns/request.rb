require 'resolv'

module Celluloid
  module DNS
    class Request
      attr_reader :questions
      
      def initialize(addr, port, socket, data)
        @addr, @port, @socket = addr, port, socket
        @message = Resolv::DNS::Message.decode(data)
        @questions = @message.question.map { |question, resource| Question.new(question, resource) }
      end
      
      def answer(responses)
        response_message = Resolv::DNS::Message.new @message.id
        response_message.qr = 1
        response_message.opcode = @message.opcode
        response_message.aa = 1
        response_message.rd = @message.rd
        response_message.ra = 0
        response_message.rcode = 0
        
        responses.each do |question, response|
          response_object = question.resource.new(response)
          response_message.add_answer question.name, DEFAULT_TTL, response_object
        end
        
        @socket.send response_message.encode, 0, @addr, @port
      end
    end
    
    class Question
      attr_reader :resource
      
      def initialize(question, resource)
        @question, @resource = question, resource
      end
      
      # Obtain the name being queried
      def name
        raise TypeError, "not a name query" unless @question.is_a? Resolv::DNS::Name
        @question.to_s
      end
    end
  end
end