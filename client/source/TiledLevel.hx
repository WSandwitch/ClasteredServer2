package;

import flash.display.BitmapData;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.editors.tiled.TiledImageLayer;
import flixel.addons.editors.tiled.TiledImageTile;
import flixel.addons.editors.tiled.TiledLayer;
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
import flixel.util.FlxSpriteUtil;
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
			var bm_blank:BitmapData = new BitmapData(tiledmap.tileWidth, tiledmap.tileHeight);
			var gid = 1;
			for (ts in tiledmap.tilesetArray){
				trace(gid, ts.firstGID);
				if (gid < ts.firstGID){
					for (i in 0...(ts.firstGID - gid))
						fr.push(bm_blank); //fill missed tile images
				}
				if (ts.tileImagesSources == null){
					var bitmap:Null<BitmapData> = Assets.getBitmapData(ts.imageSource);
					if (bitmap == null){
						bitmap = bm_blank;
						for (i in 1...ts.numTiles)
							fr.push(bitmap);
					}else{
						var tilenum = Math.floor(bitmap.width / ts.tileWidth) * Math.floor(bitmap.height / ts.tileHeight);
						if (tilenum < ts.numTiles){
							for (i in 1...(ts.numTiles-tilenum))
								fr.push(bm_blank);
						}else if (tilenum < ts.numTiles){
							trace("wrong size of tileset " + ts.imageSource);
							//TODO: add crop
						}
					}
					fr.push(bitmap);
					gid += ts.numTiles;
				}else{
					for (t in ts.tileImagesSources){
						if (t != null){
							var bitmap:Null<BitmapData> = Assets.getBitmapData(t.source);
							if (bitmap == null)
								bitmap = bm_blank;
							fr.push(bitmap);
							gid++;
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