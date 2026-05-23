package states;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import backend.GamePrefs;
import backend.Language;
import backend.Controls;
import lime.system.System;

import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.graphics.FlxGraphic;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

typedef MenuOption = {
    var transKey:String;
    var text:FlxText;
    var action:Int->Void;
}

class MainMenuState extends FlxState {
    var bg:FlxSprite;
    var titleLogo:FlxSprite;
    
    // Bottom-Right Info Texts
    var extraInfoText:FlxText;
    var versionInfoText:FlxText;
    
    // Menu HUD Variables
    var bgBox:FlxUI9SliceSprite;
    var overlayBox:FlxUI9SliceSprite; // Added the overlay texture
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

        bg = new FlxSprite(0, 0).loadGraphic("assets/img/cg/ch1/paperlily_title.png");
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
            { transKey: "system.menu.newgame", action: function(d:Int) { FlxG.switchState(new PlayState("assets/data/rooms/bathroom.xml")); } },
            { transKey: "system.menu.debugroom", action: function(d:Int) { FlxG.switchState(new RoomEditorState()); } },
            { transKey: "system.menu.settings", action: function(d:Int) { if (d == 0) openSubState(new states.options.SettingsScreenBase()); } },
            { transKey: "system.menu.website.translator", action: function(d:Int) {} },
            { transKey: "system.menu.quit", action: function(d:Int) { if (d == 0) System.exit(0); } }
        ];
        if (hasSaveFile) {
            menuDefinitions = [
                { transKey: "system.menu.loadgame", action: function(d:Int) { if (d == 0) openSubState(new SaveLoadSubState(false, true)); } },
                { transKey: "system.menu.newgame", action: function(d:Int) { FlxG.switchState(new PlayState("assets/data/rooms/bathroom.xml")); } },
                { transKey: "system.menu.debugroom", action: function(d:Int) { FlxG.switchState(new RoomEditorState()); } },
                { transKey: "system.menu.settings", action: function(d:Int) { if (d == 0) openSubState(new states.options.SettingsScreenBase()); } },
                { transKey: "system.menu.website.translator", action: function(d:Int) {} },
                { transKey: "system.menu.quit", action: function(d:Int) { if (d == 0) System.exit(0); } }
            ];
        }

        var dynamicHeight:Float = (menuDefinitions.length * layoutSpacing) + 60;
        var fixedWidth:Float = 400; 

        bgBox = create9SliceSprite("assets/img/ui/frame_default_bg.png", 1300, 561, fixedWidth, dynamicHeight, 1.0);
        overlayBox = create9SliceSprite("assets/img/ui/frame_menu_2b.png", 1300, 561, fixedWidth, dynamicHeight, 1.0);

        selector = new FlxSprite().makeGraphic(Std.int(bgBox.width - 80), 38, 0x66FFFFFF);

        itemGroup = new FlxSpriteGroup();

        add(bgBox);
        add(selector);
        add(itemGroup);
        add(overlayBox); // Overlay drawn on top
        
        var layoutY:Float = bgBox.y + 40; 

        // Generate and store the text items
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
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        
        // Disable background menu input when Options Substate is open
        if (subState != null) return; 

        if (Controls.UP_P) {
            FlxG.sound.play("assets/sfx/ui_navigation.ogg");
            changeSelection(-1);
        }
        if (Controls.DOWN_P) {
            FlxG.sound.play("assets/sfx/ui_navigation.ogg");
            changeSelection(1);
        }
        if (menuItems.length > 0) {
            var currentOpt = menuItems[selectedIndex];
            if (Controls.ACCEPT_P) {
                FlxG.sound.play("assets/sfx/ui_start.ogg");
                currentOpt.action(0);
            }
            else if (Controls.LEFT_P) currentOpt.action(-1);
            else if (Controls.RIGHT_P) currentOpt.action(1);
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
        titleLogo.loadGraphic(Language.getAsset("assets/img/ui/title_logo_paperlily.png"));
        titleLogo.scale.set(0.8, 0.8); 
        titleLogo.updateHitbox();

        extraInfoText.text = Language.GetCaption("system.menu.translator.credit");
    }

    override public function destroy():Void {
        Language.onLanguageUpdate.remove(refreshText);
        Language.onLanguageUpdate.remove(updateLocalizedImages);
        super.destroy();
    }

    private function create9SliceSprite(frameImage:String, X:Float, Y:Float, Width:Float, Height:Float, scaleFactor:Float):FlxUI9SliceSprite {
        var originalGraphic = FlxGraphic.fromAssetKey(frameImage);
        var newWidth:Int = Std.int(originalGraphic.width * scaleFactor);
        var newHeight:Int = Std.int(originalGraphic.height * scaleFactor);
        var matrix = new Matrix();
        matrix.scale(scaleFactor, scaleFactor);
        var scaledBmd = new openfl.display.BitmapData(newWidth, newHeight, true, 0x00000000);
        scaledBmd.draw(originalGraphic.bitmap, matrix, null, null, null, true);
        var finalGraphic = FlxGraphic.fromBitmapData(scaledBmd);
        
        var cutX:Int = Std.int(finalGraphic.width / 3);
        var cutY:Int = Std.int(finalGraphic.height / 3);
        var sliceRect:Array<Int> = [ cutX, cutY, Std.int(finalGraphic.width - cutX), Std.int(finalGraphic.height - cutY) ];
        
        return new FlxUI9SliceSprite(X, Y, finalGraphic, new Rectangle(0, 0, Width, Height), sliceRect);
    }
}