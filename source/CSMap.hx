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
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxColor;
import haxe.Timer;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Path;
import haxe.zip.Reader;
import util.CSAssets;

import lighting.FOV;
import lighting.Visibility;

/**
 * 
 */
class CSMap extends FlxGroup{
	
	public var tilemap:FlxTilemap = new FlxTilemap();
	public var vis:Visibility = new Visibility();
	public var fov:FOV;
	
	private var _map_ids:Map<Int,String> = new Map<Int,String>(); 
	private var _npcs:Map<Int,Null<Npc>> = new Map<Int,Null<Npc>>(); 
	private var _npcs_group:FlxSpriteGroup = new FlxSpriteGroup();
	private var _current_id:Int=0;
	private var _loaded:Bool=false;
	private var _in_progress:Bool=false;
	
	public var _tile:Null<Int->Void>;
	public var _imageSource:Null<Int->Void>;
	
	public function new(){
		super();
		add(tilemap);
		add(_npcs_group);
		fov = new FOV(FlxG.width, FlxG.height, vis, 6, 6);
		add(fov);
	}
	
	public function set_current(id: Int){
		_current_id = id;
		_loaded = false;
	}
	
	public function set_map(id:Int, name:String){
		_map_ids.set(id, name);
	}
	
	public function load(id:Int){
		if (_in_progress)
			return;
		vis.clear();
		
		var map = _map_ids.get(id);
		if (map == null)//TODO:remove
			map = "map";
			
		var parser=function(tiledmap:Null<TiledMap>){
			try{
				
				FlxG.camera.setScrollBoundsRect(0, 0, tiledmap.fullWidth, tiledmap.fullHeight, true);
				
				var fr:Array<BitmapData> = [];
				
				var tiles:Null<TiledTileLayer> = cast tiledmap.getLayer("tiles");
				if (tiles != null){
					var bm_blank:BitmapData = new BitmapData(tiledmap.tileWidth, tiledmap.tileHeight);
					var gid = 1;
					var size = tiledmap.tilesetArray.length;
					_tile = function(i:Int){
						if (i >= size){
							tilemap.loadMapFromArray(
								tiles.tileArray, 
								tiledmap.width, 
								tiledmap.height, 
								FlxTileFrames.combineTileSets(fr, new FlxPoint(tiledmap.tileWidth, tiledmap.tileHeight)), 
								tiledmap.tileWidth, 
								tiledmap.tileHeight, 
								OFF, 1, 1, 1
							);
							_loaded = true;
							_in_progress = false;
							return;
						}
						var ts = tiledmap.tilesetArray[i];
		//				trace(gid, ts.firstGID);
						if (gid < ts.firstGID){
							for (i in 0...(ts.firstGID - gid))
								fr.push(bm_blank); //fill missed tile images
						}
						if (ts.tileImagesSources == null){
							CSAssets.getBitmapData((~/(assetsExt|assetsInt)/g).replace((~/^(..\/)+/).replace(ts.imageSource,""),"assets"), function (bitmap:Null<BitmapData>){
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
								_tile(i+1);
							});
						}else{
							var tsize = ts.tileImagesSources.length;
							_imageSource=function (ti:Int){
								if (ti >= tsize){
									_tile(i+1);
									return;
								}
								var t = ts.tileImagesSources[ti];
								if (t!=null){
									CSAssets.getBitmapData(StringTools.replace((~/^(..\/)+/).replace(t.source,""),"assetsExt","assets"), function(bitmap:Null<BitmapData>){
										if (bitmap == null)
											bitmap = bm_blank;
										fr.push(bitmap);
										gid++;
										_imageSource(ti+1);
									});
								}else{
									fr.push(bm_blank);
									gid++;
									haxe.Timer.delay(_imageSource.bind(ti+1), 1);
								}
							};
							_imageSource(0);
						}
					};
					_tile(0);
					_in_progress = true;
				}
				var obj_layer:Null<TiledObjectLayer> = cast tiledmap.getLayer("shadows");
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
			}catch(e:Dynamic){
				trace(e);
			}
		}
		
		CSAssets.getBytes("assets/maps/" + map + ".zip", function(b:Null<Bytes>){
			try{
				var _entries = Reader.readZip(new BytesInput(b));
			
				for(_entry in _entries) {
			
					var fileName = _entry.fileName;
					if (fileName==map+".tmx" || fileName=="map.tmx") {
						parser(new TiledMap(Xml.parse(haxe.zip.Reader.unzip(_entry).toString())));
						return;
					}
				}
				throw "zip file assets/maps/" + map + ".zip not valid";
			}catch(e:Dynamic){
				trace(e);
				CSAssets.getText("assets/maps/"+map+".tmx", function(b:Null<String>){
					parser(new TiledMap(Xml.parse(b)));
				});
			}
		});
		_in_progress = true;
	}
	
	override
	public function update(e){
		super.update(e);
		if (!_loaded)
			load(_current_id);
	}
	
	public function resize(w:Int, h:Int){
		fov.resize(w, h);
	}
	
	public function set_npc(id:Int, n:Npc){
		_npcs.set(id, n);
		_npcs_group.add(n);
	}

	public function get_npc(id:Int):Null<Npc>{
		return _npcs.get(id);
	}

	public function remove_npc(id:Int, clear:Bool=true):Null<Npc>{
		var n:Null<Npc> = get_npc(id);
		if (n != null){
			//n.shown(false);
			if (clear){
				_npcs_group.remove(n);// , true);
				_npcs.remove(id);
			}
		}
		return n;
	}
}


/* //async sync example

var urls = [
  "//ru.stackoverflow.com/",
  "//meta.ru.stackoverflow.com/",
  "//ru.stackoverflow.com/q/619018/178988"
];

(function go(i) {
  if (i < urls.length) {
    fetch(urls[i], {mode:'no-cors'}).then(function () {
      console.log(urls[i]);
      go(i+1);
    })
  }
})(0);


*/