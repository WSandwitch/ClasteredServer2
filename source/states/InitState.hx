package states;

import flixel.FlxG;

class InitState extends CSState
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
