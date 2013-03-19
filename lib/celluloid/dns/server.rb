module Celluloid
  module DNS
    class Server
      # Maximum UDP packet we'll accept
      MAX_PACKET_SIZE = 512
      
      include Celluloid::IO
      
      def initialize(addr, port, &block)
        @block = block
        
        # Create a non-blocking Celluloid::IO::UDPSocket
        @socket = UDPSocket.new
        @socket.bind(addr, port)
        
        async.run
      end
      
      def run
        loop do
          data, (_, port, addr) = @socket.recvfrom(MAX_PACKET_SIZE)
          @block.call Request.new(addr, port, @socket, data)
        end
      end
    end
  end
end