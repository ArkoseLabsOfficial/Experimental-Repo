package objects;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxRect; // Import FlxRect

class WorldObject extends FlxSprite {
    public var xmlName:String = "";
    public var z:Int = 0;
    public var interactable:Bool = false;
    public var dialogPath:String = "";
    
    // Auto Collision Feature, can be disabled if you want.
    public var solidCollision:Bool = true;

    public function new(x:Float, y:Float, zIndex:Int, name:String) {
        super(x, y);
        this.z = zIndex;
        this.xmlName = name;
    }

    public function loadEntity(folder:String, spriteName:String) {
        folder = (folder != null && folder != "") ? folder + "/" : "";
        var xmlPath = folder + spriteName + ".xml";
        trace(xmlPath);

        if (LilyAssets.fileExists(xmlPath)) {
            frames = LilyAssets.getSparrowAtlas(folder + spriteName);
        } else if (LilyAssets.fileExists(folder + spriteName + ".png")) {
            loadGraphic(LilyAssets.image(folder + spriteName));
        }

        generateAccurateHitbox();
    }

    function generateAccurateHitbox() {
        updateHitbox(); 
        var boxHeight = height * 0.825; 
        var yOffset = height - boxHeight; 
        
        setSize(width, boxHeight);
        offset.set(0, yOffset);
    }

    public function addAnim(animName:String, prefix:String, fps:Int, loop:Bool) {
        animation.addByPrefix(animName, prefix, fps, loop);
    }

    public function getCollisionBox():FlxRect {
        return FlxRect.get(x, y, width, height);
    }
}