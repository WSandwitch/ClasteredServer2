package;

import clasteredServerClient.Lock;
import clasteredServerClient.Packet;
import flash.geom.Point;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.nape.FlxNapeSprite;
import openfl.Assets;

/**
 * @author TiagoLr ( ~~~ProG4mr~~~ )
 */
class Npc extends FlxSprite
{
	public var id:Int;
//	public var m:Lock=new Lock();
	public var dest_x:Null<Int> = 0;
	public var dest_y:Null<Int> = 0;
	public var dir_x:Null<Int> = 0;
	public var dir_y:Null<Int> = 0;
	public var updater:Map<Int, Null<Dynamic->Void>>=new Map<Int, Null<Dynamic->Void>>();
	
	public var shadow:Null<FlxSprite> = null;
	
	public function new (x:Float, y:Float, type:Int)
	{
		super(x, y, "assets/Orb.png");
		var that = this;
		//moves = false;
		//this.field("aaa")();
        //untyped this["aaa"]();
		updater[0] = function(a:Dynamic){that.dest_x = a;};
		updater[1] = function(a:Dynamic){that.dest_y = a;};
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
		while (i < p.chanks.length - 1){
			var index:Int = p.chanks[i++].i;
			if (updater[index]!=null){
				var value:Dynamic = null;
				switch p.chanks[i].type {
					case 1, 2, 3:
						value = p.chanks[i++].i;
					case 4, 5:
						value = p.chanks[i++].f;
					case 6:
						value = p.chanks[i++].s;
					default:
						i++;
				}
				updater[index](value);
			}
		}
	}
	
}