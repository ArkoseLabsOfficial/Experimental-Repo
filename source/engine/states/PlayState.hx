package engine.states;

import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import engine.backend.RoomManager;
import engine.backend.SaveManager;
import engine.states.PauseSubState;

class PlayState extends StateBackend {
    var room:RoomManager;
    var isFromLoad:Bool;
    var roomPath:String;
    public var camGame:FlxCamera;
    public static var instance:PlayState;
    public var objectives:ObjectiveManager;

    public function new(?fromLoad:Bool = false, roomPath:String = "bathroom") {
        super();
        this.isFromLoad = fromLoad;
        this.roomPath = roomPath;
    }

    override public function create():Void {
        super.create();

        camGame = new FlxCamera();
        FlxG.cameras.reset(camGame);
        FlxG.cameras.setDefaultDrawTarget(camGame, true);

        #if FEATURE_TOUCH_CONTROLS
        mobile.controls.addMobilePad("NONE", "A_B_C");
        mobile.controls.addMobilePadCamera();
        mobile.controls.addJoyStick(0, 800, 'JoyStick/joystick');
        mobile.controls.addJoyStickCamera();
        #end
        instance = this;
        objectives = new ObjectiveManager();

        room = new RoomManager(this);
        room.loadRoom(this.roomPath);
        add(room);
        add(room.solids);

        room.scripts.setParentForAll(this);
        SaveManager.currentRoomPath = this.roomPath;

        if (room.activePlayer != null) {
            if (isFromLoad && SaveManager.partyPositions != null && SaveManager.partyPositions.length > 0) {
                room.activePlayer.x = SaveManager.partyPositions[0].x;
                room.activePlayer.y = SaveManager.partyPositions[0].y;
            } else {
                SaveManager.partyPositions = [{x: room.activePlayer.x, y: room.activePlayer.y}];
            }

            room.activePlayer.positionHistory = [];

            for (i in 0...room.partyMembers.length) {
                var member = room.partyMembers[i];
                if (isFromLoad && SaveManager.partyPositions != null && i + 1 < SaveManager.partyPositions.length) {
                    member.x = SaveManager.partyPositions[i + 1].x;
                    member.y = SaveManager.partyPositions[i + 1].y;
                } else {
                    member.x = room.activePlayer.x;
                    member.y = room.activePlayer.y;
                }
                member.positionHistory = [];
            }

            camGame.zoom = room.roomZoom;
            camGame.follow(room.activePlayer, NO_DEAD_ZONE, 1); 
        }
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        SaveManager.currentPlaytime += elapsed;
        
        // Track the current party positions properly for saving
        if (room.activePlayer != null) {
            SaveManager.partyPositions = [{x: room.activePlayer.x, y: room.activePlayer.y}];
            for (member in room.partyMembers) {
                SaveManager.partyPositions.push({x: member.x, y: member.y});
            }
        }

        if (Controls.MENU_P) openSubState(new PauseSubState());
        
        if (room.activePlayer != null && Controls.ACCEPT_P) {
            var box:FlxRect = room.activePlayer.getInteractionBox();
            for (entity in room.entities) {
                if (entity.interactable && box.overlaps(entity.getHitbox())) {
                    openSubState(new engine.backend.DialogueManager(entity.dialogPath, "start"));
                    break;
                }
            }
            box.put();
        }
    }
}