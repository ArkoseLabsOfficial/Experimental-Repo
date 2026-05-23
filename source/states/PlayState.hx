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
    public static var instance:PlayState;
    public var objectives:ObjectiveManager;

    // NOTE: change current one to new(roomPath, fromLoad);
    public function new(?fromLoad:Bool = false, roomPath:String = "assets/data/rooms/bathroom.xml") {
        super();
        this.isFromLoad = fromLoad;
        this.roomPath = roomPath;
    }

    override public function create():Void {
        super.create();
        instance = this;
        objectives = new ObjectiveManager();

        room = new RoomManager();

        room.loadRoom(this.roomPath);
        add(room);
        add(room.solids);

        room.scripts.setParentForAll(this);

        SaveManager.currentRoomPath = this.roomPath;

        if (room.activePlayer != null) {
            if (isFromLoad) {
                room.activePlayer.x = SaveManager.playerX;
                room.activePlayer.y = SaveManager.playerY;
            } else {
                SaveManager.playerX = room.activePlayer.x;
                SaveManager.playerY = room.activePlayer.y;
            }

            FlxG.camera.follow(room.activePlayer, TOPDOWN, 0.1);
            FlxG.camera.zoom = room.roomZoom;
        }
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

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