package lighting;

import flash.display.CapsStyle;
import flash.filters.GlowFilter;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import lighting.FOVSegment;
import openfl.display.BitmapData;
import openfl.filters.BlurFilter;
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
	public var need_update:List<Bool> = new List<Bool>(); //may be it is not good
//	public var need_update:Bool = true;
//	public var another_update:Bool = true;
//	public var next_update:Bool = true;
	public function new(){
		super();
		for (i in 0...4)
			need_update.add(true);
	}
}

class FOV extends FlxSpriteGroup{
	public static inline var BASE_COLOR:Int = 0xEE000000;
	public static inline var FILL_COLOR:Int = 0xEEEEEEEE;
	public static inline var DARK_COLOR:Int = 0x66222222;
	
	public static inline var HALF_VIEW:Int = 30;
	public static inline var HALF_VIEW_DARK:Int = 18;

	public var follow:Null<FlxObject> = null;

	public static var use_blur:Bool = false;// #if flash true #else false #end ;
	private var _tmp:FlxSprite = new FlxSprite();
	private var _base:FlxSprite = new FlxSprite();
	private var _bases:Array<Array<FOVSprite>> = new Array<Array<FOVSprite>>();
	private var _shadow:FlxSprite = new FlxSprite();
	private var _height:Int;
	private var _width:Int;
	private var _vis:Visibility;
	private var _filter:BlurFilter=new BlurFilter(8, 8, 1);
//	private var _filter:GlowFilter = new GlowFilter(BASE_COLOR, 1, 8, 8, 2, 1, false);
	
	
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
		_tmp.makeGraphic(_width * _cols, _height * _rows, BASE_COLOR);

		_shadow.makeGraphic(_width*_cols, _height*_rows, FlxColor.TRANSPARENT);
		//_shadow.blend = openfl.display.BlendMode.SCREEN;
		_vis = vis;
		follow = f;
		
	}
	
	static var _off:Int = 5;
	public static inline var edges:Int = 16;
	
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
			FlxSpriteUtil.fill(_tmp, BASE_COLOR);
			FlxSpriteUtil.fill(_shadow, FlxColor.TRANSPARENT);
//			blend = openfl.display.BlendMode.SCREEN;
//			trace(_vis.output);
	
			if (_vis.output.length > 0){

				var zpoint = new Point(0, 0);
				var points:Array<FlxPoint> = [];
				var screen:Array<FlxPoint> = [
					new FlxPoint(x, y),
					new FlxPoint(x+_tmp.width, y),
					new FlxPoint(x+_tmp.width, y+_tmp.height),
					new FlxPoint(x, y+_tmp.height)
				];
				var halfview = HALF_VIEW; //degrees
				var rad:Float = Math.PI / 180 * (follow.angle);
				var rad30:Float = Math.PI / 180 * (follow.angle-halfview);
				var radm30:Float = Math.PI / 180 * (follow.angle+halfview);
				var l = 10000000;//very very far
				var r = 30;
				var ushift = 23;
				var fx:Float = follow.x-ushift*FlxMath.fastCos(rad);
				var fy:Float = follow.y-ushift*FlxMath.fastSin(rad);
				var rad_shift:Float = Math.PI * 2 / edges;
				var view:Array<FlxPoint> = [
					new FlxPoint(fx, fy),
					new FlxPoint(fx+l*FlxMath.fastCos(rad30), fy+l*FlxMath.fastSin(rad30)),
					new FlxPoint(fx+l*FlxMath.fastCos(radm30), fy+l*FlxMath.fastSin(radm30))
				];
				var circle:Array<FlxPoint> = [for (i in 0...edges) new FlxPoint(follow.x+r*FlxMath.fastCos(rad+i*rad_shift), follow.y+r*FlxMath.fastSin(rad+i*rad_shift))];
				for (p in _vis.output){
					points.push(p);
				}
				var _ppoints:Array<Array<FlxPoint>> = FOVCrosser.getCross(points, FOVCrosser.getCross(screen, FOVCrosser.getUnion(circle, view)[0])[0]);

				if (_ppoints.length > 0){
					//draw dark
					var ppoints:Array<Array<FlxPoint>>=[];
					var halfviewext = HALF_VIEW_DARK;
					if (halfviewext>0){
						var rad30ext:Float = Math.PI / 180 * (follow.angle-halfview-halfviewext);
						var radm30ext:Float = Math.PI / 180 * (follow.angle+halfview+halfviewext);
						var darkview:Array<FlxPoint> = [
							new FlxPoint(fx, fy),
							new FlxPoint(fx+l*FlxMath.fastCos(rad30ext), fy+l*FlxMath.fastSin(rad30ext)),
							new FlxPoint(fx+l*FlxMath.fastCos(radm30ext), fy+l*FlxMath.fastSin(radm30ext))
						];
						ppoints = FOVCrosser.getCross(points, FOVCrosser.getCross(screen, darkview)[0]);
						for (_points in ppoints){
							for (p in _points){
								p.x -= x;
								p.y -= y;
							}
							FlxSpriteUtil.drawPolygon(_shadow, _points, DARK_COLOR, {color: DARK_COLOR, thickness: 3}, {smoothing:true});
						}
					}
					//draw view
					for (_points in _ppoints){
						for (p in _points){
							p.x -= x;
							p.y -= y;
						}
						FlxSpriteUtil.drawPolygon(_shadow, _points, FILL_COLOR, {color: FILL_COLOR, thickness: 3}, {smoothing:true});
					}
				
					/////////
					//////////
	//				blend = openfl.display.BlendMode.MULTIPLY;
					FlxSpriteUtil.alphaMaskFlxSprite(_shadow, _tmp, _tmp);
	//				_tmp.graphic.bitmap.applyFilter(_tmp.graphic.bitmap, _tmp.graphic.bitmap.rect, zpoint, _filter);
						
					var bshift = 8;
					for (i in 0..._cols){
						for (j in 0..._rows){
							var bij = _bases[i][j];
							var nu:Bool = false;
							for (_nu in bij.need_update){
								if (_nu){
									nu = true;
									break;
								}
							}
							bij.need_update.pop();
							
							if ( nu ){
								var bm = bij.graphic.bitmap;
								if (use_blur){
									bij.graphic.bitmap.applyFilter(_tmp.graphic.bitmap, new Rectangle(i * bm.width, j * bm.height, bm.width, bm.height), zpoint, _filter);
								}else{
									bij.graphic.bitmap.copyPixels(_tmp.graphic.bitmap, new Rectangle(i * bm.width, j * bm.height, bm.width, bm.height), zpoint);
								}
								bij.dirty = true;
							}else{
								bij.dirty = false;
							}
							
							var s1 = new FOVSegment(new FlxPoint(i * _width - _off, j * _height - _off), new FlxPoint((i + 1) * _width + _off, (j) * _height - _off));
							var s2 = new FOVSegment(s1.p2, new FlxPoint((i + 1) * _width + _off, (j + 1) * _height + _off));
							var s3 = new FOVSegment(s2.p2, new FlxPoint((i) * _width - _off, (j + 1) * _height + _off));
							var s4 = new FOVSegment(s3.p2, s1.p1);
							var updated = false;
							for (_points in ppoints){
								if (updated)
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
										updated = true;
										break;
									}
								}
							}
							for (_points in _ppoints){
								if (updated)
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
										updated = true;
										break;
									}
								}
							}
							bij.need_update.add(updated);
						}
					}
				}
			} 
			//another way
//			FlxSpriteUtil.drawPolygon(_shadow, _vis.output, BASE_COLOR, {color: BASE_COLOR, thickness: 40});
		}
		super.draw();
	}
	
	static inline var off_mul = 0.17;
	
	public function resize(width:Int, height:Int){
		_width = Math.ceil(width/_cols);
		_height = Math.ceil(height / _rows);
		_off=FlxMath.maxInt(Math.round(_width*off_mul), Math.round(_height*off_mul));//FlxMath.maxFloat
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