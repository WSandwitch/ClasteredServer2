package clasteredServerClient;

import haxe.CallStack;

import flixel.FlxG;
import flixel.FlxCamera;

#if cpp
import cpp.vm.Thread;
#elseif neko
import neko.vm.Thread;
#elseif java
import java.vm.Thread;
#elseif flash
#end


/**
 * ...
 * @author ...
 */
class Receiver{
#if flash
	private static var state:Null<PlayState> = null;
	private static var packet:Null<Packet> = null;
	private static var size_left:Int;
	private static var next_type:Int;
	private static var next_size:Int;
	private static var status:Int=0;
#else
	private var t:Thread;
#end

	public function new(?s:Null<PlayState>){
	#if flash
		state = s;
		worker();
	#else	
		this.t = Thread.create(thread);
		this.t.sendMessage(Thread.current());
		this.t.sendMessage(s);
	#end
	}

#if flash
	private static function worker(){
//		bytesAvailable();
		if (state == null || state.connection == null){
			state.connection_lost();
			return;
		}
		try{
			while(true){
				switch(status){
					case 0:
						if (state.connection.bytesAvailable()>=2){
							size_left = state.connection.recvShort();
							packet = new Packet();
							status = 1;
						}else
							break;
					case 1:
						if (state.connection.bytesAvailable()>=1){
							packet.type = state.connection.recvChar();
							status += 1;
							size_left -= 1;
						}else
							break;
					case 2:
						if (state.connection.bytesAvailable()>=1){
							var tmp:Int = state.connection.recvChar();
							status += 1;
							size_left -= 1;
						}else
							break;
					case 3:
						if (size_left <= 0){
							state.l.lock();
								state.packets.push(packet);
							state.l.unlock();
							status = 0;
						}else							
							if (state.connection.bytesAvailable()>=1){
								next_type = state.connection.recvChar();
								switch(next_type){
									case 1:
										next_size = 1;
									case 2:
										next_size = 2;
									case 3:
										next_size = 4;
									case 4:
										next_size = 4;
									case 5:
										next_size = 8;
									case 6:
										next_size = 2;
								}
								size_left -= next_size;
								status += 1;
							}else
								break;
					case 4:
						if (state.connection.bytesAvailable()>=next_size){
							switch(next_type){
								case 1:
									packet.addChar(state.connection.recvChar());
								case 2:
									packet.addShort(state.connection.recvShort());
								case 3:
									packet.addInt(state.connection.recvInt());
								case 4:
									packet.addFloat(state.connection.recvFloat());
								case 5:
									packet.addDouble(state.connection.recvDouble());
								case 6:
									size_left -= next_size;
									next_size = state.connection.recvShort();
									status += 2;
							}
							size_left -= next_size;
							status -= 1;
						}else
							break;
					case 5:
						if (state.connection.bytesAvailable()>=next_size){
							packet.addString(state.connection.recvString(next_size));
							size_left -= next_size;
							status = 3;
						}else
							break;
				}
			}
			haxe.Timer.delay(worker, 30);
		}catch(e:Dynamic){
			trace(e);
			trace(CallStack.toString(CallStack.exceptionStack()));
			state.connection_lost();
		}
	}
#else
	private function thread(){
		var main:Thread = Thread.readMessage(true);
		var state:Null<PlayState> = Thread.readMessage(true);
		trace("receiver started");
		if (state != null && state.connection != null){
			try{
				while (state.recv_loop){
					var p:Packet = state.connection.recvPacket();
//					trace(p);
					state.l.lock();
						state.packets.push(p);
					state.l.unlock();
//					trace("loop");
				}
			}catch(e:Dynamic){
				trace(e);
				trace(CallStack.toString(CallStack.exceptionStack()));
			}
		}
		state.connection_lost();
		trace("receiver exited");
	}
	
#end
	
}