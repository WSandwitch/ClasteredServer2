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
import openfl.Assets;
import clasteredServerClient.*;
import haxe.CallStack;

import flixel.input.keyboard.FlxKey;
import input.AbstractInputManager;
import input.AbstractInputManager.*;
import input.ScreenGamepad;

using flixel.util.FlxSpriteUtil;
import flixel.system.macros.FlxMacroUtil;

/**
 * 
 */

 
class PlayState extends CSState
{
	//message ids
	public var MESSAGE_SET_DIRECTION:Int;
	public var MESSAGE_NPC_UPDATE:Int;
	public var MESSAGE_NPC_REMOVE:Int;
	public var MESSAGE_CLIENT_UPDATE:Int;
	public var MESSAGE_SET_ATTRS:Int;
	
	// Demo arena boundaries
	static var LEVEL_MIN_X;
	static var LEVEL_MAX_X;
	static var LEVEL_MIN_Y;
	static var LEVEL_MAX_Y;

	private var actions:AbstractInputManager = new AbstractInputManager();
	private var game:CSGame;
	private var orb:Npc;
	private var orbShadow:FlxSprite;
	private var hud:HUD;
	private var hudCam:FlxCamera;
	private var overlayCamera:FlxCamera;
	private var deadzoneOverlay:FlxSprite;

	///network attrs
	public var id:Int;
//	public var npcs:Map<Int,Null<Npc>> = new Map<Int,Null<Npc>>(); 
	public var npc:Null<Npc> = null;
	public var npc_id:Int = 0;
	private var _angle:Float = 0;
	private static inline var _d_angle:Float = 2 * 3.14 / 180; //2 degree
	
	
	public var l:Lock = new Lock();
	public var connection:Null<Connection> = null;
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
	
	private function checkKeyBack(e: openfl.events.KeyboardEvent):Void
	{
		switch (e.keyCode)
		{
			case FlxKey.ESCAPE:
				trace("back button");
				e.stopImmediatePropagation();
				//TODO: add show menu
//				restartLevel();
		}
	}
	
	public function connection_lost(){
		CSState.connection_lost();
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
		game = cast FlxG.game;
		
		id = game.id;
		connection = game.connection;
		recv_loop = true;
		receiver = new Receiver(this);
		
//		FlxG.mouse.visible = false;
		
//		FlxNapeSpace.velocityIterations = 5;
//		FlxNapeSpace.positionIterations = 5;

		_map = new CSMap();
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
		
		//TODO: change to send event
		FlxG.scaleMode.onMeasure(FlxG.width, FlxG.height); 
		onResize(FlxG.width, FlxG.height); 
	}
	
	function drawDeadzone() 
	{
		deadzoneOverlay.fill(FlxColor.TRANSPARENT);
		var dz:FlxRect = FlxG.camera.deadzone;
		if (dz == null)
			return;

		var lineLength:Int = 20;
		var lineStyle:LineStyle = { color: FlxColor.WHITE, thickness: 3 };
		
		// adjust points slightly so lines will be visible when at screen edges
		dz.x += lineStyle.thickness / 2;
		dz.width -= lineStyle.thickness;
		dz.y += lineStyle.thickness / 2;
		dz.height -= lineStyle.thickness;
		
		// Left Up Corner
		deadzoneOverlay.drawLine(dz.left, dz.top, dz.left + lineLength, dz.top, lineStyle);
		deadzoneOverlay.drawLine(dz.left, dz.top, dz.left, dz.top + lineLength, lineStyle);
		// Right Up Corner
		deadzoneOverlay.drawLine(dz.right, dz.top, dz.right - lineLength, dz.top, lineStyle);
		deadzoneOverlay.drawLine(dz.right, dz.top, dz.right, dz.top + lineLength, lineStyle);
		// Bottom Left Corner
		deadzoneOverlay.drawLine(dz.left, dz.bottom, dz.left + lineLength, dz.bottom, lineStyle);
		deadzoneOverlay.drawLine(dz.left, dz.bottom, dz.left, dz.bottom - lineLength, lineStyle);
		// Bottom Right Corner
		deadzoneOverlay.drawLine(dz.right, dz.bottom, dz.right - lineLength, dz.bottom, lineStyle);
		deadzoneOverlay.drawLine(dz.right, dz.bottom, dz.right, dz.bottom - lineLength, lineStyle);
	}
	
	public function setZoom(zoom:Float)
	{
		zoom = FlxMath.bound(zoom, 0.5, 4);
		FlxG.camera.zoom = zoom;
		
		var zoomDistDiffY;
		var zoomDistDiffX;
/*		
		if (zoom <= 1) 
		{
			zoomDistDiffX = Math.abs((LEVEL_MIN_X + LEVEL_MAX_X) - (LEVEL_MIN_X + LEVEL_MAX_X) / 1 + (1 - zoom));
			zoomDistDiffY = Math.abs((LEVEL_MIN_Y + LEVEL_MAX_Y) - (LEVEL_MIN_Y + LEVEL_MAX_Y) / 1 + (1 - zoom));
			zoomDistDiffX *= -.5;
			zoomDistDiffY *= -.5;
		}
		else
		{
			zoomDistDiffX = Math.abs((LEVEL_MIN_X + LEVEL_MAX_X) - (LEVEL_MIN_X + LEVEL_MAX_X) / zoom);
			zoomDistDiffY = Math.abs((LEVEL_MIN_Y + LEVEL_MAX_Y) - (LEVEL_MIN_Y + LEVEL_MAX_Y) / zoom);
			zoomDistDiffX *= .5;
			zoomDistDiffY *= .5;
		}
*/		
		zoomDistDiffX = ((LEVEL_MAX_X + (LEVEL_MIN_X))*(zoom-1));
		zoomDistDiffY = ((LEVEL_MAX_Y + (LEVEL_MIN_Y))*(zoom-1));
		
		if (zoom <= 1){
			zoomDistDiffX *= -1;
			zoomDistDiffY *= -1;
		}
		
		FlxG.camera.setScrollBoundsRect(
			LEVEL_MIN_X - zoomDistDiffX*0.5, 
			LEVEL_MIN_Y - zoomDistDiffY*0.5,
			LEVEL_MAX_X + Math.abs(LEVEL_MIN_X) + zoomDistDiffX,
			LEVEL_MAX_Y + Math.abs(LEVEL_MIN_Y) + zoomDistDiffY,
			false);
		
		FlxG.scaleMode.onMeasure(0,0);
		hud.updateZoom(FlxG.camera.zoom);
	}

	private function createFloorTiles() 
	{
		var	floorImg = Assets.getBitmapData("assets/images/FloorTexture.png");
		var imgWidth = floorImg.width;
		var imgHeight = floorImg.height;
		var i = LEVEL_MIN_X; 
		var j = LEVEL_MIN_Y; 
		
		while (i <= LEVEL_MAX_X)  
		{
			while (j <= LEVEL_MAX_Y)
			{
				add(new FlxSprite(i, j, floorImg));
				j += imgHeight;
			}
			i += imgWidth;
			j = LEVEL_MIN_Y;
		}
	}
	
	override 
	public function update(elapsed:Float):Void 
	{	
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
			_gamepad.destroy();
		}
		_gamepad = new ScreenGamepad();
		add(_gamepad);
	#end
	}
	
	private function checkInput(elapsed:Float) {
		var speed = 200;
		var p:Packet = new Packet();
		var keys_changed:Bool = false;
		actions.update();
		if (actions.anyChanged([GO_UP, GO_DOWN, GO_LEFT, GO_RIGHT])){
			p.addChar(0);
			p.addChar(Math.round((actions.value(GO_RIGHT)-(actions.value(GO_LEFT)))*100));
			p.addChar(1);
			p.addChar(Math.round((actions.value(GO_DOWN)-(actions.value(GO_UP)))*100));
		}
		if (actions.anyChanged([ATTACK])){
			p.addChar(3);
			p.addChar(Math.round(actions.value(ATTACK)));
		}
		if (npc != null){
			var angle:Float = 0;
		#if !FLX_NO_MOUSE
			angle = Math.atan2(FlxG.mouse.y - npc.y, FlxG.mouse.x - npc.x);		
		#end
			//add gamepad sngle control
//			trace(Math.abs(_angle-angle));
			if (Math.abs(_angle-angle) >= _d_angle){
				_angle = angle;
				p.addChar(2);
				p.addChar(Math.round(angle/3.14*120));	
			}
//			trace(angle / 3.14 * 180);
//			npc.angle = Math.round(angle / 3.14 * 180);
		}
		if (p.chanks.length>0){
			p.type = MESSAGE_SET_DIRECTION;
//			trace(connection);
			connection.sendPacket(p);
//			trace("sended");
		}
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
		if (FlxG.keys.justPressed.O)
			setZoom(FlxG.camera.zoom + .1);
		if (FlxG.keys.justPressed.L)
			setZoom(FlxG.camera.zoom - .1);
			
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
				if (p.type==MESSAGE_NPC_UPDATE){
					var n:Null<Npc> = _map.get_npc(p.chanks[0].i);
					if (n == null){
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
							trace("dead npc " + nid);
							var n:Null<Npc> = _map.get_npc(nid);
							_map.remove_npc(nid);
							if (n != null){
								n.destroy();
								n = null;
							}
						}
					}
				} else if (p.type==MESSAGE_CLIENT_UPDATE){
					var i:Int=0;
					while(i<p.chanks.length-1){
						switch p.chanks[i].i {
							case 1:
								npc_id=p.chanks[++i].i;
								if (_map.get_npc(npc_id) == null){
									_map.set_npc(npc_id, new Npc(0, 0, 0));
									_map.get_npc(npc_id).id = npc_id;
								}
								npc = _map.get_npc(npc_id);
								FlxG.camera.follow(npc, FlxCameraFollowStyle.NO_DEAD_ZONE);
								_map.fov.follow = npc;
								i++;
						}
					}
				}
			}
		}while(p != null);
	}
	
	private function setLead(lead:Float) 
	{
		var cam = FlxG.camera;
		cam.followLead.x += lead;
		cam.followLead.y += lead;
		
		if (cam.followLead.x < 0)
		{
			cam.followLead.x = 0;
			cam.followLead.y = 0;
		}
		
		hud.updateCamLead(cam.followLead.x);
	}
	
	private function setLerp(lerp:Float) 
	{
		var cam = FlxG.camera;
		cam.followLerp += lerp;
		cam.followLerp = Math.round(10 * cam.followLerp) / 10; // adding or subtracting .1 causes roundoff errors
		hud.updateCamLerp(cam.followLerp);
	}
	
	//for using custom actions, use with FlxG.autoPause = true;
	override public function onFocus():Void{
		
	} 
	
	override public function onFocusLost():Void{
		
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
