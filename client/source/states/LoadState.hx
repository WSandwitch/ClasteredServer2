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
import haxe.Timer.delay;

using flixel.util.FlxSpriteUtil;

/**
 * 
 */
class LoadState extends CSState
{

	override public function create():Void 
	{	
		var game:CSGame = cast FlxG.game;
		super.create();
		
		trace("load state");
		
		//add loading screen
		
		game.login = "qwer";
		game.pass = "qwer";
		
		try{
			(new Connection()).connect("172.16.1.40", 8000, false, function(conn:Connection){				
	//			conn.connect("localhost", 8000);
				game.connection = conn;
				delay(function(){
					if (game.id == null)
						game.connection_lost();
				}, 10000);//10 seconds for connect and sign in
				
				conn.auth(game.login, game.pass, function (i:Int){
					game.id = i;
					trace("Got id: ", game.id);
					
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
