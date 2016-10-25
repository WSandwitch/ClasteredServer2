require 'socket'      # Sockets are in standard library
require 'digest'
require "base64"
require_relative "clastered_server_packet"

#puts "hostname"
hostname = "localhost"#gets.chomp
#puts "port"
port = 8000#gets.to_i

#s = TCPSocket.open(hostname, port)

#login="qwer"

def auth(s, login)
	#puts connected
	s.write [9,0,1,6,login.size].pack("vcccv")
	s.write login

	#s.write [4232].pack("l")
	#s.write [1].pack("l")
	p a=s.read(6).unpack("vcccc")
	s.write [login.size+7,1,2,1,1,6,login.size].pack("vcccccv")
	puts s.write login
	p a=s.read(7).unpack("vcccv")
	p b64=s.read(a[-1])

	passwd= login
	p ans=Base64.encode64(Digest::MD5.digest(Base64.decode64(b64)+Digest::MD5.digest(passwd))).chomp
	s.write [ans.size+7,1,2,1,2,6,ans.size].pack("vcccccv")
	s.write ans

	p size=s.read(2).unpack("v")[0]
	p s.read(size)

	s.write [12,50,1,1,2,3,2,2,ans.size].pack("vcccccVcv")
end

#auth(s, login)


#p s.read(1)
#while line = s.gets   # Read lines from the socket
  #puts line.chop      # And print with platform line terminator
#end

#sleep(5)

#s.close               # Close the socket when done


=begin
md5=Digest::MD5.digest("hello")
Base64.encode64(md5)
Base64.decode64(md5)

passwd="hello" #- password
b64 #token from server
Base64.encode64(Digest::MD5.digest(Base64.decode64(b64)+Digest::MD5.digest(passwd)))

=end