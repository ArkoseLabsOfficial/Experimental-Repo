package engine.objects;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.xml.Access;

typedef CharAnimData = {
	var name:String;
	var prefix:String;
	var fps:Int;
	var loop:Bool;
	var offsetX:Float;
	var offsetY:Float;
	var cameraX:Float;
	var cameraY:Float;
	var spritePath:String;
}

enum FacingDirection {
	UP;
	DOWN;
	LEFT;
	RIGHT;
}

enum CharacterState {
	Standing;
	Walking;
	Running;
	Idle;
}

class CharacterEntity extends WorldObject {
	public var canMove:Bool = true;
	public var currentFacing:FacingDirection = DOWN;
	public var currentState:CharacterState = Standing;

	public var lockedAnim:String = "";

	public var colWidth:Float = 24;
	public var colHeight:Float = 12;
	public var colOffsetX:Float = 0;
	public var colOffsetY:Float = 0;

	public var showHitbox:Bool = false;

	private var hitboxGraphic:FlxSprite;
	private var interactionGraphic:FlxSprite;

	public var positionHistory:Array<FlxPoint> = [];
	public var maxHistory:Int = 40;
	public var historySpacing:Float = 2.0;

	public var animData:Map<String, CharAnimData> = new Map();
	public var loadedFrames:Map<String, FlxAtlasFrames> = new Map();
	public var currentSpritePath:String = "";
	public var cameraOffset:FlxPoint = FlxPoint.get();

	public function new(x:Float, y:Float, z:Int, name:String) {
		super(x, y, z, name);
		moves = false;
	}

	override public function loadEntity(folder:String, spriteName:String) {
		var fullPath = (folder != null && folder != "") ? folder + "/" + spriteName : spriteName;
		var xmlPath = fullPath + ".xml";

		if (LilyAssets.fileExists(xmlPath)) {
			var rawXml = LilyAssets.getTextFromFile(xmlPath);
			if (rawXml.indexOf("<character") != -1) {
				rawXml = StringTools.replace(rawXml, "<!DOCTYPE lily-engine-character>", "");
				var xml = Xml.parse(rawXml).firstElement();

				if (xml != null && xml.nodeName == "character") {
					var parsed = new Access(xml);
					var defaultSprite = parsed.has.sprite ? parsed.att.sprite : spriteName;

					if (parsed.has.flipX)
						this.flipX = parsed.att.flipX == "true";
					if (parsed.has.flipY)
						this.flipY = parsed.att.flipY == "true";

					if (parsed.hasNode.anim) {
						for (animNode in parsed.nodes.anim) {
							var aName = animNode.has.name ? animNode.att.name : "idle";
							var aPrefix = animNode.has.anim ? animNode.att.anim : aName;
							var aFps = animNode.has.fps ? Std.parseInt(animNode.att.fps) : 24;
							var aLoop = animNode.has.loop ? animNode.att.loop == "true" : false;
							var ax = animNode.has.x ? Std.parseFloat(animNode.att.x) : 0;
							var ay = animNode.has.y ? Std.parseFloat(animNode.att.y) : 0;
							var aCamX = animNode.has.camX ? Std.parseFloat(animNode.att.camX) : 0;
							var aCamY = animNode.has.camY ? Std.parseFloat(animNode.att.camY) : 0;
							var aSprite = animNode.has.sprite ? animNode.att.sprite : defaultSprite;

							animData.set(aName, {
								name: aName,
								prefix: aPrefix,
								fps: aFps,
								loop: aLoop,
								offsetX: ax,
								offsetY: ay,
								cameraX: aCamX,
								cameraY: aCamY,
								spritePath: aSprite
							});

							if (!loadedFrames.exists(aSprite)) {
								var atlas = LilyAssets.getSparrowAtlas(aSprite);
								if (atlas != null)
									loadedFrames.set(aSprite, atlas);
							}
						}
					}

					if (loadedFrames.exists(defaultSprite)) {
						frames = loadedFrames.get(defaultSprite);
						currentSpritePath = defaultSprite;
					}

					setupStaticHitbox();
					playAnim(animData.exists("idleDOWN") ? "idleDOWN" : "idle");
					return;
				}
			}
		}

		super.loadEntity(folder, spriteName);
		setupStaticHitbox();
		setupDefaultAnimations();
	}

	override public function applyProperties(props:Map<String, String>) {
		super.applyProperties(props);
		if (props.exists("anim")) {
			lockedAnim = props.get("anim");
			var sAnim = lockedAnim.toLowerCase();
			if (sAnim.indexOf("up") != -1)
				currentFacing = UP;
			else if (sAnim.indexOf("down") != -1)
				currentFacing = DOWN;
			else if (sAnim.indexOf("left") != -1)
				currentFacing = LEFT;
			else if (sAnim.indexOf("right") != -1)
				currentFacing = RIGHT;
			playAnim(lockedAnim, true);
		}
	}

	function setupStaticHitbox() {
		colOffsetX = -(colWidth / 2);
		colOffsetY = -colHeight;

		if (hitboxGraphic == null)
			hitboxGraphic = new FlxSprite();
		hitboxGraphic.makeGraphic(Std.int(colWidth), Std.int(colHeight), flixel.util.FlxColor.TRANSPARENT);
		flixel.util.FlxSpriteUtil.drawRect(hitboxGraphic, 0, 0, colWidth, colHeight, flixel.util.FlxColor.TRANSPARENT,
			{thickness: 2, color: flixel.util.FlxColor.RED});
	}

	function setupDefaultAnimations() {
		animation.addByPrefix("idle_down", "idle_down", 1, false);
		animation.addByPrefix("walk_down", "walk_down", 6, true);
		animation.addByPrefix("run_down", "run_down", 10, true);
		animation.play("idle_down");
	}

	public function playAnim(animName:String, force:Bool = false, reversed:Bool = false) {
		var isNewAnim = (force || animation.curAnim == null || animation.curAnim.name != animName);

		if (animData.exists(animName)) {
			var data = animData.get(animName);

			if (isNewAnim) {
				var swappedAtlas = false;
				if (currentSpritePath != data.spritePath && loadedFrames.exists(data.spritePath)) {
					var oldAnims = animation.getNameList();
					for (anim in oldAnims)
						animation.remove(anim);

					frames = loadedFrames.get(data.spritePath);
					currentSpritePath = data.spritePath;
					swappedAtlas = true;
				}

				if (swappedAtlas || animation.getByName(animName) == null) {
					animation.addByPrefix(animName, data.prefix, data.fps, data.loop);
				}

				animation.play(animName, force, reversed);
			}

			offset.set((frameWidth / 2) - data.offsetX, frameHeight - data.offsetY);
			cameraOffset.set(data.cameraX, data.cameraY);
		} else {
			if (isNewAnim)
				animation.play(animName, force, reversed);
			offset.set(frameWidth / 2, frameHeight);
		}
	}

	override public function draw():Void {
		super.draw();
		if (showHitbox) {
			if (hitboxGraphic != null) {
				hitboxGraphic.x = this.x + colOffsetX;
				hitboxGraphic.y = this.y + colOffsetY;
				hitboxGraphic.scrollFactor.set(this.scrollFactor.x, this.scrollFactor.y);
				hitboxGraphic.draw();
			}

			var iBox = getInteractionBox();
			if (interactionGraphic == null) {
				interactionGraphic = new FlxSprite();
				interactionGraphic.makeGraphic(1, 1, flixel.util.FlxColor.TRANSPARENT);
			}
			interactionGraphic.makeGraphic(Std.int(iBox.width), Std.int(iBox.height), flixel.util.FlxColor.TRANSPARENT);
			flixel.util.FlxSpriteUtil.drawRect(interactionGraphic, 0, 0, iBox.width, iBox.height, flixel.util.FlxColor.TRANSPARENT,
				{thickness: 2, color: flixel.util.FlxColor.BLUE});
			interactionGraphic.x = iBox.x;
			interactionGraphic.y = iBox.y;
			interactionGraphic.scrollFactor.set(this.scrollFactor.x, this.scrollFactor.y);
			interactionGraphic.draw();
			iBox.put();
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		if (canMove) {
			recordHistory();
			updateAnimations();
		}
	}

	public function recordHistory() {
		if (positionHistory.length == 0) {
			positionHistory.unshift(FlxPoint.get(x, y));
			return;
		}

		var lastP = positionHistory[0];
		var dx = x - lastP.x;
		var dy = y - lastP.y;
		var dist = Math.sqrt(dx * dx + dy * dy);

		if (dist >= historySpacing) {
			positionHistory.unshift(FlxPoint.get(x, y));
			while (positionHistory.length > maxHistory) {
				var old = positionHistory.pop();
				old.put();
			}
		}
	}

	public function updateAnimations():Void {
		if (lockedAnim != "") {
			playAnim(lockedAnim);
			return;
		}

		if (Math.abs(velocity.x) > 5 || Math.abs(velocity.y) > 5) {
			if (Math.abs(velocity.x) > Math.abs(velocity.y)) {
				if (velocity.x > 0)
					currentFacing = RIGHT;
				else
					currentFacing = LEFT;
			} else {
				if (velocity.y > 0)
					currentFacing = DOWN;
				else
					currentFacing = UP;
			}
		}

		var speed = Math.sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y));
		if (speed > 200)
			currentState = Running;
		else if (speed > 10)
			currentState = Walking;
		else
			currentState = Standing;

		var faceStr = switch (currentFacing) {
			case UP: "UP";
			case LEFT: "LEFT";
			case RIGHT: "RIGHT";
			default: "DOWN";
		}

		var animName = "";
		switch (currentState) {
			case Walking:
				animName = "walk" + faceStr;
			case Running:
				animName = "run" + faceStr;
			case Standing, Idle:
				animName = "idle" + faceStr;
		}

		if (animData.keys().hasNext()) {
			if (!animData.exists(animName) && (currentState == Standing || currentState == Idle)) {
				animName = animData.exists("idle") ? "idle" : "idleDOWN";
			}
			playAnim(animName);
		} else {
			var legacyFace = switch (currentFacing) {
				case UP: "_up";
				case LEFT: "_left";
				case RIGHT: "_right";
				default: "_down";
			}
			var legacyAnim = switch (currentState) {
				case Walking: "walk" + legacyFace;
				case Running: "run" + legacyFace;
				case Standing, Idle: "idle" + legacyFace;
			}
			playAnim(legacyAnim);
		}
	}

	override public function getCollisionBox():FlxRect {
		return FlxRect.get(x + colOffsetX, y + colOffsetY, colWidth, colHeight);
	}

	override public function getGraphicBox():FlxRect {
		return FlxRect.get(x - offset.x, y - offset.y, frameWidth, frameHeight);
	}

	public function getInteractionBox():FlxRect {
		var box = getCollisionBox();

		box.width = 12;
		box.height = 12;

		switch (currentFacing) {
			case UP:
				box.y -= 12;
				box.x += 6;
			case DOWN:
				box.y += 14;
				box.x += 6;
			case LEFT:
				box.x -= 12;
				box.y += 3;
			case RIGHT:
				box.x += 24;
				box.y += 3;
		}
		return box;
	}
}
