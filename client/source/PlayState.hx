package;

import clasteredServerClient.Packet;
import flash.Lib;
import flash.display.BlendMode;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.system.scaleModes.*;
import flixel.addons.nape.FlxNapeSpace;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import nape.geom.Vec2;
import openfl.Assets;
import clasteredServerClient.*;
import haxe.CallStack;

using flixel.util.FlxSpriteUtil;

/**
 * @author TiagoLr ( ~~~ProG4mr~~~ )
 */
class PlayState extends FlxState
{
	// Demo arena boundaries
	static var LEVEL_MIN_X;
	static var LEVEL_MAX_X;
	static var LEVEL_MIN_Y;
	static var LEVEL_MAX_Y;

	private var game:CSGame;
	private var orb:Npc;
	private var orbShadow:FlxSprite;
	private var hud:HUD;
	private var hudCam:FlxCamera;
	private var overlayCamera:FlxCamera;
	private var deadzoneOverlay:FlxSprite;
	private var keys:Array<Int> = [0,0,0,0];

	///network attrs
	public var id:Int;
	public var npcs:Map<Int,Null<Npc>> = new Map<Int,Null<Npc>>(); 
	public var npc:Null<Npc> = null;
	public var npc_id:Int = 0;
	
	public var l:Lock = new Lock();
	public var connection:Null<Connection> = null;
	public var recv_loop:Bool = true;
	public var receiver:Null<Receiver> = null;
	public var packets:Array<Packet> = new Array<Packet>();
	
	public function connection_lost(){
		game.connection_lost();
	}
	///out messages
	private static inline var MSG_SET_DIRECTION:Int = 2;
	//in messages
	private static inline var MSG_NPC_UPDATE:Int=3;
	private static inline var MSG_CLIENT_UPDATE:Int=6;
	///

	
	override public function create():Void 
	{	
		FlxNapeSpace.init();
		
		LEVEL_MIN_X = -FlxG.stage.stageWidth / 2;
		LEVEL_MAX_X = FlxG.stage.stageWidth * 1.5;
		LEVEL_MIN_Y = -FlxG.stage.stageHeight / 2;
		LEVEL_MAX_Y = FlxG.stage.stageHeight * 1.5;
		
		super.create();
		game = cast FlxG.game;
		
		id = game.id;
		connection = game.connection;
		recv_loop = true;
		receiver = new Receiver(this);
		
		FlxG.mouse.visible = false;
		
		FlxNapeSpace.velocityIterations = 5;
		FlxNapeSpace.positionIterations = 5;
		
		createFloorTiles();
		FlxNapeSpace.createWalls(LEVEL_MIN_X, LEVEL_MIN_Y, LEVEL_MAX_X, LEVEL_MAX_Y);
		// Walls border.
		add(new FlxSprite(-FlxG.width / 2, -FlxG.height / 2, "assets/Border.png"));
		
		// Player orb
		//orbShadow = new FlxSprite(FlxG.width / 2, FlxG.height / 2, "assets/OrbShadow.png");
		//orbShadow.centerOffsets();
		//orbShadow.blend = BlendMode.MULTIPLY;
		
		//orb = new Npc(FlxG.width / 2, FlxG.height / 2, 1);
		
		//add(orbShadow);
		//add(orb);
		
		//orb.shadow = orbShadow;
		
		// Other orbs
		for (i in 0...5) 
		{
			var otherOrbShadow = new FlxSprite(100, 100, "assets/OtherOrbShadow.png");
			otherOrbShadow.centerOffsets();
			otherOrbShadow.blend = BlendMode.MULTIPLY;
			
			var otherOrb = new Orb();
			otherOrb.loadGraphic("assets/OtherOrb.png", true, 140, 140);
			otherOrb.createCircularBody(50);
			otherOrb.setBodyMaterial(1, 0.2, 0.4, 0.5);
			otherOrb.antialiasing = true;
			otherOrb.setDrag(1, 1);
			
			add(otherOrbShadow);
			add(otherOrb);
			
			otherOrb.shadow = otherOrbShadow;
			
			switch (i) 
			{
				case 0: 
					otherOrb.body.position.setxy(320 - 400, 240 - 400);
					otherOrb.animation.frameIndex = 0;
				case 1: 
					otherOrb.body.position.setxy(320 + 400, 240 - 400); 
					otherOrb.animation.frameIndex = 4;
				case 2:
					otherOrb.body.position.setxy(320 + 400, 240 + 400); 
					otherOrb.animation.frameIndex = 3;
				case 3:
					otherOrb.body.position.setxy(-300, 240); 
					otherOrb.animation.frameIndex = 2;
				case 4:
					otherOrb.body.position.setxy(0, 240 + 400); 
					otherOrb.animation.frameIndex = 1;
			}
			otherOrb.body.velocity.setxy(FlxG.random.int(75, 150), FlxG.random.int(75, 150));
		}

		hud = new HUD();
		add(hud);

		// Camera Overlay
		deadzoneOverlay = new FlxSprite(-10000, -10000);
		deadzoneOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT, true);
		deadzoneOverlay.antialiasing = true;

		overlayCamera = new FlxCamera(0, 0, 640, 720);
		overlayCamera.bgColor = FlxColor.TRANSPARENT;
		overlayCamera.follow(deadzoneOverlay);
		FlxG.cameras.add(overlayCamera);
		add(deadzoneOverlay);
		
		FlxG.camera.setScrollBoundsRect(LEVEL_MIN_X, LEVEL_MIN_Y,
			LEVEL_MAX_X + Math.abs(LEVEL_MIN_X), LEVEL_MAX_Y + Math.abs(LEVEL_MIN_Y), true);
		//FlxG.camera.follow(orb, FlxCameraFollowStyle.NO_DEAD_ZONE);
		drawDeadzone(); // now that deadzone is present
		
		hudCam = new FlxCamera(440, 0, hud.width, hud.height);
		hudCam.zoom = 1; // For 1/2 zoom out.
		hudCam.follow(hud.background, FlxCameraFollowStyle.NO_DEAD_ZONE);
		hudCam.alpha = .5;
		FlxG.cameras.add(hudCam);
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
		var	floorImg = Assets.getBitmapData("assets/FloorTexture.png");
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
	
	override public function update(elapsed:Float):Void 
	{	
		super.update(elapsed);
		
//		trace(elapsed);
//		trace(Sys.time());
//		trace(orb.x,orb.y);
		checkInput(elapsed);
		checkPackets(elapsed);
	}
	
	private function checkInput(elapsed:Float) {
		var speed = 200;
		var p:Packet = new Packet();
		var keys_changed:Bool = false;

		if (FlxG.keys.anyJustPressed([A, LEFT])){
			keys[0] -= 100;
			keys_changed = true;
		}
		if (FlxG.keys.anyJustReleased([A, LEFT])){
			keys[0] += 100;
			keys_changed = true;
		}
		if (FlxG.keys.anyJustPressed([D, RIGHT])){
			keys[0] += 100;
			keys_changed = true;
		}
		if (FlxG.keys.anyJustReleased([D, RIGHT])){
			keys[0] -= 100;
			keys_changed = true;
		}

		if (FlxG.keys.anyJustPressed([S, DOWN])){
			keys[1] += 100;
			keys_changed = true;
		}
		if (FlxG.keys.anyJustReleased([S, DOWN])){
			keys[1] -= 100;
			keys_changed = true;
		}
		if (FlxG.keys.anyJustPressed([W, UP])){
			keys[1] -= 100;
			keys_changed = true;
		}
		if (FlxG.keys.anyJustReleased([W, UP])){
			keys[1] += 100;
			keys_changed = true;
		}
		if (keys_changed){
			p.addChar(0);
			p.addChar(keys[0]);
			p.addChar(1);
			p.addChar(keys[1]);
		}
		
		if (p.chanks.length>0){
			p.type = MSG_SET_DIRECTION;
//			trace(connection);
			connection.sendPacket(p);
//			trace("sended");
		}
		
		if (FlxG.keys.justPressed.U)
			setLerp(.1);
		if (FlxG.keys.justPressed.J)
			setLerp( -.1);
			
		if (FlxG.keys.justPressed.I)
			setLead(.5);
		if (FlxG.keys.justPressed.K)
			setLead( -.5);
			
		if (FlxG.keys.justPressed.O)
			setZoom(FlxG.camera.zoom + .1);
		if (FlxG.keys.justPressed.L)
			setZoom(FlxG.camera.zoom - .1);
			
		if (FlxG.keys.justPressed.M)
			FlxG.camera.shake();
		
	}
	
	private function checkPackets(elapsed:Float) {
		var p:Null<Packet> = null;
		do{
			l.lock();
				p = packets.pop();
			l.unlock();
			if (p!=null){
				switch p.type {
					case MSG_NPC_UPDATE:
						var n:Null<Npc> = npcs[p.chanks[0].i];
						if (n == null){
							n = new Npc(0, 0, 0);
							n.id = p.chanks[0].i;
							npcs[p.chanks[0].i] = n;
							add(n);
						}
						n.update_attributes(p);
					case MSG_CLIENT_UPDATE:
						var i:Int=0;
						while(i<p.chanks.length-1){
							switch p.chanks[i].i {
								case 1:
									npc_id=p.chanks[++i].i;
									if (npcs[npc_id] == null){
										npcs[npc_id] = new Npc(0, 0, 0);
										npcs[npc_id].id = npc_id;
										add(npcs[npc_id]);
									}
									npc = npcs[npc_id];
									FlxG.camera.follow(npc, FlxCameraFollowStyle.NO_DEAD_ZONE);
									i++;
							}
						}
				}
			}
		}while (p != null);
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
	
}
