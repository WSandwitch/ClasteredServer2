package ;

import flixel.FlxG;
import flixel.system.scaleModes.BaseScaleMode;

class BorderedStageSizeScaleMode extends BaseScaleMode{
	
	public var _scale_val:Float;
	
	public function new(scale:Float = 1){
		super();
		_scale_val = scale;
	}
	
	override public function onMeasure(Width:Int, Height:Int):Void
	{
		FlxG.width = Width;
		FlxG.height = Height;
		
		scale.set(_scale_val, _scale_val);
		FlxG.game.x = FlxG.game.y = 0;
		
		if (FlxG.camera != null)
		{
			var oldW = FlxG.camera.width;
			var oldH = FlxG.camera.height;
			
			var newW = Math.ceil(Width / FlxG.camera.zoom / _scale_val);
			var newH = Math.ceil(Height / FlxG.camera.zoom / _scale_val);
			
			FlxG.camera.setSize(newW, newH);
			FlxG.camera.flashSprite.x += (newW - oldW) / 2;
			FlxG.camera.flashSprite.y += (newH - oldH) / 2;
		}
	}
}