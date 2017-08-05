package clasteredServerClient;

import haxe.macro.Context;
import haxe.macro.Expr;

class MessageIds{
	
	macro static public function build():Array<Field> {
		var fields = Context.getBuildFields();
		var arr = getPairs();
		for (e in arr){
			var val = Std.parseInt(e[1]);
			var newField = {
			  name: "_"+e[0],
			  doc: null,
			  meta: [],
			  access: [AStatic, APublic],
			  kind: FVar(macro : Int, Context.makeExpr(val, Context.currentPos())),
			  pos: Context.currentPos()
			};
			fields.push(newField);
		}
		return fields;
	}
	
	static function getPairs(){
		var data = loadFileAsString("src/share/messages.h");
		
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
		try {
			var p = Context.resolvePath(path);
			Context.registerModuleDependency(Context.getLocalModule(),p);
			
			return sys.io.File.getContent(p);
		}
		catch(e:Dynamic) {
			return haxe.macro.Context.error('Failed to load file $path: $e', Context.currentPos());
		}
	}
}