package lighting;
import flixel.math.FlxPoint;
import clipper.Point;
import clipper.ClipType;
import clipper.Clipper;

/**
 * ...
 * @author ...
 */

class FOVCrosser
{
	private static function _getSmth(in1:Array<FlxPoint>, in2:Array<FlxPoint>, type:Int):Array<Array<FlxPoint>>{
		var poly1:Array<Point> = in1.map(function(p:FlxPoint):Point{return new Point(p.x, p.y);});
		var poly2:Array<Point> = in2.map(function(p:FlxPoint):Point{return new Point(p.x, p.y); });
		var out:Array<Array<Point>> = Clipper.clipPolygon(poly1, poly2, type);
		
		return out.map(function(pp){return pp.map(function(p):FlxPoint{return new FlxPoint(p.x, p.y); });});
	}
	
	public static function getCross(in1:Array<FlxPoint>, in2:Array<FlxPoint>):Array<Array<FlxPoint>>{
		return _getSmth(in1, in2, ClipType.INTERSECTION);
	}
	
	public static function getUnion(in1:Array<FlxPoint>, in2:Array<FlxPoint>):Array<Array<FlxPoint>>{
		return _getSmth(in1, in2, ClipType.UNION);
	}
	
}