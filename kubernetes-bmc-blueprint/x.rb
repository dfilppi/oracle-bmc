#!/usr/bin/ruby

require 'json'
require 'yaml'
require 'socket'

def port_open?(ip, port, seconds=1)
  (1..seconds).each do |i|
    begin
      TCPSocket.new(ip, port).close
      puts "CONNECTED"
      return true
    rescue 
      puts "ERR"
    end
    sleep 1
  end
  puts "TIMEOUT"
  false
end

puts port_open?("129.146.0.139 ",22,30)
