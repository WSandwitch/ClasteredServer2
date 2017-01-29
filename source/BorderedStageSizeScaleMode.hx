package ;

import flixel.FlxG;
import flixel.system.scaleModes.BaseScaleMode;

class BorderedStageSizeScaleMode extends BaseScaleMode{
	
	override public function onMeasure(Width:Int, Height:Int):Void
	{
		FlxG.width = Width;
		FlxG.height = Height;
		
		scale.set(1, 1);
		FlxG.game.x = FlxG.game.y = 0;
		
		if (FlxG.camera != null)
		{
			var oldW = FlxG.camera.width;
			var oldH = FlxG.camera.height;
			
			var newW = Math.ceil(Width / FlxG.camera.zoom);
			var newH = Math.ceil(Height / FlxG.camera.zoom);
			
			FlxG.camera.setSize(newW, newH);
			FlxG.camera.flashSprite.x += (newW - oldW) / 4;
			FlxG.camera.flashSprite.y += (newH - oldH) / 4;
		}
	}
}