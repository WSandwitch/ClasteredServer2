package states;

import flixel.FlxG;
import flixel.FlxState;

#if mobile
import extension.notifications.Notifications;
#end

class InitState extends FlxState
{
	override public function create():Void 
	{	
		super.create();
		trace(Main.tongue.locale);
		trace(Main.tongue.isLoaded);
		trace(Main.tongue.get("#login_button"));
	}
	
	override 
	public function update(e){
		super.update(e);
		FlxG.switchState(new LoginState());
	}
}
