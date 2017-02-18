package;

import util.CSAssets;
import yaml.Yaml;
import yaml.Parser;

/**
 * ...
 * @author ...
 */
class CSObjects
{

	static public var all:Map<Int, Dynamic> = new Map<Int, Dynamic>();
	
	static public inline function get(key:Int):Null<Dynamic> {
		return all.get(key);
	}
	
	static public inline function set(k:Int, v:Dynamic):Dynamic {
		all.set(k, v);	
		return v;
	}
	
	static public function init(){
		var data:String = CSAssets.getText("assets/data/objects.yml");
		var raw:Array<Dynamic> = cast Yaml.parse(data, Parser.options().useObjects());
		for (o in raw){
			set(o.id, o);
		}
	}
	
}