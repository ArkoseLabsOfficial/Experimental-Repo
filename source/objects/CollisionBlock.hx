package objects;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class CollisionBlock extends FlxSprite {
    public function new(x:Float, y:Float, w:Int, h:Int) {
        super(x, y);
        makeGraphic(w, h, FlxColor.RED); 
        immovable = true;
    }
}