package engine.objects;

import flixel.FlxSprite;
import flixel.math.FlxRect;

class WorldObject extends FlxSprite {
	public var xmlName:String = "";
	public var z:Int = 0;
	public var interactable:Bool = false;
	public var dialogPath:String = "";

	public var tiledID:Int = 0;
	public var tiledProps:Map<String, String>;

	public var solidCollision:Bool = true;

	public function new(x:Float, y:Float, zIndex:Int, name:String) {
		super(x, y);
		this.z = zIndex;
		this.xmlName = name;
		this.tiledProps = new Map();
		antialiasing = false;
	}

	public function loadEntity(folder:String, spriteName:String) {
		folder = (folder != null && folder != "") ? folder + "/" : "";
		var xmlPath = 'images/$folder$spriteName.xml';

		if (LilyAssets.fileExists(xmlPath)) {
			frames = LilyAssets.getSparrowAtlas(folder + spriteName);
		} else if (LilyAssets.fileExists('images/$folder$spriteName.png')) {
			loadGraphic(LilyAssets.image(folder + spriteName));
		}

		generateAccurateHitbox();
	}

	// Handles any standard custom properties fed from TMX
	public function applyProperties(props:Map<String, String>) {
		this.tiledProps = props;

		if (props.exists("autocollision"))
			solidCollision = props.get("autocollision") == "true" || props.get("autocollision") == "1";
		if (props.exists("interactable"))
			interactable = props.get("interactable") == "true" || props.get("interactable") == "1";
		if (props.exists("dialog"))
			dialogPath = props.get("dialog");

		immovable = true;
		allowCollisions = solidCollision ? flixel.FlxObject.ANY : flixel.FlxObject.NONE;
	}

	public function generateAccurateHitbox() {
		updateHitbox();
		var boxWidth = width * 0.9;
		var boxHeight = height * 0.9;
		var xOff = (width - boxWidth) / 2;
		var yOff = height - boxHeight;

		setSize(boxWidth, boxHeight);
		offset.set(xOff, yOff);
	}

	public function addAnim(animName:String, prefix:String, fps:Int, loop:Bool) {
		animation.addByPrefix(animName, prefix, fps, loop);
	}

	public function getCollisionBox():FlxRect {
		return FlxRect.get(x, y, width, height);
	}

	public function getGraphicBox():FlxRect {
		return FlxRect.get(x - offset.x, y - offset.y, frameWidth, frameHeight);
	}
}
