package states;

import flixel.FlxState;
import flixel.FlxG;
import flixel.math.FlxRect;
import backend.RoomManager;
import backend.SaveManager;
import states.PauseSubState;

class PlayState extends FlxState {
    var room:RoomManager;
    var isFromLoad:Bool;
    var roomPath:String;

    // Added roomPath to the constructor with a default fallback
    public function new(?fromLoad:Bool = false, roomPath:String = "assets/data/rooms/bathroom.xml") {
        super();
        this.isFromLoad = fromLoad;
        this.roomPath = roomPath;
    }

    override public function create():Void {
        super.create();

        room = new RoomManager();
        
        // 1. Load the specific room requested by the constructor
        room.loadRoom(this.roomPath);
        add(room);
        add(room.solids); // Add invisible blocks so checkCollision finds them

        // 2. Ensure the SaveManager knows exactly what room we are in
        SaveManager.currentRoomPath = this.roomPath;

        if (room.activePlayer != null) {
            // 3. ENFORCE SAVED POSITION IF LOADING!
            if (isFromLoad) {
                room.activePlayer.x = SaveManager.playerX;
                room.activePlayer.y = SaveManager.playerY;
            } else {
                // If starting fresh, lock in the initial spawn point
                SaveManager.playerX = room.activePlayer.x;
                SaveManager.playerY = room.activePlayer.y;
            }

            FlxG.camera.follow(room.activePlayer, TOPDOWN, 0.1);
            FlxG.camera.zoom = room.roomZoom;
        }
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        
        // Tick Playtime & Keep SaveManager's coordinates constantly updated
        SaveManager.currentPlaytime += elapsed;
        if (room.activePlayer != null) {
            SaveManager.playerX = room.activePlayer.x;
            SaveManager.playerY = room.activePlayer.y;
        }

        if (FlxG.keys.justPressed.ESCAPE) openSubState(new PauseSubState());
        
        if (room.activePlayer != null && Controls.ACCEPT_P) {
            var box:FlxRect = room.activePlayer.getInteractionBox();
            for (entity in room.entities) {
                if (entity.interactable && box.overlaps(entity.getHitbox())) {
                    openSubState(new backend.DialogueManager("assets/" + entity.dialogPath + ".xml", "start"));
                    break;
                }
            }
            box.put();
        }
    }
}