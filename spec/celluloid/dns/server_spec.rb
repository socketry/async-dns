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
      resolver = Resolv::DNS.new(nameserver_port: [[example_host, example_port]])
      resolver.getaddress(example_name).should eq example_p
    ensure
      server.terminate
    end
  end
end