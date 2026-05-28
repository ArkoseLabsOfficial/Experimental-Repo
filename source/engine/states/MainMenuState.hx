package engine.states;

typedef MenuOption = {
    var transKey:String;
    var text:FlxText;
    var action:Int->Void;
}

class MainMenuState extends StateBackend {
    var bg:FlxSprite;
    var titleLogo:FlxSprite;
    var extraInfoText:FlxText;
    var versionInfoText:FlxText;
    var bgBox:FlxUI9SliceSprite;
    var overlayBox:FlxUI9SliceSprite;
    var selector:FlxSprite;
    var itemGroup:FlxSpriteGroup; 
    var menuItems:Array<MenuOption> = []; 
    var selectedIndex:Int = 0;
    var layoutSpacing:Float = 50; 
    var hasSaveFile:Bool = false;

    override public function create():Void {
        super.create();
        for (slotNum in 0...31) {
            var info = SaveManager.getSlotInfo(slotNum);
            if (!hasSaveFile && !info.isEmpty) hasSaveFile = true;
        }

        GamePrefs.loadSettings();
        ItemManager.loadItems(); 
        Language.loadLanguage(Language.currentLanguage);

        bg = new FlxSprite(0, 0).loadGraphic(LilyAssets.image("img/cg/ch1/paperlily_title"));
        bg.setGraphicSize(1920, 1080);
        bg.updateHitbox();
        add(bg);

        titleLogo = new FlxSprite(1134, 282); 
        add(titleLogo);

        extraInfoText = new FlxText(0, FlxG.height - 65, FlxG.width - 15, "", 24);
        extraInfoText.alignment = "right";
        add(extraInfoText);

        versionInfoText = new FlxText(0, FlxG.height - 35, FlxG.width - 15, "v1.1.6 Debug © Leef 6010 2024", 24);
        versionInfoText.alignment = "right";
        add(versionInfoText);

        Language.onLanguageUpdate.push(updateLocalizedImages);
        updateLocalizedImages();

        var menuDefinitions = [
            { transKey: "system.menu.newgame", action: function(d:Int) { SaveManager.reset(); FlxG.switchState(new PlayState("bathroom")); } },
            { transKey: "system.menu.debugroom", action: function(d:Int) { FlxG.switchState(new RoomEditorState()); } },
            { transKey: "system.menu.settings", action: function(d:Int) { if (d == 0) openSubState(new SettingsScreenBase()); } },
            { transKey: "system.menu.website.translator", action: function(d:Int) {} },
            { transKey: "system.menu.quit", action: function(d:Int) { if (d == 0) System.exit(0); } }
        ];
        if (hasSaveFile) {
            menuDefinitions = [
                { transKey: "system.menu.loadgame", action: function(d:Int) { if (d == 0) openSubState(new SaveLoadSubState(false, true)); } },
                { transKey: "system.menu.newgame", action: function(d:Int) { SaveManager.reset(); FlxG.switchState(new PlayState("bathroom")); } },
                { transKey: "system.menu.debugroom", action: function(d:Int) { FlxG.switchState(new RoomEditorState()); } },
                { transKey: "system.menu.settings", action: function(d:Int) { if (d == 0) openSubState(new SettingsScreenBase()); } },
                { transKey: "system.menu.website.translator", action: function(d:Int) {} },
                { transKey: "system.menu.quit", action: function(d:Int) { if (d == 0) System.exit(0); } }
            ];
        }

        var dynamicHeight:Float = (menuDefinitions.length * layoutSpacing) + 60;
        var fixedWidth:Float = 400; 

        bgBox = UIUtil.create9SliceSprite(LilyAssets.image("img/ui/frame_default_bg"), 1300, 561, fixedWidth, dynamicHeight, 1.0);
        overlayBox = UIUtil.create9SliceSprite(LilyAssets.image("img/ui/frame_menu_2b"), 1300, 561, fixedWidth, dynamicHeight, 1.0);

        selector = new FlxSprite().makeGraphic(Std.int(bgBox.width - 80), 38, 0x66FFFFFF);
        itemGroup = new FlxSpriteGroup();

        add(bgBox);
        add(selector);
        add(itemGroup);
        add(overlayBox);
        
        var layoutY:Float = bgBox.y + 40; 

        for (def in menuDefinitions) {
            var txt = new FlxText(bgBox.x, layoutY, bgBox.width, Language.GetCaption(def.transKey), 20);
            txt.alignment = "center";
            itemGroup.add(txt);

            menuItems.push({
                transKey: def.transKey,
                text: txt,
                action: def.action
            });

            layoutY += layoutSpacing; 
        }

        changeSelection(0);
        Language.onLanguageUpdate.push(refreshText);
        #if FEATURE_TOUCH_CONTROLS
        mobile.controls.addMobilePad("UP_DOWN", "MAIN_MENU");
        mobile.controls.addMobilePadCamera();
        #end
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        if (subState != null) return; 

        if (Controls.UP_P) {
            UIUtil.playNavSound();
            changeSelection(-1);
        }
        if (Controls.DOWN_P) {
            UIUtil.playNavSound();
            changeSelection(1);
        }
        if (menuItems.length > 0) {
            var currentOpt = menuItems[selectedIndex];
            if (Controls.ACCEPT_P) {
                UIUtil.playConfirmSound();
                currentOpt.action(0);
            }
        }
    }

    public function changeSelection(change:Int = 0):Void {
        selectedIndex += change;
        if (selectedIndex < 0) selectedIndex = menuItems.length - 1;
        if (selectedIndex >= menuItems.length) selectedIndex = 0;
        
        selector.x = bgBox.x + 40;
        selector.y = menuItems[selectedIndex].text.y - 4; 
    }

    function refreshText():Void {
        for (item in menuItems) {
            item.text.text = Language.GetCaption(item.transKey);
        }
    }

    function updateLocalizedImages():Void {
        titleLogo.loadGraphic(LilyAssets.image("img/ui/title_logo_paperlily"));
        titleLogo.scale.set(0.8, 0.8); 
        titleLogo.updateHitbox();
        extraInfoText.text = Language.GetCaption("system.menu.translator.credit");
    }

    override public function destroy():Void {
        Language.onLanguageUpdate.remove(refreshText);
        Language.onLanguageUpdate.remove(updateLocalizedImages);
        super.destroy();
    }
}