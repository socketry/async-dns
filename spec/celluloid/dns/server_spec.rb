require 'spec_helper'
require 'resolv'

describe Celluloid::DNS::Server do
  let(:example_host) { '127.0.0.1' }
  let(:example_port) { 54321 }
  let(:example_name) { 'example.com' }
  let(:example_ip)   { '1.2.3.4' }
  
  it "answers DNS requests" do
    server = Celluloid::DNS::Server.new(example_host, example_port) do |request|
      # Totally bogus TDD-while-spiking bullshit
      request.name.should == example_name
      request.respond example_ip
    end
    
    begin
      Resolv::DNS.open(nameserver_port: [[example_host, example_port]]) do |resolv|
        resolv.getaddress(example_name).should eq example_p
      end
    ensure
      server.terminate
    end
  end
end