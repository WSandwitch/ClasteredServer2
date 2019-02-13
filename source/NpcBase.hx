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
	
//	public var m:Lock=new Lock();
	public var dest_x:Null<Float> = 0;
	public var dest_y:Null<Float> = 0;
	public var dir_x:Null<Float> = 0;
	public var dir_y:Null<Float> = 0;
	public var updater:Map<Int, Null<Dynamic->Void>>=new Map<Int, Null<Dynamic->Void>>();
	
	public var type:Int = 0; //base id, used to get base sprite
	public var sprite_changed:Bool = false;
	
	public var weapon_id:Int = 0;
	public var weapon_id_changed:Bool = false;
	public var body_id:Int = 0;
	public var body_id_changed:Bool = false;
	
//	
	
	function new(x:Float, y:Float){
		super(x, y);
		
		updater[1] = updater_pos_x;
		updater[2] = updater_pos_y;
		updater[6] = updater_type;
		updater[8] = updater_health;
		updater[9] = updater_angle;
		updater[0] = updater_timestamp;
		updater[28] = updater_weapon_id;
		updater[33] = updater_body_id;
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
	//position.x
	function updater_pos_x(a:Dynamic){
		this.dest_x = Std.int(a*FlxG.scaleMode.scale.x)/FlxG.scaleMode.scale.x;//screan scale fix, position must be int, for normal map tiles positions
	};
	
	//position.y
	function updater_pos_y(a:Dynamic){
		this.dest_y = Std.int(a*FlxG.scaleMode.scale.y)/FlxG.scaleMode.scale.y;
	};
	
	//type
	function updater_type(a:Dynamic){
		this.type = a;
		this.sprite_changed = true;
	};
	
	//weapon_id
	function updater_weapon_id(a:Dynamic){
		this.weapon_id = a;
		this.weapon_id_changed = true;
	};
	
	//base_id
	function updater_body_id(a:Dynamic){
		this.body_id = a;
		this.body_id_changed = true;
	};
	
	//angle
	function updater_angle(a:Dynamic){
		this.angle=Math.round(a / 120.0 * 180); 
	};
	
	//health
	function updater_health(a:Dynamic){
		this.health = a;
	};
	
	//timestamp
	function updater_timestamp(a:Dynamic){
		//smth
		shown(true);
	};
	
}