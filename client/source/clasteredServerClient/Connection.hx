package clasteredServerClient;


import clasteredServerClient.Packet.Chank;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesOutput;
import sys.net.Socket;
import sys.net.Host;
import haxe.crypto.Md5;
import haxe.crypto.Base64;

class Connection{
	private var sock:Socket = new Socket();
	public var write:Lock = new Lock();
	public var read:Lock = new Lock();
	
	public function new(host:String, port:Int){
		var p:Packet = new Packet();
//		sock.setBlocking(true);
//		sock.setTimeout(100000);
		sock.connect(new Host(host), port);
		sock.input.bigEndian=false;
		sock.output.bigEndian = false;
		sock.setFastSend(true);
		p.type = 0;
		p.addString("Haxe hello");
		sendPacket(p);
	}
	
	public function recvChar():Int{
//		sock.waitForRead();
		return sock.input.readInt8();
	}

	public function recvShort():Int{
//		sock.waitForRead();
		return sock.input.readInt16();
	}

	public function recvInt():Int{
//		sock.waitForRead();
		return sock.input.readInt32();
	}

	public function recvFloat():Float{
//		sock.waitForRead();
		return sock.input.readFloat();
	}

	public function recvDouble():Float{
//		sock.waitForRead();
		return sock.input.readDouble();
	}

	public function recvBytes(?size:Null<Int>):Bytes{
//		sock.waitForRead();
		if (size==null)
			size=recvShort();
		return sock.input.read(size);
	}

	public function recvString(?size:Null<Int>):String{
//		sock.waitForRead();
		if (size==null)
			size=recvShort();
		return sock.input.readString(size);
	}

	public function sendChar(a:Int):Void{
		sock.output.writeInt8(a);
	}

	public function sendShort(a:Int):Void{
		sock.output.writeInt16(a);
	}

	public function sendInt(a:Int):Void{
		sock.output.writeInt32(a);
	}

	public function sendFloat(a:Float):Void{
		sock.output.writeFloat(a);
	}

	public function sendDouble(a:Float):Void{
		sock.output.writeDouble(a);
	}

	public function sendBytes(s:Bytes):Void{
		sock.output.write(s);
	}

	public function sendString(s:String):Void{
		sock.output.writeInt16(s.length);
		sock.output.writeString(s);
	}

	public function recvPacket():Packet{
		var p:Packet = new Packet();
		var size:Int;
		read.lock();
			size = recvShort();
//			trace("size",size);
			p.size = size;
			p.type = recvChar();
			size--;
			recvChar();//
			size--;
			while(size>1){
				var type:Int = recvChar();
				size--;
				var c:Chank = new Chank(type);
				switch type {
					case 1: 
						c.i = recvChar();
						size-= 1;
					case 2: 
						c.i=recvShort();
						size-= 2;
					case 3: 
						c.i=recvInt();
						size-= 4;
					case 4: 
						c.f=recvFloat();
						size-= 4;
					case 5: 
						c.f=recvDouble();
						size-= 8;
					case 6: 
						c.s=recvString();
						size-= c.s.length+2;
				}
				p.chanks.push(c);
			}
		read.unlock();
		return p;
	}

	public function sendPacket(p:Packet):Void{
		var buf:BytesOutput = new BytesOutput();
		buf.bigEndian = false;
		buf.writeInt16(p.size+2);
		buf.writeInt8(p.type);
		buf.writeInt8(p.chanks.length>125 ? -1 : p.chanks.length);
		for (c in p.chanks){
			if (c.type>0 && c.type<7){
				buf.writeInt8(c.type);
				switch c.type {
					case 1: 
						buf.writeInt8(c.i);
					case 2: 
						buf.writeInt16(c.i);
					case 3: 
						buf.writeInt32(c.i);
					case 4: 
						buf.writeFloat(c.f);
					case 5: 
						buf.writeDouble(c.f);
					case 6: 
						buf.writeInt16(c.s.length);
						buf.writeString(c.s);
//					default: trace("wrong chank");
				}
			}
		}
		write.lock();
			sendBytes(buf.getBytes());
		write.unlock();		
	}
	
	public function auth(login:String, pass:String):Int{
		var p:Packet;
		p = recvPacket();
//		trace(p);
		p.init();
		p.type = 1;
		p.addChar(1);//first stage
		p.addString(login);
		sendPacket(p);
		
		p = recvPacket();
//		trace(p);
		var password:String = Base64.encode(Md5.make(Bytes.ofString(Base64.decode(p.chanks[0].s).toString() + Md5.make(Bytes.ofString(pass)).toString())));//WTF salted pass
		p.init();
		p.type = 1;
		p.addChar(2);
		p.addString(password);
		sendPacket(p);
		
		p.init();
		p.type = 50;
		p.addChar(2);
		p.addString(password);
		sendPacket(p);
		
		p = recvPacket();//chank 0- id(Int)
//		trace(p);
		return p.chanks[0].i;
	}
}