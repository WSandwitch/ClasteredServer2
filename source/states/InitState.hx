package states;

import flixel.FlxG;
import flixel.FlxState;

#if mobile
import extension.notifications.Notifications;
#end

//import extension.permissions.Permissions;

class InitState extends FlxState
{
	override public function create():Void 
	{	
		super.create();
	}
	
	override 
	public function update(e){
		super.update(e);
		//trace(Permissions.checkForPermissions());
		//Permissions.askForPermissions(function(){trace("works");});
		trace("go to Login");
		FlxG.switchState(new LoginState());
	}
}
