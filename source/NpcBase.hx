package;

import clasteredServerClient.Packet;
import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.FlxG;

/**
 * ...
 * @author 
 */
class NpcBase extends FlxSpriteGroup{
	public var id:Int;
	public var type:Int = 0;
//	public var m:Lock=new Lock();
	public var dest_x:Null<Float> = 0;
	public var dest_y:Null<Float> = 0;
	public var dir_x:Null<Float> = 0;
	public var dir_y:Null<Float> = 0;
	public var updater:Map<Int, Null<Dynamic->Void>>=new Map<Int, Null<Dynamic->Void>>();
	public var sprite_update:Bool = false;
	
	function new(x:Float, y:Float){
		super(x, y);
		
		updater[1] = updater_1;
		updater[2] = updater_2;
		updater[6] = updater_6;
		updater[9] = updater_9;
	}
	
	public function update_attributes(p:Packet){
		var i:Int = 1;
		while (i < p.chanks.length){
			var index:Int = p.chanks[i++].i;
			try{
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
			}catch(e:Dynamic){}
			i++;
		}
	}
	
	override
	private function set_angle(Value:Float):Float{
		forEach(function(s:FlxSprite){
			s.angle = Value; 
		});
		return super.set_angle(Value);
	}
	
	public function shown(b:Bool):Bool{
		visible = b;
		return b;
	}
	
	//updater functions
	function updater_1(a:Dynamic){
		this.dest_x = Std.int(a*FlxG.scaleMode.scale.x)/FlxG.scaleMode.scale.x;//screan scale fix, position must be int, for normal map tiles positions
	};
	
	function updater_2(a:Dynamic){
		this.dest_y = Std.int(a*FlxG.scaleMode.scale.y)/FlxG.scaleMode.scale.y;
	};
	
	function updater_6(a:Dynamic){
		this.type = a;
		this.sprite_update = true;
	};
	
	function updater_9(a:Dynamic){
		this.angle=Math.round(a / 120.0 * 180); 
	};
	
}