package engine.states;

class BaseRoom extends StateBackend {
	var room:RoomManager;
	var isFromLoad:Bool;
	var roomName:String;
	var spawnId:Int;

	public var camGame:FlxCamera;

	public static var instance:BaseRoom;

	public var objectives:ObjectiveManager;

	public function new(room:String = "bathroom", spawnId:Int = 0, fromLoad:Bool = false) {
		super();
		this.isFromLoad = fromLoad;
		this.roomName = room;
		this.spawnId = spawnId;
	}

	override function closeSubState() {
		super.closeSubState();
		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.removeJoyStick();
		Game.mobileC.removeButton();
		Game.mobileC.removeDPad();
		Game.mobileC.addJoyStick("GAME");
		Game.mobileC.addButton("GAME");
		#end
	}

	override function openSubState(SubState:flixel.FlxSubState) {
		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.removeJoyStick();
		Game.mobileC.removeButton();
		Game.mobileC.removeDPad();
		#end
		super.openSubState(SubState);
	}

	override public function create():Void {
		super.create();
		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.removeJoyStick();
		Game.mobileC.removeButton();
		Game.mobileC.removeDPad();
		Game.mobileC.addJoyStick("GAME");
		Game.mobileC.addButton("GAME");
		#end

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		instance = this;
		objectives = new ObjectiveManager();

		room = new RoomManager(this);
		room.loadRoom(roomName, spawnId);
		add(room);
		add(room.solids);

		#if FEATURE_HSCRIPT
		room.scripts.setParentForAll(this);
		room.scripts.call("onRoomLoaded");
		#end
		Game.instance.save.room = roomName;

		room.initPlayerState(camGame, isFromLoad);
	}

	public function followTheObject(obj:Dynamic, type:String = "NO_DEAD_ZONE", smoothness:Float = 1):Void {
		var realType:flixel.FlxCameraFollowStyle = NO_DEAD_ZONE;
		if (type == "LOCKON")
			realType = LOCKON;
		if (type == "PLATFORMER")
			realType = PLATFORMER;
		if (type == "TOPDOWN")
			realType = TOPDOWN;
		if (type == "TOPDOWN_TIGHT")
			realType = TOPDOWN_TIGHT;
		if (type == "SCREEN_BY_SCREEN")
			realType = SCREEN_BY_SCREEN;
		if (type == "NO_DEAD_ZONE")
			realType = NO_DEAD_ZONE;

		camGame.follow(obj, realType, smoothness);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		Game.instance.save.playtime += elapsed;

		if (room.player != null) {
			camGame.targetOffset.set(room.player.cameraOffset.x, room.player.cameraOffset.y);
		}

		if (Controls.MENU)
			openSubState(new Pause());
	}
}
