package util;

import flixel.graphics.FlxGraphic;
import haxe.io.Bytes;
import openfl.Assets;
import flixel.FlxG;
import openfl.display.BitmapData;
import sys.io.File;
import sys.io.FileInput;
import openfl.utils.ByteArray;
class CSAssets
{
	public static function getGraphic(id:String):Null<FlxGraphic>{
		var g:Null<FlxGraphic>=FlxG.bitmap.get(id);
		if (g != null)
			return g;
//		trace("from assets");
		var bd:BitmapData = Assets.getBitmapData(id);
		trace(bd);
		if (bd != null) //check if bd exists
			return FlxG.bitmap.add(bd, false, id);
//		trace("from disk");
	#if !flash
		try{
			var file:FileInput = File.read(id);
			var data:Bytes = file.readAll();
			return FlxG.bitmap.add(BitmapData.loadFromBytes(ByteArray.fromBytes(data)), false, id);
			file.close();
		}catch(e:Dynamic){
			trace("no file");
		}
		
	#end	
		return null;
	}
}