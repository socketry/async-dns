module Celluloid
  module DNS
    class Server
      # Maximum UDP packet we'll accept
      MAX_PACKET_SIZE = 512
      
      include Celluloid::IO
      
      def initialize(addr, port)
        # Create a non-blocking Celluloid::IO::UDPSocket
        @socket = UDPSocket.new
        @socket.bind(addr, port)
        
        run!
      end
      
      def run
        loop do
          data, (_, port, addr) = @socket.recvfrom(MAX_PACKET_SIZE)
          message = Resolv::DNS::Message.decode(data)
          p message
        end
      end
    end
  end
end