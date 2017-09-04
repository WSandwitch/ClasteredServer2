package lighting;

import flash.display.CapsStyle;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import lighting.FOVSegment;
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


class FOVSprite extends FlxSprite{
	public var need_update:Bool = true;
	public var another_update:Bool = true;
	public var next_update:Bool = true;
}

class FOV extends FlxSpriteGroup{
	public var follow:Null<FlxObject> = null;
	public var _tmp:FlxSprite = new FlxSprite();
	public var _base:FlxSprite = new FlxSprite();
	public var _bases:Array<Array<FOVSprite>> = new Array<Array<FOVSprite>>();
	public var _shadow:FlxSprite = new FlxSprite();
	private var _height:Int;
	private var _width:Int;
	private var _vis:Visibility;
	
	public static inline var BASE_COLOR:Int = 0xEE000000;
	public static inline var FILL_COLOR:Int = 0xEEEEEEEE;
	
	private var _rows:Int;
	private var _cols:Int;
	
	private var _segment:Null<Segment>;
	public function new(width:Int, height:Int, vis:Visibility, rows:Int=1, cols:Int=1, ?f:FlxObject){
		super();// "assets/images/lamp.png");
		_rows = rows;
		_cols = cols;
		_width = Math.ceil(width/_cols);
		_height = Math.ceil(height/_rows);
		for (i in 0..._cols){
			_bases.push(new Array<FOVSprite>());
			for (j in 0..._rows){
				var base = new FOVSprite();
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
	
	static inline var off:Int = 5;
	
	override
	public function draw(){//update(elapsed){
		if (follow != null) {
//			reset(FlxG.camera.scroll.x, FlxG.camera.scroll.y); //do not use it on sprite group !!!
			x = FlxG.camera.scroll.x;
			y = FlxG.camera.scroll.y;
			
//			_segment.p1.x = x;
//			_segment.p1.y = y;
//			_segment.p2.x = x+200;
///			_segment.p2.y = y+200;
			//calculate shadows
			_vis.setLightLocation(follow.x, follow.y);
			_vis.sweep();
			
//			_shadow.graphic.bitmap.lock();
//			_shadow.graphic.bitmap.fillRect(new Rectangle(0, 0, width, height), FlxColor.TRANSPARENT);
//			_shadow.graphic.bitmap.unlock();
//			FlxSpriteUtil.fill(this, FlxColor.TRANSPARENT);
			FlxSpriteUtil.fill(_shadow, FlxColor.TRANSPARENT);
//			blend = openfl.display.BlendMode.SCREEN;
			if (_vis.output.length > 0){
				var points:Array<FlxPoint> = [];
				var screen:Array<FlxPoint> = [
					new FlxPoint(x, y),
					new FlxPoint(x+_tmp.width, y),
					new FlxPoint(x+_tmp.width, y+_tmp.height),
					new FlxPoint(x, y+_tmp.height)
				];
				var halfview = 39; //degrees
				var rad:Float = Math.PI / 180 * (follow.angle);
				var rad30:Float = Math.PI / 180 * (follow.angle-halfview);
				var radm30:Float = Math.PI / 180 * (follow.angle+halfview);
				var l = 10000000;//very very far
				var ushift = 21;
				var fx:Float = follow.x-ushift*FlxMath.fastCos(rad);
				var fy:Float = follow.y-ushift*FlxMath.fastSin(rad);
				var view:Array<FlxPoint> = [
					new FlxPoint(fx, fy),
					new FlxPoint(fx+l*FlxMath.fastCos(rad30), fy+l*FlxMath.fastSin(rad30)),
					new FlxPoint(fx + l * FlxMath.fastCos(radm30), fy + l * FlxMath.fastSin(radm30))
				];
				
				for (p in _vis.output){
					points.push(p);
				}
				var ppoints= FOVCrosser.getCross(points, FOVCrosser.getCross(screen, view)[0]);
				
				for (_points in ppoints){
					for (p in _points){
						p.x -= x;
						p.y -= y;
					}
					FlxSpriteUtil.drawPolygon(_shadow, _points, FILL_COLOR, {color: FILL_COLOR, thickness: 3});
				}
//				blend = openfl.display.BlendMode.MULTIPLY;
				FlxSpriteUtil.alphaMaskFlxSprite(_shadow, _tmp, _tmp);
				var zpoint = new Point(0, 0);
				
				for (i in 0..._cols){
					for (j in 0..._rows){
						var bij = _bases[i][j];
						bij.need_update = bij.another_update;
						bij.another_update = bij.next_update;
						bij.next_update = false;

						if (//true ||
							bij.need_update || 
							bij.another_update ||
							bij.next_update
						){
							var bm = bij.graphic.bitmap;
							bij.graphic.bitmap.copyPixels(_tmp.graphic.bitmap, new Rectangle(i * bm.width, j * bm.height, bm.width, bm.height), zpoint);
							bij.dirty = true;
						}else{
							bij.dirty = false;
						}
						
						var s1 = new FOVSegment(new FlxPoint(i * _width - off, j * _height - off), new FlxPoint((i + 1) * _width + off, (j) * _height - off));
						var s2 = new FOVSegment(s1.p2, new FlxPoint((i + 1) * _width + off, (j + 1) * _height + off));
						var s3 = new FOVSegment(s2.p2, new FlxPoint((i) * _width - off, (j + 1) * _height + off));
						var s4 = new FOVSegment(s3.p2, s1.p1);
						for (_points in ppoints){
							if (bij.next_update)
									break;
							for (pi in 0..._points.length){
								var s = new FOVSegment(_points[pi], _points[ pi == _points.length - 1 ? 0 : pi + 1 ]);
								if (
									//( s.p1.x >= 0 && s.p1.x <= _tmp.width ||s.p2.x >= 0 && s.p2.x <= _tmp.width || s.p1.y >= 0 && s.p1.y <= _tmp.height || s.p2.y >= 0 && s.p2.y <= _tmp.height ) && 
									(
										( s1.p1.x<s.p1.x && s2.p2.x>s.p1.x && s1.p1.y<s.p1.y && s2.p2.y>s.p1.y ) || //rather faster 
										( s1.p1.x<s.p2.x && s2.p2.x>s.p2.x && s1.p1.y<s.p2.y && s2.p2.y>s.p2.y ) || 
										s.cross(s1) ||
										s.cross(s2) ||
										s.cross(s3) ||
										s.cross(s4) // add check of in<->out
	//									false
									)
								){
									bij.next_update = true;
									break;
								}
							}
						}
					}
				}
			}
			//another way
//			FlxSpriteUtil.drawPolygon(_shadow, _vis.output, BASE_COLOR, {color: BASE_COLOR, thickness: 40});
		}
		super.draw();
	}
	
	public function resize(width:Int, height:Int){
		_width = Math.ceil(width/_cols);
		_height = Math.ceil(height / _rows);
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