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
import util.CSGraphicUtil;

/**
 * @author Yarikov Denis
 */
 
class Npc extends NpcBase{
	private var _graph:FlxGraphic = FlxG.bitmap.create(1, 1, FlxColor.TRANSPARENT);
	
	private var _trail:Null<CSTrail> = null; //trail works for not animatet sprites
	
	public var show_trail(get, set):Bool;
	
	public var sprite:Null<FlxSprite> = null; //base sprite get by type
	public var weapon:Null<FlxSprite> = null; //base sprite get by weapon_id
	
	
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
		
		weapon = new FlxSprite(0, 0);
		weapon.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		add(weapon);
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
		update_sprite();
		super.update(elapsed);
	}
	
	private function setSpriteCenter(s:FlxSprite){
		s.resetSizeFromFrame();
		s.updateHitbox();
		s.x = x - s.width / 2;
		s.y = y - s.height / 2;
	}
	
	public function update_sprite(){
		//TODO: add loading animation sheets
		var path:Null<String> = null;
		if (sprite_changed){
			try{
				path = CSObjects.get(type).sprite; //path must be without file extention
			}catch (e:Dynamic){
				path = null;// "assets/images/npc/solder_base.png";
			}
	//		sprite.makeGraphic(1, 1, FlxColor.TRANSPARENT);
			if (path!=null){//if object have its own graphics
				CSGraphicUtil.loadGraficsToSprite(sprite, path, function(res:Bool, ?_sprite:FlxSprite){
					setSpriteCenter(sprite);
					//trail setup for base
					_trail.changeGraphic(sprite.graphic);
					_trail.setOrigin(sprite.origin);
				});
			}
			this.sprite_changed = false;
		}
		var names = ["weapon"];
		for (prop in names) {
			if (Reflect.getProperty(this, prop+"_id_changed")){
				try{
					path = CSObjects.get(Reflect.getProperty(this, prop+"_id")).sprite; //path must be without file extention
				}catch (e:Dynamic){
					path = "assets/images/npc/gun128";// "assets/images/npc/solder_base.png";
				}
				if (path!=null){
					CSGraphicUtil.loadGraficsToSprite(Reflect.getProperty(this, prop), path, function(res:Bool, ?sprite:FlxSprite){
						setSpriteCenter(sprite);
					});
				}else{
					Reflect.getProperty(this, prop).loadGraphic(_graph);
				}
				Reflect.setProperty(this, prop + "_id_changed", false);
			}
		}
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
