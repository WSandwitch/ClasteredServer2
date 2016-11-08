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
	private var state:Null<PlayState>=null;
#else
	private var t:Thread;
#end

	public function new(?s:Null<PlayState>){
	#if flash
		state = s;
		
	#else	
		this.t = Thread.create(thread);
		this.t.sendMessage(Thread.current());
		this.t.sendMessage(s);
	#end
	}

#if flash
	
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