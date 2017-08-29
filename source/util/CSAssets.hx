package util;

import flixel.graphics.FlxGraphic;
import haxe.io.Bytes;
import openfl.Assets;
import flixel.FlxG;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.utils.ByteArray;
import haxe.Timer.delay;
// This is what we need to retrieve the image
import openfl.display.Loader;	
// This is how we specify the location of the image	
import openfl.net.URLRequest;
import openfl.utils.SystemPath;
#if !flash
	import sys.io.File;
	import sys.io.FileInput;
#end

class CSAssets
{
	static inline var _delay:Int = 1;
	static var _host:String = "http://172.16.1.40:3000/";
	
	#if mobile
		static var _base:String = SystemPath.applicationStorageDirectory+'/'; //may be need Application.current.config.packageName
	#else
		static var _base:String = "";
	#end
	/*
	var jGetExtDir = nme.JNI.createStaticMethod('android/os/Environment', 'getExternalStorageDirectory', '()Ljava/io/File;');
	var jGetPath = nme.JNI.createMemberMethod('java/io/File', 'getAbsolutePath', '()Ljava/lang/String;');
	var jFileObj = jGetExtDir();
	var extPath : String = jGetPath(jFileObj);
	*/
	
	public static function getGraphicWeb(id:String, callback:Null<FlxGraphic>->Void){
		var loader = new Loader();
		var status:Int=0;
		loader.contentLoaderInfo.addEventListener( Event.COMPLETE, function (event:Event){
			if ( status == 200 ) {	// 200 is a successful HTTP status
				trace("loaded file "+_host+id);
				try{
					var b:Bitmap = event.target.content;
					callback(FlxG.bitmap.add(b.bitmapData, false, id));
				#if !flash
					// Saving the BitmapData 
					try{
						sys.io.File.saveBytes(_base+id, b.bitmapData.encode("png", 1));
					}catch(e:Dynamic){
						trace("can't save "+_base+id);
					}
				#end
				}catch(e:Dynamic){
					trace("web load parse error: " + e);
				}
			} else {
				callback(null);
			}
		});
		loader.contentLoaderInfo.addEventListener( HTTPStatusEvent.HTTP_STATUS, function(event:HTTPStatusEvent){
			status = event.status; // Hopefully this is 200
		});
		loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):Void {
			trace("load error " +_host+id);
			callback(null);
		});
		loader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):Void {
			trace("security error "+_host+id); 
			callback(null);
		});
		//loader.contentLoaderInfo.addEventListener( Event.OPEN, onOpen );
		//loader.contentLoaderInfo.addEventListener( ProgressEvent.PROGRESS, onProgress );
		loader.load(new URLRequest(_host+id));
	}
	
	public static function getGraphic(id:String, ?callback:Null<FlxGraphic>->Void, async:Bool = true):Null<FlxGraphic>{
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
			var data:Bytes = File.getBytes(_base+id);
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
//		trace("from web");
		if (callback != null){
			getGraphicWeb(id, callback);
		}
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
			var data:Bytes = File.getBytes(_base+id);
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
	if (callback != null){
		//TODO: add load from web
	}
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