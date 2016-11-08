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
		super.create();
		
		//add show cursor
	
		FlxG.switchState(new LoadState());
	}
	
}
