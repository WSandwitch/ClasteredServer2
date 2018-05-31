package;

import states.InitState;
import openfl.display.Sprite;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.addons.ui.FlxUIState;
import flixel.system.scaleModes.*;
import clasteredServerClient.*;
import util.Settings;

import openfl.system.Capabilities;

class Main extends Sprite
{
	public static var tongue:FireTongueEX;

	public static var id:Null<Int> = null;
	public static var connection:Null<Connection> = null;
	public static var login:Null<String> = null;
	public static var pass:Null<String> = null;
	
	public function new()
	{
		super();
		if (Main.tongue == null){
			Main.tongue = new FireTongueEX();
			Main.tongue.init("en-US");
			FlxUIState.static_tongue = Main.tongue;
		}
		Settings.init();
	#if mobile
		addChild(new FlxGame(0, 0, InitState));
	#else
		//add load saved screen size
		addChild(new FlxGame(Settings.screenWidth, Settings.screenHeight, InitState));
		FlxG.resizeWindow(FlxG.width, FlxG.height);
	#end
		FlxG.autoPause = false;
		//FlxG.fixedTimestep = false;
		trace('screen dpi ' + Capabilities.screenDPI);
		
	FlxG.scaleMode = new BorderedStageSizeScaleMode(Settings.screenScale);
	//		FlxG.scaleMode.onMeasure(FlxG.width, FlxG.height); 
//		FlxG.camera.zoom = 1.1;
	//read config and setup
	#if desktop
		//you can resize window on fly
//		CSGame.resizeWindow(1024, 768);
	#end
		//FlxG.fullscreen = true;
		//FlxG.switchState(new PlayState());
	#if (mobile && debug)
//		FlxG.log.redirectTraces = true;
		FlxG.debugger.visible = true;
	#end
//		trace(openfl.utils.SystemPath.applicationStorageDirectory);
	}
	
	public static function connection_lost(){
		connection.close();
		connection = null;
		FlxG.switchState(new InitState());
	}
}