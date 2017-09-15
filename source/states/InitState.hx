package states;

import flixel.FlxG;
import flixel.FlxState;

class InitState extends FlxState
{
	override public function create():Void 
	{	
		super.create();
	}
	
	override 
	public function update(e){
		super.update(e);
		FlxG.switchState(new LoginState());
	}
}
