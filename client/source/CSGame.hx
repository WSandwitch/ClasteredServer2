import flixel.*;
import clasteredServerClient.*;

class CSGame extends FlxGame
{
	public var id:Int;
	public var npcs:Map<Int,Null<Npc>> = new Map<Int,Null<Npc>>(); 
	public var npc:Null<Npc> = null;
	public var npc_id:Int = 0;
	
	public var l:Lock = new Lock();
	public var connection:Null<Connection> = null;
	public var recv_loop:Bool = true;
	public var receiver:Null<Receiver> = null;
	public var packets:Array<Packet> = new Array<Packet>();
	
	public function connection_lost(){
		
	}
	
	public function new(GameWidth:Int = 0, GameHeight:Int = 0, ?InitialState:Class<FlxState>, Zoom:Float = 1, UpdateFramerate:Int = 60, DrawFramerate:Int = 60, SkipSplash:Bool = false, StartFullscreen:Bool = false)
	{
		super(GameWidth, GameHeight, InitialState, Zoom, UpdateFramerate, DrawFramerate, SkipSplash, StartFullscreen);

	}
}