package;

import clasteredServerClient.Lock;
import clasteredServerClient.Packet;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import openfl.Assets;
import util.CSAssets;
import openfl.display.BitmapData;

/**
 * @author Yarikov Denis
 */
class Npc extends NpcBase{
	
	public var sprite:Null<FlxSprite> = null;
	
	public function new(x:Float, y:Float, type:Int){
		super(x, y);
		sprite = new FlxSprite(0, 0);// , "assets/images/npc/solder_gun128.png"); //base sprite
		sprite.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		add(sprite);
		//moves = false;
		//must not update sprites in updaters
		
		//antialiasing = true;
		shown(false);
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
	
	private static function addGraficToSprite(s:FlxSprite, gr:FlxGraphic){
		var w = FlxMath.maxInt(gr.bitmap.width, s.graphic.bitmap.width);
		var h = FlxMath.maxInt(gr.bitmap.height, s.graphic.bitmap.height);
		var bm:BitmapData = new BitmapData(w, h, true, 0);
		//copy current bitmap
		bm.copyPixels(gr.bitmap, s.graphic.bitmap.rect, new Point((w - s.graphic.bitmap.width) / 2, (h - s.graphic.bitmap.height) / 2));
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
		CSAssets.getGraphic(path, function(gr:Null<FlxGraphic> ){
			addGraficToSprite(sprite, gr);//recalculate new sprite
			//add another graphics
			
//			sprite.resetSize();
			sprite.resetSizeFromFrame();
			sprite.updateHitbox();
//			sprite.x = -sprite.width / 2;
//			sprite.y = -sprite.height / 2;
			sprite.x = x - sprite.width / 2;
			sprite.y = y - sprite.height / 2;
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
}