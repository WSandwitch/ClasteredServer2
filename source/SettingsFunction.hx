package ;

import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ...
 * @author ...
 */

class SettingsFunction {
	 public static function build(fieldName:String, value:Dynamic):Array<Field> {
		// get existing fields from the context from where build() is called
		var fields = Context.getBuildFields();
		
		var pos = Context.currentPos();
		
		var myFuncGet:Function = { 
			expr: macro{ 
				var a:Null<Dynamic> = save.data.$fieldName;
				if (a == null)
					a = $value;
				return a; 
			},  // actual value
			ret: (macro:Dynamic), // ret = return type
			args:[] // no arguments here
		}
		
		var myFuncSet:Function = { 
		  expr: macro{ 
			save.data.$fieldName = val;
			save.flush();
			return val;
		  },  // actual value
		  ret: myFuncGet.ret, // ret = return type
		  args:[{ name:'val', type:null }] 
		}
		
		// create: `public var $fieldName(get,null)`
		var propertyField:Field = {
		  name:  fieldName,
		  access: [Access.APublic, Access.AStatic],
		  kind: FieldType.FProp("get", "set", myFuncGet.ret), 
		  pos: pos,
		};
		
		// create: `private inline function get_$fieldName() return $value`
		var getterField:Field = {
		  name: "get_" + fieldName,
		  access: [Access.APrivate, Access.AInline, Access.AStatic],
		  kind: FieldType.FFun(myFuncGet),
		  pos: pos,
		};
		
		var setterField:Field = {
		  name: "set_" + fieldName,
		  access: [Access.APrivate, Access.AInline, Access.AStatic],
		  kind: FieldType.FFun(myFuncSet),
		  pos: pos,
		};
		
		// append both fields
		fields.push(propertyField);
		fields.push(getterField);
		fields.push(setterField);
		
		return fields;
	 }
}
 