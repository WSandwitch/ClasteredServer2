package states;

import clasteredServerClient.Packet;
import flash.Lib;
import flash.display.BlendMode;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.system.scaleModes.*;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import openfl.Assets;
import clasteredServerClient.*;
import haxe.CallStack;
import haxe.Timer;

using flixel.util.FlxSpriteUtil;

/**
 * 
 */
class LoadState extends FlxState
{

	override public function create():Void 
	{	
		super.create();
		
		trace("load state");
		
		//add loading screen
		
		try{
			(new Connection()).connect("172.16.1.40", 11099, false, function(conn:Connection){				
//			(new Connection()).connect("192.168.1.171", 11099, false, function(conn:Connection){			
//			(new Connection()).connect("localhost", 11099, false, function(conn:Connection){				
	//			conn.connect("localhost", 8000);
				Main.connection = conn;
				Timer.delay(function(){
					if (Main.id == null)
						Main.connection_lost();
				}, 10000);//10 seconds for connect and sign in
				
				conn.auth(Main.login, Main.pass, function (i:Int){
					Main.id = i;
					trace("Got id: ", Main.id);
					
					FlxG.switchState(new PlayState());
				});
			}, function(){
				FlxG.switchState(new LoginState());
			});
		}catch(e:Dynamic){
			trace(e);
			trace(CallStack.toString(CallStack.exceptionStack()));
			//Add move to AuthState
		}
	}
	
}
