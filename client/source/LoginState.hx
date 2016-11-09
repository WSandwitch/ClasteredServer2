package;

import clasteredServerClient.Packet;
import flash.Lib;
import flash.display.BlendMode;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.system.scaleModes.*;
import flixel.addons.nape.FlxNapeSpace;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import nape.geom.Vec2;
import openfl.Assets;
import clasteredServerClient.*;
import haxe.CallStack;

using flixel.util.FlxSpriteUtil;

/**
 * @author TiagoLr ( ~~~ProG4mr~~~ )
 */
class LoginState extends FlxState
{

	override public function create():Void 
	{	
		var game:CSGame = cast FlxG.game;
		super.create();
		
		trace("login state");
		
		var pass = "hello";
		var salt=haxe.crypto.Base64.encode(haxe.crypto.Md5.make(haxe.io.Bytes.ofString("hello")));
		trace(haxe.crypto.Base64.encode(haxe.crypto.Md5.make(haxe.io.Bytes.ofString(haxe.crypto.Base64.decode(salt).toString() + haxe.crypto.Md5.make(haxe.io.Bytes.ofString(pass)).toString()))));
		
		
		//add show cursor
		if (game.login == null && game.pass == null)
			FlxG.switchState(new LoadState());
		else
			trace("Login error");
	}
	
}
