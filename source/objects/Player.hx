package objects;

import flixel.FlxG;
import flixel.math.FlxRect;
import backend.Controls;

class Player extends CharacterEntity {
    public var canMove:Bool = true;
    var walkSpeed:Float = 160;
    var runSpeed:Float = 280;

    override public function loadEntity(folder:String, spriteName:String) {
        super.loadEntity(folder, spriteName);

        updateHitbox(); 
        offset.set(width / 2, height); // Visual anchor to feet
        
        // Player Hitbox
        colWidth = 24;
        colHeight = 16;
        colOffsetX = -(colWidth / 2);
        colOffsetY = -colHeight;
        
        hitboxGraphic.makeGraphic(Std.int(colWidth), Std.int(colHeight), flixel.util.FlxColor.TRANSPARENT);
        flixel.util.FlxSpriteUtil.drawRect(hitboxGraphic, 0, 0, colWidth, colHeight, flixel.util.FlxColor.TRANSPARENT, {thickness: 2, color: flixel.util.FlxColor.RED});

        showHitbox = true; 
    }

    override public function update(elapsed:Float):Void {
        velocity.set(0, 0);
        if (canMove) handleMovement(elapsed);

        // Predictive Movement
        if (velocity.x != 0 || velocity.y != 0) {
            var stepX = velocity.x * elapsed;
            var stepY = velocity.y * elapsed;

            // X Axis
            if (!checkCollision(x + stepX, y)) {
                x += stepX;
            }

            // Y Axis
            if (!checkCollision(x, y + stepY)) {
                y += stepY;
            }
        }

        super.update(elapsed); 
    }

    function checkCollision(targetX:Float, targetY:Float):Bool {
        var pBox = FlxRect.get(targetX + colOffsetX, targetY + colOffsetY, colWidth, colHeight);
        var hit = false;
        
        if (backend.RoomManager.instance != null) {
            
            // Check Invisible Solid Editor Blocks
            for (solid in backend.RoomManager.instance.solids) {
                var sBox = FlxRect.get(solid.x, solid.y, solid.width, solid.height);
                if (pBox.overlaps(sBox)) {
                    hit = true;
                    sBox.put();
                    break;
                }
                sBox.put();
            }

            // Check Auto-Collision World Objects & NPCs
            if (!hit) {
                for (entity in backend.RoomManager.instance.entities) {
                    // Ignore ourselves, and check if the object has collision enabled
                    if (entity != this && entity.solidCollision) {
                        
                        var eBox = entity.getCollisionBox(); // Grabs the correct box for both Props and NPCs!
                        
                        if (pBox.overlaps(eBox)) {
                            hit = true;
                            eBox.put();
                            break;
                        }
                        eBox.put();
                    }
                }
            }
        }
        
        pBox.put();
        return hit;
    }

    function handleMovement(elapsed:Float):Void {
        var up = Controls.UP || FlxG.keys.anyPressed([W, UP]);
        var down = Controls.DOWN || FlxG.keys.anyPressed([S, DOWN]);
        var left = Controls.LEFT || FlxG.keys.anyPressed([A, LEFT]);
        var right = Controls.RIGHT || FlxG.keys.anyPressed([D, RIGHT]);

        if (up && down) up = down = false;
        if (left && right) left = right = false;

        var speed = Controls.RUN ? runSpeed : walkSpeed;

        if (up) velocity.y -= speed;
        else if (down) velocity.y += speed;
        if (left) velocity.x -= speed;
        else if (right) velocity.x += speed;

        if (velocity.x != 0 && velocity.y != 0) {
            velocity.normalize();
            velocity.scale(speed);
        }
    }
}