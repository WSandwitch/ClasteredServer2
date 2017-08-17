package util;

import flixel.graphics.FlxGraphic;
import haxe.io.Bytes;
import openfl.Assets;
import flixel.FlxG;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import haxe.Timer.delay;
#if !flash
	import sys.io.File;
	import sys.io.FileInput;
#end

class CSAssets
{
	static inline var _delay:Int = 1;
	
	public static function getGraphic(id:String, ?callback:Null<FlxGraphic>->Void, async:Bool=true):Null<FlxGraphic>{
		var g:Null<FlxGraphic>=FlxG.bitmap.get(id);
		if (g != null){
			if (callback != null){
				if (async){
					delay(callback.bind(g), _delay);
				}else{
					callback(g);
				}
			}
			return g;
		}
//		trace("from assets");
		var bd:BitmapData = Assets.getBitmapData(id);
//		trace(bd);
		if (bd != null){ //check if bd exists
			g = FlxG.bitmap.add(bd, false, id);
			if (callback != null){
				if (async){
					delay(callback.bind(g), _delay);
				}else{
					callback(g);
				}
			}
			return g;
		}
//		trace("from disk");
	#if !flash
		try{
			var data:Bytes = File.getBytes(id);
		#if openfl_legacy
			g = FlxG.bitmap.add(BitmapData.loadFromBytes(ByteArray.fromBytes(data)), false, id);
		#else
			g = FlxG.bitmap.add(BitmapData.fromBytes(ByteArray.fromBytes(data)), false, id);
		#end
			if (callback != null){
				if (async){
					delay(callback.bind(g), _delay);
				}else{
					callback(g);
				}
			}
			return g;
		}catch(e:Dynamic){
//			trace("no file");
		}
	#end	
		//TODO: add load from web
		
		return null;
	}
	
	public static function getBitmapData(id:String, ?callback:Null<BitmapData>->Void, async:Bool=true):Null<BitmapData>{
		var o:Null<FlxGraphic> = getGraphic(id, function(g:Null<FlxGraphic>){
			try{//catch null pointer
				callback(g.bitmap); 
			}catch(e:Dynamic){}
		}, async);
		try{
			return o.bitmap;
		}catch(e:Dynamic){}
		return null;
	}
	
	public static function getBytes(id:String, ?callback:Null<Bytes>->Void, async:Bool=true):Null<Bytes>{
		var bd:Null<Bytes> = Assets.getBytes(id);
		if (bd != null){ //check if bd exists
			if (callback != null){
				if (async){
					delay(callback.bind(bd), _delay);
				}else{
					callback(bd);
				}
			}
			return bd;
		}
//		trace("from disk");
	#if !flash
		try{
			var data:Bytes = File.getBytes(id);
			if (callback != null){
				if (async){
					delay(callback.bind(data), _delay);
				}else{
					callback(data);
				}
			}
			return data;
		}catch(e:Dynamic){
//			trace("no file");
		}
	#end	
		//TODO: add load from web
		return null;
	}
	
	public static function getText(id:String, ?callback:Null<String>->Void, async:Bool=true):Null<String>{
		var s=getBytes(id, function (b:Null<Bytes>){
			try{
				callback(b.toString());
			}catch(e:Dynamic){}
		}, async);
		try{
			return s.toString();
		}catch(e:Dynamic){
			//trace("no file");
		}
		return null;
	}
	
}