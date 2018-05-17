package;

import clasteredServerClient.Lock;
import clasteredServerClient.Packet;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.graphics.FlxGraphic;
import flixel.addons.effects.FlxTrail;
import flixel.group.FlxSpriteGroup;
import openfl.Assets;
import util.CSAssets;
import openfl.display.BitmapData;

/**
 * @author Yarikov Denis
 */
 
class Npc extends NpcBase{
	
	public var sprite:Null<FlxSprite> = null;
	private var _trail:Null<CSTrail> = null;
	
	public var show_trail(get, set):Bool;
	
	public function new(x:Float, y:Float, type:Int){
		super(x, y);
		shown(false);
		sprite = new FlxSprite(0, 0);// , "assets/images/npc/solder_gun128.png"); //base sprite
		sprite.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		add(sprite);
		//moves = false;
		//must not update sprites in updaters
		
		//antialiasing = true;
		_trail = new CSTrail(sprite, null, 6, 1, 0.6, 0.1);
		add(_trail);
		show_trail = false;
	}
	
	override 
	public function update(elapsed:Float):Void{
		if (dest_x!=null){
			x = dest_x;
			dest_x = null;
		}
		if (dest_y!=null){
			y = dest_y;
			dest_y = null;
		}
		if (sprite_update){
			update_sprite();
			sprite_update = false;
		}
		super.update(elapsed);
	}
	
	private static function addGraficToSprite(s:FlxSprite, gr:Null<FlxGraphic>){
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
	
	public function update_sprite(){
		//TODO: add loading animation sheets
		var path:String;
		try{
			path = CSObjects.get(type).sprite;
		}catch (e:Dynamic){
			path = "assets/images/npc/solder_base.png";
		}
		sprite.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		CSAssets.getGraphic(path, function(gr:Null<FlxGraphic>){
			addGraficToSprite(sprite, gr);//recalculate new sprite
			//add another graphics
			
//			sprite.resetSize();
			sprite.resetSizeFromFrame();
			sprite.updateHitbox();
//			sprite.x = -sprite.width / 2;
//			sprite.y = -sprite.height / 2;
			sprite.offset.x = sprite.width / 2;
			sprite.offset.y = sprite.height / 2;
			_trail.changeGraphic(sprite.graphic);
			_trail.setOrigin(sprite.origin);
			shown(true);
		});
	}
/*	
	override
	private function set_exists(Value:Bool):Bool{
		super.set_exists(Value);
		sprite.exists = Value;
		return Value;
	}
*/	
/*	override 
	public function destroy(){
		remove(sprite);
		sprite.destroy();
		super.destroy();
	}
*/
	public function get_show_trail():Bool{
		return _trail.exists;
	}
	
	public function set_show_trail(v:Bool):Bool{
		return (_trail.exists = v);
	}
}

class CSTrail extends FlxTrail{
	public function new(Target:FlxSprite, ?Graphic:FlxGraphicAsset, Length:Int = 10, Delay:Int = 3, 
		Alpha:Float = 0.4, Diff:Float = 0.05):Void{
		super(Target, Graphic, Length, Delay, Alpha, Diff);
	}
	
	public function setOrigin(target:FlxPoint){
		_spriteOrigin.copyFrom(target);
	}
	
	public function getOrigin():FlxPoint{
		return _spriteOrigin;
	}
}
