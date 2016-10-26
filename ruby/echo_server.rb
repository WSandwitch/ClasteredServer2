require 'socket'
server = TCPServer.new(8000)
 
while (connection = server.accept)
	conn=connection
#  Thread.new(connection) do |conn|
    port, host = conn.peeraddr[1,2]
    client = "#{host}:#{port}"
    puts "#{client} is connected"
    begin
	conn.write [4,1,1,1,1].pack("vcccc")
	conn.write [4,1,1,1,1].pack("vcccc")
	conn.write [4,1,1,1,1].pack("vcccc")
      loop do
        p conn.read(1).unpack("c")
#        puts "#{client} says: #{line}"
#        conn.puts(line)
      end
    rescue #EOFError
      conn.close
      puts "#{client} has disconnected"
    end
#  end
end