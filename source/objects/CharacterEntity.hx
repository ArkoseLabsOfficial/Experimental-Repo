package objects;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

enum FacingDirection { UP; DOWN; LEFT; RIGHT; }
enum CharacterState { Standing; Walking; Running; Sneaking; Idle; }

class CharacterEntity extends WorldObject {
    public var currentFacing:FacingDirection = DOWN;
    public var currentState:CharacterState = Standing;

    public var colWidth:Float = 24;
    public var colHeight:Float = 12;
    public var colOffsetX:Float = 0;
    public var colOffsetY:Float = 0;
    
    public var showHitbox:Bool = false;
    private var hitboxGraphic:FlxSprite;

    public var positionHistory:Array<FlxPoint> = [];
    static inline var MAX_HISTORY:Int = 100;

    public function new(x:Float, y:Float, z:Int, name:String) {
        super(x, y, z, name);
        moves = false;

        for (i in 0...MAX_HISTORY) {
            positionHistory.push(FlxPoint.get(x, y));
        }
    }

    override public function loadEntity(folder:String, spriteName:String) {
        super.loadEntity(folder, spriteName);
        
        updateHitbox(); 

        offset.set(width / 2, height);
        
        colOffsetX = -(colWidth / 2);
        colOffsetY = -colHeight;

        hitboxGraphic = new FlxSprite();
        hitboxGraphic.makeGraphic(Std.int(colWidth), Std.int(colHeight), flixel.util.FlxColor.TRANSPARENT);
        flixel.util.FlxSpriteUtil.drawRect(hitboxGraphic, 0, 0, colWidth, colHeight, flixel.util.FlxColor.TRANSPARENT, {thickness: 2, color: flixel.util.FlxColor.RED});

        animation.addByPrefix("idle_down",  "idle_down", 1, false);
        animation.addByPrefix("walk_down",  "walk_down", 6, true);
        animation.addByPrefix("run_down",   "run_down", 10, true);
        animation.addByPrefix("idle_left",  "idle_left", 1, false);
        animation.addByPrefix("walk_left",  "walk_left", 6, true);
        animation.addByPrefix("run_left",   "run_left", 10, true);
        animation.addByPrefix("idle_right", "idle_right", 1, false);
        animation.addByPrefix("walk_right", "walk_right", 6, true);
        animation.addByPrefix("run_right",  "run_right", 10, true);
        animation.addByPrefix("idle_up",    "idle_up", 1, false);
        animation.addByPrefix("walk_up",    "walk_up", 6, true);
        animation.addByPrefix("run_up",     "run_up", 10, true);
        
        animation.play("idle_down");
    }

    override public function draw():Void {
        super.draw();
        
        // Draw red collision box over mathematical coordinates
        if (showHitbox && hitboxGraphic != null) {
            hitboxGraphic.x = this.x + colOffsetX;
            hitboxGraphic.y = this.y + colOffsetY;
            hitboxGraphic.scrollFactor.set(this.scrollFactor.x, this.scrollFactor.y); 
            hitboxGraphic.draw();
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        recordHistory();
        updateAnimations();
    }

    function recordHistory() {
        if (positionHistory.length == 0 || positionHistory[0].x != x || positionHistory[0].y != y) {
            positionHistory.unshift(FlxPoint.get(x, y));
            if (positionHistory.length > MAX_HISTORY) positionHistory.pop().put();
        }
    }

    public function updateAnimations():Void {
        if (velocity.x > 10) currentFacing = RIGHT;
        else if (velocity.x < -10) currentFacing = LEFT;
        else if (velocity.y > 10) currentFacing = DOWN;
        else if (velocity.y < -10) currentFacing = UP;

        var isMoving = (Math.abs(velocity.x) > 5 || Math.abs(velocity.y) > 5);
        currentState = isMoving ? Walking : Standing;

        var faceStr = switch (currentFacing) {
            case UP: "_up"; case LEFT: "_left"; case RIGHT: "_right"; default: "_down";
        }

        switch (currentState) {
            case Walking: animation.play("walk" + faceStr);
            case Running: animation.play("run" + faceStr);
            case Standing, Idle: animation.play("idle" + faceStr);
            default: animation.play("idle" + faceStr);
        }
    }

    override public function getCollisionBox():FlxRect {
        return FlxRect.get(x + colOffsetX, y + colOffsetY, colWidth, colHeight);
    }

    public function getInteractionBox():FlxRect {
        var box = FlxRect.get();
        switch (currentFacing) {
            case UP:    box.set(x - 8, y - 20, 16, 10);
            case DOWN:  box.set(x - 8, y + 2,  16, 10);
            case LEFT:  box.set(x - 20, y - 10, 10, 16);
            case RIGHT: box.set(x + 10, y - 10, 10, 16);
        }
        return box;
    }
}