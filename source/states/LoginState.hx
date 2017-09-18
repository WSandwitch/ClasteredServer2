package states;

import flash.Lib;
import flash.display.BlendMode;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUIInputText;
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
	var login:String="user" + Std.string(Std.random(999999999));
	
	override public function create():Void 
	{	
		_xml_id = "login";
		reload_ui_on_resize = true;
		super.create();
		
		trace("login state");

		//add show cursor
		
		return;
		////end
		
	}
	
	private function connect(l:String, pass:String){
		if (Main.login == null && Main.pass == null){
			//set login pass from fields
			Main.login = l;
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
//				trace("finish_load");
				cast(_ui.getAsset("login"), FlxUIInputText).text = login;
			case "click_button":
//				trace("click_button");
				try{
					switch (sender.name){ //object must have name
						case "connect": connect(cast(_ui.getAsset("login"),FlxUIInputText).text, "");
					}
				}catch(e:Dynamic){
					trace(e);
				}
			case "click_radio_group":
//				trace("click_radio_group");
				//actions on radiogroups
		}
	}

	override
	public function onResize(w:Int, h:Int){
		//super.onResize(w, h);
		login = cast(_ui.getAsset("login"), FlxUIInputText).text;
		reloadUI();
	}
	
	override 
	public function update(e){
		super.update(e);
	}
}
