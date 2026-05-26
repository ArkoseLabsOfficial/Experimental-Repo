package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import backend.UIUtil;

class PauseSubState extends SubStateBackend {
    var menuItems:Array<String> = ["system.menu.inventory", "system.menu.objectives", "system.menu.settings", "system.menu.load", "system.menu.quit"];
    var textGroup:FlxTypedGroup<FlxText>;
    var highlightBox:FlxSprite;
    var selectedIndex:Int = 2;
    var camPause:FlxCamera;

    public function new() {
        super();
    }

    override public function create():Void {
        camPause = new FlxCamera();
        camPause.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(camPause, false);
        this.cameras = [camPause];

        super.create();

        var pauseBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
        pauseBG.scrollFactor.set(0, 0);
        add(pauseBG);

        add(UIUtil.createPanel(LilyAssets.image("img/ui/frame_menu_2"), 10, 10, 450, 600, 0.66));
        add(UIUtil.createPanel(LilyAssets.image("img/ui/frame_menu_2b"), 10, 615, 450, 135, 0.66));
        add(UIUtil.createPanel(LilyAssets.image("img/ui/frame_menu_2b"), 10, 755, 450, 240, 0.66));
        
        highlightBox = UIUtil.createHighlightBox(115, 0, 240, 36);
        add(highlightBox);

        textGroup = new FlxTypedGroup<FlxText>();
        add(textGroup);

        for (i in 0...menuItems.length) {
            var itemText = UIUtil.createText(20, 60 + (i * 55), 440, Language.GetCaption(menuItems[i]), 32);
            textGroup.add(itemText);
        }

        var chapterText = UIUtil.createText(20, 660, 440, "Paper Lily Chapter 1", 32);
        add(chapterText);

        var infoBoxWidth:Float = 210;
        var infoBoxHeight:Float = 70;
        var infoBoxX:Float = FlxG.width - infoBoxWidth;
        var infoBoxY:Float = FlxG.height - infoBoxHeight;

        var infoBox = UIUtil.createInfoBox(LilyAssets.image("img/ui/frame_infobox"), infoBoxX - 35, infoBoxY - 10, infoBoxWidth, infoBoxHeight, 0.66);
        add(infoBox);

        var controlsText = UIUtil.createText(infoBoxX - 135, infoBoxY + (infoBoxHeight / 2) - 30, 400, Language.GetCaption("system.menu.tip"), 24);
        add(controlsText);

        updateHighlight();

        mobile.controls.addMobilePad("FULL", "A_B");
        mobile.controls.addMobilePadCamera();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (Controls.UP_P) {
            UIUtil.playNavSound();
            selectedIndex--;
            if (selectedIndex < 0) selectedIndex = menuItems.length - 1;
            updateHighlight();
        } else if (Controls.DOWN_P) {
            UIUtil.playNavSound();
            selectedIndex++;
            if (selectedIndex >= menuItems.length) selectedIndex = 0;
            updateHighlight();
        }

        if (Controls.ACCEPT_P) {
            UIUtil.playConfirmSound();
            selectCurrentItem();
        }

        if (Controls.CANCEL_P) {
            UIUtil.playCancelSound();
            close();
        }
    }

    override public function destroy():Void {
        FlxG.cameras.remove(camPause);
        camPause.destroy();
        super.destroy();
    }

    private function updateHighlight():Void {
        var activeText = textGroup.members[selectedIndex];
        highlightBox.y = activeText.y + 8; 
    }

    private function selectCurrentItem():Void {
        switch(selectedIndex) {
            case 0: openSubState(new InventorySubState());
            case 1: openSubState(new ObjectivesMenuSubstate());
            case 2: openSubState(new SettingsScreenBase("main", true));                
            case 3: openSubState(new SaveLoadSubState(false));
            case 4: FlxG.switchState(new MainMenuState());
        }
    }
}