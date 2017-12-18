package input;

import haxe.Timer;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.util.FlxDestroyUtil;
import flixel.ui.FlxButton;
import flixel.ui.FlxAnalog;

import openfl.system.Capabilities;
import flixel.input.gamepad.FlxGamepad.FlxGamepadModel;
import flixel.input.gamepad.id.XInputID;
import flixel.input.gamepad.FlxGamepadInputID;

import haxe.ds.EnumValueMap;

/**
 * screen gamepad, that used as real one
 * worls only with FLX_JOYSTICK_API
 * 
 * based on FlxVirtualPad by Ka Wing Chin
 * @author Yarikov Denis
 */
class ScreenGamepad extends FlxSpriteGroup{
	/**
	 * 	id of gamepad
	 **/
	public var id(get, null):Int = 0;
	
	/**
	 * show middle buttons
	 */
	public var SB:Bool = false;
	
	/**
	 * 	map of all buttons of gamepad
	 **/
	public var buttons:Map<Int, Null<FlxButton>> = new Map<Int, Null<FlxButton>>();
	
	/**
	 * Group of directions buttons.
	 */
	public var dPad:Null<FlxSpriteGroup> = null;
	
	/**
	 * Group of center buttons.
	 */
	public var center:Null<FlxSpriteGroup> = null;

	/**
	 * Group of action buttons.
	 */
	public var actions:Null<FlxSpriteGroup> = null;
	
	
	/**
	 * Analog sticks.
	 */
	public var analogLeft:Null<FlxAnalog> = null;
	public var analogRight:Null<FlxAnalog> = null;
	public var mode:FlxMode = XBOX;
	public var gamepad:VirtualGamepad = new VirtualGamepad();
	
	private var _radius:Float=0;
	private var _frames:Map<String, FlxTileFrames> = new Map<String, FlxTileFrames>();
	private var _buttonSize:FlxPoint=new FlxPoint();
	private var _distanse:FlxPoint = new FlxPoint();
	private var _offset:FlxPoint = new FlxPoint();
	private var _scale:Float = 1;
	
	/**
	 * Create a gamepad which contains 4 directional buttons and 4 action buttons, and 2 analog sticks.
	 * 
	 * @param 	FlxMode			The mode. XBOX for default.
	 * @param 	useStartBack	Show StartBack group.
	 * @param 	buttonSize		Size of the button.
	 * @param 	offset		Offset of the screen borders, and between buttons/analog.
	 */
	public function new(scale:Float=1.0, ?M:FlxMode, useStartBack:Bool=true, ?buttonSize:FlxPoint, ?offset:FlxPoint){	
		super();
		_scale = scale;
		if (buttonSize==null)
			buttonSize = new FlxPoint(32, 32);
		_buttonSize = new FlxPoint(Math.round(buttonSize.x*_scale), Math.round(buttonSize.y*_scale));
		if (offset==null)
			offset = new FlxPoint(_buttonSize.x*0.7, _buttonSize.y*0.7);
		_offset = offset;
		if (M == null)
			M = mode;		
		_distanse.x = 1.1 * _buttonSize.x;
		_distanse.y = 1.1 * _buttonSize.y;
	
		var base_sprite = new FlxSprite(0, 0, "assets/images/gamepad/base.png");
		var thumb_sprite = new FlxSprite(0, 0, "assets/images/gamepad/thumb.png");
		
		var button_sprites = ["up","down","left","right","a","b","x","y","back","start"];	
		var names = ["normal", "highlight", "pressed"];	
		for (sprite_f in button_sprites){
			var bmd = FlxG.bitmap.add('assets/images/gamepad/${sprite_f}.png');
			_frames[sprite_f]=FlxTileFrames.fromGraphic(bmd, new FlxPoint(bmd.height/3,bmd.height/3));
			for( i in 0...3){
				_frames[sprite_f].frames[i].name = names[i];
			}
		}
	
		scrollFactor.set();
		
		dPad = new FlxSpriteGroup(_distanse.x/2+_buttonSize.x+_offset.x, FlxG.height-(_distanse.y/2+_buttonSize.y+_offset.y));
		dPad.scrollFactor.set();
		dPad.exists = false;
		add(dPad);
		
		dPad.add(createButton(-_buttonSize.x/2, -(_distanse.y/2+_buttonSize.y), "up", FlxButtons.DPAD_UP));
		dPad.add(createButton(-(_distanse.x/2+_buttonSize.x), -_buttonSize.y/2, "left", FlxButtons.DPAD_LEFT));
		dPad.add(createButton(_distanse.x/2, -_buttonSize.y/2, "right", FlxButtons.DPAD_RIGHT));
		dPad.add(createButton(-_buttonSize.x/2, _distanse.y/2, "down", FlxButtons.DPAD_DOWN));

		actions = new FlxSpriteGroup(FlxG.width-(_distanse.x/2+_buttonSize.x+_offset.y), FlxG.height-(_distanse.y/2+_buttonSize.y+_offset.y));
		actions.scrollFactor.set();
		actions.exists = false;
		add(actions);
		
		actions.add(createButton(-_buttonSize.x/2, -(_distanse.y/2+_buttonSize.y), "y", FlxButtons.Y));
		actions.add(createButton(-(_distanse.x/2+_buttonSize.x), -_buttonSize.y/2, "x", FlxButtons.X));
		actions.add(createButton(_distanse.x/2, -_buttonSize.y/2, "b", FlxButtons.B));
		actions.add(createButton(-_buttonSize.x/2, _distanse.y/2, "a", FlxButtons.A));
		
		center = new FlxSpriteGroup(FlxG.width/2);
		center.scrollFactor.set();
		center.exists = false;
		add(center);
		
		center.add(createButton(-_buttonSize.x*1.5, FlxG.height - _buttonSize.y, "back", FlxButtons.BACK));
		center.add(createButton(_buttonSize.x/2, FlxG.height - _buttonSize.y, "start", FlxButtons.START));

		
		analogLeft = new FlxAnalog(100, FlxG.height - 200, base_sprite.width/2);
		analogLeft.base.x += analogLeft.base.width / 2;
		analogLeft.base.y += analogLeft.base.height / 2;
		analogLeft.base.frames = base_sprite.frames;
		analogLeft.base.resetSizeFromFrame();
		analogLeft.base.scale.set(_scale, _scale);
		analogLeft.base.updateHitbox();
		analogLeft.base.x -= analogLeft.base.width / 2;
		analogLeft.base.y -= analogLeft.base.height / 2;
		analogLeft.thumb.x += analogLeft.thumb.width / 2;
		analogLeft.thumb.y += analogLeft.thumb.height / 2;
		analogLeft.thumb.frames = thumb_sprite.frames;
		analogLeft.thumb.resetSizeFromFrame();
		analogLeft.thumb.scale.set(_scale, _scale);
		analogLeft.thumb.updateHitbox();
		analogLeft.thumb.x -= analogLeft.thumb.width / 2;
		analogLeft.thumb.y -= analogLeft.thumb.height / 2;
		analogLeft.exists = false;
		analogLeft.onPressed = drag_handler;
		analogLeft.onUp = Timer.delay.bind(drag_handler, 40);
		add(analogLeft);
		
		analogRight = new FlxAnalog(FlxG.width - 100, FlxG.height - 100, base_sprite.width/2);
		analogRight.exists = false;
		analogRight.base.x += analogRight.base.width / 2;
		analogRight.base.y += analogRight.base.height / 2;
		analogRight.base.frames = base_sprite.frames;
		analogRight.base.resetSizeFromFrame();
		analogRight.base.scale.set(_scale, _scale);
		analogRight.base.updateHitbox();
		analogRight.base.x -= analogRight.base.width / 2;
		analogRight.base.y -= analogRight.base.height / 2;
		analogRight.thumb.x += analogRight.thumb.width / 2;
		analogRight.thumb.y += analogRight.thumb.height / 2;
		analogRight.thumb.frames = thumb_sprite.frames;
		analogRight.thumb.resetSizeFromFrame();
		analogRight.thumb.scale.set(_scale, _scale);
		analogRight.thumb.updateHitbox();
		analogRight.thumb.x -= analogRight.thumb.width / 2;
		analogRight.thumb.y -= analogRight.thumb.height / 2;
		analogRight.onPressed = drag_handler;
		analogRight.onUp = Timer.delay.bind(drag_handler, 40);
		add(analogRight);
		
		if (_radius == 0)
			_radius = _scale*(analogLeft.base.width)/2;
		
		setMode(M);
		setAlpha(0.5);
	}

	@:noCompletion
	public function get_id():Int{
		return gamepad.id;
	}	
	
	override public function destroy():Void{
		super.destroy();
		
		dPad = FlxDestroyUtil.destroy(dPad);
		actions = FlxDestroyUtil.destroy(actions);
		center = FlxDestroyUtil.destroy(center);
		gamepad = FlxDestroyUtil.destroy(gamepad);
		
		dPad = null;
		actions = null;
		center = null;
		gamepad = null;
	}
	
	public function setMode(M:FlxMode, ?w:Int, ?h:Int){
//		trace(M);
		mode = M;
		if (w == null)
			w = FlxG.camera.width;
		if (h == null)
			h = FlxG.camera.height;

		var buttons_shift:FlxPoint = new FlxPoint(_distanse.x / 2 + _buttonSize.x, _distanse.y / 2 + _buttonSize.y);
		switch (M){
			//TODO: add inverse modes (as it has angle=180)
			case XBOX:
				dPad.exists = true;
				dPad.x = (buttons_shift.x + _offset.x); 
				dPad.y = h - (buttons_shift.y + _offset.y);
				actions.exists = true;
				actions.x = w - (buttons_shift.x + _offset.x);
				actions.y = h - (_radius + _offset.y)*2 - buttons_shift.y;
				analogLeft.exists = true;
				analogLeft.x = (buttons_shift.x + _offset.x);
				analogLeft.y = h - (buttons_shift.y + _offset.y) * 2 - _radius;
				analogRight.exists = true;
				analogRight.x = w - (buttons_shift.x + _offset.x);
				analogRight.y = h - (_radius + _offset.y);
			case PS:
				dPad.exists = true;
				dPad.x = (buttons_shift.x + _offset.x); 
				dPad.y = h - (_radius + _offset.y)*2 - buttons_shift.y;
				actions.exists = true;
				actions.x = w - (buttons_shift.x + _offset.x);
				actions.y = h - (_radius + _offset.y)*2 - (buttons_shift.y);
				analogLeft.exists = true;
				analogLeft.x = (buttons_shift.x + _offset.x);
				analogLeft.y = h - (_radius + _offset.y);
				analogRight.exists = true;
				analogRight.x = w - (buttons_shift.x + _offset.x);
				analogRight.y = h - (_radius + _offset.y);
			case SIMPLE:
				dPad.exists = false;
				actions.exists = true;
				actions.x = w - (buttons_shift.x + _offset.x);
				actions.y = h - (buttons_shift.y + _offset.y);
				analogLeft.exists = true;
				analogLeft.x = (buttons_shift.x + _offset.x);
				analogLeft.y = h - (buttons_shift.y + _offset.y);
				analogRight.exists = false;
			case ANALOG:
				dPad.exists = false;
				actions.exists = false;
				analogLeft.exists = true;
				analogLeft.x = (buttons_shift.x + _offset.x);
				analogLeft.y = h - (buttons_shift.y + _offset.y);
				analogRight.exists = true;
				analogRight.x = w - (buttons_shift.x + _offset.x);
				analogRight.y = h - (buttons_shift.y + _offset.y);
			case SNES:
				dPad.exists = true;
				dPad.x = (buttons_shift.x + _offset.x); 
				dPad.y = h - (buttons_shift.y + _offset.y);
				actions.exists = true;
				actions.x = w - (buttons_shift.x + _offset.x);
				actions.y = h - (buttons_shift.y + _offset.y);
				analogLeft.exists = false;
				analogRight.exists = false;
			case _:
				dPad.exists = false;
				actions.exists = false;
				analogLeft.exists = false;
				analogRight.exists = false;
		}
		center.exists = SB;
	}	
	
	/**
	 * @param 	X			The x-position of the button.
	 * @param 	Y			The y-position of the button.
	 * @param 	Width		The width of the button.
	 * @param 	Height		The height of the button.
	 * @param 	Graphic		The image of the button. It must contains 3 frames (NORMAL, HIGHLIGHT, PRESSED).
	 * @param 	I			Button id.
	 * @return	The button
	 */
	private function createButton(X:Float, Y:Float, Graphic:String, I:Int):FlxButton{
		var button = new FlxButton(X, Y);
		button.frames = _frames[Graphic];
		button.resetSizeFromFrame();
		button.scale.set(_scale, _scale);
		button.updateHitbox();
		button.solid = false;
		button.immovable = true;
		button.scrollFactor.set();
		button.onDown.callback = function(){gamepad.button_down(I);};
		button.onOut.callback = button.onUp.callback = function(){gamepad.button_up(I);};
	#if FLX_DEBUG
		button.ignoreDrawDebug = true;
	#end
		buttons[I] = button;
		return button;
	}
	
	private function drag_handler(){
		gamepad.axis_move(
			analogLeft.acceleration.x,///_radius,
			analogLeft.acceleration.y,///_radius,
			0,
			analogRight.acceleration.x,///_radius,
			analogRight.acceleration.y,///_radius,
			0
		);
	}

	public function setAlpha(a){
		alpha = a;
		analogLeft.thumb.alpha = a;
		analogLeft.base.alpha = a;
		analogRight.thumb.alpha = a;
		analogRight.base.alpha = a;	
		return this;
	}
	
	public function resize(w:Int, h:Int){
		//fill body
		setMode(mode);
	}
}

class FlxButtons{
	
	public static inline var A:Int = XInputID.A;
	public static inline var B:Int = XInputID.B;
	public static inline var X:Int = XInputID.X;
	public static inline var Y:Int = XInputID.Y;

	public static inline var BACK:Int = XInputID.BACK;
	public static inline var START:Int = XInputID.START;
	public static inline var DPAD_UP:Int = XInputID.DPAD_UP;
	public static inline var DPAD_DOWN:Int = XInputID.DPAD_DOWN;
	public static inline var DPAD_LEFT:Int = XInputID.DPAD_LEFT;
	public static inline var DPAD_RIGHT:Int = XInputID.DPAD_RIGHT;
}

enum FlxMode{
	XBOX;
	PS;
	SNES;
	SIMPLE;
	ANALOG;
}

