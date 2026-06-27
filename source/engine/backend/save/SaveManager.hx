package engine.backend.save;

import flixel.util.FlxSave;

typedef SavedItem = {id:String, amount:Int}
typedef Position = {x:Float, y:Float}

typedef SaveSlotData = {
    var id:String;
    var slotNum:Int;
    var location:String;
    var chapterName:String;
    var playtime:Float;
    var party:Array<String>;
    var partyPositions:Array<Position>;
    var room:String;
    var inventory:Array<SavedItem>;
    var currentObjectives:Array<String>;
    var completedObjectives:Array<String>;
    var failedObjectives:Array<String>;
    var flags:Dynamic;
    var variables:Dynamic;
    var scriptVariables:Dynamic;
    var isEmpty:Bool;
}

class SaveManager {
    // Singleton Instance
    public static var instance:SaveManager = new SaveManager();

    // Meta Info
    public var chapterName:String;
    public var location:String;

    // Live Game State
    public var flags:Map<String, Bool>;
    public var variables:Map<String, Dynamic>;
    public var scriptVariables:Map<String, Dynamic>;
    public var party:Array<String>;

    // Loaded Cache
    public var room:String;
    public var partyPositions:Array<Position>;

    public var currentObjectives:Array<String>;
    public var completedObjectives:Array<String>;
    public var failedObjectives:Array<String>;

    // Playtime Tracking
    public var playtime:Float;
    private var sessionStartTime:Float;

    public function new() {
        flags = new Map();
        variables = new Map();
        scriptVariables = new Map();
        party = ["lacie"];
        partyPositions = [{x: 0, y: 0}];
        currentObjectives = [];
        completedObjectives = [];
        failedObjectives = [];
        reset();
    }

    public function initSession():Void {
        sessionStartTime = haxe.Timer.stamp();
    }

    public function reset():Void {
        chapterName = "Chapter 1";
        location = "Living Room";
        room = "room";
        playtime = 0;
        sessionStartTime = haxe.Timer.stamp();
        party = ["lacie"];
        partyPositions = [{x: 0, y: 0}];
        flags.clear();
        variables.clear();
        scriptVariables.clear();
        currentObjectives = [];
        completedObjectives = [];
        failedObjectives = [];
    }

    public function getSlotInfo(slot:Int):SaveSlotData {
        var save = new FlxSave();
        save.bind("LacieEngine_Slot_" + slot);

        if (save.data.location == null)
            return getEmptySlot(slot);

        var d = save.data;
        return {
            id: "slot" + slot,
            slotNum: slot,
            location: d.location,
            chapterName: d.chapterName != null ? d.chapterName : "Chapter 1",
            playtime: d.playtime != null ? d.playtime : 0,
            party: d.party != null ? d.party : ["lacie"],
            partyPositions: d.partyPositions != null ? d.partyPositions : [{x: 0, y: 0}],
            room: d.room != null ? d.room : "room",
            inventory: d.inventory != null ? d.inventory : [],
            currentObjectives: d.currentObjectives != null ? d.currentObjectives : [],
            completedObjectives: d.completedObjectives != null ? d.completedObjectives : [],
            failedObjectives: d.failedObjectives != null ? d.failedObjectives : [],
            flags: d.flags != null ? d.flags : {},
            variables: d.variables != null ? d.variables : {},
            scriptVariables: d.scriptVariables != null ? d.scriptVariables : {},
            isEmpty: false
        };
    }

    private function getEmptySlot(slot:Int):SaveSlotData {
        return {
            id: "slot" + slot,
            slotNum: slot,
            location: "",
            chapterName: "",
            playtime: 0,
            party: ["lacie"],
            partyPositions: [{x: 0, y: 0}],
            room: "",
            inventory: [],
            currentObjectives: [],
            completedObjectives: [],
            failedObjectives: [],
            flags: {},
            variables: {},
            scriptVariables: {},
            isEmpty: true
        };
    }

    public function saveGame(slot:Int):Void {
        var save = new FlxSave();
        save.bind("LacieEngine_Slot_" + slot);

        var currentPlaytime = playtime + (haxe.Timer.stamp() - sessionStartTime);
        var currentRoom = RoomManager.currentRoomName != null ? RoomManager.currentRoomName : room;

        var currentPositions:Array<Position> = [];
        if (RoomManager.instance != null && RoomManager.instance.player != null) {
            currentPositions.push({x: RoomManager.instance.player.x, y: RoomManager.instance.player.y});
            for (member in RoomManager.instance.partyMembers) {
                currentPositions.push({x: member.x, y: member.y});
            }
        } else {
            currentPositions = partyPositions;
        }

        if (RoomManager.instance != null && RoomManager.instance.scripts != null) {
            for (id => script in RoomManager.instance.scripts.scriptMap) {
                var state:Dynamic = {};
                if (script.interp != null) {
                    for (k in script.interp.variables.keys()) {
                        if (engine.scripting.GameScript.defaultImports.exists(k))
                            continue;
                        if (k == "this" || k == "obj" || k == "room" || k == "player" || k == "parent")
                            continue;

                        var val = script.interp.variables.get(k);
                        if (Std.isOfType(val, String) || Std.isOfType(val, Int) || Std.isOfType(val, Float) || Std.isOfType(val, Bool)) {
                            Reflect.setField(state, k, val);
                        }
                    }
                }
                scriptVariables.set(currentRoom + "_" + id, state);
            }
        }

        save.data.location = location;
        save.data.chapterName = chapterName;
        save.data.playtime = currentPlaytime;
        save.data.party = party;
        save.data.partyPositions = currentPositions;
        save.data.room = currentRoom;

        save.data.currentObjectives = currentObjectives;
        save.data.completedObjectives = completedObjectives;
        save.data.failedObjectives = failedObjectives;

        var savedFlags:Dynamic = {};
        for (k in flags.keys())
            Reflect.setField(savedFlags, k, flags.get(k));
        save.data.flags = savedFlags;

        var savedVars:Dynamic = {};
        for (k in variables.keys())
            Reflect.setField(savedVars, k, variables.get(k));
        save.data.variables = savedVars;

        var savedScripts:Dynamic = {};
        for (k in scriptVariables.keys())
            Reflect.setField(savedScripts, k, scriptVariables.get(k));
        save.data.scriptVariables = savedScripts;

        var savedInv:Array<SavedItem> = [];
        if (Game.instance != null) {
            for (id => amount in Game.instance.items.inventory)
                savedInv.push({id: id, amount: amount});
        }
        save.data.inventory = savedInv;

        save.flush();

        playtime = currentPlaytime;
        sessionStartTime = haxe.Timer.stamp();
    }

    public function loadGame(slot:Int):Bool {
        var info = getSlotInfo(slot);
        if (info.isEmpty)
            return false;

        location = info.location;
        chapterName = info.chapterName;

        playtime = info.playtime;
        sessionStartTime = haxe.Timer.stamp();

        party = info.party;
        partyPositions = info.partyPositions;
        room = info.room;

        currentObjectives = info.currentObjectives;
        completedObjectives = info.completedObjectives;
        failedObjectives = info.failedObjectives;

        flags.clear();
        if (info.flags != null) {
            for (f in Reflect.fields(info.flags))
                flags.set(f, Reflect.field(info.flags, f));
        }

        variables.clear();
        if (info.variables != null) {
            for (f in Reflect.fields(info.variables))
                variables.set(f, Reflect.field(info.variables, f));
        }

        scriptVariables.clear();
        if (info.scriptVariables != null) {
            for (f in Reflect.fields(info.scriptVariables))
                scriptVariables.set(f, Reflect.field(info.scriptVariables, f));
        }

        if (Game.instance != null) {
            Game.instance.items.inventory.clear();
            for (item in info.inventory)
                Game.instance.items.inventory.set(item.id, item.amount);
        }

        return true;
    }

    public function setFlag(key:String, value:Bool):Void {
        flags.set(key, value);
    }

    public function getFlag(key:String):Bool {
        return flags.exists(key) ? flags.get(key) : false;
    }

    /* ----------------------------------------------------------------------------- */

    /**
     * Initializes the save file. 
     * Call this once before using getSave/setSave.
     */
    public function init(saveName:String) 
    {
        FlxG.save.bind(saveName);
    }

    /**
     * Saves a value to the bound FlxSave file.
     */
    public function setSave(name:String, value:Dynamic) 
    {
        Reflect.setField(FlxG.save.data, name, value);
        FlxG.save.flush();
    }

    /**
     * Retrieves a value from the bound FlxSave file.
     */
    public function getSave(name:String, defaultValue:Dynamic = null):Dynamic 
    {
        if (hasSave(name))
        {
            return Reflect.field(FlxG.save.data, name);
        }
        return defaultValue;
    }

    /**
     * Checks if a specific key exists in the save data.
     */
    public function hasSave(name:String):Bool 
    {
        return Reflect.hasField(FlxG.save.data, name);
    }

    /**
     * Removes a specific key from the save data.
     */
    public function removeSave(name:String) 
    {
        if (hasSave(name)) 
        {
            Reflect.deleteField(FlxG.save.data, name);
            FlxG.save.flush();
        }
    }
}