package lighting;

import flixel.math.FlxPoint;
/**
 * ...
 * @author ...
 */

class FOVSegment{
	public var p1:FlxPoint;
	public var p2:FlxPoint;

	static public function getPointOfIntersection(p1:FlxPoint, p2:FlxPoint, p3:FlxPoint, p4:FlxPoint):Null<FlxPoint>{
		try{
			var d:Float = (p1.x - p2.x) * (p4.y - p3.y) - (p1.y - p2.y) * (p4.x - p3.x);
			var da:Float = (p1.x - p3.x) * (p4.y - p3.y) - (p1.y - p3.y) * (p4.x - p3.x);
			var db:Float = (p1.x - p2.x) * (p1.y - p3.y) - (p1.y - p2.y) * (p1.x - p3.x);
			var ta:Float = da / d;
			var tb:Float = db / d;
		 
			if (ta >= 0 && ta <= 1 && tb >= 0 && tb <= 1){
				var dx:Float = p1.x + ta * (p2.x - p1.x);
				var dy:Float = p1.y + ta * (p2.y - p1.y);
		 
				return new FlxPoint(dx, dy);
			}
		}catch(e:Dynamic){}
	 
		return null;
	}

	public function new(_p1:FlxPoint, _p2:FlxPoint){
		p1 = _p1;
		p2 = _p2;
	}
	//math
	public function vector(p:FlxPoint):Float{
		return (p2.x - p1.x) * (p.y - p1.y) - (p2.y - p1.y) * (p.x - p1.x);
	}
	
	public function cross(s:FOVSegment):Bool{
		var v1=vector(s.p1);
		var v2=vector(s.p2);
		if ((v1>=0 && v2<=0) || (v1<=0 && v2>=0)){
			v1=s.vector(p1);
			v2=s.vector(p2);
			if (v1>=0 && v2<=0)
				return true;
			if (v1<=0 && v2>=0)
				return true;
		}
		return false;
	}
	
	public function linesCrossPoint(s:FOVSegment):Null<FlxPoint>{
		return getPointOfIntersection(p1, p2, s.p1, s.p2);
	}
	
}