package engine.states;

typedef MenuDefinition = {
	var transKey:String;
	var action:Int->Void;
}

class TitleMenu extends StateBackend {
	var bg:FlxSprite;
	var titleLogo:FlxSprite;
	var extraInfoText:FlxText;
	var versionInfoText:FlxText;

	var menuFrame:MenuFrameNode;
	var optionContainer:FlxSpriteGroup;
	var visualItems:Array<MainMenuVisualEntry> = [];
	var menuDefinitions:Array<MenuDefinition> = [];

	var selectedIndex:Int = 0;
	var layoutSpacing:Float = 50;
	var hasSaveFile:Bool = false;

	override public function create():Void {
		super.create();

		for (slotNum in 0...31) {
			var info = Game.instance.save.getSlotInfo(slotNum);
			if (!hasSaveFile && !info.isEmpty)
				hasSaveFile = true;
		}

		GamePrefs.loadSettings();
		Game.instance.items.load();
		Game.instance.language.loadLanguage(Game.instance.language.currentLanguage);

		bg = new FlxSprite(0, 0).loadGraphic(LilyAssets.image("img/cg/ch1/paperlily_title"));
		bg.setGraphicSize(1920, 1080);
		bg.updateHitbox();
		add(bg);

		titleLogo = new FlxSprite(1134, 282);
		add(titleLogo);

		extraInfoText = new FlxText(0, FlxG.height - 65, FlxG.width - 15, "", 24);
		extraInfoText.alignment = RIGHT;
		add(extraInfoText);

		versionInfoText = new FlxText(0, FlxG.height - 35, FlxG.width - 15, "v1.1.6 Debug © Leef 6010 2024", 24);
		versionInfoText.alignment = RIGHT;
		add(versionInfoText);

		Game.instance.language.onLanguageUpdate.push(updateLocalizedImages);
		updateLocalizedImages();

		if (hasSaveFile) {
			menuDefinitions.push({transKey: "system.menu.loadgame", action: function(d:Int) {
				openSubState(new SaveLoad(false, true));
			}});
		}
		menuDefinitions.push({transKey: "system.menu.newgame", action: function(d:Int) {
			Game.instance.save.reset();
			StateBackend.switchState(new BaseRoom(LilyAssets.getTextFromFile("rooms/start_room.txt")));
		}});
		// menuDefinitions.push({ transKey: "system.menu.debugroom", action: function(d:Int) { FlxG.switchState(new RoomEditorState()); } });
		menuDefinitions.push({transKey: "system.menu.settings", action: function(d:Int) {
			openSubState(new Settings());
		}});
		menuDefinitions.push({transKey: "system.menu.website.translator", action: function(d:Int) {}});
		menuDefinitions.push({transKey: "system.menu.quit", action: function(d:Int) {
			System.exit(0);
		}});

		var frameX:Float = 1300;
		var frameY:Float = 561;
		var fixedWidth:Float = 400;
		var dynamicHeight:Float = (menuDefinitions.length * layoutSpacing) + 60;

		menuFrame = new MenuFrameNode(frameX, frameY, fixedWidth, dynamicHeight, 0);
		add(menuFrame);

		optionContainer = new FlxSpriteGroup();
		var startY = frameY + 30; // 30px top padding

		for (i in 0...menuDefinitions.length) {
			var def = menuDefinitions[i];
			var entryY = startY + (i * layoutSpacing);

			var entry = new MainMenuVisualEntry(frameX, entryY, def.transKey, fixedWidth, layoutSpacing);
			visualItems.push(entry);
			optionContainer.add(entry);
		}

		add(optionContainer);
		changeSelection(0);

		Game.instance.language.onLanguageUpdate.push(refreshText);

		#if FEATURE_TOUCH_CONTROLS
		Game.mobileC.addDPad("FULL");
		Game.mobileC.addButton("MENU");
		#end
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		if (subState != null)
			return;

		if (Controls.UP_P) {
			LilyAssets.play(LilyAssets.NAVIGATE);
			changeSelection(-1);
		}
		if (Controls.DOWN_P) {
			LilyAssets.play(LilyAssets.NAVIGATE);
			changeSelection(1);
		}
		if (visualItems.length > 0 && Controls.ACCEPT) {
			LilyAssets.play(LilyAssets.CONFIRM);
			menuDefinitions[selectedIndex].action(0);
		}
	}

	public function changeSelection(change:Int = 0):Void {
		selectedIndex += change;
		if (selectedIndex < 0)
			selectedIndex = visualItems.length - 1;
		if (selectedIndex >= visualItems.length)
			selectedIndex = 0;

		for (i in 0...visualItems.length) {
			visualItems[i].setHighlight(i == selectedIndex);
		}
	}

	function refreshText():Void {
		for (item in visualItems) {
			item.refreshText();
		}
	}

	function updateLocalizedImages():Void {
		titleLogo.loadGraphic(LilyAssets.image("img/ui/title_logo_paperlily"));
		titleLogo.scale.set(0.8, 0.8);
		titleLogo.updateHitbox();
		extraInfoText.text = Game.instance.language.getCaption("system.menu.translator.credit");
	}

	override public function destroy():Void {
		Game.instance.language.onLanguageUpdate.remove(refreshText);
		Game.instance.language.onLanguageUpdate.remove(updateLocalizedImages);
		super.destroy();
	}
}

class MainMenuVisualEntry extends MenuVisualEntry {
	public var optionLabel:FlxText;
	public var transKey:String;

	public function new(X:Float, Y:Float, transKey:String, frameWidth:Float, cellHeight:Float) {
		super(X, Y, "", frameWidth, cellHeight);
		this.transKey = transKey;

		bg.makeGraphic(Std.int(frameWidth - 80), 38, FlxColor.TRANSPARENT);

		bg.x = this.x + 40;
		bg.y = this.y + (cellHeight - 38) / 2;

		var ts = 24;

		optionLabel = new FlxText(0, 0, frameWidth, Game.instance.language.getCaption(transKey), ts);
		optionLabel.alignment = CENTER;

		add(optionLabel);

		optionLabel.x = this.x;
		optionLabel.y = this.y + (cellHeight - optionLabel.height) / 2;
	}

	override public function setHighlight(isActive:Bool):Void {
		bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), isActive ? 0x66FFFFFF : FlxColor.TRANSPARENT);
	}

	public function refreshText():Void {
		optionLabel.text = Game.instance.language.getCaption(transKey);
	}
}
