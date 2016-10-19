require 'socket'
require 'io/wait'

require_relative "clastered_server_drawer"
require_relative "clastered_server_packet"
require_relative "test_client"

include ClasteredServer

class World
	attr_reader :drawer, :size
	attr_accessor :npcs
	def initialize(x,y, cell)
		@scale=1#600.0/x
		@size=[x,y]
		@drawer=Drawer.new(x,y,0,0, scale: 1/@scale, translate:{x: 0,y: 0})
		@npcs={}
		@cell=cell
		@objects=[]
	end
	def remove(x)
		@drawer.remove(x)
	end
	
	def bind(*args)
		@drawer.bind(*args)
	end
	
end

class Npc
	attr_accessor :bot, :keys
	attr_reader :id, :obj, :position
	def initialize(world, id)
		@id=id
		@world=world
		@obj=@world.drawer.c_rpoly(0, 0, 5, 5, state: 'hidden', fill:"white", outline: "black")
		@dir=[0,0]
		@goal=[0,0]
		@position=[0,0]
		@vel=1
		@keys=[0,0,0,0]
		@bot=false
	end
	
	def move(x,y)
		@position[0]+=x
		@position[1]+=y
		@obj.move(x,y)
		if @bot
			if (@position[0]-@goal[0])**2+(@position[1]-@goal[1])**2<=@vel**2
				@goal=[rand*@world.size[0], rand*@world.size[1]]
				set_dir(@goal[0]-@position[0], @goal[1]-@position[1])
			end
		end
	end
	
	def walk
		move(@dir[0]*@vel, @dir[1]*@vel)
	end
	
	def update_position(x,y)
		move(x-@position[0],y-@position[1])
	end
	
	def set_dir(x=nil,y=nil)
		@dir[0]=x||@keys[3]-@keys[2]
		@dir[1]=y||@keys[1]-@keys[0]
		normalize_dir
	end
	
	def hide!
		@obj.state="hidden"
	end
	
	def show!
		@obj.state="normal"
	end
	
	def bind(*args)
		@obj.bind(*args)
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

#########

world=World.new(200,200,0)
drawer=world.drawer

#mouse event listener


=begin
drawer.c_rect(10,  5,    55,  50, 
                         'width' => 1)
drawer.c_rect(10,  65,  55, 110, 
                         'width' => 5) 
drawer.c_rect(10,  125, 55, 170, 
                         'width' => 1, 'fill'  => "red") 
drawer.c_line(0, 5, 100, 5)
drawer.c_line(0, 15, 100, 15, 'width' => 2)
drawer.c_line(0, 25, 100, 25, 'width' => 3)
drawer.c_line(0, 35, 100, 35, 'width' => 4)
=end
#n=Npc.new(world,-1)

events={
	"w"=>1,
	"s"=>3,
	'a'=>0,
	'd'=>2
}
keys=[0,0,0,0]
#world.npcs[n.id]=n

lat=1.0/18000

s = TCPSocket.open("localhost", 8000)
login="qwer"

world.bind("KeyPress", 
	proc{|e| 
		packet=ClasteredServer::Packet.new
		if events[e]
			packet.init.set_type(41).add_char(events[e]).add_char(1).send(s)
		end
	},
"%K")
world.bind("KeyRelease", 
	proc{|e| 
		packet=ClasteredServer::Packet.new
		if events[e]
			packet.init.set_type(41).add_char(events[e]).add_char(0).send(s)
		end
	},
"%K")



auth(s, login)

Thread.new{
	packet=ClasteredServer::Packet.new
	loop{
		begin
			t1=Time.now
			if s.ready?
				packet.init
				packet.recv(s, false)
				a=packet.parse
				case a[0]
					when 2 
						#do some stuff
					when 40
						cl=world.npcs[a[2]] || world.npcs[a[2]]=Npc.new(world,a[2])
						if cl
							cl.show!
							cl.update_position(a[4],a[6])
							#do some stuff
						end
					else
						puts "unknown packet"
				end
			end
			dif=time_diff(t1,Time.now)
			sleep(lat-dif) if (lat-dif>0)
		rescue Exception=> e
			puts e
			puts e.backtrace
		end
	}
}

Drawer.loop

s.close