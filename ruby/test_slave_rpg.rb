require 'socket'
require 'io/wait'
require_relative "clastered_server_packet"
require_relative "clastered_server_grid"

class Npc
	attr_accessor :bot, :keys, :client_id
	attr_reader :id, :position
	def initialize(id)
		@id=id
		@world_size=[600,600]
		@dir=[0,0]
		@goal=[0,0]
		@position=[0,0]
		@keys=[0,0,0,0]
		@vel=2
	end
	
	def move(x,y)
		@position[0]+=x
		@position[1]+=y
		if @bot
			if (@position[0]-@goal[0])**2+(@position[1]-@goal[1])**2<=2*@vel
				@goal=[rand*@world_size[0], rand*@world_size[1]]
				set_dir(@goal[0]-@position[0], @goal[1]-@position[1])
			end
		end
	end
	
	def walk
		move(@dir[0]*@vel, @dir[1]*@vel)
	end
	
	def set_dir(x=nil,y=nil)
		@dir[0]=x||@keys[3]-@keys[2]
		@dir[1]=y||@keys[1]-@keys[0]
		normalize_dir
	end


	private
	
	def normalize_dir
		if (l=Math.sqrt(@dir[0]*@dir[0]+@dir[1]*@dir[1]))!=0
			@dir[0]/=l
			@dir[1]/=l
		end
	end
end


def time_diff(start, finish)
   (finish - start)
end

def addBot(npcs)
	npc=Npc.new((rand*1000).to_i)
	npc.bot=true
	npcs[npc.id]=npc
end


server = TCPServer.new(12345)
npcs={}
connection=nil
lat=1.0/10
latr=1.0/600
id=0
clients={}

Thread.new{
	packet=ClasteredServer::Packet.new
	loop{
		t=Time.now
		begin
			npcs.each{|k,v|
				v.walk
				packet.init.set_type(40).add_int(v.id).add_float(v.position[0]).add_float(v.position[1])
				clients.each{|k,v|
					packet.set_dest(1,v.client_id).send(connection)
				}
			}if connection && id!=0
		rescue Exception => e
			puts e
			puts e.backtrace
		end	
		dif=time_diff(t,Time.now)
		sleep(lat-dif) if (lat-dif>0)
	}
} if false

3.times{addBot(npcs)}

puts "wait for connections"
while (connection = server.accept)
	puts "connected"
	Thread.new(connection) do |conn|
		port, host = conn.peeraddr[1,2]
		client = "#{host}:#{port}"
		puts "#{client} is connected"
		begin
			packet=ClasteredServer::Packet.new
			packet.init
			packet.recv(conn, true)
			
			a=packet.parse
			if a[0]==2 #server connected
				id=a[2]
			end
			puts "server id #{id}"
			packet.init.set_type(5).add_int(id).set_dest(0,0).send(connection)
			puts "ready"
			loop{
				t=Time.now
				if (conn.ready?)
					packet.init
					packet.recv(conn, true)
					#p packet.to_s
					a=packet.parse
					case a[0]
						when 5 #client connected
							puts "connected client #{a[2]}"
							npcs[a[2]]=Npc.new(a[2])
							npcs[a[2]].client_id=a[2]
							clients[npcs[a[2]].client_id]=npcs[a[2]]
						when 6 #client disconnected
							puts "disconnected client #{a[2]}"
							npcs.delete(a[2])
							clients.delete(a[2])
						when 41
#							puts "kay #{a[2]} #{a[3]}" 
							cl=npcs[packet.dest[1]]
							if cl
								cl.keys[a[2]]=a[3]
								cl.set_dir
							end
						else
							puts "unknown packet"
					end
				end
				npcs.each{|k,v|
					v.walk
					packet.init.set_type(40).add_int(v.id).add_float(v.position[0]).add_float(v.position[1])
					clients.each{|k,v|
						packet.set_dest(1,v.client_id).send(connection)
					}
				}if connection && id!=0
	#        line = conn.read
	#        puts "#{client} says: #{line}"
	#        conn.write(line)
	#        conn.write(conn.read(1))
				dif=time_diff(t,Time.now)
				sleep(lat-dif) if (lat-dif>0)
			}
		rescue EOFError => e
			puts e
			conn.close
			puts "#{client} has disconnected"
		rescue Exception => e
			puts e
			puts e.backtrace
		end
	end
end