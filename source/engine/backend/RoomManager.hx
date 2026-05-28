package engine.backend;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.util.FlxSort;
import flixel.math.FlxRect;
import flixel.FlxObject; 
import haxe.xml.Access;
import engine.objects.WorldObject;
import engine.objects.CharacterEntity;
import engine.objects.Player;
import engine.objects.Follower;
import engine.objects.CollisionBlock;

typedef TresTile = { var path:String; var rx:Int; var ry:Int; var solid:Bool; }
typedef SortData = { var sortY:Float; var treeIndex:Int; var z:Int; var isDynamic:Bool; }

class RoomManager extends FlxTypedGroup<FlxSprite> {
    public static var instance:RoomManager;
    public static var currentRoomName:String;
    
    public var entities:Map<String, WorldObject>;
    public var characters:Map<String, CharacterEntity>;
    public var solids:FlxTypedGroup<CollisionBlock>; 
    public var partyMembers:Array<Follower>;
    public var spawnPoints:Map<String, {x:Float, y:Float, dir:String}>;
    public var roomEvents:Array<{id:String, rect:FlxRect, trigger:String}>;
    public var sortMap:Map<FlxSprite, SortData>;
    
    public var activePlayer:Player;
    public var activeCutscenePlayer:CharacterEntity;
    
    public var roomZoom:Float = 1.0;
    public var scripts:ScriptHandler;
    public var mainState:Dynamic = null;

    public function new(?mainState:Dynamic) {
        super();
        instance = this;
        
        entities = new Map();
        characters = new Map();
        solids = new FlxTypedGroup<CollisionBlock>();
        partyMembers = [];
        spawnPoints = new Map();
        roomEvents = [];
        sortMap = new Map();
        scripts = new ScriptHandler();
        this.mainState = mainState;
    }

    public function loadRoom(filePath:String) {
        if (!LilyAssets.fileExists("rooms/" + filePath + ".xml")) {
            flixel.FlxG.log.warn("Room file not found: " + filePath);
            return;
        }
        
        var rawData = LilyAssets.getTextFromFile("rooms/" + filePath + ".xml");
        loadRoomFromString(rawData); 

        var autoScriptPath = filePath.substr(0, filePath.lastIndexOf(".")) + ".hx";
        if (LilyAssets.fileExists(autoScriptPath)) {
            scripts.loadScript(autoScriptPath);
        }

        injectScriptVariables();
        if (scripts != null) scripts.call("create");
    }

    public function getPartyMember(index:Int):CharacterEntity {
        if (index == 0) return activePlayer;
        if (index > 0 && index <= partyMembers.length) return partyMembers[index - 1];
        return null;
    }

    public function spawnParty(px:Float, py:Float, pz:Int, ?node:Access) {
        var party = SaveManager.currentParty;
        if (party == null || party.length == 0) party = ["lacie"];

        // Cleanup existing party
        if (activePlayer != null) {
            remove(activePlayer);
            entities.remove(activePlayer.xmlName);
            characters.remove(activePlayer.xmlName);
            sortMap.remove(activePlayer);
        }
        for (f in partyMembers) {
            remove(f);
            entities.remove(f.xmlName);
            characters.remove(f.xmlName);
            sortMap.remove(f);
        }
        partyMembers = [];

        // Spawn Main Player
        activePlayer = new Player(px, py, pz, node != null && node.has.name ? node.att.name : "player");
        activePlayer.loadEntity("", "characters/" + party[0]);
        if (node != null) parseSharedAttributes(activePlayer, node);
        
        addEntity(activePlayer);
        characters.set(activePlayer.xmlName, activePlayer);
        sortMap.set(activePlayer, {sortY: 0, treeIndex: 102, z: pz, isDynamic: true});

        // Spawn Followers
        var previousTarget:CharacterEntity = activePlayer;
        for (i in 1...party.length) {
            var fName = party[i];
            var member = new Follower(px, py, pz, fName);
            member.loadEntity("", "characters/" + fName);
            member.target = previousTarget; 
            
            addEntity(member);
            characters.set(member.xmlName, member);
            sortMap.set(member, {sortY: 0, treeIndex: 102 + i, z: pz, isDynamic: true});
            partyMembers.push(member);
            
            previousTarget = member; 
        }
    }

    function addEntity(obj:WorldObject) {
        add(obj);
        entities.set(obj.xmlName, obj);
    }

    public function injectScriptVariables():Void {
        if (scripts == null) return;
        scripts.setGlobal("room", this);
        scripts.setGlobal("player", activePlayer);
        scripts.setGlobal("cutscenePlayer", activeCutscenePlayer);
        
        for (key => val in entities) scripts.setGlobal(key, val);
        for (key => val in characters) {
            if (!entities.exists(key)) scripts.setGlobal(key, val);
        }
    }

    public function fireEvent<T:CancellableEvent>(eventName:String, eventClass:Class<T>, ?setup:T->Void):T {
        if (scripts == null) return null;
        return scripts.fireEvent(eventName, eventClass, setup);
    }

    public function loadRoomFromString(rawXML:String) {
        if (rawXML == null || rawXML == "") return;
        rawXML = StringTools.replace(rawXML, "<!DOCTYPE lily-engine-room>", "");
        
        var parsed = Xml.parse(rawXML).firstElement();
        if (parsed == null) return;
        
        sortMap.clear();
        var xml = new Access(parsed);
        var baseFolder = xml.has.folder ? xml.att.folder : "";
        currentRoomName = xml.has.name ? xml.att.name : "placeholder";
        
        if (xml.hasNode.camera && xml.node.camera.has.zoom) {
            roomZoom = Std.parseFloat(xml.node.camera.att.zoom);
        }

        var objContainer = xml.hasNode.objects ? xml.node.objects : xml;

        parseScripts(xml);
        parsePoints(xml);
        parseTilemaps(objContainer);
        parseSolids(objContainer);
        parseSprites(objContainer, baseFolder);
        parseCharacters(objContainer, baseFolder);
        parsePlayer(objContainer);
        parseEvents(xml);
    }

    private function parseScripts(xml:Access) {
        if (!xml.hasNode.scripts) return;
        for (scriptNode in xml.node.scripts.nodes.script) {
            if (scriptNode.has.path) scripts.loadScript(scriptNode.att.path + ".hx");
        }
    }

    private function parsePoints(xml:Access) {
        if (!xml.hasNode.point) return;
        for (node in xml.nodes.point) {
            spawnPoints.set(
                node.has.id ? node.att.id : "spawn", 
                { x: node.has.x ? Std.parseFloat(node.att.x) : 0, y: node.has.y ? Std.parseFloat(node.att.y) : 0, dir: node.has.direction ? node.att.direction : "down" }
            );
        }
    }

    private function parseTilemaps(objContainer:Access) {
        if (!objContainer.hasNode.tilemap) return;
        
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
                    
                    if (LilyAssets.fileExists(tileInfo.path)) {
                        var graph = flixel.FlxG.bitmap.add(tileInfo.path);
                        var sheetColumns = Std.int(graph.width / size);
                        
                        tile.loadGraphic(tileInfo.path, true, size, size);
                        var frameX = Std.int(tileInfo.rx / size) + cx;
                        var frameY = Std.int(tileInfo.ry / size) + cy;
                        tile.animation.frameIndex = (frameY * sheetColumns) + frameX;
                    }
                    
                    tile.solidCollision = solidCollision;
                    tile.allowCollisions = tile.solidCollision ? FlxObject.ANY : FlxObject.NONE;
                    tile.immovable = true; 
                    
                    addEntity(tile);
                    sortMap.set(tile, {sortY: 0, treeIndex: 0, z: z, isDynamic: false});
                }
                i += 3;
            }
        }
    }

    private function parseSolids(objContainer:Access) {
        if (!objContainer.hasNode.solid) return;
        for (node in objContainer.nodes.solid) {
            var sx = node.has.x ? Std.parseFloat(node.att.x) : 0;
            var sy = node.has.y ? Std.parseFloat(node.att.y) : 0;
            var w = node.has.width ? Std.parseInt(node.att.width) : 32;
            var h = node.has.height ? Std.parseInt(node.att.height) : 32;
            solids.add(new CollisionBlock(sx, sy, w, h));
        }
    }

    private function parseSprites(objContainer:Access, baseFolder:String) {
        if (!objContainer.hasNode.sprite) return;
        for (node in objContainer.nodes.sprite) {
            var z = getZIndex(node);
            var obj = new WorldObject(
                node.has.x ? Std.parseFloat(node.att.x) : 0, 
                node.has.y ? Std.parseFloat(node.att.y) : 0, 
                z, 
                node.has.name ? node.att.name : "obj"
            );
            var sprPath = node.has.path ? node.att.path : (node.has.sprite ? node.att.sprite : "");
            obj.loadEntity(baseFolder != "" ? baseFolder : "", sprPath);
            
            if (node.has.collision) obj.solidCollision = node.att.collision == "true";
            parseSharedAttributes(obj, node);
            
            addEntity(obj);
            sortMap.set(obj, {sortY: obj.y + obj.height, treeIndex: 0, z: z, isDynamic: false});
        }
    }

    private function parseCharacters(objContainer:Access, baseFolder:String) {
        // NPCs
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
                npc.loadEntity(baseFolder != "" ? baseFolder : "", sprPath);
                parseSharedAttributes(npc, node);
                
                addEntity(npc);
                characters.set(npc.xmlName, npc);
                sortMap.set(npc, {sortY: 0, treeIndex: 100, z: z, isDynamic: true});
            }
        }

        // Cutscene Player
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
                activeCutscenePlayer.loadEntity(baseFolder != "" ? baseFolder : "", sprPath);
                parseSharedAttributes(activeCutscenePlayer, node);
                
                addEntity(activeCutscenePlayer);
                characters.set(activeCutscenePlayer.xmlName, activeCutscenePlayer);
                sortMap.set(activeCutscenePlayer, {sortY: 0, treeIndex: 101, z: z, isDynamic: true});
            }
        }
    }

    private function parsePlayer(objContainer:Access) {
        var playerSpawned = false;
        
        if (objContainer.hasNode.player) {
            for (node in objContainer.nodes.player) {
                var z = getZIndex(node);
                var px = node.has.x ? Std.parseFloat(node.att.x) : 0;
                var py = node.has.y ? Std.parseFloat(node.att.y) : 0;
                
                spawnParty(px, py, z, node);
                playerSpawned = true;
                break;
            }
        }

        // Failsafe if <player> node is missing
        if (!playerSpawned) {
            var startX:Float = 0; var startY:Float = 0;
            var pointList = [for (p in spawnPoints) p];
            if (pointList.length > 0) {
                var pt = spawnPoints.exists("entrance") ? spawnPoints.get("entrance") : pointList[0];
                startX = pt.x; startY = pt.y;
            }
            spawnParty(startX, startY, 10);
        }
    }

    private function parseEvents(xml:Access) {
        if (!xml.hasNode.event) return;
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

    function getZIndex(node:Access):Int {
        if (node.has.layer) {
            if (node.att.layer == "bg") return 0;
            if (node.att.layer == "main") return 10;
            if (node.att.layer == "fg") return 20;
        }
        return node.has.z ? Std.parseInt(node.att.z) : 10;
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
        
        if (node.hasNode.script) {
            for (scriptNode in node.nodes.script) {
                if (scriptNode.has.path) {
                    var objScript = scripts.loadScript(scriptNode.att.path + ".hx");
                    objScript.set("this", obj);
                    objScript.set("obj", obj);
                }
            }
        }
    }

    function parseTresTileSet(tresPath:String):Map<Int, TresTile> {
        var map = new Map<Int, TresTile>();
        if (!LilyAssets.fileExists(tresPath)) return map;
        
        var raw = LilyAssets.getTextFromFile(tresPath);
        var lines = raw.split("\n");

        var extRes = new Map<Int, String>();
        var extReg = ~/\[ext_resource path="res:\/\/(.*?)" .*?id=([0-9]+)\]/;
        var texReg = ~/([0-9]+)\/texture = ExtResource\(\s*([0-9]+)\s*\)/;
        var regReg = ~/([0-9]+)\/region = Rect2\(\s*([0-9.]+),\s*([0-9.]+),\s*([0-9.]+),\s*([0-9.]+)\s*\)/;
        var shapeReg = ~/([0-9]+)\/shapes\s*=\s*\[(.*)/;

        for (line in lines) {
            if (extReg.match(line)) extRes.set(Std.parseInt(extReg.matched(2)), extReg.matched(1));
            else if (texReg.match(line)) {
                var tid = Std.parseInt(texReg.matched(1));
                if (!map.exists(tid)) map.set(tid, {path:"", rx:0, ry:0, solid:false});
                map.get(tid).path = extRes.get(Std.parseInt(texReg.matched(2)));
            } else if (regReg.match(line)) {
                var tid = Std.parseInt(regReg.matched(1));
                if (!map.exists(tid)) map.set(tid, {path:"", rx:0, ry:0, solid:false});
                map.get(tid).rx = Std.int(Std.parseFloat(regReg.matched(2)));
                map.get(tid).ry = Std.int(Std.parseFloat(regReg.matched(3)));
            } else if (shapeReg.match(line)) {
                var tid = Std.parseInt(shapeReg.matched(1));
                var remainder = StringTools.trim(shapeReg.matched(2));
                if (!map.exists(tid)) map.set(tid, {path:"", rx:0, ry:0, solid:false});
                if (remainder != "]" && remainder != "") map.get(tid).solid = true;
            }
        }
        return map;
    }

    override public function update(elapsed:Float) {
        if (scripts != null) scripts.call("update", [elapsed]);
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

            var z1 = (d1 != null) ? d1.z : (Std.isOfType(obj1, WorldObject) ? cast(obj1, WorldObject).z : 10);
            var z2 = (d2 != null) ? d2.z : (Std.isOfType(obj2, WorldObject) ? cast(obj2, WorldObject).z : 10);
            
            if (z1 != z2) return FlxSort.byValues(order, z1, z2);
            
            if (d1 != null && d2 != null) {
                var sy1 = d1.isDynamic ? (obj1.y + obj1.height) : d1.sortY;
                var sy2 = d2.isDynamic ? (obj2.y + obj2.height) : d2.sortY;
                if (sy1 == sy2) return FlxSort.byValues(order, d1.treeIndex, d2.treeIndex);
                return FlxSort.byValues(order, sy1, sy2);
            }
            
            return FlxSort.byY(order, obj1, obj2);
        });
        if (scripts != null) scripts.call("postUpdate", [elapsed]);
    }

    override public function destroy() {
        if (scripts != null) {
            scripts.destroy();
            scripts = null;
        }
        EventManager.reset(); 
        currentRoomName = null;
        
        super.destroy();
    }
}