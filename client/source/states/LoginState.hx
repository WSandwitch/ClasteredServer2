package states;

import clasteredServerClient.Packet;
import flash.Lib;
import flash.display.BlendMode;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.system.scaleModes.*;
import flixel.addons.nape.FlxNapeSpace;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import input.ScreenGamepad;
import nape.geom.Vec2;
import openfl.Assets;
import clasteredServerClient.*;
import haxe.CallStack;

using flixel.util.FlxSpriteUtil;

import flixel.input.keyboard.FlxKey;
import input.AbstractInputManager;
import input.AbstractInputManager.*;


/**
 * @author TiagoLr ( ~~~ProG4mr~~~ )
 */
 
class LoginState extends FlxState
{
	var g:ScreenGamepad;
	override public function create():Void 
	{	
		var game:CSGame = cast FlxG.game;
		super.create();
		
		trace("login state");
				
		//add show cursor
		if (game.login == null && game.pass == null)
			FlxG.switchState(new LoadState());
		else
			trace("Login error");
	}
	
	override 
	public function update(e){
		super.update(e);
	}
}
