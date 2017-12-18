package util;

import flixel.util.FlxSave;


/**
 * ...
 * @author ...
 */

@:build(SettingsFunction.build("screenWidth", 720))
@:build(SettingsFunction.build("screenHeight", 560))
@:build(SettingsFunction.build("screenScale", 1))
class Settings
{
	static private var save:FlxSave = new FlxSave();
	
	static public function init(){
		if (!save.bind("settings"))
			trace("[Settings] can't bind");
	}
	
	static public function trace(){
		trace(save.data);
	}	
}


