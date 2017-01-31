package;

import states.LoginState;
import openfl.display.Sprite;

import flixel.FlxG;
import flixel.system.scaleModes.*;
import clasteredServerClient.*;

class Main extends Sprite
{
	public function new()
	{
		super();
	#if mobile
		addChild(new CSGame(0, 0, LoginState));
	#else
		//add load saved screen size
		addChild(new CSGame(720, 560, LoginState));
		FlxG.resizeWindow(FlxG.width, FlxG.height);
	#end
		FlxG.autoPause = false;
		//FlxG.fixedTimestep = false;
	#if flash
		FlxG.scaleMode = new BorderedStageSizeScaleMode(1); 
	#else
		FlxG.scaleMode = new BorderedStageSizeScaleMode(1);//BorderedStageSizeScaleMode(1920, 1080); //StageSizeScaleMode();// 
	#end
	//read config and setup
	#if desktop
		//you can resize window on fly
//		FlxG.resizeGame(1024, 800);
//		FlxG.resizeWindow(1024, 800);
//		FlxG.camera.setSize(1024, 800);
	#end
		//FlxG.fullscreen = true;
		//FlxG.switchState(new PlayState());
	#if (mobile && debug)
		FlxG.log.redirectTraces = true;
		FlxG.debugger.visible = true;
	#end
	}
}