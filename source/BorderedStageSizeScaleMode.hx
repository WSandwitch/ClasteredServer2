package ;

import flixel.FlxG;
import flixel.system.scaleModes.BaseScaleMode;

class BorderedStageSizeScaleMode extends BaseScaleMode{
	
	private var width:Int;
	private var height:Int;
	private var last_width:Int;
	private var last_height:Int;
	
	public function new(?width:Int, ?height:Int){
		super();
		this.width = width;
		this.height = height;
	}
	
	override public function onMeasure(Width:Int, Height:Int):Void{
		if (Width==0)
			Width = this.last_width;
		else
			this.last_width = Width;
		if (Height==0)
			Height = this.last_height;
		else
			this.last_height = Height;
		
		FlxG.width = (Width > this.width)? this.width : Width;
		FlxG.height = (Height > this.height)? this.height : Height;
		
		scale.set(1, 1);
		FlxG.game.x = 0;
		FlxG.game.y = 0;
		
		if (FlxG.camera != null){
			
			var oldW = FlxG.camera.width;
			var oldH = FlxG.camera.height;
			var screenW:Int = (Width > this.width)? this.width : Width;	
			var screenH:Int = (Height > this.height)? this.height : Height;
			var newW = Math.floor(screenW * FlxG.camera.zoom);
			var newH = Math.floor(screenH * FlxG.camera.zoom);
			if (newW > Width)
				newW = Width;
			if (newH > Height)
				newH = Height;
			FlxG.camera.setSize(newW, newH);
			//FlxG.camera.flashSprite.x += (newW - oldW) / 2;
			//FlxG.camera.flashSprite.y += (newH - oldH) / 2;
			FlxG.game.x = (Width-newW)/2;
			FlxG.game.y = (Height-newH)/2;
		}
	}
}