package engine.substates;

class Pause extends SubStateBackend {
	var menuItems:Array<String> = [
		"system.menu.inventory",
		"system.menu.objectives",
		"system.menu.settings",
		"system.menu.load",
		"system.menu.quit"
	];
	var visualItems:Array<PauseMenuVisualEntry> = [];
	var optionContainer:FlxSpriteGroup;
	var selectedIndex:Int = 0;

	var isAnimating:Bool = true;

	public function new() {
		super();
	}

	override public function create():Void {
		super.create();

		var pauseBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
		pauseBG.scrollFactor.set(0, 0);
		pauseBG.alpha = 0;
		add(pauseBG);

		var mainFrame = new MenuFrameNode(10, 10, 450, 600, 1);
		add(mainFrame);

		var chapterFrame = new MenuFrameNode(10, 615, 450, 135, 1);
		chapterFrame.nodeFrame.texture = "ui/frames/frame_menu_2b";
		add(chapterFrame);

		var bottomFrame = new MenuFrameNode(10, 755, 450, 240, 1);
		bottomFrame.nodeFrame.texture = "ui/frames/frame_menu_2b";
		add(bottomFrame);

		optionContainer = new FlxSpriteGroup();
		var startY:Float = 60;
		var cellSpacing:Float = 55;

		for (i in 0...menuItems.length) {
			var entryY = startY + (i * cellSpacing);
			var entry = new PauseMenuVisualEntry(20, entryY, menuItems[i], 440, cellSpacing);
			visualItems.push(entry);
			optionContainer.add(entry);
		}

		add(optionContainer);

		var chapterText = new FlxText(20, 660, 440, Game.instance.language.getCaption("system.menu.pause.text"), 32);
		chapterText.alignment = CENTER;
		add(chapterText);

		updateHighlight();

		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.addDPad("FULL");
		Game.mobileC.addButton("MENU");
		#end

		var slideOffset:Float = 450.0;
		var duration:Float = 0.15;

		mainFrame.x -= slideOffset;
		optionContainer.x -= slideOffset;

		chapterFrame.x -= slideOffset;
		chapterText.x -= slideOffset;

		bottomFrame.x -= slideOffset;

		FlxTween.tween(pauseBG, {alpha: 1}, duration);

		FlxTween.tween(mainFrame, {x: mainFrame.x + slideOffset}, duration, {ease: FlxEase.quadOut});
		FlxTween.tween(optionContainer, {x: optionContainer.x + slideOffset}, duration, {ease: FlxEase.quadOut});

		FlxTween.tween(chapterFrame, {x: chapterFrame.x + slideOffset}, duration, {ease: FlxEase.quadOut, startDelay: 0.08});
		FlxTween.tween(chapterText, {x: chapterText.x + slideOffset}, duration, {ease: FlxEase.quadOut, startDelay: 0.08});

		FlxTween.tween(bottomFrame, {x: bottomFrame.x + slideOffset}, duration, {
			ease: FlxEase.quadOut,
			startDelay: 0.16,
			onComplete: function(twn:FlxTween) {
				isAnimating = false;
			}
		});
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (isAnimating)
			return;

		if (Controls.UP_P) {
			LilyAssets.play(LilyAssets.NAVIGATE);
			selectedIndex--;
			if (selectedIndex < 0)
				selectedIndex = menuItems.length - 1;
			updateHighlight();
		} else if (Controls.DOWN_P) {
			LilyAssets.play(LilyAssets.NAVIGATE);
			selectedIndex++;
			if (selectedIndex >= menuItems.length)
				selectedIndex = 0;
			updateHighlight();
		}

		if (Controls.ACCEPT) {
			LilyAssets.play(LilyAssets.CONFIRM);
			selectCurrentItem();
		}

		if (Controls.CANCEL) {
			LilyAssets.play(LilyAssets.CANCEL);
			close();
		}
	}

	private function updateHighlight():Void {
		for (i in 0...visualItems.length) {
			visualItems[i].setHighlight(i == selectedIndex);
		}
	}

	private function selectCurrentItem():Void {
		switch (selectedIndex) {
			case 0:
				openSubState(new Inventory());
			case 1:
				openSubState(new Objectives());
			case 2:
				openSubState(new Settings("main", true));
			case 3:
				openSubState(new SaveLoad(false, false));
			case 4:
				StateBackend.switchState(new engine.states.TitleMenu());
		}
	}
}

class PauseMenuVisualEntry extends MenuVisualEntry {
	public var optionLabel:FlxText;

	public function new(X:Float, Y:Float, transKey:String, textWidth:Float, cellHeight:Float) {
		super(X, Y, "", textWidth, cellHeight);

		bg.makeGraphic(240, 36, FlxColor.TRANSPARENT);
		bg.x = this.x + 115;
		bg.y = this.y + 8;

		optionLabel = new FlxText(0, 0, textWidth, Game.instance.language.getCaption(transKey), 32);
		optionLabel.alignment = CENTER;
		add(optionLabel);

		optionLabel.x = this.x;
		optionLabel.y = this.y + (cellHeight - optionLabel.height) / 2;
	}

	override public function setHighlight(isActive:Bool):Void {
		bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), isActive ? 0x66FFFFFF : FlxColor.TRANSPARENT);
	}
}
