package util;
import flash.display.BitmapData;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import openfl.geom.Point;
import yaml.Yaml;
import yaml.Parser;
/**
 * ...
 * @author ...
 */

class CSGraphicUtil{
	
	public static function addGraficToSprite(s:FlxSprite, gr:Null<FlxGraphic>){
		if (gr == null)
			return;
		var w = FlxMath.maxInt(gr.bitmap.width, s.graphic.bitmap.width);
		var h = FlxMath.maxInt(gr.bitmap.height, s.graphic.bitmap.height);
		var bm:BitmapData = new BitmapData(w, h, true, 0);
		//copy current bitmap
		bm.copyPixels(s.graphic.bitmap, s.graphic.bitmap.rect, new Point((w - s.graphic.bitmap.width) / 2, (h - s.graphic.bitmap.height) / 2));
		//add new bitmap
		bm.copyPixels(gr.bitmap, gr.bitmap.rect, new Point((w - gr.bitmap.width) / 2, (h - gr.bitmap.height) / 2));
		s.loadGraphic(bm); //maybe false, "id")
	}
	
	public static function loadGraficsToSprite(s:FlxSprite, path:String, ?callback:Bool->?FlxSprite->Void, call_in_the_middle=true){
		//try to open path+".yml"
		/*
		 * grafic conf format [{name: "a", frames:[1,2], rate:30}]
		*/
		CSAssets.getGraphic(path+".png", function(gr:Null<FlxGraphic>){
			if (gr != null){
				//now check if there animation
				var gsize = FlxMath.minInt(gr.bitmap.height, gr.bitmap.width);
				s.loadGraphic(gr, true, gsize, gsize);//frame width must be equal to height //TODO: update
				if (call_in_the_middle && callback != null)
					callback(false, s);
				CSAssets.getText(path+".yml", function(data:Null<String>){
					try{	
						var raw:Array<Dynamic> = cast Yaml.parse(data, Parser.options().useObjects()); //animation grafics conf file						
						for (o in raw){
							s.animation.add(o.name, o.frames, o.rate);
						}
					}catch(e:Dynamic){}
					if (callback != null)
						callback(true, s);
				});
			}else{
				if (callback != null)
					callback(false);
			}
		});
	}
}