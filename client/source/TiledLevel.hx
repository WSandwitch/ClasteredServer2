package;

import flash.display.BitmapData;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.editors.tiled.TiledImageLayer;
import flixel.addons.editors.tiled.TiledImageTile;
import flixel.addons.editors.tiled.TiledLayer.TiledLayerType;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledTileSet;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import haxe.io.Path;
import openfl.Assets;

/**
 * @author Samuel Batista
 */
class TiledLevel extends FlxTilemap{
		
	public function new()
	{
		super();
		var tiledmap:TiledMap = new TiledMap("assets/map.tmx");

		FlxG.camera.setScrollBoundsRect(0, 0, tiledmap.fullWidth, tiledmap.fullHeight, true);
		
		var fr:Array<BitmapData> = [];
		
		var tiles:Null<TiledTileLayer> = cast tiledmap.getLayer("tiles");
		if (tiles != null){
			for(ts in tiledmap.tilesetArray){
				if (ts.tileImagesSources == null){
					fr.push(Assets.getBitmapData(ts.imageSource));
				}else{
					for (t in ts.tileImagesSources){
						if (t != null){
							fr.push(Assets.getBitmapData(t.source));
						}
					}
				}
			}
			loadMapFromArray(
				tiles.tileArray, 
				tiledmap.width, 
				tiledmap.height, 
				FlxTileFrames.combineTileSets(fr, new FlxPoint(tiledmap.tileWidth, tiledmap.tileHeight)), 
				tiledmap.tileWidth, 
				tiledmap.tileHeight, 
				OFF, 1, 1, 1
			);
		}
		
	}
	
}