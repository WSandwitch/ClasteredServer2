package lighting;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxColor;
import lighting.Visibility;

/**
 * ...
 * @author ...
 */
class FOV extends FlxSprite{
	
	public var follow:Null<FlxObject> = null;
	public var _shadow:FlxSprite = new FlxSprite();
	private var _vis:Visibility;
	
	public static inline var BASE_COLOR:Int = 0xEE000000;
	public static inline var FILL_COLOR:Int = 0xEEEEEEEE;
	
	public function new(width:Int, height:Int, vis:Visibility, ?f:FlxObject){
		super();// "assets/images/lamp.png");
		makeGraphic(width, height, BASE_COLOR);
		_shadow.makeGraphic(width, height, FlxColor.TRANSPARENT);
		//_shadow.blend = openfl.display.BlendMode.SCREEN;
		_vis = vis;
		follow = f;
		blend = openfl.display.BlendMode.MULTIPLY;
	}
	
	override
	public function draw(){//update(elapsed){
		if (follow != null) {
			reset(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
			_vis.setLightLocation(follow.x, follow.y);
			_vis.sweep();
			
			_shadow.graphic.bitmap.lock();
			_shadow.graphic.bitmap.fillRect(new Rectangle(0, 0, width, height), FlxColor.TRANSPARENT);
			_shadow.graphic.bitmap.unlock();
//			FlxSpriteUtil.fill(_shadow, FlxColor.TRANSPARENT);
//			blend = openfl.display.BlendMode.SCREEN;
			if (_vis.output.length > 0){
				for (p in _vis.output){
					p.x -= FlxG.camera.scroll.x;
					p.y -= FlxG.camera.scroll.y;
				}
				FlxSpriteUtil.drawPolygon(_shadow, _vis.output, FILL_COLOR);
			}
//			blend = openfl.display.BlendMode.MULTIPLY;
			FlxSpriteUtil.alphaMaskFlxSprite(_shadow, this, this);
		}
		super.draw();
	}
	
	public function resize(width:Int, height:Int){
		makeGraphic(width, height, BASE_COLOR);
		_shadow.makeGraphic(width, height, FlxColor.TRANSPARENT);
	}
}