package states;

import clasteredServerClient.Packet;
import flash.Lib;
import flash.display.BlendMode;
import flash.media.ID3Info;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.system.scaleModes.*;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.Assets;
import clasteredServerClient.*;
import haxe.CallStack;

import flixel.input.keyboard.FlxKey;
import input.AbstractInputManager;
import input.AbstractInputManager.*;
import input.ScreenGamepad;

using flixel.util.FlxSpriteUtil;
import flixel.system.macros.FlxMacroUtil;

#if mobile
import extension.notifications.Notifications;
#end
/**
 * 
 */

 
class PlayState extends FlxState
{
	//message ids
	public var MESSAGE_SET_ACTIONS:Int;
	public var MESSAGE_NPC_UPDATE:Int;
	public var MESSAGE_NPC_REMOVE:Int;
	public var MESSAGE_CLIENT_UPDATE:Int;
	public var MESSAGE_SET_ATTRS:Int;
	public var MESSAGE_GET_NPC_INFO:Int;
	
	// Demo arena boundaries
	static var LEVEL_MIN_X;
	static var LEVEL_MAX_X;
	static var LEVEL_MIN_Y;
	static var LEVEL_MAX_Y;

	private var actions:AbstractInputManager = new AbstractInputManager();
	private var orb:Npc;
	private var orbShadow:FlxSprite;
	private var hud:HUD;
	private var hudCam:FlxCamera;
	private var overlayCamera:FlxCamera;
	private var deadzoneOverlay:FlxSprite;

	///network attrs
	public var id(get,set):Int;
//	public var npcs:Map<Int,Null<Npc>> = new Map<Int,Null<Npc>>(); 
	public var npc:Null<Npc> = null;
	public var npc_id:Int = 0;
	private var _angle:Float = 0;
	private static var _d_angle:Float = 1 * Math.PI / 120; //~1 pdegree
	
	
	public var l:Lock = new Lock();
	public var connection(get,set):Null<Connection>;
	public var recv_loop:Bool = true;
	public var receiver:Null<Receiver> = null;
	public var packets:Array<Packet> = new Array<Packet>();
	
//	public function connection_lost(){
//		game.connection_lost();
//	}
	///
	private var _map:CSMap;
	private var _gamepad:Null<ScreenGamepad>;
	
	private var _map_group:FlxGroup = new FlxGroup();
	private var _hud_group:FlxGroup = new FlxGroup();
	
	private function exit(){
		#if !flash
			openfl.Lib.exit();//TODO: check for android
			openfl.Lib.close();
		#end
	}
	
	private function checkKeyBack(e: openfl.events.KeyboardEvent):Void
	{
		switch (e.keyCode)
		{
			case FlxKey.ESCAPE:
				trace("back button");
				e.stopImmediatePropagation();
				//TODO: add show menu
				exit();//change to open menu
//				restartLevel();
		}
	}
	
	public function connection_lost(){
		Main.connection_lost();
	}
	
	public function get_id():Int{
		return Main.id;
	}
	
	public function set_id(id:Int):Int{
		return Main.id=id;
	}
	
	public function get_connection():Null<Connection>{
		return Main.connection;
	}
	
	public function set_connection(connection:Null<Connection>):Null<Connection>{
		return Main.connection=connection;
	}
	
	override public function create():Void 
	{	
		FlxG.stage.addEventListener(openfl.events.KeyboardEvent.KEY_UP, checkKeyBack);
		
//		LEVEL_MIN_X = -FlxG.stage.stageWidth / 2;
//		LEVEL_MAX_X = FlxG.stage.stageWidth * 1.5;
//		LEVEL_MIN_Y = -FlxG.stage.stageHeight / 2;
//		LEVEL_MAX_Y = FlxG.stage.stageHeight * 1.5;
		MessageIds.build(this);
		CSObjects.init();
		
		super.create();
		trace("play state");
		
		recv_loop = true;
		receiver = new Receiver(this);
		
//		FlxG.mouse.visible = false;
		
//		FlxNapeSpace.velocityIterations = 5;
//		FlxNapeSpace.positionIterations = 5;

		_map = new CSMap(); //must be here because of screen size, or must call resize before add
	//	_map.load(0);
		add(_map_group);
		_map_group.add(_map);
		

		hud = new HUD();
		add(_hud_group);
		_hud_group.add(hud);

		// Camera Overlay
		deadzoneOverlay = new FlxSprite(-10000, -10000);
		deadzoneOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT, true);
		//deadzoneOverlay.antialiasing = true;

		overlayCamera = new FlxCamera(0, 0, 640, 720);
		overlayCamera.bgColor = FlxColor.TRANSPARENT;
		overlayCamera.follow(deadzoneOverlay);
	#if !flash
		overlayCamera.antialiasing=true;
		FlxG.camera.antialiasing=true;
	#end
		FlxG.cameras.add(overlayCamera);
		add(deadzoneOverlay);
		
		
//		FlxG.camera.setScrollBoundsRect(LEVEL_MIN_X, LEVEL_MIN_Y,
//			LEVEL_MAX_X + Math.abs(LEVEL_MIN_X), LEVEL_MAX_Y + Math.abs(LEVEL_MIN_Y), true);
		//FlxG.camera.follow(orb, FlxCameraFollowStyle.NO_DEAD_ZONE);

/*
		hudCam = new FlxCamera(440, 0, hud.width, hud.height);
		hudCam.zoom = 1; // For 1/2 zoom out.
		hudCam.follow(hud.background, FlxCameraFollowStyle.NO_DEAD_ZONE);
		hudCam.alpha = .5;
		FlxG.cameras.add(hudCam);
*/
		//add gamepad to screen
		addGamepad();
		//change to normal mapping
		var a = actions.addAction(GO_UP);
		a.addKey(FlxKey.W);
		a.addKey(FlxKey.UP);
		a.addGamepadAxis(GamepadAxisID.LEFT_STICK_Y_MINUS);
		a=actions.addAction(GO_DOWN);
		a.addKey(FlxKey.S);
		a.addKey(FlxKey.DOWN);
		a.addGamepadAxis(GamepadAxisID.LEFT_STICK_Y_PLUS);
		a=actions.addAction(GO_LEFT);
		a.addKey(FlxKey.A);
		a.addKey(FlxKey.LEFT);
		a.addGamepadAxis(GamepadAxisID.LEFT_STICK_X_MINUS);
		a=actions.addAction(GO_RIGHT);
		a.addKey(FlxKey.D);
		a.addKey(FlxKey.RIGHT);
		a.addGamepadAxis(GamepadAxisID.LEFT_STICK_X_PLUS);
		a=actions.addAction(ATTACK);
		a.addMouseKey(MouseID.MOUSE_LEFT);
		
		a=actions.addAction(LOOK_UP);
		a.addGamepadAxis(GamepadAxisID.RIGHT_STICK_Y_MINUS);
		a=actions.addAction(LOOK_DOWN);
		a.addGamepadAxis(GamepadAxisID.RIGHT_STICK_Y_PLUS);
		a=actions.addAction(LOOK_LEFT);
		a.addGamepadAxis(GamepadAxisID.RIGHT_STICK_X_MINUS);
		a=actions.addAction(LOOK_RIGHT);
		a.addGamepadAxis(GamepadAxisID.RIGHT_STICK_X_PLUS);
	}
	
	override 
	public function draw(){	
		super.draw();
	}
	
	override 
	public function update(elapsed:Float){	
//		trace(elapsed);
//		trace(Sys.time());
//		trace(orb.x,orb.y);
		send_screen_position();
		checkInput(elapsed);
		checkPackets(elapsed);

		super.update(elapsed);
	}
	
	private function send_screen_size(_w:Int,_h:Int){
		try{
			var p:Packet = new Packet();
			p.addChar(1);
			p.addShort(_w);
			p.addChar(2);
			p.addShort(_h);
			p.type = MESSAGE_SET_ATTRS;
			connection.sendPacket(p);
			trace("send screen size");
		}catch(e:Dynamic){
			trace(e);
		}
	}
	
	private var _position:FlxPoint = new FlxPoint(0, 0); 
	private function send_screen_position(){
		try{
			var p:Packet = new Packet();
			p.type = MESSAGE_SET_ATTRS;
			if (npc != null){
				var pos = npc.getScreenPosition();
				if (pos.x - _position.x > 10 || _position.x - pos.x > 10){
					_position.x = pos.x;
					p.addChar(3);
					p.addShort(Std.int(_position.x));
				}
				if (pos.y - _position.y > 10 || _position.y - pos.y > 10){
					_position.y = pos.y;
					p.addChar(4);
					p.addShort(Std.int(_position.y));
				}
			}
			if (p.chanks.length>0)
				connection.sendPacket(p);
		}catch(e:Dynamic){
			trace(e);
		}
	}
	
	override
	public function onResize(w:Int, h:Int){
//		trace(w);
		super.onResize(w, h);
		var _w:Int = Std.int(w / FlxG.scaleMode.scale.x);
		var _h:Int = Std.int(h / FlxG.scaleMode.scale.y);
		_map.resize(_w, _h);
		
		send_screen_size(_w, _h);
		
		addGamepad();
	}
	
	public function addGamepad(){
	#if mobile
		if (_gamepad != null){
			remove(_gamepad);
			FlxDestroyUtil.destroy(_gamepad);
		}
		_gamepad = new ScreenGamepad();
		add(_gamepad);
	#end
	}
	
	private function checkInput(elapsed:Float) {
		var p:Packet = new Packet();
		var keys_changed:Bool = false;
		actions.update();
		if (actions.anyChanged([GO_UP, GO_DOWN, GO_LEFT, GO_RIGHT])){
			p.addChar(0);
			p.addChar(Math.round((actions.value(GO_RIGHT)-actions.value(GO_LEFT))*100));
			p.addChar(1);
			p.addChar(Math.round((actions.value(GO_DOWN)-actions.value(GO_UP))*100));
		}
		if (actions.anyChanged([ATTACK])){
			p.addChar(3);
			p.addChar(Math.round(actions.value(ATTACK)));
		}
		if (npc != null){
			var angle_send:Bool = false;
			var angle:Float = 0;
			if (actions.anyChanged([LOOK_UP, LOOK_DOWN, LOOK_LEFT, LOOK_RIGHT])){
				 var angle = Math.atan2(actions.value(LOOK_DOWN) - actions.value(LOOK_UP), actions.value(LOOK_RIGHT) - actions.value(LOOK_LEFT)); 
				 if (Math.abs(_angle-angle) >= _d_angle){
					_angle = angle;
					angle_send = true;
//					trace("gamepad angle "+angle);
				}
			}
		#if !FLX_NO_MOUSE
			{
				var angle = Math.atan2(FlxG.mouse.y - npc.y, FlxG.mouse.x - npc.x);	
				if (Math.abs(_angle-angle) >= _d_angle){
					_angle = angle;
					angle_send = true;
//					trace("mouse angle");
				}
			}
		#end
			if (angle_send){
				p.addChar(2);
				p.addChar(Math.round(_angle/3.14*120));	
			}
		}
		if (p.chanks.length>0){
			p.type = MESSAGE_SET_ACTIONS;
//			trace(connection);
			connection.sendPacket(p);
//			trace("sended");
		}
		
		
		///test 
	#if !FLX_NO_KEYBOARD	
		if (FlxG.keys.justPressed.U)
			npc.sprite.y+=3;
		if (FlxG.keys.justPressed.J)
			npc.sprite.y-=3;
			
		if (FlxG.keys.justPressed.H)
			npc.sprite.x-=3;
		if (FlxG.keys.justPressed.K)
			npc.sprite.x+=3;
			
		if (FlxG.keys.justPressed.Y){
			trace(npc.x);
			trace(npc.y);
			trace(npc.sprite.x);
			trace(npc.sprite.y);
		}
			
		if (FlxG.keys.justPressed.M)
			FlxG.camera.shake();
	#end	
	}
	
	private function checkPackets(elapsed:Float) {
		var p:Null<Packet> = null;
		do{
			l.lock();
				p = packets.pop();
			l.unlock();
			if (p!=null){
				if (p.type == MESSAGE_NPC_UPDATE){
//					trace("update npc " + p.chanks[0].i);
					var n:Null<Npc> = _map.get_npc(p.chanks[0].i);
					if (n == null){
//						trace("add new npc " + p.chanks[0].i);
						n = new Npc(FlxG.camera.scroll.x-100, FlxG.camera.scroll.y-100, 0);//create object out of screen
						n.id = p.chanks[0].i;
						_map.set_npc(n.id, n);
					}
					n.update_attributes(p);
				} else if (p.type==MESSAGE_NPC_REMOVE){
					for (chank in p.chanks){
						var nid = chank.i;
						if (npc_id==nid){
							//player npc add screen you are died
						}else{
							var n:Null<Npc> = _map.remove_npc(nid, false);
							if (n != null){
//								trace("remove npc " + nid);
//								FlxDestroyUtil.destroy(n); //don't need
								n = null;
							}
						}
					}
				} else if (p.type==MESSAGE_CLIENT_UPDATE){
					var i:Int = 0;
					while(i<p.chanks.length-1){
						switch p.chanks[i].i {
							case 1:
								npc_id = p.chanks[++i].i;
//								trace("client npc "+npc_id);
								if (_map.get_npc(npc_id) == null){
									_map.set_npc(npc_id, new Npc(0, 0, 0));
									_map.get_npc(npc_id).id = npc_id;
//									trace("add new npc ");
									var p:Packet = new Packet();
									p.addInt(npc_id);
									p.type = MESSAGE_GET_NPC_INFO;
									connection.sendPacket(p);
									send_screen_size(FlxG.width, FlxG.height);
								}
								npc = _map.get_npc(npc_id);
								FlxG.camera.follow(npc, FlxCameraFollowStyle.NO_DEAD_ZONE);
								_map.fov.follow = npc;
								i++;
							case 2:
								trace("map id updated");
								_map.set_current(p.chanks[++i].i);
								i++;
						}
					}
				}
			}
		}while(p != null);
	}
	
	
	private static inline var slot:Int = 7;
	//for using custom actions, use with FlxG.autoPause = true;
	override 
	public function onFocus():Void{
//		super.onFocus();
#if (android || ios)
	Notifications.cancelLocalNotifications();
#end	
//	trace("focus");
	} 
	
	override 
	public function onFocusLost():Void{
//		super.onFocusLost();
	//set normal message
#if android
	Notifications.scheduleLocalNotification(slot, 0, Main.tongue.get("#NOTIFICATION_TITLE"), Main.tongue.get("#NOTIFICATION_BUTTON"), Main.tongue.get("#NOTIFICATION_MESSAGE"), "", false, true);
#elseif ios
	Notifications.scheduleLocalNotification(slot, 0, Main.tongue.get("#NOTIFICATION_TITLE"), Main.tongue.get("#NOTIFICATION_MESSAGE"), Main.tongue.get("#NOTIFICATION_BUTTON"), false);
#end
//	trace("focus lost");
	} 
	
}

@:enum
abstract ActionID(Int) from Int to Int{
	public static var fromStringMap(default, null):Map<String, ActionID>
		= FlxMacroUtil.buildMap("PlayState.ActionID");
		
	public static var toStringMap(default, null):Map<ActionID, String>
		= FlxMacroUtil.buildMap("PlayState.ActionID", true);

	var NONE = -1;	
	var GO_UP = 1;
	var GO_DOWN = 2;
	var GO_LEFT = 3;
	var GO_RIGHT = 4;
	var ATTACK = 5;
	var LOOK_UP = 6;
	var LOOK_DOWN = 7;
	var LOOK_LEFT = 8;
	var LOOK_RIGHT = 9;
	
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
