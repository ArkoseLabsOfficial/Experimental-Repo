package states.options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import backend.Language;
import backend.UIUtil;
import ui.TitledMenuFrame;

// ==========================================
// INTERFACES
// ==========================================

interface IMenuEntry {
    function drawEntry(width:Float):FlxSpriteGroup;
    function accept():Void;
    function cancel():Void;
    function left():Void;
    function right():Void;
}

// ==========================================
// BASE MENU SYSTEM
// ==========================================

class SimpleVerticalMenu extends FlxSpriteGroup {
    public var entries:Array<IMenuEntry> = [];
    public var selection:Int = 0;
    public var onBack:Void->Void;
    
    public var parentMenu:SimpleVerticalMenu;
    public var menuContainer:LanguageMenu;
    
    private var selectBgs:Array<FlxSprite> = [];
    private var separation:Float = 5;

    public function new(parent:SimpleVerticalMenu, container:LanguageMenu) {
        super();
        this.parentMenu = parent;
        this.menuContainer = container;
    }

    public function drawContent(w:Float):Void {
        clear();
        selectBgs = [];
        var currentY:Float = 0;

        for (entry in entries) {
            var entryView = entry.drawEntry(w);
            
            // Selection Background (Transparent by default)
            var bg = new FlxSprite(0, currentY).makeGraphic(Std.int(w), Std.int(entryView.height + 10), FlxColor.TRANSPARENT);
            selectBgs.push(bg);
            add(bg);

            // Center entry inside its row
            entryView.y = currentY + 5;
            add(entryView);

            currentY += bg.height + separation;
        }
        highlightSelection();
    }

    public function highlightSelection():Void {
        for (bg in selectBgs) {
            bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.TRANSPARENT);
        }
        
        if (selection > -1 && selection < selectBgs.length) {
            // Equivalent to UIUtil.SelectionColor (0.93, 0.87, 0.87, 0.2)
            selectBgs[selection].makeGraphic(Std.int(selectBgs[selection].width), Std.int(selectBgs[selection].height), 0x33EDDEDE);
        }
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        handleInput();
    }

    public function handleInput():Void {
        if (Controls.UP_P) {
            FlxG.sound.play("assets/sfx/ui_navigation.ogg");
            selection--;
            if (selection < 0) selection = entries.length - 1;
            highlightSelection();
        } 
        else if (Controls.DOWN_P) {
            FlxG.sound.play("assets/sfx/ui_navigation.ogg");
            selection++;
            if (selection >= entries.length) selection = 0;
            highlightSelection();
        } 
        else if (Controls.LEFT_P) {
            entries[selection].left();
        }
        else if (Controls.RIGHT_P) {
            entries[selection].right();
        }
        else if (Controls.ACCEPT_P) {
            entries[selection].accept();
        } 
        else if (Controls.CANCEL_P) {
            FlxG.sound.play("assets/sfx/ui_navigation2.ogg");
            entries[selection].cancel();
        }
    }

    public function root():Void {
        if (menuContainer != null) {
            menuContainer.setMenu(this);
        }
        selection = 0;
        highlightSelection();
    }

    public function back():Void {
        if (onBack != null) {
            onBack();
        } else if (parentMenu != null) {
            parentMenu.root();
        }
    }
}

// ==========================================
// MENU ENTRIES
// ==========================================

class LanguageChangeMenuEntry implements IMenuEntry {
    var languageId:String;
    var caption:String;
    var extraLanguages:Bool;
    var parent:StartupLanguageMenu;

    public function new(languageId:String, extraLanguages:Bool, parent:StartupLanguageMenu) {
        this.languageId = languageId;
        this.extraLanguages = extraLanguages;
        this.parent = parent;
        
        // Fetch translated name, fallback to languageId if not found
        this.caption = Language.GetCaption("system.settings.game.language." + languageId);
        if (this.caption == "system.settings.game.language." + languageId) this.caption = languageId; 
    }

    public function drawEntry(w:Float):FlxSpriteGroup {
        var grp = new FlxSpriteGroup();
        var txt = new FlxText(0, 0, w, caption, 24);
        txt.alignment = CENTER;
        grp.add(txt);
        return grp;
    }

    public function accept():Void {
        parent.menuContainer.closeMenu();
        FlxG.sound.play("assets/sfx/ui_start.ogg");
        
        Language.loadLanguage(languageId);
        
        if (extraLanguages) {
            parent.parentMenu.back();
        } else {
            parent.back();
        }
    }

    public function cancel():Void {
        if (extraLanguages && parent.menuContainer != null && parent.menuContainer.frame != null) {
            parent.menuContainer.frame.setTitle(Language.GetCaption("system.settings.game.language.select"));
        }
        parent.back();
    }
    
    public function left():Void {}
    public function right():Void {}
}

class MoreLanguagesMenuEntry implements IMenuEntry {
    var parent:StartupLanguageMenu;

    public function new(parent:StartupLanguageMenu) {
        this.parent = parent;
    }

    public function drawEntry(w:Float):FlxSpriteGroup {
        var grp = new FlxSpriteGroup();
        var txt = new FlxText(0, 0, w, Language.GetCaption("system.settings.game.language.more"), 24);
        txt.alignment = CENTER;
        grp.add(txt);
        return grp;
    }

    public function accept():Void {
        FlxG.sound.play("assets/sfx/ui_start.ogg");
        showExtraLanguages();
    }

    private function showExtraLanguages():Void {
        if (parent.menuContainer != null && parent.menuContainer.frame != null) {
            parent.menuContainer.frame.setTitle(Language.GetCaption("system.settings.game.language.unofficial"));
        }
        var newMenu = new StartupLanguageMenu(true, parent, parent.menuContainer);
        newMenu.root();
    }

    public function cancel():Void {
        parent.back();
    }
    
    public function left():Void {}
    public function right():Void {}
}

class StartupLanguageMenu extends SimpleVerticalMenu {
    var extraLanguages:Bool;

    public function new(extraLanguages:Bool, parentMenu:SimpleVerticalMenu, container:LanguageMenu) {
        super(parentMenu, container);
        this.extraLanguages = extraLanguages;
        buildEntries();
    }

    public function buildEntries():Void {
        entries = [];
        var langs = extraLanguages ? Language.getUnofficialLanguages() : Language.officialLanguages;
        
        for (lang in langs) {
            entries.push(new LanguageChangeMenuEntry(lang, extraLanguages, this));
        }
        
        if (!extraLanguages && Language.getUnofficialLanguages().length > 0) {
            entries.push(new MoreLanguagesMenuEntry(this));
        }
    }
}

// ==========================================
// VISUAL FRAME
// ==========================================
// ==========================================
// MAIN MENU STATE (The entry point)
// ==========================================

class LanguageMenu extends FlxSubState {
    public var frame:TitledMenuFrame;
    public var currentMenu:SimpleVerticalMenu;
    public var onClose:Void->Void;
    
    var frameWidth:Float = 900;  
    var frameHeight:Float = 400; 

    public function new(?onClose:Void->Void) {
        super();
        this.onClose = onClose;
    }

    override public function create():Void {
        super.create();
        var camPause = new flixel.FlxCamera();
        camPause.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(camPause, false);
        this.cameras = [camPause];

        // Darkener Overlay
        var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xB3000000);
        add(overlay);

        // Add Frame
        var px = (FlxG.width - frameWidth) / 2;
        var py = (FlxG.height - frameHeight) / 2;
        
        frame = new TitledMenuFrame(px, py, frameWidth, frameHeight, Language.GetCaption("system.settings.game.language.select"), "assets/img/ui/divider_md.png");
        add(frame);

        // Initialize Initial Menu
        var startupMenu = new StartupLanguageMenu(false, null, this);
        startupMenu.onBack = closeMenu;
        startupMenu.root();

        var infoBoxWidth:Float = 210;
        var infoBoxHeight:Float = 70;

        // Calculate bottom-right positioning anchoring
        var infoBoxX:Float = FlxG.width - infoBoxWidth;
        var infoBoxY:Float = FlxG.height - infoBoxHeight;

        var infoBox = createBox("assets/img/ui/frame_infobox.png", infoBoxX - 35, infoBoxY - 10, infoBoxWidth, infoBoxHeight, 0.66);
        infoBox.scale.set(1.3, 1.3);

        // Ported text labels attached dynamically inside InfoBox
        var controlsText = new FlxText(infoBoxX - 135, infoBoxY + (infoBoxHeight / 2) - 30, 400, "[Z] Seç   [X] Geri", 32);
        controlsText.alignment = CENTER;
        controlsText.font = "assets/fonts/AlegreyaSC-Regular.ttf"; // Keeping the project UI aesthetic uniform
        add(controlsText);
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

    public function setMenu(menu:SimpleVerticalMenu):Void {
        if (currentMenu != null) {
            remove(currentMenu);
        }
        currentMenu = menu;
        
        // Define inner bounds based on TitledMenuFrame margins
        var contentW = frameWidth - 100; 
        menu.drawContent(contentW);
        
        // Position relative to frame
        menu.x = frame.x + 50; 
        menu.y = frame.y + 160; 
        add(menu);
    }

    public function closeMenu():Void {
        if (onClose != null) onClose();
        close();
    }
}