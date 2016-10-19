require 'stringio'
module ClasteredServer
	class Packet
		attr_reader :dest
		
		def initialize(type=nil)
			@type=type
			@n=0
			@data=""
		end
		
		TYPES={
			1=>{
				name:'char',
				pack: 'c',
				size: 1
			},
			2=>{
				name:'short',
				pack: 'v',
				size: 2
			},
			3=>{
				name:'int',
				pack: 'V',
				size: 4
			},
			4=>{
				name:'float',
				pack: 'e',
				size: 4
			},
			5=>{
				name:'double', 
				pack: 'E',
				size: 8
			}
		}
		
		TYPES.each do |k, v|
			define_method("add_#{v[:name]}") do |a|
				@data+=if a.class==Array
					@n+=a.size
					a.inject('') do |o,e|
						o+[k,e].pack('c'+v[:pack])
					end
				else
					@n+=1
					[k,a].pack('c'+v[:pack])
				end
				return self
			end
		end
		
		def add_string(a)
			@data+=[6,a.size].pack('cv')
			@data+=a
			@n+=1
			return self
		end
		
		def set_dest(type, id)
			@dest=[type, id]
			return self
		end
		
		def set_type(type)
			@type=type
			return self
		end
		
		def clean_dest
			@dest=nil
			return self
		end
		
		def send(s)
			data=[@data.size+(@dest ? 7: 2), @type, @n<127 ? @n : -1].pack('vcc')
			data+=@data
			data+=@dest.pack('cV') if @dest
			s.write data
			return self
		end
		
		def recv(s, server=false)
			size=s.read(2).unpack('v')[0]
			@type=s.read(1).unpack('c')[0]
			@n=s.read(1).unpack('c')[0]
			@data=s.read(size-(server ? 7 : 2))
			@dest=s.read(5).unpack('cV') if server
			return self
		end
		
		def parse
			out=[@type, @n]
			StringIO.open(@data,'rb') do |s|
				while(!s.eof?) do
					t=s.read(1).unpack('c')[0]
					out<<if (t==6)
						s.read(s.read(2).unpack('v')[0])
					else
						s.read(TYPES[t][:size]).unpack(TYPES[t][:pack])[0]
					end
				end
			end
			return out+(@dest || [])
		end

		def init
			@data=''
			@type=nil
			@n=0
			@dest=nil
			return self
		end
		
		def to_s
			dest=""
			dest=@dest.pack('cV') if @dest
			([@data.size,@type,@n<127 ? @n : -1].pack('vcc')+@data+dest).inspect
		end
	end
end

#p (p ClasteredServer::Packet.new(1).add_char([1,2,3]).add_int(3).set_dest(0,0).add_string('test')).parse

