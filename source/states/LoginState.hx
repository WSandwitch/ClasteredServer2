package states;

import flash.Lib;
import flash.display.BlendMode;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.addons.ui.FlxUIState;
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
 * 
 */
 
//class Test{}

class LoginState extends FlxUIState
{
	override public function create():Void 
	{	
		_xml_id = "login";
		
		super.create();
		
		trace("login state");

		//add show cursor
		FlxG.scaleMode.onMeasure(FlxG.width, FlxG.height); 
		

		////end
		if (Main.login == null && Main.pass == null){
			//set login pass from fields
			Main.login = "user" + Std.string(Std.random(999999999));
			Main.pass = Main.login; //for testing
			FlxG.switchState(new LoadState());
		}else{
			Main.login = null;
			Main.pass = null;
			trace("Login error");
		}
	}
	
	override
	public function getEvent(name:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>):Void
	{
		switch (name)
		{
			case "finish_load":
				trace("save");
				//do something after loading
			case "click_button":
				if (params != null && params.length > 0){
					switch (Std.string(params[0])){ //get first param, must be button name, or may be get it from sender?
						case "saves": trace("save");
					}
				}
			case "click_radio_group":
				trace("save");
				//actions on radiogroups
		}
	}
	
	override 
	public function update(e){
		super.update(e);
	}
}
