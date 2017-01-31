package;

import flash.display.BitmapData;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
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
import flixel.util.FlxColor;
import haxe.io.Path;
import util.CSAssets;

import lighting.FOV;
import lighting.Visibility;

/**
 * 
 */
class CSMap extends FlxGroup{
	
	public var tilemap:FlxTilemap;
	public var vis:Visibility = new Visibility();
	public var fov:FOV;
	
	private var _fovCamera:FlxCamera; 
	private var _npcs:Map<Int,Null<Npc>> = new Map<Int,Null<Npc>>(); 
	private var _npcs_group:FlxGroup = new FlxGroup();
	
	public function new(?map:String)
	{
		super();
		tilemap = new FlxTilemap();
		add(tilemap);
		add(_npcs_group);
		fov = new FOV(FlxG.width, FlxG.height, vis);
		_fovCamera = new FlxCamera(0, 0, Std.int(fov.width), Std.int(fov.height));
		_fovCamera.bgColor = FlxColor.TRANSPARENT;
		_fovCamera.follow(fov, FlxCameraFollowStyle.NO_DEAD_ZONE);
		FlxG.cameras.add(_fovCamera);
		fov.x =-100000; //move outside of screen
		add(fov);
		if (map == null)
			map = "assets/maps/map.tmx";
			
		var tiledmap:TiledMap = new TiledMap(map);

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
					var bitmap:Null<BitmapData> = CSAssets.getBitmapData((~/^(..\/)+/).replace(ts.imageSource,""));
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
							var bitmap:Null<BitmapData> = CSAssets.getBitmapData((~/^(..\/)+/).replace(t.source,""));
							if (bitmap == null)
								bitmap = bm_blank;
							fr.push(bitmap);
							gid++;
						}
					}
				}
			}
			tilemap.loadMapFromArray(
				tiles.tileArray, 
				tiledmap.width, 
				tiledmap.height, 
				FlxTileFrames.combineTileSets(fr, new FlxPoint(tiledmap.tileWidth, tiledmap.tileHeight)), 
				tiledmap.tileWidth, 
				tiledmap.tileHeight, 
				OFF, 1, 1, 1
			);
			
		}
		var obj_layer:Null<TiledObjectLayer> = cast tiledmap.getLayer("collision");
		if (obj_layer != null){
			for (o in obj_layer.objects){	
				for (i in 0...o.points.length-1){
					var p1 = o.points[i];
					var p2 = o.points[i+1];
					vis.addSegment(o.x+p1.x, o.y+p1.y, o.x+p2.x, o.y+p2.y);
				}
				if (o.points.length>1 && o.objectType == TiledObject.POLYGON){
					var p1 = o.points[o.points.length-1];
					var p2 = o.points[0];
					vis.addSegment(o.x+p1.x, o.y+p1.y, o.x+p2.x, o.y+p2.y);
				}
			}
		}
		
	}
	
	override
	public function update(e){
		super.update(e);
	}
	
	public function resize(w:Int, h:Int){
		fov.resize(w, h);
		_fovCamera.setSize(w, h);
	}
	
	public function set_npc(id:Int, n:Npc){
		_npcs.set(id, n);
		_npcs_group.add(n);
	}

	public function get_npc(id:Int):Npc{
		return _npcs.get(id);
	}

	public function remove_npc(id:Int){
		var n:Null<Npc> = get_npc(id);
		_npcs_group.remove(n);
		_npcs.remove(id);
	}
}