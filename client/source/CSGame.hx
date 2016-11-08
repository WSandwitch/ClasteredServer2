import flixel.*;
import clasteredServerClient.*;

class CSGame extends FlxGame
{
	public var id:Int = null;
	public var connection:Null<Connection> = null;
	
	public function new(GameWidth:Int = 0, GameHeight:Int = 0, ?InitialState:Class<FlxState>, Zoom:Float = 1, UpdateFramerate:Int = 60, DrawFramerate:Int = 60, SkipSplash:Bool = false, StartFullscreen:Bool = false)
	{
		super(GameWidth, GameHeight, InitialState, Zoom, UpdateFramerate, DrawFramerate, SkipSplash, StartFullscreen);

	}
}