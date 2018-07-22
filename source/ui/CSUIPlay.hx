package ui;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIText;

/**
 * ...
 * @author ...
 */
class CSUIPlay
{

	private var _ui:FlxUI;
	
	public var health:FlxUIText;
	public var npc:Null<Npc>;
	
	public function new(ui:FlxUI) 
	{
		_ui = ui;
		
		health = cast _ui.getAsset("health");
		
		health.text = ""+100;
	}
	
	public function destroy(){
		health = null;
		_ui = null;
	}
	
	public function update(elapsed:Float){
		if (npc!=null){
			if (health!=null)
				health.text = ""+npc.health;
		}
	}
	
}