package;

import clasteredServerClient.Lock;
import clasteredServerClient.Packet;
import flash.geom.Point;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import openfl.Assets;
import util.CSAssets;

/**
 * @author TiagoLr ( ~~~ProG4mr~~~ )
 */
class Npc extends FlxSpriteGroup
{
	public var id:Int;
	public var type:Int = 0;
//	public var m:Lock=new Lock();
	public var dest_x:Null<Int> = 0;
	public var dest_y:Null<Int> = 0;
	public var dir_x:Null<Int> = 0;
	public var dir_y:Null<Int> = 0;
	public var updater:Map<Int, Null<Dynamic->Void>>=new Map<Int, Null<Dynamic->Void>>();
	public var sprite_updated:Bool = false;
	
	public var sprite:Null<FlxSprite> = null;
	public var shadow:Null<FlxSprite> = null;
	
	public function new (x:Float, y:Float, type:Int)
	{
		super(x, y);
		sprite = new FlxSprite(0, 0);// , "assets/npc/solder_gun128.png"); //base sprite
//		sprite.x =-sprite.width / 2;
//		sprite.y =-sprite.height / 2;
		add(sprite);
		var that = this;
		//moves = false;
		//this.field("aaa")();
        //untyped this["aaa"]();
		updater[1] = function(a:Dynamic){
			that.dest_x = a;
		};
		updater[2] = function(a:Dynamic){
			that.dest_y = a;
		};
		updater[6] = function(a:Dynamic){
			that.type = a;
			sprite_updated = true;
		};
		updater[9] = function(a:Dynamic){
			that.setAngle(Math.round(a / 120.0 * 180)); 
		};
		//antialiasing = true;
	}
	
	override public function update(elapsed:Float):Void 
	{
		if (dest_x!=null){
			x = dest_x;
			dest_x = null;
		}
		if (dest_y!=null){
			y = dest_y;
			dest_y = null;
		}
		super.update(elapsed);
		if (FlxG.camera.target != null && FlxG.camera.followLead.x == 0) // target check is used for debug purposes.
		{
			x = Math.round(x); // Smooths camera and orb shadow following. Does not work well with camera lead.
			y = Math.round(y); // Smooths camera and orb shadow following. Does not work well with camera lead.
		}
		if (shadow != null){
			shadow.x = Math.round(x);
			shadow.y = Math.round(y);
		}
	}
	
	public function update_attributes(p:Packet){
		var i:Int = 1;
		while (i < p.chanks.length){
			var index:Int = p.chanks[i++].i;
			if (updater[index]!=null){
				var value:Dynamic = null;
				switch p.chanks[i].type {
					case 1, 2, 3:
						value = p.chanks[i].i;
					case 4, 5:
						value = p.chanks[i].f;
					case 6:
						value = p.chanks[i].s;
				}
				updater[index](value);
			}
			i++;
		}
		if (sprite_updated){
			update_sprite();
			sprite_updated = false;
		}
	}
	
	public function update_sprite(){
		//TODO: add loading animation sheets
		try{
			sprite.loadGraphic(CSAssets.getGraphic(CSObjects.get(type).sprite));
		}catch(e:Dynamic){
			sprite.loadGraphic(CSAssets.getGraphic("assets/npc/solder_base.png"));
		}
//		sprite.resetSize();
		sprite.resetSizeFromFrame();
		sprite.updateHitbox();
//		sprite.x = -sprite.width / 2;
//		sprite.y = -sprite.height / 2;
		sprite.x -= sprite.width / 2;
		sprite.y -= sprite.height / 2;
	}
	
	public function setAngle(a:Int){
		forEach(function(s:FlxSprite){
			s.angle = a; 
		});
	}
	
}