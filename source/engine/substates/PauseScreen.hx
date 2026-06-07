package engine.substates;

class PauseScreen extends SubStateBackend {
    var menuItems:Array<String> = ["system.menu.inventory", "system.menu.objectives", "system.menu.settings", "system.menu.load", "system.menu.quit"];
    var visualItems:Array<PauseMenuVisualEntry> = [];
    var optionContainer:FlxSpriteGroup;
    var selectedIndex:Int = 0;
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

        var mainFrame = new MenuFrameNode(10, 10, 450, 600, 1);
        add(mainFrame);

        var chapterFrame = new MenuFrameNode(10, 615, 450, 135, 1);
        chapterFrame.nodeFrame.texture = LilyAssets.image("img/ui/frame_menu_2b");
        chapterFrame.nodeFrame.render();
        add(chapterFrame);

        var bottomFrame = new MenuFrameNode(10, 755, 450, 240, 1);
        bottomFrame.nodeFrame.texture = LilyAssets.image("img/ui/frame_menu_2b");
        bottomFrame.nodeFrame.render();
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

        var chapterText = new FlxText(0, 0, 440, "lilyengine.mods.modname", 32);
        chapterText.alignment = CENTER;
        add(chapterText);
        
        chapterText.x = 20;
        chapterText.y = 660;

        updateHighlight();

        #if FEATURE_TOUCH_CONTROLS
        mobile.controls.addMobilePad("FULL", "A_B");
        mobile.controls.addMobilePadCamera();
        #end
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
        for (i in 0...visualItems.length) {
            visualItems[i].setHighlight(i == selectedIndex);
        }
    }

    private function selectCurrentItem():Void {
        switch(selectedIndex) {
            case 0: openSubState(new Inventory());
            case 1: openSubState(new ObjectivesMenu());
            case 2: openSubState(new SettingsScreen("main", true));                
            case 3: openSubState(new SaveLoadSubState(false));
            case 4: FlxG.switchState(new MainMenuState());
        }
    }
}

class PauseMenuVisualEntry extends MenuVisualEntry {
    public var optionLabel:FlxText;
    
    public function new(X:Float, Y:Float, transKey:String, textWidth:Float, cellHeight:Float) {
        super(X, Y, "", textWidth, cellHeight); 
        
        bg.makeGraphic(240, 36, FlxColor.TRANSPARENT);
        bg.x = 115; 
        bg.y = Y + 8; 
        
        optionLabel = new FlxText(0, 0, textWidth, Language.GetCaption(transKey), 32);
        optionLabel.alignment = CENTER;
        add(optionLabel);
        
        optionLabel.x = X; 
        optionLabel.y = Y;
    }
    
    override public function setHighlight(isActive:Bool):Void { 
        bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), isActive ? 0x66FFFFFF : FlxColor.TRANSPARENT); 
    }
}