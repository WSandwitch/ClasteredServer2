import flixel.*;
import clasteredServerClient.*;
import states.*;

class CSGame extends FlxGame
{
	public var id:Null<Int> = null;
	public var connection:Null<Connection> = null;
	public var login:Null<String> = null;
	public var pass:Null<String> = null;
	
	public function connection_lost(){
		connection.close();
		FlxG.switchState(new LoginState());
	}
	
	public function new(GameWidth:Int = 0, GameHeight:Int = 0, ?InitialState:Class<FlxState>, Zoom:Float = 1, UpdateFramerate:Int = 60, DrawFramerate:Int = 60, SkipSplash:Bool = false, StartFullscreen:Bool = false)
	{
		super(GameWidth, GameHeight, InitialState, Zoom, UpdateFramerate, DrawFramerate, SkipSplash, StartFullscreen);

	}
}