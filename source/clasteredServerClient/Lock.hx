package clasteredServerClient;

#if cpp
import cpp.vm.Mutex;
#elseif neko
import neko.vm.Mutex;
#elseif java
import java.vm.Mutex;
#end


/**
 * ...
 * @author ...
 */
class Lock{
	#if !flash
	private var m:Mutex=new Mutex();
	#end
	
	public function new(){
		
	}
	
	public function lock():Void{
		#if !flash
			m.acquire();
		#end
	}
	
	public function unlock():Void{
		#if !flash
			m.release();
		#end
	}
	
}