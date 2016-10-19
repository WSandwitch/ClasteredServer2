module ClasteredServer
	class Grid
		attr_accessor :id
		
		def initialize(size, offset)
			@size=size.map{|e| e.to_f}
			@offset=offset
			@cell=[0,0]
			@data=[]
			@server_ids=[]
			@grid_size=[0,0]
			@id=0
			@recover=1
		end
		
		def get_owner(x,y)
			return (@data[to_grid(x/@cell[0],y/@cell[1])])[:owner]
		end
		
		def get_shares(x,y)
			return (@data[to_grid(x/@cell[0],y/@cell[1])])[:shares]
		end
		
		def add(s)
			if s.class==Array
				@server_ids+=s
			else
				@server_ids<<s
			end
			@server_ids.uniq!
			@server_ids.sort!
			reconfigure
		end
		
		def remove(s)
			if s.class==Array
				@server_ids-=s
			else
				@server_ids-=[s]
			end
			@server_ids.sort!
			reconfigure
		end
		
		def get_area(id)
			return (@servers[id]||{})[:area]
		end
		
		private
		
		def reconfigure
			@servers={}
			counts=nil
			size=@server_ids.size#/@recover
			size.step(0,-1){|n|
				size=n
				counts=[(1..Math.sqrt(size).round).inject{|o,i| 
					(i if (size%i)==0)||o
				}]
				counts<<n/counts[0]
				counts=[counts[1],counts[0]] if (@size[0]>@size[1])#int 
				break if @offset<=@size[0]/counts[0] && @offset<=@size[1]/counts[1]
			}
			#p size, counts
			#p [@size[0]/counts[0],@size[1]/counts[1]]
			@cell=[]
			2.times{|i|
				l=@size[i]/counts[i]
				d=@offset
				1.step(1000000, 1){|n|#TODO: change
					a=l/n
					m=(d/a).ceil
					if (d<=m*a && 1.1*d>=m*a)
						@cell<<a
						break
					end
				}
			}
			#p @cell
			#p (@offset/@cell[1]).ceil
			@grid_size=[(@size[0]/@cell[0]).ceil,(@size[1]/@cell[1]).ceil]
			#need to find nok
			0.step(@server_ids.size-1,1){|j|#@recover){|j|
				id=@server_ids[j]
				i=j#/@recover
				@servers[id]={
					id: id, 
					index: i, 
					area:{
						l: @size[0]/@cell[0]/counts[0]*(i% counts[0]),
						t: @size[1]/@cell[1]/counts[1]*(i/ counts[0]),
						r: @size[0]/@cell[0]/counts[0]*(1+(i% counts[0])), 
						b: @size[1]/@cell[1]/counts[1]*(1+(i/ counts[0]))
					}
				}
			}
			cells={}
			@data=Array.new(@grid_size[0]*@grid_size[1])
			(@grid_size[1]).times{|y|
				(@grid_size[0]).times{|x|
#					puts "#{x} #{y} #{x/(@grid_size[0]/counts[0])+y/(@grid_size[1]/counts[1])*counts[0]}|#{@grid_size[1]/counts[1]}"
					s=@servers[@server_ids[x/(@grid_size[0]/counts[0])+y/(@grid_size[1]/counts[1])*counts[0]]]
					o={}
					o[:owner]=s[:id]
					o[:shares]=[] #because Array is faster
					if (@id==0 || s[:id]==@id)
						ix,iy=s[:index]% counts[0],s[:index]/ counts[0]
						offset=[(@offset/@cell[0]).ceil,(@offset/@cell[1]).ceil]
						l=s[:area][:l]<=x && x<s[:area][:l]+offset[0]
						t=s[:area][:t]<=y && y<s[:area][:t]+offset[1]
						r=s[:area][:r]>x && x>=s[:area][:r]-offset[0]
						b=s[:area][:b]>y && y>=s[:area][:b]-offset[1]
						if l
							x1=ix-1
							y1=iy
							o[:shares]<<@server_ids[(y1)*counts[0]+x1] if x1>=0 && x1<counts[0] && y1>=0 && y1<counts[1]
							if t
								x1=x1
								y1=y1-1
								o[:shares]<<@server_ids[(y1)*counts[0]+x1] if x1>=0 && x1<counts[0] && y1>=0 && y1<counts[1]
							end
						end
						if t
							x1=ix
							y1=iy-1
							o[:shares]<<@server_ids[(y1)*counts[0]+x1] if x1>=0 && x1<counts[0] && y1>=0 && y1<counts[1]
							if r
								x1=x1+1
								y1=y1
								o[:shares]<<@server_ids[(y1)*counts[0]+x1] if x1>=0 && x1<counts[0] && y1>=0 && y1<counts[1]
							end
						end
						if r
							x1=ix+1
							y1=iy
							o[:shares]<<@server_ids[(y1)*counts[0]+x1] if x1>=0 && x1<counts[0] && y1>=0 && y1<counts[1]
							if b
								x1=x1
								y1=y1+1
								o[:shares]<<@server_ids[(y1)*counts[0]+x1] if x1>=0 && x1<counts[0] && y1>=0 && y1<counts[1]
							end
						end
						if b
							x1=ix
							y1=iy+1
							o[:shares]<<@server_ids[(y1)*counts[0]+x1] if x1>=0 && x1<counts[0] && y1>=0 && y1<counts[1]
							if l
								x1=x1-1
								y1=y1
								o[:shares]<<@server_ids[(y1)*counts[0]+x1] if x1>=0 && x1<counts[0] && y1>=0 && y1<counts[1]
							end
						end
					end
					@data[to_grid(x,y)]= cells[o] || cells[o]=o
				}
			}
			#p @data
			return self
		end

		def to_grid(x,y)
			#puts "data #{@grid_size[0]} (#{x},#{y}) on (#{x/@cell[0]},#{y/@cell[1]})"
			index=(y.to_i*@grid_size[0]).to_i+(x).to_i
			index>0 ? index : 0
		end
	end
end

=begin

size=[32000,32000]
#data=ClasteredServer::Grid.new([8,8],2)
#data=ClasteredServer::Grid.new([67,83],3)
data=ClasteredServer::Grid.new(size, 20)
#data=ClasteredServer::Grid.new([2,5],1)
#data.reconfigure([1,24,-39,45,15,36,2,42,-6,-22], 24)
data.add((1..9).map{|i| i})

=end