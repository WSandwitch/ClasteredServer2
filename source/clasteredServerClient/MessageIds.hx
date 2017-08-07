package clasteredServerClient;

import util.CSAssets;

class MessageIds{
	
	static public function build(?obj:Dynamic){
		var arr = getPairs();
		for (e in arr){
			try{
				var val = Std.parseInt(e[1]);
				Reflect.setProperty(obj, e[0], val);
			}catch(e:Dynamic){
				trace(e);
			}
		}
	}
	
	static function getPairs(){
		var data = loadFileAsString("assets/messages.h");
		
		var regexp:EReg = ~/define[ ]+[A-Z_]+[ ]+[0-9]+/;

		var index = 0;
		var input = data;
		var out=[];
		while (regexp.match(input)) {
			var elems=(~/ +/g).split(regexp.matched(index));
			out.push([elems[1], elems[2]]);
			input = regexp.matchedRight();
		}
		return out;
	}
	
	static function loadFileAsString(path:String) {
		return CSAssets.getText(path);
	}
}