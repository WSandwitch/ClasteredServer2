package ;

import flixel.FlxG;
import flixel.system.scaleModes.BaseScaleMode;

class BorderedStageSizeScaleMode extends BaseScaleMode{
	
	public var _scale_val:Float;
	
	public function new(scale:Float = 1){
		super();
		updateScale(scale);
	}
	
	public function updateScale(s:Float){
		_scale_val = s;
		onMeasure(FlxG.width, FlxG.height); 
	}
	
	override 
	public function onMeasure(Width:Int, Height:Int):Void{
		var newW = Math.ceil(Width / _scale_val);
		var newH = Math.ceil(Height / _scale_val); // / FlxG.camera.zoom 
		FlxG.width = newW;
		FlxG.height = newH;
		
		scale.set(_scale_val, _scale_val);
		FlxG.game.x = FlxG.game.y = 0;
		
		if (FlxG.camera != null)
		{
			var oldW = FlxG.camera.width;
			var oldH = FlxG.camera.height;
			
			
			FlxG.camera.setSize(newW, newH);
			FlxG.camera.flashSprite.x += (newW - oldW) / 2;
			FlxG.camera.flashSprite.y += (newH - oldH) / 2;
		}
	}
}