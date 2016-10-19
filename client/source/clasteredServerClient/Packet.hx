package clasteredServerClient;


class Chank{
	public var type:Int;
	public var i:Null<Int>=null;
	public var f:Null<Float>=null;
	public var s:Null<String>=null;
	
	public function new(id){
		type=id;
	}
}

class Packet{
	
	public var chanks:Array<Chank>;
	public var type:Int;
	public var size:Int;
	
	public function new(){
		init();
	}
	
	public function init():Void{
		chanks = [];
		size = 0;
	}
	
	public function addChar(a:Int):Void{
		var c:Chank=new Chank(1);
		c.i=a;
		chanks.push(c);
		size+= 2;
	}
	
	public function addShort(a:Int):Void{
		var c:Chank=new Chank(2);
		c.i=a;
		chanks.push(c);
		size+= 3;
	}
	
	public function addInt(a:Int):Void{
		var c:Chank=new Chank(3);
		c.i=a;
		chanks.push(c);
		size+= 5;
	}
	
	public function addFloat(a:Float):Void{
		var c:Chank=new Chank(4);
		c.f=a;
		chanks.push(c);
		size+= 5;
	}
	
	public function addDouble(a:Float):Void{
		var c:Chank=new Chank(5);
		c.f=a;
		chanks.push(c);
		size+= 9;
	}
	
	public function addString(a:String):Void{
		var c:Chank=new Chank(6);
		c.s=a;
		chanks.push(c);
		size+= 1+2+a.length;
	}
	
}