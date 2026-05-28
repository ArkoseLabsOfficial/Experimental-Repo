package engine.objects;

class WorldObject extends FlxSprite {
    public var xmlName:String = "";
    public var z:Int = 0;
    public var interactable:Bool = false;
    public var dialogPath:String = "";
    
    public var solidCollision:Bool = true;

    public function new(x:Float, y:Float, zIndex:Int, name:String) {
        super(x, y);
        this.z = zIndex;
        this.xmlName = name;
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