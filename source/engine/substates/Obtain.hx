package engine.substates;

typedef ObtainedItem = {
	var itemID:String;
	var count:Int;
}

class Obtain extends SubStateBackend {
	var itemQueue:Array<ObtainedItem>;
	var currentIndex:Int = 0;

	var menuFrame:MenuFrameNode;
	var contentGroup:FlxSpriteGroup;

	var itemIcon:FlxSprite;
	var obtainText:FlxText;

	var panelW:Float = 500;
	var panelH:Float = 120;

	public function new(itemsToGive:Array<ObtainedItem>) {
		super();
		this.itemQueue = itemsToGive;
	}

	override public function create() {
		super.create();
		var obtainBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
		obtainBG.scrollFactor.set(0, 0);
		add(obtainBG);

		menuFrame = new MenuFrameNode(0, 0, panelW, panelH, 0);
		menuFrame.screenCenter();
		add(menuFrame);

		contentGroup = new FlxSpriteGroup();
		obtainText = new FlxText(0, 0, 0, "", 28);
		obtainText.alignment = LEFT;

		itemIcon = new FlxSprite(0, 0);

		contentGroup.add(itemIcon);
		contentGroup.add(obtainText);
		add(contentGroup);

		updateScreenToCurrentItem();
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var justTouched:Bool = false;
		#if FLX_TOUCH
		for (touch in FlxG.touches.list) {
			if (touch.justPressed) {
				justTouched = true;
				break;
			}
		}
		#end

		if (Controls.ACCEPT || justTouched) {
			progressQueue();
		}
	}

	private function progressQueue():Void {
		var currentItem = itemQueue[currentIndex];
		Game.instance.items.addItem(currentItem.itemID, currentItem.count);
		currentIndex++;

		if (currentIndex >= itemQueue.length) {
			close();
		} else {
			updateScreenToCurrentItem();
		}
	}

	private function updateScreenToCurrentItem():Void {
		var currentItem = itemQueue[currentIndex];
		var localizedItemName:String = Game.instance.language.getCaption("system.game.item." + currentItem.itemID);
		var quantityStr = currentItem.count > 1 ? " x" + currentItem.count : "";
		obtainText.text = Game.instance.language.getCaption("system.menu.obtained") + ": " + localizedItemName + quantityStr;
		itemIcon.loadGraphic(LilyAssets.image("sprite/common/item/" + currentItem.itemID));
		itemIcon.setGraphicSize(40, 40);
		itemIcon.updateHitbox();

		var spacing:Float = 15;
		var totalContentWidth = itemIcon.width + spacing + obtainText.width;
		var startX = menuFrame.x + (panelW - totalContentWidth) / 2;
		itemIcon.x = startX;
		itemIcon.y = menuFrame.y + (panelH - itemIcon.height) / 2;
		obtainText.x = itemIcon.x + itemIcon.width + spacing;
		obtainText.y = menuFrame.y + (panelH - obtainText.height) / 2;
	}
}
