package util;

import flixel.graphics.FlxGraphic;
import haxe.io.Bytes;
import openfl.Assets;
import flixel.FlxG;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.events.Event;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.URLLoader;
import openfl.utils.ByteArray;
import haxe.Timer.delay;
// This is what we need to retrieve the image
import openfl.display.Loader;	
// This is how we specify the location of the image	
import openfl.net.URLRequest;
import openfl.utils.SystemPath;
#if !flash
	import sys.FileSystem;
	import sys.io.File;
	import sys.io.FileInput;
#end

class CSAssets
{
	static inline var _delay:Int = 2; //used for async call
	static var _host:String = "http://disk.wsstudio.tk/";
	
	static var unsuccess:Map<String, Int> = new Map<String, Int>();
	static inline var _tries:Int = 4;
	
#if mobile
	static var _base:String = SystemPath.applicationStorageDirectory+'/'; 
#else
	#if debug
		static var _base:String = "ext/";
	#else
		#if windows
			static var _base:String = "downloaded/";// SystemPath.applicationStorageDirectory + '/';
		#else
			static var _base:String = SystemPath.applicationStorageDirectory+'/';//may be use SystemPath.documentsDirectory+'/'+Application.current.config.packageName+'/'
	#end
	#end
#end
	/*
	var jGetExtDir = nme.JNI.createStaticMethod('android/os/Environment', 'getExternalStorageDirectory', '()Ljava/io/File;');
	var jGetPath = nme.JNI.createMemberMethod('java/io/File', 'getAbsolutePath', '()Ljava/lang/String;');
	var jFileObj = jGetExtDir();
	var extPath : String = jGetPath(jFileObj);
	*/

	private static function setBroken(id:String){
		if (unsuccess[id] == null )
			unsuccess[id] = 0;
		unsuccess[id]++;	
	}
	
	public static function getGraphicWeb(id:String, callback:Null<FlxGraphic>->Void){
		var loader = new Loader();
		var status:Int=0;
		loader.contentLoaderInfo.addEventListener( Event.COMPLETE, function (event:Event){
			if ( status == 200 ) {	// 200 is a successful HTTP status
				trace("[CSAssets] loaded from web "+id);
				try{
					var b:Bitmap = event.target.content;
					callback(FlxG.bitmap.add(b.bitmapData, false, id));
				#if !flash
					// Saving the BitmapData 
					try{
						try{
							var r = (~/.+\//);
							r.match(_base+id);
							sys.FileSystem.createDirectory(r.matched(0));
						}catch (e:Dynamic){
							trace("[CSAssets] "+e);
						}
					#if legacy
						sys.io.File.saveBytes(_base+id, b.bitmapData.encode("png", 1));
					#else
						sys.io.File.saveBytes(_base+id, b.bitmapData.encode(b.bitmapData.rect, new PNGEncoderOptions ()));
					#end
					}catch(e:Dynamic){
						trace("[CSAssets] can't save "+_base+id+": "+e);
					}
				#end
				}catch(e:Dynamic){
					trace("[CSAssets] web load parse error: " + e);
				}
			} else {
				setBroken(id);
				callback(null);
			}
		});
		loader.contentLoaderInfo.addEventListener( HTTPStatusEvent.HTTP_STATUS, function(event:HTTPStatusEvent){
			status = event.status; // Hopefully this is 200
		});
		loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):Void {
			trace("[CSAssets] load error "+_host+id);
			setBroken(id);
			callback(null);
		});
		loader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):Void {
			trace("[CSAssets] security error "+_host+id);
			setBroken(id);
			callback(null);
		});
		//loader.contentLoaderInfo.addEventListener( Event.OPEN, onOpen );
		//loader.contentLoaderInfo.addEventListener( ProgressEvent.PROGRESS, onProgress );
		try{
			loader.load(new URLRequest(_host + id));
		}catch (e:Dynamic){
			trace("[CSAssets] load start error "+_host+id); 
			setBroken(id);
			callback(null);
		}
	}
	
	public static function getGraphic(id:String, ?callback:Null<FlxGraphic>->Void, async:Bool = true):Null<FlxGraphic>{
		if (unsuccess[id]>_tries){
			if (callback != null){
				if (async){
					delay(callback.bind(null), _delay);
				}else{
					callback(null);
				}
			}
			return null;
		}
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
		var bd:BitmapData = Assets.getBitmapData(id);
//		trace("[CSAssets] "+bd);
		if (bd != null){ //check if bd exists
			g = FlxG.bitmap.add(bd, false, id);
		#if debug
//			trace("[CSAssets] loaded from assets "+id);
		#end
			if (callback != null){
				if (async){
					delay(callback.bind(g), _delay);
				}else{
					callback(g);
				}
			}
			return g;
		}
	#if !flash
		try{
			var data:Bytes = File.getBytes(_base+id);
		#if openfl_legacy
			g = FlxG.bitmap.add(BitmapData.loadFromBytes(ByteArray.fromBytes(data)), false, id);
		#else
			g = FlxG.bitmap.add(BitmapData.fromBytes(ByteArray.fromBytes(data)), false, id);
		#end
		#if debug
			trace("[CSAssets] loaded from disk "+id);
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
//			trace("[CSAssets] no file");
		}
	#end	
//		trace("[CSAssets] from web");
		if (callback != null && async){
			getGraphicWeb(id, callback);
		}
		return null;
	}
	
	public static function getBitmapData(id:String, ?callback:Null<BitmapData>->Void, async:Bool=true):Null<BitmapData>{
		if (callback != null){
			getGraphic(id, function(g:Null<FlxGraphic>){
				try{//catch null pointer
					callback(g.bitmap); 
				}catch(e:Dynamic){
					callback(null); 
				}
			}, async);
		}else{
			try{
				return  getGraphic(id).bitmap;
			}catch (e:Dynamic){}
		}
		return null;
	}
	
	public static function getBytesWeb(id:String, callback:Null<Bytes>->Void){
		var loader:URLLoader = new URLLoader();
		var status:Int = 0;
		loader.addEventListener( HTTPStatusEvent.HTTP_STATUS, function(event:HTTPStatusEvent){
			status = event.status; // Hopefully this is 200
		});
		loader.addEventListener( IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):Void {
			trace("[CSAssets] load error " +_host+id);
			setBroken(id);
			callback(null);
		});
		loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):Void {
			trace("[CSAssets] security error "+_host+id); 
			setBroken(id);
			callback(null);
		});
		loader.addEventListener(Event.COMPLETE, function(event:Event){
			if ( status == 200 ) {
				try{
					var bytes:Bytes = Bytes.ofString(event.target.data);
				#if !flash
					// Saving got Bytes
					try{
						try{
							var r = (~/.+\//);
							r.match(_base+id);
							sys.FileSystem.createDirectory(r.matched(0));
						}catch (e:Dynamic){
							trace("[CSAssets] "+e);
						}
						sys.io.File.saveBytes(_base+id, bytes);
					}catch(e:Dynamic){
						trace("[CSAssets] can't save "+_base+id+": "+e);
					}
				#end
					callback(bytes);//may be need to convert from string to bytes
				}catch(e:Dynamic){
					trace("[CSAssets] "+e);
				}
			} else {
				setBroken(id);
				callback(null);
			}
		});
		try{
			loader.load(new URLRequest(_host+id));
		}catch (e:Dynamic){
			trace("[CSAssets] load start error "+_host+id); 
			setBroken(id);
			callback(null);
		}
	}
	
	public static function getBytes(id:String, ?callback:Null<Bytes>->Void, async:Bool = true):Null<Bytes>{
		if (unsuccess[id]>_tries){
			if (callback != null){
				if (async){
					delay(callback.bind(null), _delay);
				}else{
					callback(null);
				}
			}
			return null;
		}
		var bd:Null<Bytes> = null;
		try{
			bd = Assets.getBytes(id);
		}catch(e:Dynamic){}
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
	#if !flash
		try{
			var data:Bytes = File.getBytes(_base+id);
		#if debug
			trace("[CSAssets] loaded from disk");
		#end
			if (callback != null){
				if (async){
					delay(callback.bind(data), _delay);
				}else{
					callback(data);
				}
			}
			return data;
		}catch(e:Dynamic){
//			trace("[CSAssets] no file");
		}
	#end	
		if (callback != null){
			//TODO: add load from web
			getBytesWeb(id, callback);
		}
		return null;
	}
	
	public static function getText(id:String, ?callback:Null<String>->Void, async:Bool=true):Null<String>{
		if (callback!=null){
			getBytes(id, function (b:Null<Bytes>){
				try{
					callback(b.toString());
				}catch(e:Dynamic){
					callback(null);
				}
			}, async);
		}else{
			try{
				return getBytes(id).toString();
			}catch(e:Dynamic){
				//trace("[CSAssets] no file");
			}
		}
		return null;
	}
	
}