package util;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;


/**
 * ...
 * @author ...
 */
class CompileTime
{
	
	macro public static function getBuildDate():ExprOf<String> {
		return Context.makeExpr(DateTools.format(Date.now(), "%Y%m%d"), Context.currentPos());
	}
	
}