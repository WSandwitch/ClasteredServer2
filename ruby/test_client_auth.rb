require 'socket'
require 'io/wait'

require_relative "test_client"



#puts "hostname"
hostname = "localhost"#gets.chomp
#puts "port"
port = 8000#gets.to_i

s = TCPSocket.open(hostname, port)

login="qwer"

auth(s, login)

s.close