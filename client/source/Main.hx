package;

import clasteredServerClient.Connection;
import clasteredServerClient.Receiver;
import clasteredServerClient.Packet;
import flixel.FlxGame;
import openfl.display.Sprite;

import flixel.FlxG;
import flixel.system.scaleModes.*;


class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new CSGame(640, 480, PlayState));
		
		//FlxG.fixedTimestep = false;
		FlxG.scaleMode = new BorderedStageSizeScaleMode(1024,768);
		//read config and setup
	#if desktop
		FlxG.resizeGame(800, 600);
		FlxG.resizeWindow(800, 600);
//		FlxG.camera.setSize(800, 600);
	#end
		//FlxG.fullscreen = true;
		
	}
}