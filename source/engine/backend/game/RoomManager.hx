package engine.backend.game;

typedef SortData = {
	var sortY:Float;
	var treeIndex:Int;
	var z:Int;
	var isDynamic:Bool;
	var isFlat:Bool;
}

class RoomManager extends FlxTypedGroup<FlxSprite> {
	public static var instance:RoomManager;
	public static var currentRoomName:String;

	// Objects
	public var entities:Map<String, WorldObject>;

	// Characters
	public var characters:Map<String, CharacterEntity>;

	// Barriers or Collisions
	public var solids:FlxTypedGroup<CollisionBlock>;

	// Party Members
	public var partyMembers:Array<Follower>;

	// SpawnPoints
	public var spawnPoints:Map<String, {x:Float, y:Float, dir:String}>;

	// Room Events
	public var roomEvents:Array<{id:String, rect:FlxRect, trigger:String}>;

	// Quit Objects
	public var quitObjects:Map<WorldObject, {room:String, spawnId:Int}>;

	// Sort Map & Layers
	public var sortMap:Map<FlxSprite, SortData>;
	public var layerIndices:Map<String, Int>; // Maps layer name to its Z-Index

	// Player
	public var player:Player;

	public var roomZoom:Float = 1.0;

	private var interactCooldown:Float = 0;
	private var wasInteractPressed:Bool = false;
	public var info:Map<String, Dynamic>;

	#if FEATURE_HSCRIPT
	public var scripts:ScriptHandler;
	#end
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
		quitObjects = new Map();
		sortMap = new Map();
		layerIndices = new Map();
		info = new Map<String, Dynamic>();

		#if FEATURE_HSCRIPT
		scripts = new ScriptHandler();
		#end
		this.mainState = mainState;
	}

	public function loadRoom(filePath:String, spawnId:Int = 0):Void {
		var tmxPath = "rooms/" + filePath + ".tmx";

		if (LilyAssets.fileExists(tmxPath)) {
			TmxParser.read(this, LilyAssets.getTextFromFile(tmxPath), filePath, spawnId);
		} else {
			flixel.FlxG.log.error("Failed to load map. File does not exist: " + tmxPath);
			return;
		}

		#if FEATURE_HSCRIPT
		injectScriptVariables();
		scripts.setParentForAll(engine.states.BaseRoom.instance);
		if (scripts != null)
			scripts.call("create");
		#end
	}

	public function initPlayerState(camGame:FlxCamera, isFromLoad:Bool):Void {
		if (player != null) {
			if (isFromLoad && Game.instance.save.partyPositions != null && Game.instance.save.partyPositions.length > 0) {
				player.x = Game.instance.save.partyPositions[0].x;
				player.y = Game.instance.save.partyPositions[0].y;
			} else {
				Game.instance.save.partyPositions = [{x: player.x, y: player.y}];
			}

			player.positionHistory = [];

			for (i in 0...partyMembers.length) {
				var member = partyMembers[i];
				if (isFromLoad && Game.instance.save.partyPositions != null && i + 1 < Game.instance.save.partyPositions.length) {
					member.x = Game.instance.save.partyPositions[i + 1].x;
					member.y = Game.instance.save.partyPositions[i + 1].y;
				} else {
					member.x = player.x;
					member.y = player.y;
				}
				member.positionHistory = [];
			}

			camGame.zoom = roomZoom;
			camGame.follow(player, NO_DEAD_ZONE, 1);
		}
	}

	public function getObject<T>(objName:String, objClass:Class<T>):T {
		var obj = entities.get(objName);
		if (obj != null && Std.isOfType(obj, objClass)) {
			return cast obj;
		}
		return null;
	}

	public function getPartyMember(index:Int):CharacterEntity {
		if (index == 0)
			return player;
		if (index > 0 && index <= partyMembers.length)
			return partyMembers[index - 1];
		return null;
	}

	public function spawnParty(px:Float, py:Float, pz:Int, ?node:Access):Void {
		var party = Game.instance.save.party;
		if (party == null || party.length == 0)
			party = ["lacie"];

		if (player != null) {
			remove(player);
			entities.remove(player.xmlName);
			characters.remove(player.xmlName);
			sortMap.remove(player);
		}
		for (f in partyMembers) {
			remove(f);
			entities.remove(f.xmlName);
			characters.remove(f.xmlName);
			sortMap.remove(f);
		}
		partyMembers = [];

		player = new Player(px, py, pz, node != null && node.has.name ? node.att.name : "player");
		player.loadEntity("", "characters/" + party[0]);

		addEntity(player);
		characters.set(player.xmlName, player);
		sortMap.set(player, {
			sortY: 0,
			treeIndex: 1000000,
			z: pz,
			isDynamic: true,
			isFlat: false
		});

		var previousTarget:CharacterEntity = player;
		for (i in 1...party.length) {
			var fName = party[i];
			var member = new Follower(px, py, pz, fName);
			member.loadEntity("", "characters/" + fName);
			member.target = previousTarget;

			addEntity(member);
			characters.set(member.xmlName, member);
			sortMap.set(member, {
				sortY: 0,
				treeIndex: 1000000 + i,
				z: pz,
				isDynamic: true,
				isFlat: false
			});
			partyMembers.push(member);

			previousTarget = member;
		}
	}

	public function addEntity(obj:WorldObject):Void {
		add(obj);
		entities.set(obj.xmlName, obj);
	}

	public function changeLayer(obj:Dynamic, layerName:String):Void {
		var targetSpr:FlxSprite = null;

		if (Std.isOfType(obj, String)) {
			var strObj = cast(obj, String);
			if (characters.exists(strObj))
				targetSpr = characters.get(strObj);
			else if (entities.exists(strObj))
				targetSpr = entities.get(strObj);
		} else if (Std.isOfType(obj, FlxSprite)) {
			targetSpr = cast obj;
		}

		if (targetSpr != null && layerName != null) {
			var ln = layerName.toLowerCase();
			if (layerIndices.exists(ln)) {
				var data = sortMap.get(targetSpr);
				if (data != null) {
					data.z = layerIndices.get(ln);
				}
			} else {
				flixel.FlxG.log.error('changeLayer Failed: Layer "$layerName" does not exist in the TMX file!');
			}
		}
	}

	public function injectScriptVariables():Void {
		#if FEATURE_HSCRIPT
		if (scripts == null)
			return;
		scripts.setGlobal("room", this);
		scripts.setGlobal("player", player);
		scripts.setGlobal("parent", engine.states.BaseRoom.instance);

		scripts.setGlobal("changeLayer", changeLayer);

		// quick item functions
		scripts.setGlobal("addItem", Game.instance.items.addItem);
		scripts.setGlobal("removeItem", Game.instance.items.removeItem);
		scripts.setGlobal("getOwnedAmount", Game.instance.items.getOwnedAmount);

		Game.instance.bindToScript(scripts);

		for (key => val in entities)
			scripts.setGlobal(key, val);
		for (key => val in characters) {
			if (!entities.exists(key))
				scripts.setGlobal(key, val);
		}
		#end
	}

	override public function update(elapsed:Float):Void {
		#if FEATURE_HSCRIPT
		if (scripts != null)
			scripts.call("update", [elapsed]);
		#end

		super.update(elapsed);

		if (interactCooldown > 0) {
			interactCooldown -= elapsed;
		}

		if (player != null && player.canMove) {
			FlxG.collide(player, solids);
			for (entity in entities) {
				if (entity != player && entity.solidCollision) {
					FlxG.collide(player, entity);
				}
			}
		}

		if (player != null) {
			Game.instance.save.partyPositions = [{x: player.x, y: player.y}];
			for (member in partyMembers) {
				Game.instance.save.partyPositions.push({x: member.x, y: member.y});
			}
		}

		if (player != null && player.canMove) {
			var playerHitbox = player.getCollisionBox();
			var switchedRoom = false;

			var isInteractPressedNow = Controls.ACCEPT;

			if (isInteractPressedNow && !wasInteractPressed && interactCooldown <= 0) {
				if (quitObjects != null) {
					for (quitObj in quitObjects.keys()) {
						if (playerHitbox.overlaps(quitObj.getCollisionBox())) {
							var quitData = quitObjects.get(quitObj);
							StateBackend.switchState(new engine.states.BaseRoom(quitData.room, quitData.spawnId, false));
							switchedRoom = true;
							break;
						}
					}
				}

				if (!switchedRoom) {
					var box = player.getInteractionBox();
					for (entity in entities) {
						if (entity != player && entity.interactable && box.overlaps(entity.getCollisionBox())) {
							interactCooldown = 0.2;

							#if FEATURE_HSCRIPT
							var typeStr = Std.isOfType(entity, CharacterEntity) ? "Entity" : "Object";
							if (scripts != null) {
								scripts.callOn(entity.xmlName, "onInteracted", [entity.xmlName, entity.tiledID, typeStr, entity.tiledProps]);
							}
							#end

							if (entity.dialogPath != "")
								Game.instance.playDialogue(entity.dialogPath, "start");
							break;
						}
					}
					box.put();
				}
			}

			wasInteractPressed = isInteractPressedNow;
			playerHitbox.put();
		}

		sort(function(order:Int, obj1:FlxSprite, obj2:FlxSprite):Int {
			var d1 = sortMap.get(obj1);
			var d2 = sortMap.get(obj2);

			var z1 = (d1 != null) ? d1.z : (Std.isOfType(obj1, WorldObject) ? cast(obj1, WorldObject).z : 1);
			var z2 = (d2 != null) ? d2.z : (Std.isOfType(obj2, WorldObject) ? cast(obj2, WorldObject).z : 1);

			// TMX read order defines absolute rendering stack priority
			if (z1 != z2) {
				return FlxSort.byValues(order, z1, z2);
			}

			// If they share the exact same layer, then dynamically Y-sort them.
			var b1 = obj1.y - obj1.offset.y + (obj1.frameHeight != 0 ? obj1.frameHeight : obj1.height);
			var b2 = obj2.y - obj2.offset.y + (obj2.frameHeight != 0 ? obj2.frameHeight : obj2.height);

			if (b1 != b2)
				return FlxSort.byValues(order, b1, b2);

			// If completely identical Z and Y, fallback to the exact sub-element Read Order in TMX
			var t1 = (d1 != null) ? d1.treeIndex : 0;
			var t2 = (d2 != null) ? d2.treeIndex : 0;
			return FlxSort.byValues(order, t1, t2);
		});

		#if FEATURE_HSCRIPT
		if (scripts != null)
			scripts.call("postUpdate", [elapsed]);
		#end
	}

	override public function destroy():Void {
		#if FEATURE_HSCRIPT
		if (scripts != null) {
			scripts.destroy();
			scripts = null;
		}
		#end
		currentRoomName = null;
		if (layerIndices != null) {
			layerIndices.clear();
			layerIndices = null;
		}
		if (quitObjects != null) {
			quitObjects.clear();
			quitObjects = null;
		}
		super.destroy();
	}
}
