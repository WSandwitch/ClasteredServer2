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
#end


/**
 * ...
 * @author ...
 */
class Receiver{
#if flash
	
#else
	private var t:Thread;

	public function new(){
		this.t = Thread.create(thread);
		this.t.sendMessage(Thread.current());
	}
	
	private function thread(){
		var main:Thread = Thread.readMessage(true);
		var game:CSGame = cast FlxG.game;
		trace("receiver started");
		if (game.connection != null){
			try{
				while (game.recv_loop){
					var p:Packet = game.connection.recvPacket();
//					trace(p);
					game.l.lock();
						game.packets.push(p);
					game.l.unlock();
//					trace("loop");
				}
			}catch(e:Dynamic){
				trace(e);
				trace(CallStack.toString(CallStack.exceptionStack()));
			}
		}
		game.connection_lost();
		trace("receiver exited");
	}
	
#end
	
}