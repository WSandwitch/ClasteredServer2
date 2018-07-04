package util;

import flixel.util.FlxSave;


/**
 * ...
 * @author ...
 */

#if flash //72 dpi
	@:build(SettingsFunction.build("screenScale", 1))
#elseif mobile
			//TODO: use in future
//@:build(SettingsFunction.build("screenScale", openfl.system.Capabilities.screenDPI/96.0));//BorderedStageSizeScaleMode(1920, 1080); //StageSizeScaleMode();// 
//		FlxG.scaleMode = new BorderedStageSizeScaleMode(1.4);//BorderedStageSizeScaleMode(1920, 1080); //StageSizeScaleMode();// 
	@:build(SettingsFunction.build("screenScale", 1))
#else
	@:build(SettingsFunction.build("screenScale", 1))
#end
@:build(SettingsFunction.build("useMouse", #if(mobile) false #else true #end ))
@:build(SettingsFunction.build("useTouch", #if(!mobile) false #else true #end ))
@:build(SettingsFunction.build("useScreenGamepad", #if(!mobile) false #else true #end ))
@:build(SettingsFunction.build("useGamepad", #if(!mobile) false #else true #end ))
@:build(SettingsFunction.build("screenWidth", 720))
@:build(SettingsFunction.build("screenHeight", 560))

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


