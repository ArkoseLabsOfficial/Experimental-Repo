package objects;

class Follower extends CharacterEntity {
    public var target:CharacterEntity;
    public var followDistance:Int = 30;

    public function new(x:Float, y:Float, z:Int, name:String) {
        super(x, y, z, name);
        solidCollision = false; // Followers never block the player!
    }

    override public function update(elapsed:Float) {
        if (target != null && target.positionHistory.length > followDistance) {
            var targetPos = target.positionHistory[followDistance];
            
            velocity.x = (targetPos.x - x) / elapsed;
            velocity.y = (targetPos.y - y) / elapsed;
            
            // Snap mathematically
            x = targetPos.x;
            y = targetPos.y;
        } else {
            velocity.set(0, 0);
        }
        super.update(elapsed);
    }
}