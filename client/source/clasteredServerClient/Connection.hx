package clasteredServerClient;


import clasteredServerClient.Packet.Chank;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesOutput;
#if flash
import flash.net.Socket;
#else
import sys.net.Socket;
import sys.net.Host;
#end
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
	#if flash
		sock.connect(host, port);
		sock.endian = LITTLE_ENDIAN;
	#else
		sock.connect(new Host(host), port);
		sock.input.bigEndian=false;
		sock.output.bigEndian = false;
		sock.setFastSend(true);
	#end
		p.type = 0;
		p.addString("Haxe hello");
		sendPacket(p);
	}
	
	public function bytesAvailable(size:UInt):Bool{
	#if flash 
		trace(sock.bytesAvailable);
		return sock.bytesAvailable>=size;
	#else
		return true;
	#end
	}

	public function recvChar():Int{
//		sock.waitForRead();
	#if flash
		return sock.readByte();
	#else
		return sock.input.readInt8();
	#end
	}

	public function recvShort():Int{
//		sock.waitForRead();
	#if flash
		return sock.readShort();
	#else
		return sock.input.readInt16();
	#end
	}

	public function recvInt():Int{
//		sock.waitForRead();
	#if flash
		return sock.readInt();
	#else
		return sock.input.readInt32();
	#end
	}

	public function recvFloat():Float{
//		sock.waitForRead();
	#if flash
		return sock.readFloat();
	#else
		return sock.input.readFloat();
	#end
	}

	public function recvDouble():Float{
//		sock.waitForRead();
	#if flash
		return sock.readDouble();
	#else
		return sock.input.readDouble();
	#end
	}

	public function recvBytes(?size:Null<Int>):Bytes{
//		sock.waitForRead();
	#if flash
		return Bytes.ofString(recvString(size));
	#else
		if (size==null)
			size=recvShort();
		return sock.input.read(size);
	#end
	}

	public function recvString(?size:Null<Int>):String{
//		sock.waitForRead();
	#if flash
		if (size == null)
			return sock.readUTF();//unsigned!!
		else
			return sock.readUTFBytes(size);
	#else
		if (size==null)
			size=recvShort();
		return sock.input.readString(size);
	#end
	}

	public function sendChar(a:Int):Void{
	#if flash
		sock.writeByte(a);
		sock.flush();
	#else
		sock.output.writeInt8(a);
	#end
	}

	public function sendShort(a:Int):Void{
	#if flash
		sock.writeShort(a);
		sock.flush();
	#else
		sock.output.writeInt16(a);
	#end
	}

	public function sendInt(a:Int):Void{
	#if flash
		sock.writeInt(a);
		sock.flush();
	#else
		sock.output.writeInt32(a);
	#end
	}

	public function sendFloat(a:Float):Void{
	#if flash
		sock.writeFloat(a);
		sock.flush();
	#else
		sock.output.writeFloat(a);
	#end
	}

	public function sendDouble(a:Float):Void{
	#if flash
		sock.writeDouble(a);
		sock.flush();
	#else
		sock.output.writeDouble(a);
	#end
	}

	public function sendBytes(s:Bytes):Void{
	#if flash
		sock.writeBytes(s.getData(), 0, s.length);
		sock.flush();
	#else
		sock.output.write(s);
	#end
	}

	public function sendString(s:String):Void{
	#if flash
		sock.writeUTF(s);//unsigned!!
		sock.flush();
	#else
		sock.output.writeInt16(s.length);
		sock.output.writeString(s);
	#end
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
	
	public function auth(login:String, pass:String, f:Int->Void):Int{
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
		f(p.chanks[0].i);
		return p.chanks[0].i;
	}
	
	private function authStep(callback){
		
	}
}