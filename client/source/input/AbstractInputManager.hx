package input;

import flash.display.InteractiveObject;
import flixel.input.gamepad.FlxGamepad;
import haxe.ds.EnumValueMap;

import flixel.FlxG;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

import flixel.system.macros.FlxMacroUtil;

/**
 * abstract input allow you to set custom input ids 
 * and bind it to buttons of keybard, mouse, gamepad 
 * and gamepad axis (positiv and negativ directions)
 * @author Yarikov Denis
 */

 typedef KeyType = String;
 
class AbstractInputManager{
	
	public var ids:Array<AbstractInputID> = [];
	public var actions:Map<KeyType, Null<AbstractInputAction>> = new Map<KeyType, AbstractInputAction>();
	
	public var key_ids:Map<FlxKey, AbstractInputKeyboardID> = new Map<FlxKey, AbstractInputKeyboardID>();
	public var mouse_ids:Map<MouseID, AbstractInputMouseID> = new Map<MouseID, AbstractInputMouseID>();
	public var gamepad_key_ids:Map<FlxGamepadInputID, AbstractInputGamepadKeyID> = new Map<FlxGamepadInputID, AbstractInputGamepadKeyID>();
	public var gamepad_axis_ids:Map<GamepadAxisID, AbstractInputGamepadAxisID> = new Map<GamepadAxisID, AbstractInputGamepadAxisID>();

	public function new(){
		
	}
	
	public function addAction(name:KeyType):AbstractInputAction{
		if (!actions.exists(name))
			actions[name] = new AbstractInputAction(this, name);
		return actions[name];
	}
	
	public function getAction(name:KeyType):Null<AbstractInputAction>{
		if (!actions.exists(name))
			return null;
		return actions[name];
	}
	
	public function removeAction(name:KeyType):Bool{
		if (!actions.exists(name))
			return false;
		for (id in ids)
			id.actions.remove(name);
		return actions.remove(name);
	}
	
	public function value(name:KeyType):Float{
		if (!actions.exists(name))
			return 0;
		return actions.get(name).value;
	}
	
	public function justPressed(name:KeyType):Bool{
		if (!actions.exists(name))
			return false;
		return actions.get(name).justPressed;
	}
	
	public function justReleased(name:KeyType):Bool{
		if (!actions.exists(name))
			return false;
		return actions.get(name).justReleased;
	}
	
	public function pressed(name:KeyType):Bool{
		if (!actions.exists(name))
			return false;
		return actions.get(name).pressed;
	}
	
	public function update(){
		for(action in actions){
			action.justPressed = false;
			action.justReleased = false;
			action.pressed = false;
			action.value = 0;
		}
		for (id in ids){
			id.update();
		}
	}
	
	public function removeSource(id:AbstractInputID){
		switch(id.type){
			case KEY:
				var cid:AbstractInputKeyboardID = cast id;
				key_ids.remove(cid.key);
				ids.remove(id);
			case MOUSE:
				var cid:AbstractInputMouseID = cast id;
				mouse_ids.remove(cid.key);
				ids.remove(id);
			case GAMEPADKEY:
				var cid:AbstractInputGamepadKeyID = cast id;
				gamepad_key_ids.remove(cid.key);
				ids.remove(id);
			case GAMEPADAXIS:
				var cid:AbstractInputGamepadAxisID = cast id;
				gamepad_axis_ids.remove(cid.key);
				ids.remove(id);
		}
	}
	
	public function getSources(name:KeyType):Array<AbstractInputID>{
		var a:Array<AbstractInputID> = [];
		for (s in ids){
			if (s.actions.indexOf(name) >= 0)
			 a.push(s);
		}
		return a;
	}
}

class AbstractInputAction{
	
	public var manager:AbstractInputManager;
	
	public var name:KeyType;
	public var justPressed:Bool;
	public var justReleased:Bool;
	public var pressed:Bool;
	public var value:Float;
	
	
	public function new(manager:AbstractInputManager, name:KeyType){
		this.manager = manager;
		this.name = name;
	}
	
	public function addKey(key:FlxKey){
		if (!manager.key_ids.exists(key)){
			manager.ids.push(manager.key_ids[key] = new AbstractInputKeyboardID(manager, key));
		}
		manager.key_ids[key].addAction(name);
	}

	public function removeKey(key:FlxKey){
		if (manager.key_ids.exists(key)){
			var key_id = manager.key_ids[key];
			key_id.removeAction(name);
			if (key_id.actions.length == 0)
				manager.ids.remove(key_id);
		}
	}
	
	public function addMouseKey(key:MouseID){
		if (!manager.mouse_ids.exists(key)){
			var action = new AbstractInputMouseID(manager, key);
			manager.mouse_ids.set(key, action);
			manager.ids.push(action);
		}
		manager.mouse_ids.get(key).addAction(name);
	}
	
	public function removeMouseKey(key:MouseID){
		if (manager.mouse_ids.exists(key)){
			var key_id = manager.mouse_ids.get(key);
			key_id.removeAction(name);
			if (key_id.actions.length == 0)
				manager.ids.remove(key_id);
		}
	}
	
	public function addGamepadKey(key:FlxGamepadInputID, ?id:Int){
		if (!manager.gamepad_key_ids.exists(key)){
			var action = new AbstractInputGamepadKeyID(manager, key, id);
			manager.gamepad_key_ids.set(key, action);
			manager.ids.push(action);
		}
		manager.gamepad_key_ids.get(key).addAction(name);
	}
	
	public function removeGamepadKey(key:FlxGamepadInputID){
		if (manager.gamepad_key_ids.exists(key)){
			var key_id = manager.gamepad_key_ids.get(key);
			key_id.removeAction(name);
			if (key_id.actions.length == 0)
				manager.ids.remove(key_id);
		}
	}
	
	public function addGamepadAxis(key:GamepadAxisID, ?id:Int){
		if (!manager.gamepad_axis_ids.exists(key)){
			var action = new AbstractInputGamepadAxisID(manager, key, id);
			manager.gamepad_axis_ids.set(key, action);
			manager.ids.push(action);
		}
		manager.gamepad_axis_ids.get(key).addAction(name);
	}
	
	public function removeGamepadAxis(key:GamepadAxisID){
		if (manager.gamepad_axis_ids.exists(key)){
			var key_id = manager.gamepad_axis_ids.get(key);
			key_id.removeAction(name);
			if (key_id.actions.length == 0)
				manager.ids.remove(key_id);
		}
	}
	
}

class AbstractInputGamepadAxisID extends AbstractInputID{

	public var key:GamepadAxisID;
	public var gamepad_id:Null<Int> = null;
	private var _value:Float = 0;
	
	
	public function new(manager:AbstractInputManager, key:GamepadAxisID, ?id){
		super(manager);
		this.key = key;
		this.gamepad_id = id;
		this.type = GAMEPADAXIS;
	}
		
	override
	public function update(){
		for (name in actions){
			var action = manager.actions[name];
			if (gamepad_id==null){
				var gamepads = FlxG.gamepads.getActiveGamepads();
				for (gamepad in gamepads){
					proceedGamepad(gamepad, action);
				}
			}else{
				var gamepad = FlxG.gamepads.getByID(gamepad_id);
				if (gamepad != null){ 
					proceedGamepad(gamepad, action);
				}
			}
		}
	}	

	private function proceedGamepad(gamepad:FlxGamepad, action:AbstractInputAction){
		switch(key){
			case LEFT_STICK_X_PLUS:
				var value = gamepad.getXAxis(FlxGamepadInputID.LEFT_ANALOG_STICK);
				if (value > 0 && value > action.value){
					action.pressed = true;
					action.value = value;
				}
			case LEFT_STICK_X_MINUS:
				var value = gamepad.getXAxis(FlxGamepadInputID.LEFT_ANALOG_STICK);
				if (value < 0 && -value > action.value){
					action.pressed = true;
					action.value = -value;
				}
			case LEFT_STICK_Y_PLUS:
				var value = gamepad.getYAxis(FlxGamepadInputID.LEFT_ANALOG_STICK);
				if (value > 0 && value > action.value){
					action.pressed = true;
					action.value = value;
				}
			case LEFT_STICK_Y_MINUS:
				var value = gamepad.getYAxis(FlxGamepadInputID.LEFT_ANALOG_STICK);
				if (value < 0 && -value > action.value){
					action.pressed = true;
					action.value = -value;
				}
			case RIGHT_STICK_X_PLUS:
				var value = gamepad.getXAxis(FlxGamepadInputID.RIGHT_ANALOG_STICK);
				if (value > 0 && value > action.value){
					action.pressed = true;
					action.value = value;
				}
			case RIGHT_STICK_X_MINUS:
				var value = gamepad.getXAxis(FlxGamepadInputID.RIGHT_ANALOG_STICK);
				if (value < 0 && -value > action.value){
					action.pressed = true;
					action.value = -value;
				}
			case RIGHT_STICK_Y_PLUS:
				var value = gamepad.getYAxis(FlxGamepadInputID.RIGHT_ANALOG_STICK);
				if (value > 0 && value > action.value){
					action.pressed = true;
					action.value = value;
				}
			case RIGHT_STICK_Y_MINUS:
				var value = gamepad.getYAxis(FlxGamepadInputID.RIGHT_ANALOG_STICK);
				if (value < 0 && -value > action.value){
					action.pressed = true;
					action.value = -value;
				}
			case LEFT_TRIGGER_PLUS:
				
				var value = gamepad.getAxis(FlxGamepadInputID.LEFT_TRIGGER);
				if (value > 0 && value > action.value){
					action.pressed = true;
					action.value = value;
				}
			case LEFT_TRIGGER_MINUS:
				var value = gamepad.getAxis(FlxGamepadInputID.LEFT_TRIGGER);
				if (value < 0 && -value > action.value){
					action.pressed = true;
					action.value = -value;
				}
			case RIGHT_TRIGGER_PLUS:
				var value = gamepad.getAxis(FlxGamepadInputID.RIGHT_TRIGGER);
				if (value > 0 && value > action.value){
					action.pressed = true;
					action.value = value;
				}
			case RIGHT_TRIGGER_MINUS:
				var value = gamepad.getAxis(FlxGamepadInputID.RIGHT_TRIGGER);
				if (value < 0 && -value > action.value){
					action.pressed = true;
					action.value = -value;
				}
			case POINTER_X_PLUS:
				var value = gamepad.getAxis(FlxGamepadInputID.POINTER_X);
				if (value > 0 && value > action.value){
					action.pressed = true;
					action.value = value;
				}
			case POINTER_X_MINUS:
				var value = gamepad.getAxis(FlxGamepadInputID.POINTER_X);
				if (value < 0 && -value > action.value){
					action.pressed = true;
					action.value = -value;
				}
			case POINTER_Y_PLUS:
				var value = gamepad.getAxis(FlxGamepadInputID.POINTER_Y);
				if (value > 0 && value > action.value){
					action.pressed = true;
					action.value = value;
				}
			case POINTER_Y_MINUS:
				var value = gamepad.getAxis(FlxGamepadInputID.POINTER_Y);
				if (value < 0 && -value > action.value){
					action.pressed = true;
					action.value = -value;
				}
			case NONE:
		}
		if (_value != action.value){
			if (action.value == 0){
				action.justReleased = true;
			}
			action.justPressed = true; //value has been changed
			_value = action.value;
		}
	}
	
	override
	public function toString():String{
		return key.toString();
	}

}



class AbstractInputGamepadKeyID extends AbstractInputID{
	
	public var key:FlxGamepadInputID;
	public var gamepad_id:Null<Int> = null;

	public function new(manager:AbstractInputManager, key:FlxGamepadInputID, ?id:Int){
		super(manager);
		this.key = key;
		this.gamepad_id = id;
		this.type = GAMEPADKEY;
	}
	
	override
	public function update(){
		for (name in actions){
			var action = manager.actions[name];
			if (gamepad_id==null){
				action.justPressed = action.justPressed || FlxG.gamepads.anyJustPressed(key);
				action.justReleased = action.justReleased || FlxG.gamepads.anyJustReleased(key);
				action.pressed = action.pressed || FlxG.gamepads.anyPressed(key);
			}else{
				var gamepad = FlxG.gamepads.getByID(gamepad_id);
				if (gamepad != null){
					action.justPressed = action.justPressed || gamepad.anyJustPressed([key]);
					action.justReleased = action.justReleased || gamepad.anyJustReleased([key]);
					action.pressed = action.pressed || gamepad.anyPressed([key]);
				}
			}
			if (action.justPressed || action.pressed)
				action.value = 1;
		}
	}
	
	override
	public function toString():String{
		return "GAMEPAD_"+key.toString();
	}

}

class AbstractInputMouseID extends AbstractInputID{
	
	public var key:MouseID;
	
	public function new(manager:AbstractInputManager, key:MouseID){
		super(manager);
		this.key = key;
		this.type = MOUSE;
	}
	
	override
	public function update(){
		for (name in actions){
			var action = manager.actions[name];
			switch(key){
				case MOUSE_LEFT:
					action.justPressed = action.justPressed || FlxG.mouse.justPressed;
					action.justReleased = action.justReleased || FlxG.mouse.justReleased;
					action.pressed = action.pressed || FlxG.mouse.pressed;
				case MOUSE_RIGHT:
					action.justPressed = action.justPressed || FlxG.mouse.justPressedRight;
					action.justReleased = action.justReleased || FlxG.mouse.justReleasedRight;
					action.pressed = action.pressed || FlxG.mouse.pressedRight;
				case MOUSE_MIDDLE:
					action.justPressed = action.justPressed || FlxG.mouse.justPressedMiddle;
					action.justReleased = action.justReleased || FlxG.mouse.justReleasedMiddle;
					action.pressed = action.pressed || FlxG.mouse.pressedMiddle;
				case MOUSE_WEEL_UP: 
					if (FlxG.mouse.wheel > 0 && FlxG.mouse.wheel > action.value){
						action.justPressed = true;
						action.value = FlxG.mouse.wheel;
					}
				case MOUSE_WEEL_DOWN: 
					if (FlxG.mouse.wheel < 0 && -FlxG.mouse.wheel > action.value){
						action.justPressed = true;
						action.value = -FlxG.mouse.wheel;
					}
				case NONE:
			}
			if (action.justPressed || action.pressed)
				action.value = 1;
		}
	} 

	override
	public function toString():String{
		return key.toString();
	}

}

class AbstractInputKeyboardID extends AbstractInputID{

	public var key:FlxKey;
	
	public function new(manager:AbstractInputManager, key:FlxKey){
		super(manager);
		this.key = key;
		this.type = KEY;
	}
	
	override
	public function update(){
		for (name in actions){
			var action = manager.actions[name];
			action.justPressed = action.justPressed || FlxG.keys.anyJustPressed([key]);
			action.justReleased = action.justReleased || FlxG.keys.anyJustReleased([key]);
			action.pressed = action.pressed || FlxG.keys.anyPressed([key]);
			if (action.justPressed || action.pressed)
				action.value = 1;
		}
	}
	
	override
	public function toString():String{
		return key.toString();
	}

}

class AbstractInputID{
	
	public var type:AbstractSource;
	
	public var actions:Array<KeyType>=[];
	public var manager:AbstractInputManager;

	public function new(manager:AbstractInputManager){
		this.manager = manager;
	}
	
	public function update(){
		trace("base update");
	}
	
	public function addAction(name:KeyType){
		if (actions.indexOf(name) < 0){
			if (actions.length > 0)
				actions[0] = name;
			else
				actions.push(name);
		}
	}

	public function removeAction(name:KeyType):Bool{
		return actions.remove(name);
	}
	
	public function toString():String{
		return "";
	}

}

@:enum
abstract GamepadAxisID(Int) from Int to Int{
	public static var fromStringMap(default, null):Map<String, GamepadAxisID>
		= FlxMacroUtil.buildMap("input.AbstractInputManager.GamepadAxisID");
		
	public static var toStringMap(default, null):Map<GamepadAxisID, String>
		= FlxMacroUtil.buildMap("input.AbstractInputManager.GamepadAxisID", true);
		
	var NONE = -1;
	var LEFT_STICK_X_PLUS = 0;
	var LEFT_STICK_X_MINUS = 1;
	var LEFT_STICK_Y_PLUS = 2;
	var LEFT_STICK_Y_MINUS = 3;
	var LEFT_TRIGGER_PLUS = 4;
	var LEFT_TRIGGER_MINUS = 5;
	var RIGHT_STICK_X_PLUS = 6;
	var RIGHT_STICK_X_MINUS = 7;
	var RIGHT_STICK_Y_PLUS = 8;
	var RIGHT_STICK_Y_MINUS = 9;
	var RIGHT_TRIGGER_PLUS = 10;
	var RIGHT_TRIGGER_MINUS = 11;
	var POINTER_X_PLUS = 12;
	var POINTER_X_MINUS = 13;
	var POINTER_Y_PLUS = 14;
	var POINTER_Y_MINUS = 15;

	@:from
	public static inline function fromString(s:String)
	{
		s = s.toUpperCase();
		return fromStringMap.exists(s) ? fromStringMap.get(s) : NONE;
	}
	
	@:to
	public inline function toString():String
	{
		return toStringMap.get(this);
	}
}

@:enum
abstract MouseID(Int) from Int to Int{
	public static var fromStringMap(default, null):Map<String, MouseID>
		= FlxMacroUtil.buildMap("input.AbstractInputManager.MouseID");
		
	public static var toStringMap(default, null):Map<MouseID, String>
		= FlxMacroUtil.buildMap("input.AbstractInputManager.MouseID", true);

	var NONE = -1;	
	var MOUSE_LEFT = 0;
	var MOUSE_RIGHT = 1;
	var MOUSE_MIDDLE = 2;
	var MOUSE_WEEL_UP = 3;
	var MOUSE_WEEL_DOWN = 4;

	@:from
	public static inline function fromString(s:String)
	{
		s = s.toUpperCase();
		return fromStringMap.exists(s) ? fromStringMap.get(s) : NONE;
	}
	
	@:to
	public inline function toString():String
	{
		return toStringMap.get(this);
	}
}

enum AbstractSource{
	KEY;
	MOUSE;
	GAMEPADKEY;
	GAMEPADAXIS;
}




