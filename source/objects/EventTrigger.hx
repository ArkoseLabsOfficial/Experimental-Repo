package objects;

import flixel.FlxObject;

class EventTrigger extends FlxObject {
    public var eventId:String;
    public var triggerType:String; // "touch", "interact", "enter"
    public var directions:Int;

    public function new(X:Float, Y:Float, Width:Float, Height:Float, id:String, trig:String, dirs:Int, isSolid:Bool = false) {
        super(X, Y, Width, Height);
        
        this.eventId = id;
        this.triggerType = trig;
        this.directions = dirs;
        
        this.immovable = true;
        this.solid = isSolid; 
        if (!this.solid) this.allowCollisions = flixel.FlxObject.NONE;
    }
}