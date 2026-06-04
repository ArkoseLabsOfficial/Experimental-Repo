package engine.substates;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import engine.backend.Language;
import engine.backend.Controls;
import engine.ui.LacieUIExperimental.MenuFrameNode;
import io.LilyAssets;

typedef ObtainedItem = {
    var itemID:String;
    var count:Int;
}

class ObtainScreen extends SubStateBackend {
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
        
        var camObtain = new flixel.FlxCamera();
        camObtain.bgColor = FlxColor.TRANSPARENT; 
        FlxG.cameras.add(camObtain, false);
        this.cameras = [camObtain];

        var obtainBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
        obtainBG.scrollFactor.set(0, 0);
        add(obtainBG);

        menuFrame = new MenuFrameNode(0, 0, panelW, panelH, false);
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

        #if FEATURE_TOUCH_CONTROLS
        mobile.controls.addMobilePad("NONE", "B");
        mobile.controls.addMobilePadCamera();
        #end
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (Controls.ACCEPT_P) {
            progressQueue();
        }
    }

    private function progressQueue():Void {
        var currentItem = itemQueue[currentIndex];
        ItemManager.addItem(currentItem.itemID, currentItem.count);
        currentIndex++;

        if (currentIndex >= itemQueue.length) {
            close();
        } else {
            updateScreenToCurrentItem();
        }
    }

    private function updateScreenToCurrentItem():Void {
        var currentItem = itemQueue[currentIndex];
        var localizedItemName:String = Language.GetCaption("system.game.item." + currentItem.itemID);
        var quantityStr = currentItem.count > 1 ? " x" + currentItem.count : "";
        obtainText.text = Language.GetCaption("system.menu.obtained") + ": " + localizedItemName + quantityStr;
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