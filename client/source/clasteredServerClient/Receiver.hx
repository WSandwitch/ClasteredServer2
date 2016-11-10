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
		if (state.connection == null){
			state.connection_lost();
			return;
		}
		try{
			while(true){
				if (packet == null){
					if (state.connection.bytesAvailable(2)){
						packet = new Packet();
						packet.size = state.connection.recvShort();
					}else
						break;
				}else{
					if (state.connection.bytesAvailable(packet.size)){
						state.connection.recvPacketData(packet);
						state.l.lock();
							state.packets.push(packet);
						state.l.unlock();
						packet = null;
					}else 
						break;
				}
			}
			haxe.Timer.delay(worker, 33);
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
//					trace("Got packet", p.type);
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