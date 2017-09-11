package states;

import flixel.FlxG;
import flixel.FlxState;
import clasteredServerClient.Connection;

/**
 * 
 */
class CSState extends FlxState
{
	static public var id:Null<Int> = null;
	static public var connection:Null<Connection> = null;
	static public var login:Null<String> = null;
	static public var pass:Null<String> = null;
	
	static public function connection_lost(){
		FlxG.switchState(new LoginState());
	}
	
	
	override public function create():Void 
	{	
		super.create();
	}
	

}
