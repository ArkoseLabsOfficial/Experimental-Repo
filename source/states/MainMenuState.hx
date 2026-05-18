package states;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import backend.GamePrefs;
import backend.Language;
import backend.Controls;
import states.options.Option;
import states.options.OptionsHubSubState;
import lime.system.System;

class MainMenuState extends FlxState {
    var bg:FlxSprite;
    var titleLogo:FlxSprite;
    
    // Bottom-Right Info Texts (Mapped from Godot's InfoMargin)
    var extraInfoText:FlxText;
    var versionInfoText:FlxText;
    
    // Integrated Menu Variables
    var bgBox:FlxSprite;
    var selector:FlxSprite;
    var options:FlxTypedGroup<Option>;
    var selectedIndex:Int = 0;
    
    var layoutY:Float = 50;
    var layoutSpacing:Float = 50; 

    override public function create():Void {
        super.create();
        
        GamePrefs.loadSettings();
        ItemManager.loadItems();
        Language.loadLanguage(GamePrefs.language);

        // 1. Background
        bg = new FlxSprite(0, 0).loadGraphic("assets/img/cg/ch1/paperlily_title.png");
        bg.setGraphicSize(1920, 1080); // Ensure it fills the 1080p screen
        bg.updateHitbox();
        add(bg);

        // 2. Title Logo (Godot: X=378, Y=94 -> 1080p Scale x3 = X=1134, Y=282)
        titleLogo = new FlxSprite(1134, 282); 
        add(titleLogo);

        // 3. InfoMargin Texts (Bottom Right, 5px margin -> 1080p Scale = 15px margin)
        // ExtraInfo (Fan Translation Credit)
        extraInfoText = new FlxText(0, FlxG.height - 65, FlxG.width - 15, "", 24);
        extraInfoText.alignment = "right";
        add(extraInfoText);

        // VersionInfo
        versionInfoText = new FlxText(0, FlxG.height - 35, FlxG.width - 15, "v1.1.6 Debug © Leef 6010 2024", 24);
        versionInfoText.alignment = "right";
        add(versionInfoText);

        // Trigger text/image translations
        Language.onLanguageUpdate.push(updateLocalizedImages);
        updateLocalizedImages();

        // 4. Build Menu HUD (Godot CenterContainer: X=389, Y=187 -> 1080p x3 = X=1167, Y=561)
        options = new FlxTypedGroup<Option>();

        bgBox = new FlxSprite(1300, 561).loadGraphic("assets/img/ui/frame_menu.png");
        bgBox.scale.set(0.6, 1);
        //bgBox.setGraphicSize(500, 400);
        bgBox.updateHitbox();

        // Selector Highlight
        selector = new FlxSprite().makeGraphic(Std.int(bgBox.width - 80), 38, 0x66FFFFFF);

        add(bgBox);
        add(selector);
        add(options);
        

        layoutY = bgBox.y + 45;

        // Populate Options
        addOption("system.menu.newgame", "", function(d:Int){
            FlxG.switchState(new PlayState("assets/data/rooms/cafe.tscn"));
        }, true);
        addOption("system.menu.debugroom", "", function(d:Int){
            FlxG.switchState(new RoomEditorState());
        }, true);
        addOption("system.menu.settings", "", function(d:Int){ 
            if (d == 0) openSubState(new OptionsHubSubState()); 
        }, true);
        addOption("system.menu.website.translator", "", function(d:Int){}, true);
        addOption("system.menu.quit", "", function(d:Int){ if (d == 0) System.exit(0); }, true);

        changeSelection(0);
        Language.onLanguageUpdate.push(refreshText);
    }

    public function addOption(transKey:String, val:String, action:Int->Void, centered:Bool = false):Void {
        var opt = new Option(transKey, val, action);
        opt.labelText.x = bgBox.x;
        opt.labelText.fieldWidth = bgBox.width;
        opt.labelText.alignment = "center";
        opt.valueText.visible = false;
        opt.labelText.y = layoutY;
        options.add(opt);
        layoutY += layoutSpacing; 
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        
        // Disable background menu input when Options Substate is open!
        if (subState != null) return; 

        if (Controls.UP_P) changeSelection(-1);
        if (Controls.DOWN_P) changeSelection(1);
        
        if (options.members[selectedIndex] != null) {
            if (Controls.ACCEPT_P) options.members[selectedIndex].action(0);
            else if (Controls.LEFT_P) options.members[selectedIndex].action(-1);
            else if (Controls.RIGHT_P) options.members[selectedIndex].action(1);
        }
    }

    public function changeSelection(change:Int = 0):Void {
        selectedIndex += change;
        if (selectedIndex < 0) selectedIndex = options.length - 1;
        if (selectedIndex >= options.length) selectedIndex = 0;
        
        selector.x = bgBox.x + 40;
        selector.y = options.members[selectedIndex].labelText.y - 4; 
    }

    function refreshText():Void {
        for (opt in options) if (opt != null) opt.updateText();
    }

    function updateLocalizedImages():Void {
        titleLogo.loadGraphic(Language.getAsset("assets/img/ui/title_logo_paperlily.png"));
        
        // Godot explicitly scales the logo to 0.5. 
        titleLogo.scale.set(0.8, 0.8); 
        titleLogo.updateHitbox();

        // Update the Translator Text dynamically via JSON
        extraInfoText.text = Language.GetCaption("menu_translator_credit");
    }

    override public function destroy():Void {
        Language.onLanguageUpdate.remove(refreshText);
        Language.onLanguageUpdate.remove(updateLocalizedImages);
        super.destroy();
    }
}