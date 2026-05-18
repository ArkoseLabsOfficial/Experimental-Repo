package backend;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.util.FlxSort;
import flixel.math.FlxRect;
import flixel.FlxObject; 
import haxe.xml.Access;
import objects.WorldObject;
import objects.CharacterEntity;
import objects.Player;
import objects.Follower;
import objects.CollisionBlock;

// Ensure your GameState is imported to use GameState.fallbackPlayer
// import states.GameState; 

typedef TresTile = {
    var path:String;
    var rx:Int;
    var ry:Int;
    var solid:Bool;
}

typedef GodotNode = {
    var name:String;
    var type:String;
    var parentPath:String;
    var fullPath:String;
    var props:Map<String, String>;
    var treeIndex:Int;
}

typedef SortData = {
    var sortY:Float;
    var treeIndex:Int;
    var z:Int;
    var isDynamic:Bool;
}

class RoomManager extends FlxTypedGroup<FlxSprite> {
    public static var instance:RoomManager;
    
    public var entities:Map<String, WorldObject>;
    public var characters:Map<String, CharacterEntity>;
    public var solids:FlxTypedGroup<CollisionBlock>; 
    
    public var followers:Array<Follower>;
    public var spawnPoints:Map<String, {x:Float, y:Float, dir:String}>;
    public var roomEvents:Array<{id:String, rect:FlxRect, trigger:String}>;
    
    public var activePlayer:Player;
    public var activeCutscenePlayer:CharacterEntity;
    public var roomZoom:Float = 1.0;

    public var sortMap:Map<FlxSprite, SortData>;

    public function new() {
        super();
        instance = this;
        
        entities = new Map();
        characters = new Map();
        solids = new FlxTypedGroup<CollisionBlock>();
        followers = [];
        spawnPoints = new Map();
        roomEvents = [];
        sortMap = new Map();
    }

    public function loadRoom(filePath:String) {
        if (!openfl.utils.Assets.exists(filePath)) {
            flixel.FlxG.log.warn("Room file not found: " + filePath);
            return;
        }
        var rawData = openfl.utils.Assets.getText(filePath);
        
        if (StringTools.endsWith(filePath, ".tscn")) {
            loadRoomFromTSCN(rawData);
        } else {
            loadRoomFromString(rawData); 
        }
    }

    // ==========================================
    // --- TSCN TO XML EXPORTER UTILITY ---
    // ==========================================
    public function convertTSCN(filePath:String):String {
        if (!openfl.utils.Assets.exists(filePath)) {
            flixel.FlxG.log.warn("Cannot convert. File not found: " + filePath);
            return "";
        }
        var rawTSCN = openfl.utils.Assets.getText(filePath);
        var lines = rawTSCN.split("\n");
        var extResources = new Map<Int, String>();
        
        var nodeTree:Array<GodotNode> = [];
        var nodeDb:Map<String, GodotNode> = new Map();
        var currentNode:GodotNode = null;
        var tIndex = 0;

        var extResReg = ~/\[ext_resource path="res:\/\/(.*?)" .*?id=([0-9]+)\]/;
        var propReg = ~/^([a-zA-Z0-9_]+)\s*=\s*(.*)$/;

        for (line in lines) {
            line = StringTools.trim(line);
            if (line == "") continue;

            if (extResReg.match(line)) {
                extResources.set(Std.parseInt(extResReg.matched(2)), extResReg.matched(1));
            } 
            else if (StringTools.startsWith(line, "[node ")) {
                var nName = extractGodotAttr(line, "name");
                var nType = extractGodotAttr(line, "type");
                var nParent = extractGodotAttr(line, "parent");

                if (nName == "") nName = "unnamed_" + tIndex;
                if (nType == "") nType = "Node";
                if (nParent == "") nParent = "root";

                var fPath = (nParent == "." || nParent == "root") ? nName : nParent + "/" + nName;

                currentNode = {
                    name: nName, type: nType, parentPath: nParent, fullPath: fPath,
                    props: new Map<String, String>(), treeIndex: tIndex++
                };
                
                nodeTree.push(currentNode);
                nodeDb.set(fPath, currentNode);
            } 
            else if (currentNode != null && propReg.match(line)) {
                currentNode.props.set(propReg.matched(1), propReg.matched(2));
            }
        }

        var xml = new StringBuf();
        xml.add('<?xml version="1.0" encoding="utf-8"?>\n');
        xml.add('<room folder="">\n');

        for (node in nodeTree) {
            var pLow = node.parentPath.toLowerCase();
            var nLow = node.name.toLowerCase();
            
            var z:Int = 10;
            if (node.props.exists("z_index")) z = Std.parseInt(node.props.get("z_index"));
            else {
                if (nLow.indexOf("bg") != -1 || pLow.indexOf("background") != -1) z = 0;
                else if (nLow.indexOf("fg") != -1 || pLow.indexOf("foreground") != -1) z = 20;
                else if (nLow.indexOf("lighting") != -1 || pLow.indexOf("lighting") != -1) z = 30;
                else if (node.type == "TileMap") z = -1; 
            }

            var absPos = getAbsolutePosition(node.fullPath, nodeDb);
            var px = absPos.x;
            var py = absPos.y;

            var sx:Float = 1; var sy:Float = 1;
            if (node.props.exists("scale")) {
                var scl = parseGodotVector2(node.props.get("scale"));
                sx = scl.x; sy = scl.y;
            }

            if (node.type == "Sprite" && node.props.exists("texture")) {
                var idStr = extractExtResourceID(node.props.get("texture"));
                var texPath = extResources.get(Std.parseInt(idStr));

                if (texPath != null) {
                    texPath = StringTools.replace(texPath, "assets/", "");
                    texPath = StringTools.replace(texPath, ".png", "");

                    var tempObj = new WorldObject(0, 0, 0, "temp");
                    tempObj.loadEntity("", texPath);
                    tempObj.scale.set(sx, sy);
                    tempObj.updateHitbox();

                    var isCentered = node.props.exists("centered") ? node.props.get("centered") != "false" : true;
                    if (isCentered && tempObj.width > 0 && tempObj.height > 0) {
                        px -= tempObj.width / 2;
                        py -= tempObj.height / 2;
                    }
                    tempObj.destroy();

                    var flipH = node.props.exists("flip_h") && node.props.get("flip_h") == "true";
                    var flipV = node.props.exists("flip_v") && node.props.get("flip_v") == "true";

                    xml.add('    <sprite name="${node.name}" x="${px}" y="${py}" z="${z}" sprite="${texPath}"');
                    if (sx != 1 || sy != 1) {
                        xml.add(' scaleX="${sx}" scaleY="${sy}"');
                    }
                    if (flipH) xml.add(' flipX="true"');
                    if (flipV) xml.add(' flipY="true"');
                    xml.add(' />\n');
                }
            }
            else if (node.type == "TileMap" && node.props.exists("tile_data")) {
                var tsIdStr = extractExtResourceID(node.props.get("tile_set"));
                var tsPath = extResources.get(Std.parseInt(tsIdStr));
                
                var cSize = node.props.exists("cell_size") ? parseGodotVector2(node.props.get("cell_size")) : {x:32.0, y:32.0};
                var layerSolid = node.props.exists("collision_layer") && node.props.get("collision_layer") != "0";

                var rawData = StringTools.replace(node.props.get("tile_data"), "PoolIntArray(", "");
                rawData = StringTools.replace(rawData, ")", "");

                var layerStr = z <= 0 ? "bg" : (z >= 20 ? "fg" : "main");

                xml.add('    <tilemap tileset="${tsPath}" layer="${layerStr}" size="${Std.int(cSize.x)}" collision="${layerSolid}">\n');
                xml.add('        <data>${rawData}</data>\n');
                xml.add('    </tilemap>\n');
            }
            else if (node.parentPath == "Events") {
                var ew:Float = 32; var eh:Float = 32;
                if (node.props.exists("Area")) {
                    var area = parseGodotVector2(node.props.get("Area"));
                    ew = area.x; eh = area.y;
                }
                xml.add('    <event id="${node.name}" x="${px}" y="${py}" width="${ew}" height="${eh}" trigger="touch" />\n');
            }
            else if (node.parentPath == "Points") {
                var dirStr = "down";
                if (node.props.exists("Direction")) {
                    var d = Std.parseInt(node.props.get("Direction"));
                    if (d == 0) dirStr = "up"; else if (d == 1) dirStr = "right";
                    else if (d == 2) dirStr = "down"; else if (d == 3) dirStr = "left";
                }
                xml.add('    <point id="${node.name}" x="${px}" y="${py}" direction="${dirStr}" />\n');
            }
        }
        
        xml.add('</room>');
        return xml.toString();
    }


    // ==========================================
    // --- NATIVE GODOT .TSCN PARSER ---
    // ==========================================
    public function loadRoomFromTSCN(rawTSCN:String) {
        if (rawTSCN == null || rawTSCN == "") return;
        sortMap.clear();
        
        var lines = rawTSCN.split("\n");
        var extResources = new Map<Int, String>();
        
        var nodeTree:Array<GodotNode> = [];
        var nodeDb:Map<String, GodotNode> = new Map();
        var currentNode:GodotNode = null;
        var tIndex = 0;

        var extResReg = ~/\[ext_resource path="res:\/\/(.*?)" .*?id=([0-9]+)\]/;
        var propReg = ~/^([a-zA-Z0-9_]+)\s*=\s*(.*)$/;

        for (line in lines) {
            line = StringTools.trim(line);
            if (line == "") continue;

            if (extResReg.match(line)) {
                extResources.set(Std.parseInt(extResReg.matched(2)), extResReg.matched(1));
            } 
            else if (StringTools.startsWith(line, "[node ")) {
                var nName = extractGodotAttr(line, "name");
                var nType = extractGodotAttr(line, "type");
                var nParent = extractGodotAttr(line, "parent");

                if (nName == "") nName = "unnamed_" + tIndex;
                if (nType == "") nType = "Node";
                if (nParent == "") nParent = "root";

                var fPath = (nParent == "." || nParent == "root") ? nName : nParent + "/" + nName;

                currentNode = {
                    name: nName,
                    type: nType,
                    parentPath: nParent,
                    fullPath: fPath,
                    props: new Map<String, String>(),
                    treeIndex: tIndex++
                };
                
                nodeTree.push(currentNode);
                nodeDb.set(fPath, currentNode);
            } 
            else if (currentNode != null && propReg.match(line)) {
                currentNode.props.set(propReg.matched(1), propReg.matched(2));
            }
        }

        for (node in nodeTree) {
            var pLow = node.parentPath.toLowerCase();
            var nLow = node.name.toLowerCase();
            
            var z:Int = 10;
            if (node.props.exists("z_index")) {
                z = Std.parseInt(node.props.get("z_index"));
            } else {
                if (nLow.indexOf("bg") != -1 || pLow.indexOf("background") != -1) z = 0;
                else if (nLow.indexOf("fg") != -1 || pLow.indexOf("foreground") != -1) z = 20;
                else if (nLow.indexOf("lighting") != -1 || pLow.indexOf("lighting") != -1) z = 30;
                else if (node.type == "TileMap") z = -1; 
            }

            var absPos = getAbsolutePosition(node.fullPath, nodeDb);
            var px = absPos.x;
            var py = absPos.y;

            var sx:Float = 1; var sy:Float = 1;
            if (node.props.exists("scale")) {
                var scl = parseGodotVector2(node.props.get("scale"));
                sx = scl.x; sy = scl.y;
            }

            // SPRITES
            if (node.type == "Sprite" && node.props.exists("texture")) {
                var idStr = extractExtResourceID(node.props.get("texture"));
                var texPath = extResources.get(Std.parseInt(idStr));

                if (texPath != null) {
                    texPath = StringTools.replace(texPath, "assets/", "");
                    texPath = StringTools.replace(texPath, ".png", "");

                    var obj = new WorldObject(px, py, z, node.name);
                    obj.loadEntity("", texPath);
                    obj.scale.set(sx, sy);
                    obj.updateHitbox(); 

                    var isCentered = node.props.exists("centered") ? node.props.get("centered") != "false" : true;
                    if (isCentered && obj.width > 0 && obj.height > 0) {
                        obj.x -= obj.width / 2;
                        obj.y -= obj.height / 2;
                    }

                    if (node.props.exists("flip_h") && node.props.get("flip_h") == "true") obj.flipX = true;
                    if (node.props.exists("flip_v") && node.props.get("flip_v") == "true") obj.flipY = true;

                    addEntity(obj);
                    
                    var calcSortY = getSortY(node.fullPath, nodeDb);
                    sortMap.set(obj, {sortY: calcSortY, treeIndex: node.treeIndex, z: z, isDynamic: false});
                }
            }
            // TILEMAPS
            else if (node.type == "TileMap" && node.props.exists("tile_data")) {
                var tsIdStr = extractExtResourceID(node.props.get("tile_set"));
                var tsPath = extResources.get(Std.parseInt(tsIdStr));
                var tresData = parseTresTileSet(tsPath);
                
                var cSize = node.props.exists("cell_size") ? parseGodotVector2(node.props.get("cell_size")) : {x:32.0, y:32.0};
                var layerSolid = node.props.exists("collision_layer") && node.props.get("collision_layer") != "0";

                var rawData = StringTools.replace(node.props.get("tile_data"), "PoolIntArray(", "");
                rawData = StringTools.replace(rawData, ")", "");
                var tokens = rawData.split(",");

                // Calculate sort base once for the whole tilemap
                var calcSortY = getSortY(node.fullPath, nodeDb);

                var i = 0;
                while (i < tokens.length - 2) {
                    var posStr = StringTools.trim(tokens[i]);
                    if (posStr == "") { i++; continue; } 
                    
                    var pos = Std.parseInt(posStr);
                    var id = Std.parseInt(StringTools.trim(tokens[i+1]));
                    var coord = Std.parseInt(StringTools.trim(tokens[i+2]));
                    
                    var tx = (pos & 0xFFFF); if (tx >= 32768) tx -= 65536;
                    var ty = (pos >> 16) & 0xFFFF; if (ty >= 32768) ty -= 65536;
                    var cx = (coord & 0xFFFF);
                    var cy = (coord >> 16) & 0xFFFF;
                    
                    var tileInfo = tresData.get(id);
                    if (tileInfo != null && tileInfo.path != "") {
                        var tile = new WorldObject(absPos.x + (tx * cSize.x), absPos.y + (ty * cSize.y), z, "tile_" + tx + "_" + ty);
                        if (openfl.utils.Assets.exists(tileInfo.path)) {
                            var graph = flixel.FlxG.bitmap.add(tileInfo.path);
                            var sheetColumns = Std.int(graph.width / cSize.x);
                            tile.loadGraphic(tileInfo.path, true, Std.int(cSize.x), Std.int(cSize.y));
                            var frameX = Std.int(tileInfo.rx / cSize.x) + cx;
                            var frameY = Std.int(tileInfo.ry / cSize.y) + cy;
                            tile.animation.frameIndex = (frameY * sheetColumns) + frameX;
                        }
                        
                        tile.solidCollision = layerSolid && tileInfo.solid;
                        if (tile.solidCollision) {
                            tile.allowCollisions = FlxObject.ANY;
                        } else {
                            tile.allowCollisions = FlxObject.NONE;
                        }
                        tile.immovable = true; 
                        addEntity(tile);
                        
                        // FIX: Add tiles to sort map so they actually sort by Z!
                        sortMap.set(tile, {sortY: calcSortY, treeIndex: node.treeIndex, z: z, isDynamic: false});
                    }
                    i += 3;
                }
            }
            // EVENTS
            else if (node.parentPath == "Events") {
                var ew:Float = 32; var eh:Float = 32;
                if (node.props.exists("Area")) {
                    var area = parseGodotVector2(node.props.get("Area"));
                    ew = area.x; eh = area.y;
                }
                roomEvents.push({ id: node.name, rect: FlxRect.get(px, py, ew, eh), trigger: "touch" });
            }
            // POINTS
            else if (node.parentPath == "Points") {
                var dirStr = "down";
                if (node.props.exists("Direction")) {
                    var d = Std.parseInt(node.props.get("Direction"));
                    if (d == 0) dirStr = "up"; else if (d == 1) dirStr = "right";
                    else if (d == 2) dirStr = "down"; else if (d == 3) dirStr = "left";
                }
                spawnPoints.set(node.name, { x: px, y: py, dir: dirStr });
            }
        }

        var startX:Float = 0;
        var startY:Float = 0;

        var pointList = [for (p in spawnPoints) p];
        if (pointList.length > 0) {
            var selectedPoint = spawnPoints.exists("entrance") ? spawnPoints.get("entrance") : pointList[0];
            startX = selectedPoint.x;
            startY = selectedPoint.y;
        }

        activePlayer = new Player(startX, startY, 10, "player");
        activePlayer.loadEntity("", GameState.fallbackPlayer); 
        
        if (activePlayer.width > 0 && activePlayer.height > 0) {
            activePlayer.x -= activePlayer.width / 2;
            activePlayer.y -= activePlayer.height / 2;
        }

        addEntity(activePlayer);
        characters.set(activePlayer.xmlName, activePlayer);

        sortMap.set(activePlayer, {sortY: 0, treeIndex: 999999, z: 10, isDynamic: true});
    }

    // HELPER: Calculate recursive absolute positioning for Godot children
    function getAbsolutePosition(fullPath:String, db:Map<String, GodotNode>):{x:Float, y:Float} {
        var node = db.get(fullPath);
        if (node == null) return {x:0, y:0};
        
        var px:Float = 0; var py:Float = 0;
        if (node.props.exists("position")) {
            var local = parseGodotVector2(node.props.get("position"));
            px = local.x; py = local.y;
        }

        if (node.parentPath != "." && node.parentPath != "root" && node.parentPath != "") {
            var pPos = getAbsolutePosition(node.parentPath, db);
            px += pPos.x;
            py += pPos.y;
        }
        return {x:px, y:py};
    }

    // HELPER: Forces children to adopt their parent's Y-Sort layer identically
    function getSortY(fullPath:String, db:Map<String, GodotNode>):Float {
        var node = db.get(fullPath);
        if (node == null) return 0.0;
        
        var pLow = node.parentPath.toLowerCase();
        if (pLow == "root" || pLow == "." || pLow == "main" || pLow == "background" || pLow == "foreground" || pLow == "lighting" || pLow.indexOf("bg") != -1 || pLow.indexOf("fg") != -1) {
            return getAbsolutePosition(fullPath, db).y; 
        }
        return getSortY(node.parentPath, db);
    }

    // HELPER: Safe Node Attribute Extractor
    function extractGodotAttr(line:String, attr:String):String {
        var search = attr + '="';
        var idx = line.indexOf(search);
        if (idx == -1) return "";
        idx += search.length;
        var endIdx = line.indexOf('"', idx);
        if (endIdx == -1) return "";
        return line.substring(idx, endIdx);
    }

    function parseGodotVector2(val:String):{x:Float, y:Float} {
        var r = ~/Vector2\(\s*([0-9.-]+),\s*([0-9.-]+)\s*\)/;
        if (r.match(val)) return { x: Std.parseFloat(r.matched(1)), y: Std.parseFloat(r.matched(2)) };
        return {x: 0, y: 0};
    }

    function extractExtResourceID(val:String):String {
        var r = ~/ExtResource\(\s*([0-9]+)\s*\)/;
        if (r.match(val)) return r.matched(1);
        return "-1";
    }

    function parseTresTileSet(tresPath:String):Map<Int, TresTile> {
        var map = new Map<Int, TresTile>();
        if (!openfl.utils.Assets.exists(tresPath)) return map;
        
        var raw = openfl.utils.Assets.getText(tresPath);
        var lines = raw.split("\n");

        var extRes = new Map<Int, String>();
        var extReg = ~/\[ext_resource path="res:\/\/(.*?)" .*?id=([0-9]+)\]/;
        var texReg = ~/([0-9]+)\/texture = ExtResource\(\s*([0-9]+)\s*\)/;
        var regReg = ~/([0-9]+)\/region = Rect2\(\s*([0-9.]+),\s*([0-9.]+),\s*([0-9.]+),\s*([0-9.]+)\s*\)/;
        var shapeReg = ~/([0-9]+)\/shapes\s*=\s*\[(.*)/;

        for (line in lines) {
            if (extReg.match(line)) {
                extRes.set(Std.parseInt(extReg.matched(2)), extReg.matched(1));
            } else if (texReg.match(line)) {
                var tid = Std.parseInt(texReg.matched(1));
                var eid = Std.parseInt(texReg.matched(2));
                if (!map.exists(tid)) map.set(tid, {path:"", rx:0, ry:0, solid:false});
                map.get(tid).path = extRes.get(eid);
            } else if (regReg.match(line)) {
                var tid = Std.parseInt(regReg.matched(1));
                var rx = Std.int(Std.parseFloat(regReg.matched(2)));
                var ry = Std.int(Std.parseFloat(regReg.matched(3)));
                if (!map.exists(tid)) map.set(tid, {path:"", rx:0, ry:0, solid:false});
                map.get(tid).rx = rx;
                map.get(tid).ry = ry;
            } else if (shapeReg.match(line)) {
                var tid = Std.parseInt(shapeReg.matched(1));
                var remainder = StringTools.trim(shapeReg.matched(2));
                if (!map.exists(tid)) map.set(tid, {path:"", rx:0, ry:0, solid:false});
                if (remainder != "]" && remainder != "") map.get(tid).solid = true;
            }
        }
        return map;
    }

    // ==========================================
    // --- CLASSIC XML PARSER ---
    // ==========================================
    public function loadRoomFromString(rawXML:String) {
        if (rawXML == null || rawXML == "") return;
        rawXML = StringTools.replace(rawXML, "<!DOCTYPE lacie-engine-room>", "");
        var parsed = Xml.parse(rawXML).firstElement();
        if (parsed == null) return;
        
        sortMap.clear();
        var xml = new Access(parsed);
        var baseFolder = xml.has.folder ? xml.att.folder : "";
        if (xml.hasNode.camera && xml.node.camera.has.zoom) {
            roomZoom = Std.parseFloat(xml.node.camera.att.zoom);
        }

        var objContainer = xml.hasNode.objects ? xml.node.objects : xml;

        // TILEMAP PARSER RESTORED FOR XML
        if (objContainer.hasNode.tilemap) {
            for (node in objContainer.nodes.tilemap) {
                var tsPath = node.has.tileset ? node.att.tileset : "";
                var size = node.has.size ? Std.parseInt(node.att.size) : 32;
                var solidCollision = node.has.collision ? (node.att.collision == "true") : false;
                var z = getZIndex(node);
                
                var tresData = parseTresTileSet(tsPath);
                var rawData = node.hasNode.data ? node.node.data.innerData : "";
                var tokens = rawData.split(",");
                
                var i = 0;
                while (i < tokens.length - 2) {
                    var posStr = StringTools.trim(tokens[i]);
                    if (posStr == "") { i++; continue; } 
                    
                    var pos = Std.parseInt(posStr);
                    var id = Std.parseInt(StringTools.trim(tokens[i+1]));
                    var coord = Std.parseInt(StringTools.trim(tokens[i+2]));
                    
                    var tx = (pos & 0xFFFF); if (tx >= 32768) tx -= 65536;
                    var ty = (pos >> 16) & 0xFFFF; if (ty >= 32768) ty -= 65536;
                    var cx = (coord & 0xFFFF);
                    var cy = (coord >> 16) & 0xFFFF;
                    
                    var tileInfo = tresData.get(id);
                    if (tileInfo != null && tileInfo.path != "") {
                        var tile = new WorldObject(tx * size, ty * size, z, "tile_" + tx + "_" + ty);
                        
                        if (openfl.utils.Assets.exists(tileInfo.path)) {
                            var graph = flixel.FlxG.bitmap.add(tileInfo.path);
                            var sheetColumns = Std.int(graph.width / size);
                            
                            tile.loadGraphic(tileInfo.path, true, size, size);
                            var frameX = Std.int(tileInfo.rx / size) + cx;
                            var frameY = Std.int(tileInfo.ry / size) + cy;
                            tile.animation.frameIndex = (frameY * sheetColumns) + frameX;
                        }
                        
                        tile.solidCollision = solidCollision;
                        if (tile.solidCollision) tile.allowCollisions = FlxObject.ANY;
                        else tile.allowCollisions = FlxObject.NONE;
                        tile.immovable = true; 
                        addEntity(tile);
                        sortMap.set(tile, {sortY: 0, treeIndex: 0, z: z, isDynamic: false});
                    }
                    i += 3;
                }
            }
        }

        if (objContainer.hasNode.solid) {
            for (node in objContainer.nodes.solid) {
                var sx = node.has.x ? Std.parseFloat(node.att.x) : 0;
                var sy = node.has.y ? Std.parseFloat(node.att.y) : 0;
                var w = node.has.width ? Std.parseInt(node.att.width) : 32;
                var h = node.has.height ? Std.parseInt(node.att.height) : 32;
                solids.add(new CollisionBlock(sx, sy, w, h));
            }
        }

        if (objContainer.hasNode.sprite) {
            for (node in objContainer.nodes.sprite) {
                var z = getZIndex(node);
                var obj = new WorldObject(
                    node.has.x ? Std.parseFloat(node.att.x) : 0, 
                    node.has.y ? Std.parseFloat(node.att.y) : 0, 
                    z, 
                    node.has.name ? node.att.name : "obj"
                );
                var sprPath = node.has.path ? node.att.path : (node.has.sprite ? node.att.sprite : "");
                obj.loadEntity(baseFolder != "" ? "/" + baseFolder : "", sprPath);
                
                if (node.has.collision) obj.solidCollision = node.att.collision == "true";
                parseSharedAttributes(obj, node);
                addEntity(obj);
                
                sortMap.set(obj, {sortY: obj.y + obj.height, treeIndex: 0, z: z, isDynamic: false});
            }
        }

        if (objContainer.hasNode.npc) {
            for (node in objContainer.nodes.npc) {
                var z = getZIndex(node);
                var npc = new CharacterEntity(
                    node.has.x ? Std.parseFloat(node.att.x) : 0, 
                    node.has.y ? Std.parseFloat(node.att.y) : 0, 
                    z, 
                    node.has.name ? node.att.name : "npc"
                );
                var sprPath = node.has.path ? node.att.path : (node.has.sprite ? node.att.sprite : "");
                npc.loadEntity(baseFolder != "" ? "/" + baseFolder : "", sprPath);
                parseSharedAttributes(npc, node);
                addEntity(npc);
                characters.set(npc.xmlName, npc);
                sortMap.set(npc, {sortY: 0, treeIndex: 100, z: z, isDynamic: true});
            }
        }

        if (objContainer.hasNode.cutscenePlayer) {
            for (node in objContainer.nodes.cutscenePlayer) {
                var z = getZIndex(node);
                activeCutscenePlayer = new CharacterEntity(
                    node.has.x ? Std.parseFloat(node.att.x) : 0, 
                    node.has.y ? Std.parseFloat(node.att.y) : 0, 
                    z, 
                    node.has.name ? node.att.name : "cutscene_player"
                );
                var sprPath = node.has.path ? node.att.path : (node.has.sprite ? node.att.sprite : "");
                activeCutscenePlayer.loadEntity(baseFolder != "" ? "/" + baseFolder : "", sprPath);
                parseSharedAttributes(activeCutscenePlayer, node);
                addEntity(activeCutscenePlayer);
                characters.set(activeCutscenePlayer.xmlName, activeCutscenePlayer);
                sortMap.set(activeCutscenePlayer, {sortY: 0, treeIndex: 101, z: z, isDynamic: true});
            }
        }

        if (objContainer.hasNode.player) {
            for (node in objContainer.nodes.player) {
                var z = getZIndex(node);
                activePlayer = new Player(
                    node.has.x ? Std.parseFloat(node.att.x) : 0, 
                    node.has.y ? Std.parseFloat(node.att.y) : 0, 
                    z, 
                    node.has.name ? node.att.name : "player"
                );
                var sprPath = node.has.path ? node.att.path : (node.has.sprite ? node.att.sprite : "");
                activePlayer.loadEntity(baseFolder != "" ? "/" + baseFolder : "", sprPath);
                parseSharedAttributes(activePlayer, node);
                addEntity(activePlayer);
                characters.set(activePlayer.xmlName, activePlayer);
                sortMap.set(activePlayer, {sortY: 0, treeIndex: 102, z: z, isDynamic: true});
            }
        }

        if (objContainer.hasNode.follower) {
            for (node in objContainer.nodes.follower) {
                var z = getZIndex(node);
                var follower = new Follower(
                    node.has.x ? Std.parseFloat(node.att.x) : 0, 
                    node.has.y ? Std.parseFloat(node.att.y) : 0, 
                    z, 
                    node.has.name ? node.att.name : "follower"
                );
                var sprPath = node.has.path ? node.att.path : (node.has.sprite ? node.att.sprite : "");
                follower.loadEntity(baseFolder != "" ? "/" + baseFolder : "", sprPath);
                parseSharedAttributes(follower, node);
                
                if (node.hasNode.target) {
                    var tName = node.node.target.att.name;
                    follower.followDistance = node.node.target.has.distance ? Std.parseInt(node.node.target.att.distance) : 30;
                    
                    if (activePlayer != null && tName == activePlayer.xmlName && activeCutscenePlayer != null) {
                        follower.target = activeCutscenePlayer;
                    } else if (characters.exists(tName)) {
                        follower.target = characters.get(tName);
                    }
                }
                addEntity(follower);
                characters.set(follower.xmlName, follower);
                followers.push(follower); 
                sortMap.set(follower, {sortY: 0, treeIndex: 103, z: z, isDynamic: true});
            }
        }

        if (xml.hasNode.event) {
            for (node in xml.nodes.event) {
                var ex = node.has.x ? Std.parseFloat(node.att.x) : 0;
                var ey = node.has.y ? Std.parseFloat(node.att.y) : 0;
                var ew = node.has.width ? Std.parseFloat(node.att.width) : 32;
                var eh = node.has.height ? Std.parseFloat(node.att.height) : 32;
                roomEvents.push({ 
                    id: node.has.id ? node.att.id : "event", 
                    rect: FlxRect.get(ex, ey, ew, eh), 
                    trigger: node.has.trigger ? node.att.trigger : "touch" 
                });
            }
        }

        if (xml.hasNode.point) {
            for (node in xml.nodes.point) {
                spawnPoints.set(
                    node.has.id ? node.att.id : "spawn", 
                    { 
                        x: node.has.x ? Std.parseFloat(node.att.x) : 0, 
                        y: node.has.y ? Std.parseFloat(node.att.y) : 0, 
                        dir: node.has.direction ? node.att.direction : "down" 
                    }
                );
            }
        }
    }

    function getZIndex(node:Access):Int {
        if (node.has.layer) {
            if (node.att.layer == "bg") return 0;
            if (node.att.layer == "main") return 10;
            if (node.att.layer == "fg") return 20;
        }
        return node.has.z ? Std.parseInt(node.att.z) : 10;
    }

    function addEntity(obj:WorldObject) {
        add(obj);
        entities.set(obj.xmlName, obj);
    }

    function parseSharedAttributes(obj:WorldObject, node:Access) {
        var scrollX = node.has.scrollX ? Std.parseFloat(node.att.scrollX) : 1.0;
        var scrollY = node.has.scrollY ? Std.parseFloat(node.att.scrollY) : 1.0;
        obj.scrollFactor.set(scrollX, scrollY);
        
        if (node.has.flipX) obj.flipX = node.att.flipX == "true";
        if (node.has.flipY) obj.flipY = node.att.flipY == "true";

        if (node.hasNode.scale) {
            obj.scale.set(node.node.scale.has.x ? Std.parseFloat(node.node.scale.att.x) : 1.0, 
                          node.node.scale.has.y ? Std.parseFloat(node.node.scale.att.y) : 1.0);
            obj.updateHitbox();
        }
        
        if (node.hasNode.visibility) {
            obj.visible = node.node.visibility.has.visible ? (node.node.visibility.att.visible == "true") : true;
            if (node.node.visibility.has.alpha) obj.alpha = Std.parseFloat(node.node.visibility.att.alpha);
        }

        if (node.hasNode.interaction) {
            obj.interactable = node.node.interaction.has.interactable ? (node.node.interaction.att.interactable == "true") : false;
            if (node.node.interaction.has.dialog) obj.dialogPath = node.node.interaction.att.dialog;
        }

        var firstAnim:String = null;
        if (node.hasNode.anim) {
            for (animNode in node.nodes.anim) {
                if (firstAnim == null) firstAnim = animNode.att.name;
                var loop = animNode.has.loop ? animNode.att.loop == "true" : false;
                var fps = animNode.has.fps ? Std.parseInt(animNode.att.fps) : 12;
                obj.addAnim(animNode.att.name, animNode.att.anim, fps, loop);
            }
        }

        if (firstAnim != null) obj.animation.play(firstAnim);
    }

    // ==========================================
    // --- ULTIMATE Y-SORT FIX ---
    // ==========================================
    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (activeCutscenePlayer != null && activePlayer != null) {
            activePlayer.visible = false;
            activePlayer.x = activeCutscenePlayer.x;
            activePlayer.y = activeCutscenePlayer.y;
            activePlayer.canMove = false;
        }

        sort(function(order:Int, obj1:FlxSprite, obj2:FlxSprite):Int {
            var d1 = sortMap.get(obj1);
            var d2 = sortMap.get(obj2);
            
            // Smarter fallback: Read actual object Z if it missed the sort map
            var z1 = (d1 != null) ? d1.z : (Std.isOfType(obj1, WorldObject) ? cast(obj1, WorldObject).z : 10);
            var z2 = (d2 != null) ? d2.z : (Std.isOfType(obj2, WorldObject) ? cast(obj2, WorldObject).z : 10);
            
            if (z1 != z2) {
                return FlxSort.byValues(order, z1, z2);
            }
            
            if (d1 != null && d2 != null) {
                var sy1 = d1.isDynamic ? (obj1.y + obj1.height) : d1.sortY;
                var sy2 = d2.isDynamic ? (obj2.y + obj2.height) : d2.sortY;

                if (sy1 == sy2) {
                    return FlxSort.byValues(order, d1.treeIndex, d2.treeIndex);
                }
                
                return FlxSort.byValues(order, sy1, sy2);
            }
            
            return FlxSort.byY(order, obj1, obj2);
        });
    }
}