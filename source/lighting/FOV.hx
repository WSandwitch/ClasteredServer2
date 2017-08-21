package lighting;

import flash.display.CapsStyle;
import flixel.group.FlxSpriteGroup;
import openfl.display.BitmapData;
import openfl.geom.Point;
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
class FOV extends FlxSpriteGroup{
	public var follow:Null<FlxObject> = null;
	public var _tmp:FlxSprite = new FlxSprite();
	public var _base:FlxSprite = new FlxSprite();
	public var _bases:Array<Array<FlxSprite>> = new Array<Array<FlxSprite>>();
	public var _shadow:FlxSprite = new FlxSprite();
	private var _vis:Visibility;
	
	public static inline var BASE_COLOR:Int = 0xEE000000;
	public static inline var FILL_COLOR:Int = 0xEEEEEEEE;
	
	private var _rows:Int;
	private var _cols:Int;
	
	public function new(width:Int, height:Int, vis:Visibility, rows:Int=1, cols:Int=1, ?f:FlxObject){
		super();// "assets/images/lamp.png");
		_rows = rows;
		_cols = cols;
		var _width = Math.ceil(width/_cols);
		var _height = Math.ceil(height/_rows);
		for (i in 0..._cols){
			_bases.push(new Array<FlxSprite>());
			for (j in 0..._rows){
				var base = new FlxSprite();
				base.makeGraphic(_width, _height, BASE_COLOR, true);
				base.blend = openfl.display.BlendMode.MULTIPLY;
				base.x = i * _width;
				base.y = j * _height;
				_bases[i].push(base);
				add(base);
			}
		}
		_tmp.makeGraphic(_width*_cols, _height*_rows, BASE_COLOR);
		_shadow.makeGraphic(_width*_cols, _height*_rows, FlxColor.TRANSPARENT);
		//_shadow.blend = openfl.display.BlendMode.SCREEN;
		_vis = vis;
		follow = f;
		
	}
	
	override
	public function draw(){//update(elapsed){
		if (follow != null) {
//			reset(FlxG.camera.scroll.x, FlxG.camera.scroll.y); //do not use it on sprite group !!!
			x = FlxG.camera.scroll.x;
			y = FlxG.camera.scroll.y;
			_vis.setLightLocation(follow.x, follow.y);
			_vis.sweep();
			
//			_shadow.graphic.bitmap.lock();
//			_shadow.graphic.bitmap.fillRect(new Rectangle(0, 0, width, height), FlxColor.TRANSPARENT);
//			_shadow.graphic.bitmap.unlock();
//			FlxSpriteUtil.fill(this, FlxColor.TRANSPARENT);
			FlxSpriteUtil.fill(_shadow, FlxColor.TRANSPARENT);
//			blend = openfl.display.BlendMode.SCREEN;
			if (_vis.output.length > 0){
				for (p in _vis.output){
					p.x -= FlxG.camera.scroll.x;
					p.y -= FlxG.camera.scroll.y;
				}
				FlxSpriteUtil.drawPolygon(_shadow, _vis.output, FILL_COLOR, {color: FILL_COLOR, thickness: 3});
			}
//			blend = openfl.display.BlendMode.MULTIPLY;
			FlxSpriteUtil.alphaMaskFlxSprite(_shadow, _tmp, _tmp);
			for (i in 0..._cols){
			var zpoint = new Point(0, 0);
				for (j in 0..._rows){
					var bm = _bases[i][j].graphic.bitmap;
					_bases[i][j].graphic.bitmap.copyPixels(_tmp.graphic.bitmap, new Rectangle(i * bm.width, j * bm.height, bm.width, bm.height), zpoint);
					_bases[i][j].dirty = true;
				}
			}
			//another way
//			FlxSpriteUtil.drawPolygon(_shadow, _vis.output, BASE_COLOR, {color: BASE_COLOR, thickness: 40});
		}
		super.draw();
	}
	
	public function resize(width:Int, height:Int){
		var _width = Math.ceil(width/_cols);
		var _height = Math.ceil(height / _rows);
		reset(0, 0);
		for (i in 0..._cols){
			for (j in 0..._rows){
				_bases[i][j].makeGraphic(_width, _height, BASE_COLOR, true);
				_bases[i][j].x = i * _width;
				_bases[i][j].y = j * _height;
			}
		}
		_tmp.makeGraphic(_width*_cols, _height*_rows, BASE_COLOR);
		_shadow.makeGraphic(_width*_cols, _height*_rows, FlxColor.TRANSPARENT);
	}
}