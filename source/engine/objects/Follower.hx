package engine.objects;

class Follower extends CharacterEntity {
	public var target:CharacterEntity;
	public var followDistance:Int = 12;
	public var getPlayerAnims:Bool = false;

	public function new(x:Float, y:Float, z:Int, name:String) {
		super(x, y, z, name);
		solidCollision = false;
	}

	override public function update(elapsed:Float) {
		if (target != null && target.positionHistory.length > followDistance) {
			var targetPos = target.positionHistory[followDistance];

			var oldX = x;
			var oldY = y;

			var lerp = elapsed * 14;
			if (lerp > 1)
				lerp = 1;

			x += (targetPos.x - x) * lerp;
			y += (targetPos.y - y) * lerp;

			velocity.x = (x - oldX) / elapsed;
			velocity.y = (y - oldY) / elapsed;

			if (Math.abs(targetPos.x - x) < 0.5 && Math.abs(targetPos.y - y) < 0.5) {
				x = targetPos.x;
				y = targetPos.y;
				velocity.set(0, 0);
			}
		} else {
			velocity.x *= 0.8;
			velocity.y *= 0.8;
			if (Math.abs(velocity.x) < 5)
				velocity.x = 0;
			if (Math.abs(velocity.y) < 5)
				velocity.y = 0;
		}

		super.update(elapsed);
	}

	override public function updateAnimations():Void {
		if (getPlayerAnims && target != null) {
			currentFacing = target.currentFacing;
			currentState = target.currentState;

			var faceStr = switch (currentFacing) {
				case UP: "UP";
				case LEFT: "LEFT";
				case RIGHT: "RIGHT";
				default: "DOWN";
			}

			var animName = switch (currentState) {
				case Walking: "walk" + faceStr;
				case Running: "run" + faceStr;
				case Standing, Idle: "idle" + faceStr;
				default: "idle" + faceStr;
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
		} else {
			super.updateAnimations();
		}
	}
}
