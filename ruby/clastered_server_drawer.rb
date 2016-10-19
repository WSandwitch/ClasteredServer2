require 'tk'
module ClasteredServer
	class Drawer
		attr_accessor :scale, :translate
		def initialize(height=400,width=400,x=0,y=0, options={})
			@root = TkRoot.new(width:x+width, height:y+height)
			@root.title = "Window"		
			@scale = (options[:scale] || 1).to_f
			@translate=options[:translate] || {x:0,y:0}
			@canvas = TkCanvas.new(@root) do
				place('height' => height, 'width' => width, 
					'x' => x, 'y' => x)
			end
		end

		def bind(*args)
			@root.bind(*args)
		end

		def c_oval(l,t,r,b,*args)
			TkcOval.new(@canvas,(@translate[:x]+l)/@scale,(@translate[:y]+t)/@scale,(@translate[:x]+r)/@scale,(@translate[:y]+b)/@scale, *args)
		end

		def c_circle(x,y,r,*args)
			TkcOval.new(@canvas,(@translate[:x]+x-r)/@scale,(@translate[:y]+y-r)/@scale,(@translate[:x]+x+r)/@scale,(@translate[:y]+y+r)/@scale, *args)
		end

		def c_rpoly(x0,y0,n,r,args)
			seg=2*Math::PI/n
			shape=(0...n*2).map{|i|
				if i%2==0
					x=x0+r*Math.cos(seg*(i/2))
					(@translate[:x]+x)/@scale
				else
					y=y0+r*Math.sin(seg*(i/2))
					(@translate[:y]+y)/@scale
				end
			}
			args[:fill]||=''
			args[:outline]||= "black"
			TkcPolygon.new(@canvas, shape, args)
		end


		def c_rect(l,t,r,b,args)
			args[:fill]||=''
			args[:outline]||= "black"
			TkcPolygon.new(@canvas,[
				(@translate[:x]+l)/@scale,(@translate[:y]+t)/@scale,
				(@translate[:x]+r)/@scale,(@translate[:y]+t)/@scale, 
				(@translate[:x]+r)/@scale,(@translate[:y]+b)/@scale,
				(@translate[:x]+l)/@scale,(@translate[:y]+b)/@scale
			],
			args)
		end

		def c_line(x1,y1,x2,y2,*args)
			TkcLine.new(@canvas,(@translate[:x]+x1)/@scale,(@translate[:y]+y1)/@scale,(@translate[:x]+x2)/@scale,(@translate[:y]+y2)/@scale, *args)
		end

		def c_clear
			@canvas.delete("all")
		end

		def remove(x)
			@canvas.delete(x)
		end

		def move(x,y)
			@translate[:x]+=x
			@translate[:y]+=y
			@canvas.move("all", @translate[:x], @translate[:y])
		end
		
		def scale(s, x=0,y=0)
			@scale*=s
			@canvas.scale("all", x, y, @scale, @scale)
		end
		
		def set_move(x,y)
			@translate[:x]=x
			@translate[:y]=y
			@canvas.move("all", @translate[:x], @translate[:y])
		end
		
		def set_scale(s, x=0,y=0)
			@scale=s
			@canvas.scale("all", x, y, @scale, @scale)
		end
		
		def self.loop
			Tk.mainloop
		end
		private

	end
end

=begin


#@root.bind('Button',
#				proc{|b,x,y,root_x,root_y|
#					yield(b,x,y,root_x,root_y)
#				}, "%b %x %y %X %Y"
#			)
			
			
drawer=Drawer.new(600,600,0,0, scale: 1, translate:{x: 10,y: 10}){|b,x,y,root_x,root_y|

}

#mouse event listener


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



Thread.new{
	i=0
	loop{
		drawer.c_rect(10+i,  5,    55-i,  50, 
                         'width' => 1)
		i+=1
		rpoly=drawer.c_rpoly(20, 70, i, 30, activefill:"black", fill:"", outline: "black")
		rpoly.bind("Button-1", ->{
			puts "pressed LMB"
		})
		rpoly.bind("Button-3", ->{
			puts "pressed RMB"
		})
		rpoly.bind("Double-Button-1", ->{
			puts "pressed Double LMB"
		})
		drawer.c_circle(20, 70, i, activefill:"black")
		
		
		sleep(1)
		drawer.c_clear
	}
}

Tk.mainloop

=end