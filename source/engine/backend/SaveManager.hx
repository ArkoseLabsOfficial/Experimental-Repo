package engine.backend;

import flixel.util.FlxSave;
import engine.backend.ItemManager;

typedef SavedItem = { id:String, amount:Int }
typedef Position = { x:Float, y:Float }

typedef SaveSlotData = {
    var id:String;
    var slotNum:Int;
    var location:String;
    var playtime:Float; 
    var party:Array<String>;
    var partyPositions:Array<Position>;
    var image:String;

    var roomPath:String;
    
    var inventory:Array<SavedItem>;
    var currentObjectives:Array<String>;
    var completedObjectives:Array<String>;
    var failedObjectives:Array<String>;
    var progression:Dynamic; 
    
    var isEmpty:Bool;
}

class SaveManager {
    public static var chapterName:String = "Chapter 1";
    
    public static var currentLocation:String = "Living Room";
    public static var currentLocationImage:String = "img/ui/save/ch1_home_day";
    public static var currentRoomPath:String = "rooms/bathroom.xml";
    
    public static var currentPlaytime:Float = 0;
    private static var defaultParty:Array<String> = ["lacie"];
    public static var currentParty:Array<String> = ["lacie"];
    
    public static var partyPositions:Array<Position> = [{x: 0, y: 0}];
    
    public static var progressionFlags:Dynamic = {}; 
    
    public static var currentObjectives:Array<String> = [];
    public static var completedObjectives:Array<String> = [];
    public static var failedObjectives:Array<String> = [];

    public static function reset() {
        chapterName = "Chpater 1";
        currentLocation = "Living Room";
        currentLocationImage = "img/ui/save/ch1_home_day";
        currentRoomPath = "rooms/bathroom.xml";
        currentPlaytime = 0;
        currentParty = defaultParty.copy();
        partyPositions = [{x: 0, y: 0}];
        progressionFlags = {};
        currentObjectives = [];
        completedObjectives = [];
        failedObjectives = [];
    }
        
    public static function getSlotInfo(slot:Int):SaveSlotData {
        var save = new FlxSave();
        save.bind("LacieEngine_Slot_" + slot);
        
        if (save.data.location != null) {
            return {
                id: "slot" + slot,
                slotNum: slot,
                location: save.data.location,
                playtime: save.data.playtime != null ? save.data.playtime : 0,
                party: save.data.party != null ? save.data.party : ["lacie"],
                partyPositions: save.data.partyPositions != null ? save.data.partyPositions : [{x: 0, y: 0}],
                image: save.data.image != null ? save.data.image : "img/ui/save/unknown",
                roomPath: save.data.roomPath != null ? save.data.roomPath : "rooms/bathroom.xml",
                inventory: save.data.inventory != null ? save.data.inventory : [],
                currentObjectives: save.data.currentObjectives != null ? save.data.currentObjectives : [],
                completedObjectives: save.data.completedObjectives != null ? save.data.completedObjectives : [],
                failedObjectives: save.data.failedObjectives != null ? save.data.failedObjectives : [],
                progression: save.data.progression != null ? save.data.progression : {},
                isEmpty: false
            };
        }
        
        return {
            id: "slot" + slot, slotNum: slot, location: "", 
            playtime: 0, party: ["lacie"], partyPositions: [{x:0, y:0}], image: "", 
            roomPath: "", inventory: [], currentObjectives: [], completedObjectives: [], failedObjectives: [], progression: {},
            isEmpty: true
        };
    }

    public static function saveGame(slot:Int) {
        var save = new FlxSave();
        save.bind("LacieEngine_Slot_" + slot);
        
        save.data.location = currentLocation;
        save.data.playtime = currentPlaytime;
        save.data.party = currentParty;
        save.data.partyPositions = partyPositions;
        save.data.image = currentLocationImage; 
        save.data.roomPath = currentRoomPath;
        save.data.progression = progressionFlags;
        save.data.currentObjectives = currentObjectives;
        save.data.completedObjectives = completedObjectives;
        save.data.failedObjectives = failedObjectives;
        
        var savedInv:Array<SavedItem> = [];
        for (id in ItemManager.inventory.keys()) {
            savedInv.push({ id: id, amount: ItemManager.inventory.get(id) });
        }
        save.data.inventory = savedInv;
        
        save.flush(); 
    }

    public static function loadGame(slot:Int):Bool {
        var info = getSlotInfo(slot);
        if (info.isEmpty) return false; 
        
        currentLocation = info.location;
        currentPlaytime = info.playtime;
        currentParty = info.party;
        partyPositions = info.partyPositions;
        currentLocationImage = info.image;
        currentRoomPath = info.roomPath;
        progressionFlags = info.progression;
        currentObjectives = info.currentObjectives;
        completedObjectives = info.completedObjectives;
        failedObjectives = info.failedObjectives;

        ItemManager.inventory.clear();
        if (info.inventory != null) {
            for (item in info.inventory) {
                ItemManager.inventory.set(item.id, item.amount);
            }
        }
        
        return true;
    }
}