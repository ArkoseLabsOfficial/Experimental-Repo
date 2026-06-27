package engine.objects;

class Player extends CharacterEntity {
	var walkSpeed:Float = 160;
	var runSpeed:Float = 280;

	override public function loadEntity(folder:String, spriteName:String) {
		super.loadEntity(folder, spriteName);

		colWidth = 24;
		colHeight = 16;
		colOffsetX = -(colWidth / 2);
		colOffsetY = -colHeight;

		hitboxGraphic.makeGraphic(Std.int(colWidth), Std.int(colHeight), flixel.util.FlxColor.TRANSPARENT);
		flixel.util.FlxSpriteUtil.drawRect(hitboxGraphic, 0, 0, colWidth, colHeight, flixel.util.FlxColor.TRANSPARENT,
			{thickness: 2, color: flixel.util.FlxColor.RED});

		showHitbox = false;
	}

	override public function update(elapsed:Float):Void {
		velocity.set(0, 0);
		if (canMove)
			handleMovement(elapsed);

		if (velocity.x != 0 || velocity.y != 0) {
			var stepX = velocity.x * elapsed;
			var stepY = velocity.y * elapsed;

			if (!checkCollision(x + stepX, y))
				x += stepX;
			if (!checkCollision(x, y + stepY))
				y += stepY;
		}

		super.update(elapsed);
	}

	function checkCollision(targetX:Float, targetY:Float):Bool {
		var pBox = FlxRect.get(targetX + colOffsetX, targetY + colOffsetY, colWidth, colHeight);
		var hit = false;

		if (RoomManager.instance != null) {
			for (solid in RoomManager.instance.solids) {
				var sBox = FlxRect.get(solid.x, solid.y, solid.width, solid.height);
				if (pBox.overlaps(sBox)) {
					hit = true;
					sBox.put();
					break;
				}
				sBox.put();
			}

			if (!hit) {
				for (entity in RoomManager.instance.entities) {
					if (entity != this && entity.solidCollision) {
						var eBox = entity.getCollisionBox();
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

		if (up && down)
			up = down = false;
		if (left && right)
			left = right = false;

		var speed = Controls.RUN ? runSpeed : walkSpeed;

		if (up)
			velocity.y -= speed;
		else if (down)
			velocity.y += speed;
		if (left)
			velocity.x -= speed;
		else if (right)
			velocity.x += speed;

		if (velocity.x != 0 && velocity.y != 0) {
			velocity.normalize();
			velocity.scale(speed);
		}
	}
}
