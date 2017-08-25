package states;

import flash.Lib;
import flash.display.BlendMode;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.system.scaleModes.*;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import input.ScreenGamepad;
import openfl.Assets;
import clasteredServerClient.*;
import haxe.CallStack;

using flixel.util.FlxSpriteUtil;

import flixel.input.keyboard.FlxKey;
import input.AbstractInputManager;
import input.AbstractInputManager.*;

import util.CSAssets;


import clasteredServerClient.MessageIds;

/**
 * @author TiagoLr ( ~~~ProG4mr~~~ )
 */
 
//class Test{}

class LoginState extends CSState
{
	override public function create():Void 
	{	
		var game:CSGame = cast FlxG.game;
		super.create();
		
		trace("login state");

		//add show cursor
		FlxG.scaleMode.onMeasure(FlxG.width, FlxG.height); 
		

		////end
		if (game.login == null && game.pass == null){
			//set login pass from fields
			game.login = "user" + Std.string(Std.random(999999999));
			game.pass = game.login; //for testing
			FlxG.switchState(new LoadState());
		}else{
			game.login = null;
			game.pass = null;
			trace("Login error");
		}
	}
	
	override 
	public function update(e){
		super.update(e);
	}
}
