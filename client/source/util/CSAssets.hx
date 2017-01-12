package util;

import flixel.graphics.FlxGraphic;
import haxe.io.Bytes;
import haxe.zip.Reader;
import haxe.zip.Entry;
import openfl.Assets;
import flixel.FlxG;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;
#if !flash
	import sys.io.File;
	import sys.io.FileInput;
#end

class CSAssets
{
	public static function getGraphic(id:String):Null<FlxGraphic>{
		var g:Null<FlxGraphic>=FlxG.bitmap.get(id);
		if (g != null)
			return g;
//		trace("from assets");
		var bd:BitmapData = Assets.getBitmapData(id);
//		trace(bd);
		if (bd != null) //check if bd exists
			return FlxG.bitmap.add(bd, false, id);
//		trace("from disk");
	#if !flash
		try{
			var data:Bytes = File.getBytes(id);
			return FlxG.bitmap.add(BitmapData.loadFromBytes(ByteArray.fromBytes(data)), false, id);
		}catch(e:Dynamic){
//			trace("no file");
		}
//		trace("from aff");
		try{
			var path:Array<String> = id.split("/");
			var folder:String = path.shift();
			var file:String = path.join("/");
			var f:FileInput = File.read(folder+".aff");
			var entries:List<Entry> = Reader.readZip(f);
			for (entry in entries){
				if (entry.fileName == file){
					var data:Null<Bytes> = Reader.unzip(entry);
					if (data != null){
						return FlxG.bitmap.add(BitmapData.loadFromBytes(ByteArray.fromBytes(data)), false, id);
					}
				}	
			}
			f.close();
		}catch(e:Dynamic){
			
		}
	#end	
		return null;
	}
	
	public static function getBitmapData(id:String):Null<BitmapData>{
		var o:Null<FlxGraphic> = getGraphic(id);
		try{
			return o.bitmap;
		}catch(e:Dynamic){
		}
		return null;
	}

}