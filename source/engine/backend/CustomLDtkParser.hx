package engine.backend;

import haxe.Json;
import flixel.FlxG;
import StringTools;

class CustomLDtkParser {
    
    // Call this to load a specific room like "RoomMain" or "Room1"
    public static function loadRoom(jsonString:String, levelName:String, zIndex:Int = 0) {
        var data:Dynamic = Json.parse(jsonString);
        
        if (data == null || data.levels == null) {
            FlxG.log.warn("Invalid LDtk JSON data.");
            return;
        }

        var levels:Array<Dynamic> = cast data.levels;
        var targetLevel:Dynamic = null;

        // Find the specific level by its identifier
        for (lvl in levels) {
            if (Std.string(lvl.identifier) == levelName) {
                targetLevel = lvl;
                break;
            }
        }

        if (targetLevel == null) {
            FlxG.log.warn("Level not found: " + levelName);
            return;
        }

        var layerInstances:Array<Dynamic> = cast targetLevel.layerInstances;
        if (layerInstances == null) return;

        // LDtk layers are listed Top-to-Bottom. 
        // We iterate backwards to render them Bottom-to-Top.
        var i:Int = layerInstances.length - 1;
        while (i >= 0) {
            var layer:Dynamic = layerInstances[i];
            var layerType:String = Std.string(layer.__type);
            var layerId:String = Std.string(layer.__identifier);

            if (layerType == "Tiles") {
                parseTiles(layer, zIndex);
            } else if (layerType == "IntGrid") {
                parseIntGrid(layer, zIndex);
            } else if (layerType == "Entities") {
                parseEntities(layer, zIndex);
            }
            i--;
        }
    }

    private static function parseTiles(layer:Dynamic, zIndex:Int) {
        if (layer.gridTiles == null && layer.autoLayerTiles == null) return;

        var gridSize:Int = Std.int(layer.__gridSize);
        var rawPath:String = Std.string(layer.__tilesetRelPath);
        
        if (rawPath == "null" || rawPath == "") return;

        // Strip out the absolute LDtk project path to match your asset directory
        var tsPath:String = StringTools.replace(rawPath, "Projeler/Paper-Lily-Mobile/assets/", "");
        tsPath = StringTools.replace(tsPath, ".png", "");
        
        // Grab either auto-tiles or standard grid tiles depending on the layer type
        var autoTiles:Array<Dynamic> = cast layer.autoLayerTiles;
        var gridTiles:Array<Dynamic> = cast layer.gridTiles;
        var tilesToRender:Array<Dynamic> = (autoTiles != null && autoTiles.length > 0) ? autoTiles : gridTiles;

        if (tilesToRender == null) return;

        for (tile in tilesToRender) {
            var px:Array<Dynamic> = cast tile.px;
            var src:Array<Dynamic> = cast tile.src;
            
            var rx:Float = cast px[0];
            var ry:Float = cast px[1];
            var srcX:Float = cast src[0];
            var srcY:Float = cast src[1];

            var tileObj = new WorldObject(rx, ry, zIndex, "tile_" + rx + "_" + ry);

            if (LilyAssets.fileExists(tsPath)) {
                var graph = FlxG.bitmap.add(tsPath);
                var sheetColumns = Std.int(graph.width / gridSize);

                tileObj.loadGraphic(tsPath, true, gridSize, gridSize);
                var frameX = Std.int(srcX / gridSize);
                var frameY = Std.int(srcY / gridSize);
                tileObj.animation.frameIndex = (frameY * sheetColumns) + frameX;
            }

            tileObj.solidCollision = false; 
            tileObj.immovable = true;

            // Hook back into your existing RoomManager/State logic here
            // e.g., addEntity(tileObj);
            // e.g., sortMap.set(tileObj, {sortY: 0, treeIndex: 0, z: zIndex, isDynamic: false});
        }
    }

    private static function parseIntGrid(layer:Dynamic, zIndex:Int) {
        if (layer.intGridCsv == null) return;

        var csv:Array<Dynamic> = cast layer.intGridCsv;
        var cWid:Int = Std.int(layer.__cWid);
        var gridSize:Int = Std.int(layer.__gridSize);

        for (i in 0...csv.length) {
            var value:Int = cast csv[i];
            
            // In LDtk, 0 usually means empty space, values > 0 are collisions/data
            if (value > 0) {
                var gridX:Int = i % cWid;
                var gridY:Int = Std.int(i / cWid);
                
                var px:Float = gridX * gridSize;
                var py:Float = gridY * gridSize;

                // Create collision blocks here
                // var block = new FlxObject(px, py, gridSize, gridSize);
                // block.immovable = true;
                // addCollision(block);
            }
        }
    }

    private static function parseEntities(layer:Dynamic, zIndex:Int) {
        if (layer.entityInstances == null) return;

        var entities:Array<Dynamic> = cast layer.entityInstances;

        for (entity in entities) {
            var px:Array<Dynamic> = cast entity.px;
            var ex:Float = cast px[0];
            var ey:Float = cast px[1];
            var id:String = Std.string(entity.__identifier);
            var iid:String = Std.string(entity.iid);

            var obj = new WorldObject(ex, ey, zIndex, iid);

            // Access custom fields (like strings, booleans defined in LDtk)
            var fieldInstances:Array<Dynamic> = cast entity.fieldInstances;
            if (fieldInstances != null) {
                for (field in fieldInstances) {
                    var fieldId:String = Std.string(field.__identifier);
                    var fieldValue:Dynamic = field.__value;
                    // Apply field values to obj here
                }
            }

            // e.g., addEntity(obj);
        }
    }
}