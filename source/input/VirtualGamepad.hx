package input;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.events.JoystickEvent;
import flixel.math.FlxRandom;
import flixel.FlxG;


/**
 * virtual gamepad, that used as real one
 * worls only with FLX_JOYSTICK_API
 * 
 * @author Yarikov Denis
 */
class VirtualGamepad implements IFlxDestroyable{
	/**
	 * 	id of gamepad
	 **/
	private static var _random:FlxRandom = new FlxRandom();
	private static var _ids:Array<Int> = [];

	public var id:Int = 0;
	
	public function new(){
		id = _random.int(1, 1000, _ids);
		_ids.push(id);
	#if FLX_JOYSTICK_API
		FlxG.stage.dispatchEvent(new JoystickEvent(JoystickEvent.DEVICE_ADDED, true, false, id, 0, 0));
	#end
	}

	public function button_down(I:Int){
	#if FLX_JOYSTICK_API
		FlxG.stage.dispatchEvent(new JoystickEvent(JoystickEvent.BUTTON_DOWN, true, false, id, I));
	#end	

	}
	public function button_up(I:Int){
	#if FLX_JOYSTICK_API
		FlxG.stage.dispatchEvent(new JoystickEvent(JoystickEvent.BUTTON_UP, true, false, id, I));
	#end
	}
	
	public function axis_move(lx:Float, ly:Float, lz:Float, rx:Float, ry:Float, rz:Float){
	#if FLX_JOYSTICK_API
		var event = new JoystickEvent(JoystickEvent.AXIS_MOVE, true, false, id);//??
		event.axis = [lx,ly,lz,rx,ry,rz];
		FlxG.stage.dispatchEvent(event);
	#end
	}
	
	public function destroy():Void{
	#if FLX_JOYSTICK_API
		FlxG.stage.dispatchEvent(new JoystickEvent(JoystickEvent.DEVICE_REMOVED, true, false, id));
	#end
	}
}