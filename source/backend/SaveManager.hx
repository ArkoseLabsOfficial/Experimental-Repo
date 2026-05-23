package backend;

import flixel.util.FlxSave;
import backend.ItemManager;

typedef SavedItem = { id:String, amount:Int }

typedef SaveSlotData = {
    var id:String;
    var slotNum:Int;
    var location:String;
    var playtime:Float; 
    var party:Array<String>;
    var image:String;

    var roomPath:String;
    var playerX:Float;
    var playerY:Float;
    
    var inventory:Array<SavedItem>;
    var progression:Dynamic; 
    
    var isEmpty:Bool;
}

class SaveManager {
    public static var chapterName:String = "Chapter 1";
    
    // Active Game State
    public static var currentLocation:String = "Living Room";
    public static var currentLocationImage:String = "assets/img/ui/save/ch1_home_day.png";
    public static var currentRoomPath:String = "assets/data/rooms/bathroom.xml";
    
    public static var currentPlaytime:Float = 0;
    public static var currentParty:Array<String> = ["lacie"];
    
    public static var playerX:Float = 0;
    public static var playerY:Float = 0;
    public static var progressionFlags:Dynamic = {}; 
    
    public static function getSlotInfo(slot:Int):SaveSlotData {
        var save = new FlxSave();
        save.bind("LacieEngine_Slot_" + slot);
        
        if (save.data.location != null) {
            return {
                id: "slot" + slot,
                slotNum: slot,
                location: save.data.location,
                playtime: save.data.playtime != null ? save.data.playtime : 0,
                party: save.data.party != null ? save.data.party : [],
                image: save.data.image != null ? save.data.image : "assets/img/ui/save/unknown.png",
                
                roomPath: save.data.roomPath != null ? save.data.roomPath : "assets/data/rooms/bathroom.xml",
                playerX: save.data.playerX != null ? save.data.playerX : 0,
                playerY: save.data.playerY != null ? save.data.playerY : 0,
                inventory: save.data.inventory != null ? save.data.inventory : [],
                progression: save.data.progression != null ? save.data.progression : {},
                
                isEmpty: false
            };
        }
        
        return {
            id: "slot" + slot, slotNum: slot, location: "", 
            playtime: 0, party: [], image: "", 
            roomPath: "", playerX: 0, playerY: 0, 
            inventory: [], progression: {},
            isEmpty: true
        };
    }

    public static function saveGame(slot:Int) {
        var save = new FlxSave();
        save.bind("LacieEngine_Slot_" + slot);
        
        save.data.location = currentLocation;
        save.data.playtime = currentPlaytime;
        save.data.party = currentParty;
        save.data.image = currentLocationImage; 
        
        save.data.roomPath = currentRoomPath;
        save.data.playerX = playerX;
        save.data.playerY = playerY;
        save.data.progression = progressionFlags;
        
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
        currentLocationImage = info.image;
        
        currentRoomPath = info.roomPath;
        playerX = info.playerX;
        playerY = info.playerY;
        progressionFlags = info.progression;
        
        ItemManager.inventory.clear();
        if (info.inventory != null) {
            for (item in info.inventory) {
                ItemManager.inventory.set(item.id, item.amount);
            }
        }
        
        return true;
    }
}