package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;

class PauseSubState extends FlxSubState
{
    var menuItems:Array<String> = ["system.menu.inventory", "system.menu.objectives", "system.menu.settings", "system.menu.load", "system.menu.quit"];
    var textGroup:FlxTypedGroup<FlxText>;
    var highlightBox:FlxSprite;
    var selectedIndex:Int = 2;

    var camPause:FlxCamera;

    public function new()
    {
        super();
    }

    override public function create():Void
    {
        camPause = new FlxCamera();
        camPause.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(camPause, false);
        this.cameras = [camPause];

        super.create();

        var pauseBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
        pauseBG.scrollFactor.set(0, 0);
        add(pauseBG);

        // Left-side Panels
        createPanel("assets/img/ui/frame_menu_2.png", 10, 10, 450, 600, 0.66);
        createPanel("assets/img/ui/frame_menu_2b.png", 10, 615, 450, 135, 0.66);
        createPanel("assets/img/ui/frame_menu_2b.png", 10, 755, 450, 240, 0.66);
        
        // White Selector
        highlightBox = new FlxSprite(115, 0).makeGraphic(240, 36, 0xFF4A4A4A);
        add(highlightBox);

        // Text Group
        textGroup = new FlxTypedGroup<FlxText>();
        add(textGroup);

        for (i in 0...menuItems.length)
        {
            var itemText = new FlxText(20, 60 + (i * 55), 440, Language.GetCaption(menuItems[i]), 32);
            itemText.alignment = CENTER;
            itemText.font = "assets/fonts/AlegreyaSC-Regular.ttf";
            textGroup.add(itemText);
        }

        // Chapter Text (Replica of System Name backup logic)
        var chapterText = new FlxText(20, 660, 440, "Paper Lily Chapter 1", 32);
        chapterText.alignment = CENTER;
        add(chapterText);

        var infoBoxWidth:Float = 210;
        var infoBoxHeight:Float = 70;

        // Calculate bottom-right positioning anchoring
        var infoBoxX:Float = FlxG.width - infoBoxWidth;
        var infoBoxY:Float = FlxG.height - infoBoxHeight;

        var infoBox = createBox("assets/img/ui/frame_infobox.png", infoBoxX - 35, infoBoxY - 10, infoBoxWidth, infoBoxHeight, 0.66);
        infoBox.scale.set(1.3, 1.3);

        // Ported text labels attached dynamically inside InfoBox
        var controlsText = new FlxText(infoBoxX - 135, infoBoxY + (infoBoxHeight / 2) - 30, 400, Language.GetCaption("system.menu.tip"), 24);
        controlsText.alignment = CENTER;
        controlsText.font = "assets/fonts/AlegreyaSC-Regular.ttf"; // Keeping the project UI aesthetic uniform
        add(controlsText);

        updateHighlight();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (Controls.UP_P)
        {
            FlxG.sound.play("assets/sfx/ui_navigation.ogg");
            selectedIndex--;
            if (selectedIndex < 0) selectedIndex = menuItems.length - 1;
            updateHighlight();
        }
        else if (Controls.DOWN_P)
        {
            FlxG.sound.play("assets/sfx/ui_navigation.ogg");
            selectedIndex++;
            if (selectedIndex >= menuItems.length) selectedIndex = 0;
            updateHighlight();
        }

        if (Controls.ACCEPT_P)
        {
            FlxG.sound.play("assets/sfx/ui_start.ogg");
            selectCurrentItem();
        }

        if (Controls.CANCEL_P)
        {
            FlxG.sound.play("assets/sfx/ui_navigation2.ogg");
            close();
        }
    }

    override public function destroy():Void
    {
        FlxG.cameras.remove(camPause);
        camPause.destroy();
        super.destroy();
    }

    private function updateHighlight():Void
    {
        var activeText = textGroup.members[selectedIndex];
        highlightBox.y = activeText.y + 8; 
    }

    private function selectCurrentItem():Void
    {
        switch(selectedIndex) {
            case 0:
                openSubState(new InventorySubState());
            case 1:
                openSubState(new ObjectivesMenuSubstate());
                //openSubState(new ObjectivesSubState());
            case 2:
                openSubState(new SettingsScreenBase("main", true));                
            case 3:
                openSubState(new SaveLoadSubState(false));
            case 4:
                //openSubState(new SaveLoadSubState(true));
                FlxG.switchState(new MainMenuState());
        }
    }

    private function createPanel(frameImage:String, X:Float, Y:Float, Width:Float, Height:Float, scaleFactor:Float):Dynamic
    {
        var bgPadding:Int = 4;
        var bg = new FlxSprite(X + bgPadding, Y + bgPadding, "assets/img/ui/frame_menu_bg.png");
        bg.setGraphicSize(Std.int(Width - (bgPadding * 2)), Std.int(Height - (bgPadding * 2)));
        bg.updateHitbox();
        add(bg);

        var hud = UIUtil.create9SliceSprite(frameImage, X, Y, Width, Height, scaleFactor);
        add(hud);

        return hud;
    }

    private function createBox(frameImage:String, X:Float, Y:Float, Width:Float, Height:Float, scaleFactor:Float):Dynamic
    {
        var bgPadding:Int = -30;
        var bg = new FlxSprite(X + bgPadding, Y + bgPadding + 20, "assets/img/ui/frame_menu_bg.png");
        bg.setGraphicSize(Std.int(Width) * 1.3, Std.int(Height) * 1.3);
        bg.updateHitbox();
        add(bg);

        var hud = UIUtil.create9SliceSprite(frameImage, X, Y, Width, Height, scaleFactor);
        add(hud);

        return hud;
    }
}