package engine;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.frames.FlxImageFrame;
import flixel.math.FlxRect;
import flixel.input.keyboard.FlxKey;
import openfl.system.System;
import engine.backend.GamePrefs;
import io.LilyAssets;
import Xml;
import Math;
import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

// ==========================================
// 1. TITLE SCREEN STATE
// ==========================================
class TitleScreen extends FlxState
{
    private var bgmPath:String = "bgm/ch1_title";
    private var versionInfo:FlxText;
    private var extraInfo:FlxText;
    private var menuContainer:FlxSpriteGroup;
    private var defaultFrame:MenuFrameNode;
    private var titleMenu:TitleMenu;

    override public function create():Void
    {
        super.create();

        var bg = new FlxSprite(0, 0);
        bg.loadGraphic(LilyAssets.image("img/cg/ch1/paperlily_title"));
        bg.setGraphicSize(1920, 1080);
        bg.updateHitbox();
        bg.antialiasing = true;
        add(bg);

        var logo = new FlxSprite(1134, 282);
        logo.loadGraphic(LilyAssets.image("img/ui/title_logo_paperlily"));
        logo.scale.set(1.5, 1.5);
        logo.updateHitbox();
        logo.antialiasing = true;
        add(logo);

        extraInfo = new FlxText(1320, 960, 570, GameCore.language.getTranslatorCredit(), 36);
        extraInfo.alignment = RIGHT;
        
        versionInfo = new FlxText(1320, 1008, 570, "v" + GameCore.settings.productVersion + " © " + GameCore.settings.productCopyright, 36);
        versionInfo.alignment = RIGHT;
        
        add(extraInfo);
        add(versionInfo);

        menuContainer = new FlxSpriteGroup(1167, 561);
        defaultFrame = new MenuFrameNode(0, 0, 600, 450, false);
        titleMenu = new TitleMenu(this);
        
        defaultFrame.addMenu(titleMenu);
        menuContainer.add(defaultFrame);
        add(menuContainer);

        GameCore.audio.playBgm(bgmPath);
        titleMenu.resetSelection();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        titleMenu.handleInput();
    }
}

// ==========================================
// 2. MAIN TITLE MENU LOGIC
// ==========================================
class TitleMenu extends SimpleVerticalMenu
{
    private var parentState:TitleScreen;

    public function new(parent:TitleScreen)
    {
        super();
        this.parentState = parent;
        drawContent();
    }

    override public function drawContent():Void
    {
        entries = [];
        if (GameCore.gameState.anySaveExists()) addEntry("Continue", continueGame);
        addEntry("New Game", newGame);
        #if debug
        addEntry("Debug Room", debugRoom);
        #end
        addEntry("Settings", openSettings);
        if (GameCore.settings.websiteEnabled) addEntry(GameCore.settings.websiteCaption, homePage);
        addEntry("Quit", quitGame);
        buildVisualList(72);
    }

    private function continueGame():Void { GameCore.audio.playSystemSound("sfx/ui_start"); }
    private function newGame():Void { GameCore.audio.playSystemSound("sfx/ui_start"); }
    private function debugRoom():Void { GameCore.audio.playSystemSound("sfx/ui_start"); }
    private function homePage():Void { FlxG.openURL(GameCore.settings.websiteLink); }
    private function quitGame():Void { System.exit(0); }

    private function openSettings():Void 
    { 
        GameCore.audio.playSystemSound("sfx/ui_start"); 
        var settingsMenu = MainMenuCreator.createSettingsMenu();
        parentState.openSubState(settingsMenu);
    }
}

// ==========================================
// 3. SETTINGS MENU SUBSTATE
// ==========================================
class OptionsSubState extends FlxSubState
{
    private var bgOverlay:FlxSprite;
    private var menuFrame:MenuFrameNode;
    private var menuStack:Array<OptionsMenu> = [];
    public var activeMenu:OptionsMenu;

    public function new(initialMenu:OptionsMenu)
    {
        super();
        
        bgOverlay = new FlxSprite(0, 0);
        bgOverlay.makeGraphic(1920, 1080, 0xB3000000);
        add(bgOverlay);

        menuFrame = new MenuFrameNode(0, 0, 900, 750, true);
        menuFrame.screenCenter();
        add(menuFrame);

        switchMenu(initialMenu);
    }

    public function switchMenu(newMenu:OptionsMenu):Void
    {
        if (activeMenu != null)
        {
            menuStack.push(activeMenu);
            menuFrame.remove(activeMenu);
        }
        
        activeMenu = newMenu;
        activeMenu.parentSubState = this;
        menuFrame.setTitle(activeMenu.menuTitle);
        menuFrame.addMenu(activeMenu);
        activeMenu.resetSelection();
    }

    public function goBack():Void
    {
        if (menuStack.length > 0)
        {
            menuFrame.remove(activeMenu);
            activeMenu = menuStack.pop();
            menuFrame.setTitle(activeMenu.menuTitle);
            menuFrame.addMenu(activeMenu);
            activeMenu.updateVisuals();
        }
        else
        {
            GamePrefs.saveSettings();
            close();
        }
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (activeMenu != null) activeMenu.handleInput();
    }
}

// ==========================================
// 4. OPTIONS MENU & XML PARSER
// ==========================================
class MainMenuCreator
{
    public static function createSettingsMenu():OptionsSubState
    {
        // XML layout mirrored exactly from TitleSettingsMenu.cs
        var xmlData = "
        <menu title='system.settings'>
            <languagemenu text='system.settings.game.language' />
            <submenu text='system.settings.game' title='Game'>
                <bool text='Skip Enabled' pref='skip_enabled' default='true' />
                <bool text='Objective Notifications' pref='obj_notif' default='true' />
                <bool text='Show Skip On Death' pref='skip_death' default='true' />
                <back text='system.common.back' />
            </submenu>
            <submenu text='system.settings.audio' title='Audio'>
                <number text='Master Volume' pref='vol_master' default='100' min='0' max='100' step='5' />
                <number text='BGM Volume' pref='vol_bgm' default='100' min='0' max='100' step='5' />
                <number text='SFX Volume' pref='vol_sfx' default='100' min='0' max='100' step='5' />
                <number text='System Volume' pref='vol_sys' default='100' min='0' max='100' step='5' />
                <number text='Text Volume' pref='vol_txt' default='100' min='0' max='100' step='5' />
                <bool text='Mute Audio' pref='mute_audio' default='false' />
                <back text='system.common.back' />
            </submenu>
            <submenu text='system.settings.video' title='Video'>
                <bool text='Fullscreen' pref='fullscreen' default='false' />
                <number text='FPS Limit' pref='fps_limit' default='60' min='30' max='240' step='30' />
                <number text='Brightness' pref='brightness' default='100' min='0' max='200' step='10' />
                <number text='Contrast' pref='contrast' default='100' min='0' max='200' step='10' />
                <number text='Gamma' pref='gamma' default='100' min='0' max='200' step='10' />
                <bool text='Hide Cursor' pref='hide_cursor' default='false' />
                <back text='system.common.back' />
            </submenu>
            <submenu text='system.settings.input' title='Input'>
                <number text='Deadzone' pref='deadzone' default='0.2' min='0.0' max='1.0' step='0.05' />
                <bool text='Auto Switch Input' pref='input_auto' default='true' />
                <keybind text='Up' action='UP' />
                <keybind text='Down' action='DOWN' />
                <keybind text='Left' action='LEFT' />
                <keybind text='Right' action='RIGHT' />
                <keybind text='Action' action='ACCEPT' />
                <keybind text='Cancel' action='CANCEL' />
                <keybind text='Run' action='RUN' />
                <keybind text='Special' action='SPECIAL' />
                <keybind text='Menu' action='MENU' />
                <back text='system.common.back' />
            </submenu>
            <back text='system.common.back' />
        </menu>
        ";

        var rootMenu = XmlMenuBuilder.build(xmlData);
        return new OptionsSubState(rootMenu);
    }
}

class LanguageMenuBuilder
{
    // Ported strictly from StartupLanguageMenu.cs and AreYouSureContainer.cs
    public static function build(extra:Bool):OptionsMenu
    {
        var menu = new OptionsMenu();
        menu.menuTitle = extra ? "system.settings.game.language.select.extra" : "system.settings.game.language.select";
        var langs = extra ? GameCore.language.getExtraLanguages() : GameCore.language.getAvailableLanguages();
        
        for (lang in langs)
        {
            menu.addOption(new ActionEntry(lang, function() {
                GameCore.audio.playSystemSound("sfx/ui_start");
                GameCore.settings.translationBaseLocale = lang;
                GameCore.language.loadLanguage(lang);
                
                if (extra) {
                    menu.parentSubState.goBack(); // Pop extra languages
                    menu.parentSubState.goBack(); // Pop language menu
                } else {
                    menu.parentSubState.goBack(); // Pop language menu
                }
            }));
        }
        
        if (!extra && GameCore.language.getExtraLanguages().length > 0)
        {
            menu.addOption(new ActionEntry("system.settings.game.language.extra", function() {
                if (!GameCore.settings.translationExtraEnabled)
                {
                    GameCore.audio.playSystemSound("sfx/ui_start");
                    var confirmMenu = new OptionsMenu();
                    confirmMenu.menuTitle = "system.settings.game.language.extra.warning";
                    
                    confirmMenu.addOption(new ActionEntry("Yes", function() {
                        GameCore.audio.playSystemSound("sfx/ui_start");
                        GameCore.settings.translationExtraEnabled = true;
                        GamePrefs.saveSettings();
                        menu.parentSubState.goBack(); // Close AreYouSure
                        menu.parentSubState.switchMenu(LanguageMenuBuilder.build(true)); // Open Extra
                    }));
                    
                    confirmMenu.addOption(new BackEntry("No"));
                    confirmMenu.buildVisualList(72);
                    menu.parentSubState.switchMenu(confirmMenu);
                }
                else
                {
                    GameCore.audio.playSystemSound("sfx/ui_start");
                    menu.parentSubState.switchMenu(LanguageMenuBuilder.build(true));
                }
            }));
        }
        
        menu.addOption(new BackEntry("system.common.back"));
        menu.buildVisualList(72);
        return menu;
    }
}

class XmlMenuBuilder
{
    public static function build(xmlString:String):OptionsMenu
    {
        var xmlRoot = Xml.parse(xmlString).firstElement();
        return parseNode(xmlRoot);
    }

    private static function parseNode(node:Xml):OptionsMenu
    {
        var menu = new OptionsMenu();
        if (node.exists("title")) menu.menuTitle = node.get("title");

        for (child in node.elements())
        {
            var text = child.get("text");
            var pref = child.get("pref");

            switch (child.nodeName.toLowerCase())
            {
                case "submenu":
                    var subMenu = parseNode(child);
                    menu.addOption(new SubMenuEntry(text, subMenu));

                case "languagemenu":
                    if (GameCore.language.getAvailableLanguages().length > 1) {
                        var langMenu = LanguageMenuBuilder.build(false);
                        menu.addOption(new SubMenuEntry(text, langMenu));
                    }

                case "bool":
                    var def = (child.get("default") == "true");
                    menu.addOption(new BoolOptionEntry(text, pref, def));
                    
                case "number":
                    var def = Std.parseFloat(child.get("default"));
                    var min = Std.parseFloat(child.get("min"));
                    var max = Std.parseFloat(child.get("max"));
                    var step = Std.parseFloat(child.get("step"));
                    menu.addOption(new NumberOptionEntry(text, pref, def, min, max, step));

                case "keybind":
                    menu.addOption(new KeybindEntry(text, child.get("action")));

                case "back":
                    menu.addOption(new BackEntry(text != null ? text : "system.common.back"));
            }
        }
        menu.buildVisualList(72);
        return menu;
    }
}

// ==========================================
// 5. CORE OPTION CLASSES
// ==========================================
class OptionsMenu extends FlxSpriteGroup
{
    public var selection:Int = 0;
    public var parentSubState:OptionsSubState;
    public var menuTitle:String = "";
    private var entries:Array<OptionEntry> = [];
    private var visualItems:Array<OptionVisualEntry> = [];
    public var isWaitingForInput:Bool = false;
    public var activeBindEntry:KeybindEntry = null;

    public function new() { super(); }

    public function addOption(entry:OptionEntry):Void
    {
        entry.parentMenu = this;
        entries.push(entry);
    }

    public function buildVisualList(separation:Float = 72):Void
    {
        for (i in 0...entries.length)
        {
            var item = new OptionVisualEntry(0, i * separation, 792, Std.int(separation), entries[i]);
            visualItems.push(item);
            add(item);
        }
        highlightSelection();
    }

    public function updateVisuals():Void { for (item in visualItems) item.updateText(); }

    public function handleInput():Void
    {
        if (isWaitingForInput && activeBindEntry != null)
        {
            var key:FlxKey = FlxG.keys.firstJustPressed();
            if (key != FlxKey.NONE && key != FlxKey.ESCAPE)
            {
                activeBindEntry.setNewBind(key.toString());
                isWaitingForInput = false;
                activeBindEntry = null;
                updateVisuals();
            }
            else if (key == FlxKey.ESCAPE)
            {
                isWaitingForInput = false;
                activeBindEntry = null;
                updateVisuals();
            }
            return;
        }

        if (FlxG.keys.anyJustPressed([UP, W]))
        {
            GameCore.audio.playSystemSound("sfx/ui_navigation");
            selection--;
            if (selection < 0) selection = entries.length - 1;
            highlightSelection();
        }
        else if (FlxG.keys.anyJustPressed([DOWN, S]))
        {
            GameCore.audio.playSystemSound("sfx/ui_navigation");
            selection++;
            if (selection >= entries.length) selection = 0;
            highlightSelection();
        }
        else if (FlxG.keys.anyJustPressed([LEFT, A])) { if (entries[selection] != null) entries[selection].left(); }
        else if (FlxG.keys.anyJustPressed([RIGHT, D])) { if (entries[selection] != null) entries[selection].right(); }
        else if (FlxG.keys.anyJustPressed([ENTER, SPACE, Z])) { if (entries[selection] != null) entries[selection].accept(); }
        else if (FlxG.keys.anyJustPressed([ESCAPE, X, BACKSPACE])) { if (parentSubState != null) parentSubState.goBack(); }
    }

    public function highlightSelection():Void { for (i in 0...visualItems.length) visualItems[i].setHighlight(i == selection); }
    public function resetSelection():Void { selection = 0; highlightSelection(); }
    public function triggerKeybind(entry:KeybindEntry):Void { isWaitingForInput = true; activeBindEntry = entry; }
}

class OptionEntry
{
    public var caption:String;
    public var parentMenu:OptionsMenu;
    public function new(caption:String) { this.caption = caption; }
    public function getValueText():String { return ""; }
    public function left():Void {}
    public function right():Void {}
    public function accept():Void {}
}

class ActionEntry extends OptionEntry
{
    private var action:Void->Void;
    public function new(caption:String, action:Void->Void)
    {
        super(caption);
        this.action = action;
    }
    override public function accept():Void { action(); }
}

class SubMenuEntry extends OptionEntry
{
    private var targetMenu:OptionsMenu;
    public function new(caption:String, target:OptionsMenu) { super(caption); this.targetMenu = target; }
    override public function getValueText():String { return ">"; }
    
    override public function accept():Void 
    { 
        GameCore.audio.playSystemSound("sfx/ui_navigation");
        if (parentMenu.parentSubState != null) parentMenu.parentSubState.switchMenu(targetMenu); 
    }
}

class BackEntry extends OptionEntry
{
    public function new(caption:String = "Back") { super(caption); }
    override public function accept():Void 
    { 
        GameCore.audio.playSystemSound("sfx/ui_navigation2");
        if (parentMenu.parentSubState != null) parentMenu.parentSubState.goBack(); 
    }
}

class BoolOptionEntry extends OptionEntry
{
    private var prefKey:String;
    private var defaultValue:Bool;
    public function new(caption:String, prefKey:String, defaultValue:Bool = false)
    {
        super(caption);
        this.prefKey = prefKey;
        this.defaultValue = defaultValue;
        if (GamePrefs.getOption(prefKey) == null) GamePrefs.setOption(prefKey, defaultValue);
    }
    override public function getValueText():String { return GamePrefs.getOption(prefKey, defaultValue) ? "ON" : "OFF"; }
    override public function left():Void { toggle(); }
    override public function right():Void { toggle(); }
    override public function accept():Void { toggle(); }
    private function toggle():Void
    {
        GameCore.audio.playSystemSound("sfx/ui_navigation");
        GamePrefs.setOption(prefKey, !GamePrefs.getOption(prefKey, defaultValue));
        
        // Special logic for fullscreen mapped directly to Flixel
        if (prefKey == "fullscreen") FlxG.fullscreen = GamePrefs.getOption(prefKey, defaultValue);
        
        parentMenu.updateVisuals();
    }
}

class NumberOptionEntry extends OptionEntry
{
    private var prefKey:String;
    private var min:Float;
    private var max:Float;
    private var step:Float;
    public function new(caption:String, prefKey:String, def:Float, min:Float, max:Float, step:Float)
    {
        super(caption);
        this.prefKey = prefKey;
        this.min = min;
        this.max = max;
        this.step = step;
        if (GamePrefs.getOption(prefKey) == null) GamePrefs.setOption(prefKey, def);
    }
    override public function getValueText():String { return Std.string(GamePrefs.getOption(prefKey)); }
    override public function left():Void
    {
        GameCore.audio.playSystemSound("sfx/ui_navigation");
        var val:Float = GamePrefs.getOption(prefKey);
        val -= step;
        if (val < min) val = min;
        GamePrefs.setOption(prefKey, val);
        parentMenu.updateVisuals();
    }
    override public function right():Void
    {
        GameCore.audio.playSystemSound("sfx/ui_navigation");
        var val:Float = GamePrefs.getOption(prefKey);
        val += step;
        if (val > max) val = max;
        GamePrefs.setOption(prefKey, val);
        parentMenu.updateVisuals();
    }
}

class KeybindEntry extends OptionEntry
{
    private var actionKey:String;
    public function new(caption:String, actionKey:String) { super(caption); this.actionKey = actionKey; }
    override public function getValueText():String
    {
        if (parentMenu != null && parentMenu.isWaitingForInput && parentMenu.activeBindEntry == this) return "...";
        var binds = GamePrefs.keybinds.get(actionKey);
        return (binds != null && binds.length > 0) ? binds[0] : "NONE";
    }
    override public function accept():Void 
    { 
        GameCore.audio.playSystemSound("sfx/ui_start");
        if (parentMenu != null) parentMenu.triggerKeybind(this); 
    }
    public function setNewBind(newKey:String):Void
    {
        GameCore.audio.playSystemSound("sfx/ui_start");
        var binds = GamePrefs.keybinds.get(actionKey);
        if (binds == null) binds = ["NONE", "NONE"];
        binds[0] = newKey;
        GamePrefs.keybinds.set(actionKey, binds);
    }
}

class OptionVisualEntry extends FlxSpriteGroup
{
    private var bg:FlxSprite;
    private var labelLeft:FlxText;
    private var labelRight:FlxText;
    private var entryRef:OptionEntry;
    private static inline var SELECT_COLOR:FlxColor = 0x33EDDEDE;

    public function new(X:Float, Y:Float, width:Float, height:Float, entry:OptionEntry)
    {
        super(X, Y);
        this.entryRef = entry;
        
        bg = new FlxSprite(0, 0);
        bg.makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT);
        add(bg);

        labelLeft = new FlxText(16, (height - 48) / 2, width - 32, entry.caption, 48);
        labelLeft.alignment = LEFT;
        add(labelLeft);

        labelRight = new FlxText(16, (height - 48) / 2, width - 32, entry.getValueText(), 48);
        labelRight.alignment = RIGHT;
        add(labelRight);
    }

    public function setHighlight(isActive:Bool):Void { bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), isActive ? SELECT_COLOR : FlxColor.TRANSPARENT); }
    public function updateText():Void { labelRight.text = entryRef.getValueText(); }
}

// ==========================================
// 6. UI RENDERERS (Frame & Scaling)
// ==========================================
class SpecialNinePatch extends FlxSpriteGroup
{
    public var texture:FlxGraphicAsset;
    public var bgTexture:FlxGraphicAsset;
    public var bgMaskTexture:FlxGraphicAsset;
    public var decorTexture:FlxGraphicAsset;
    public var decorBgTexture:FlxGraphicAsset;

    public var patchMarginLeft:Int = 0;
    public var patchMarginTop:Int = 0;
    public var patchMarginRight:Int = 0;
    public var patchMarginBottom:Int = 0;
    public var decorMarginTop:Float = 0;
    public var decorMarginBottom:Float = 0;
    public var scaleFactor:Float = 1.0;
    public var bgModulate:FlxColor = FlxColor.WHITE;
    public var drawCenter:Bool = true;

    private var targetWidth:Int;
    private var targetHeight:Int;

    public function new(X:Float = 0, Y:Float = 0) { super(X, Y); }

    public function setSizeEx(width:Float, height:Float):Void
    {
        targetWidth = Math.round(width);
        targetHeight = Math.round(height);
        render();
    }

    private function render():Void
    {
        clear();
        if (targetWidth <= 0 || targetHeight <= 0) return;

        // 1. Background Processing (Stretched BG + 9-Patch Mask)
        if (bgTexture != null)
        {
            var bgSprite = new FlxSprite(0, 0);
            var bgGraphic = FlxG.bitmap.add(bgTexture);

            if (bgGraphic != null)
            {
                var finalBgBmp = new BitmapData(targetWidth, targetHeight, true, 0x00000000);
                
                // Stretch the background texture to the target size
                var bgMat = new Matrix();
                bgMat.scale(targetWidth / bgGraphic.width, targetHeight / bgGraphic.height);
                finalBgBmp.draw(bgGraphic.bitmap, bgMat, null, null, null, true);

                if (bgMaskTexture != null)
                {
                    var maskGraphic = FlxG.bitmap.add(bgMaskTexture);
                    if (maskGraphic != null)
                    {
                        var maskBmp = new BitmapData(targetWidth, targetHeight, true, 0x00000000);
                        
                        var x0:Int = 0;
                        var x1:Int = Math.round(patchMarginLeft * scaleFactor);
                        var x2:Int = targetWidth - Math.round(patchMarginRight * scaleFactor);
                        var x3:Int = targetWidth;

                        var y0:Int = 0;
                        var y1:Int = Math.round(patchMarginTop * scaleFactor);
                        var y2:Int = targetHeight - Math.round(patchMarginBottom * scaleFactor);
                        var y3:Int = targetHeight;

                        var w0 = x1 - x0;
                        var w1 = x2 - x1;
                        var w2 = x3 - x2;

                        var h0 = y1 - y0;
                        var h1 = y2 - y1;
                        var h2 = y3 - y2;

                        var rS = maskGraphic.width - patchMarginRight;
                        var bS = maskGraphic.height - patchMarginBottom;
                        var mX = maskGraphic.width - patchMarginLeft - patchMarginRight;
                        var mY = maskGraphic.height - patchMarginTop - patchMarginBottom;

                        // Helper to slice and scale individual 9-patch fragments for the mask
                        function drawMaskPiece(rx:Float, ry:Float, rw:Float, rh:Float, dw:Int, dh:Int, px:Int, py:Int) {
                            if (dw <= 0 || dh <= 0 || rw <= 0 || rh <= 0) return;
                            
                            var irw = Math.round(rw);
                            var irh = Math.round(rh);
                            var pieceBmp = new BitmapData(irw, irh, true, 0x00000000);
                            pieceBmp.copyPixels(maskGraphic.bitmap, new Rectangle(rx, ry, irw, irh), new Point(0, 0));
                            
                            var mat = new Matrix();
                            mat.scale(dw / irw, dh / irh);
                            mat.translate(px, py);
                            
                            maskBmp.draw(pieceBmp, mat, null, null, null, true);
                            pieceBmp.dispose(); // Free memory
                        }

                        // Build the 9-patch mask onto maskBmp (Center is always drawn for masks)
                        drawMaskPiece(0, 0, patchMarginLeft, patchMarginTop, w0, h0, x0, y0);
                        drawMaskPiece(patchMarginLeft, 0, mX, patchMarginTop, w1, h0, x1, y0);
                        drawMaskPiece(rS, 0, patchMarginRight, patchMarginTop, w2, h0, x2, y0);
                        drawMaskPiece(0, patchMarginTop, patchMarginLeft, mY, w0, h1, x0, y1);
                        drawMaskPiece(patchMarginLeft, patchMarginTop, mX, mY, w1, h1, x1, y1); 
                        drawMaskPiece(rS, patchMarginTop, patchMarginRight, mY, w2, h1, x2, y1);
                        drawMaskPiece(0, bS, patchMarginLeft, patchMarginBottom, w0, h2, x0, y2);
                        drawMaskPiece(patchMarginLeft, bS, mX, patchMarginBottom, w1, h2, x1, y2);
                        drawMaskPiece(rS, bS, patchMarginRight, patchMarginBottom, w2, h2, x2, y2);

                        // Apply the baked mask alpha channel onto the background
                        finalBgBmp.copyChannel(maskBmp, maskBmp.rect, new Point(0, 0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
                        maskBmp.dispose();
                    }
                }

                // Load baked texture
                bgSprite.loadGraphic(finalBgBmp);
                bgSprite.updateHitbox();
                bgSprite.color = bgModulate;
                bgSprite.antialiasing = true;
                add(bgSprite);
            }
        }

        // 2. Decor Background
        if (decorBgTexture != null)
        {
            var decorBg = new FlxSprite(0, 0);
            decorBg.loadGraphic(decorBgTexture);
            if (decorBg.graphic != null)
            {
                decorBg.origin.set(0, 0);
                decorBg.scale.set(scaleFactor, scaleFactor);
                decorBg.x = Math.round((targetWidth - (decorBg.width * scaleFactor)) / 2);
                decorBg.y = Math.round((targetHeight - (decorBg.height * scaleFactor)) / 2);
                decorBg.antialiasing = true;
                add(decorBg);
            }
        }

        // 3. Foreground Frame (9-Patch)
        if (texture != null)
        {
            var g = FlxG.bitmap.add(texture);
            if (g != null)
            {
                var x0:Int = 0;
                var x1:Int = Math.round(patchMarginLeft * scaleFactor);
                var x2:Int = targetWidth - Math.round(patchMarginRight * scaleFactor);
                var x3:Int = targetWidth;

                var y0:Int = 0;
                var y1:Int = Math.round(patchMarginTop * scaleFactor);
                var y2:Int = targetHeight - Math.round(patchMarginBottom * scaleFactor);
                var y3:Int = targetHeight;

                var w0 = x1 - x0;
                var w1 = x2 - x1;
                var w2 = x3 - x2;

                var h0 = y1 - y0;
                var h1 = y2 - y1;
                var h2 = y3 - y2;

                var rS = g.width - patchMarginRight;
                var bS = g.height - patchMarginBottom;
                var mX = g.width - patchMarginLeft - patchMarginRight;
                var mY = g.height - patchMarginTop - patchMarginBottom;

                function addF(rx:Float, ry:Float, rw:Float, rh:Float, dw:Int, dh:Int, px:Int, py:Int) {
                    if (dw <= 0 || dh <= 0) return;
                    var f = new FlxSprite(px, py);
                    f.frames = FlxImageFrame.fromRectangle(g, FlxRect.get(rx, ry, rw, rh));
                    f.setGraphicSize(dw, dh);
                    f.updateHitbox();
                    f.antialiasing = true;
                    add(f);
                }

                addF(0, 0, patchMarginLeft, patchMarginTop, w0, h0, x0, y0);
                addF(patchMarginLeft, 0, mX, patchMarginTop, w1, h0, x1, y0);
                addF(rS, 0, patchMarginRight, patchMarginTop, w2, h0, x2, y0);
                addF(0, patchMarginTop, patchMarginLeft, mY, w0, h1, x0, y1);
                if (drawCenter) addF(patchMarginLeft, patchMarginTop, mX, mY, w1, h1, x1, y1);
                addF(rS, patchMarginTop, patchMarginRight, mY, w2, h1, x2, y1);
                addF(0, bS, patchMarginLeft, patchMarginBottom, w0, h2, x0, y2);
                addF(patchMarginLeft, bS, mX, patchMarginBottom, w1, h2, x1, y2);
                addF(rS, bS, patchMarginRight, patchMarginBottom, w2, h2, x2, y2);
            }
        }
    }
}

class MenuFrameNode extends FlxSpriteGroup
{
    private var nodeFrame:SpecialNinePatch;
    private var titleText:FlxText;
    private var divider:FlxSprite;
    private var hasTitle:Bool = false;

    public function new(X:Float = 0, Y:Float = 0, targetWidth:Float, targetHeight:Float, useTitleFrame:Bool = false)
    {
        super(X, Y);
        hasTitle = useTitleFrame;
        
        nodeFrame = new SpecialNinePatch();
        
        if (useTitleFrame)
        {
            nodeFrame.texture = LilyAssets.image("img/ui/frame_menu_2");
            nodeFrame.bgMaskTexture = LilyAssets.image("img/ui/frame_menu_2_mask");
            nodeFrame.patchMarginLeft = 50;
            nodeFrame.patchMarginTop = 50;
            nodeFrame.patchMarginRight = 50;
            nodeFrame.patchMarginBottom = 50;
            nodeFrame.scaleFactor = 0.75;
            
            titleText = new FlxText(0, 30, Std.int(targetWidth), 48);
            titleText.alignment = CENTER;
            
            divider = new FlxSprite(0, 90);
            divider.loadGraphic(LilyAssets.image("img/ui/divider_md"));
            divider.scale.set(0.75, 0.75);
            divider.updateHitbox();
            divider.x = (targetWidth - divider.width) / 2;
        }
        else
        {
            nodeFrame.texture = LilyAssets.image("img/ui/frame_default");
            nodeFrame.bgTexture = LilyAssets.image("img/ui/frame_default_bg");
            nodeFrame.bgMaskTexture = LilyAssets.image("img/ui/frame_default_bg_mask");
            nodeFrame.patchMarginLeft = 123;
            nodeFrame.patchMarginTop = 142;
            nodeFrame.patchMarginRight = 123;
            nodeFrame.patchMarginBottom = 120;
            nodeFrame.scaleFactor = 0.45; 
        }

        nodeFrame.setSizeEx(targetWidth, targetHeight);
        add(nodeFrame);
        
        if (useTitleFrame)
        {
            add(titleText);
            add(divider);
        }
    }

    public function setTitle(text:String):Void
    {
        if (hasTitle && titleText != null) 
        {
            titleText.text = text;
            
            var showTitle = (text != null && text.length > 0);
            titleText.visible = showTitle;
            divider.visible = showTitle;
        }
    }

    public function addMenu(menu:FlxSpriteGroup):Void
    {
        menu.x = 54; 
        menu.y = hasTitle && titleText.visible ? 130 : 36; 
        add(menu);
    }
}

class SimpleVerticalMenu extends FlxSpriteGroup
{
    public var selection:Int = 0;
    private var entries:Array<{caption:String, action:Void->Void}> = [];
    private var visualItems:Array<MenuVisualEntry> = [];

    public function new() { super(); }
    public function drawContent():Void { }

    public function addEntry(caption:String, action:Void->Void):Void
    {
        entries.push({caption: caption, action: action});
    }

    public function buildVisualList(separation:Float = 72):Void
    {
        for (i in 0...entries.length)
        {
            var item = new MenuVisualEntry(0, i * separation, entries[i].caption, 492, Std.int(separation));
            visualItems.push(item);
            add(item);
        }
        highlightSelection();
    }

    public function handleInput():Void
    {
        if (FlxG.keys.anyJustPressed([UP, W]))
        {
            GameCore.audio.playSystemSound("sfx/ui_navigation");
            selection--;
            if (selection < 0) selection = entries.length - 1;
            highlightSelection();
        }
        else if (FlxG.keys.anyJustPressed([DOWN, S]))
        {
            GameCore.audio.playSystemSound("sfx/ui_navigation");
            selection++;
            if (selection >= entries.length) selection = 0;
            highlightSelection();
        }
        else if (FlxG.keys.anyJustPressed([ENTER, SPACE, Z]))
        {
            if (entries[selection] != null) entries[selection].action();
        }
    }

    public function highlightSelection():Void { for (i in 0...visualItems.length) visualItems[i].setHighlight(i == selection); }
    public function resetSelection():Void { selection = 0; highlightSelection(); }
}

class MenuVisualEntry extends FlxSpriteGroup
{
    private var bg:FlxSprite;
    private var label:FlxText;
    private static inline var SELECT_COLOR:FlxColor = 0x33EDDEDE; 

    public function new(X:Float, Y:Float, text:String, width:Float, height:Float)
    {
        super(X, Y);
        bg = new FlxSprite(0, 0);
        bg.makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT);
        add(bg);

        label = new FlxText(0, (height - 48) / 2, width, text, 48);
        label.alignment = CENTER;
        add(label);
    }

    public function setHighlight(isActive:Bool):Void { bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), isActive ? SELECT_COLOR : FlxColor.TRANSPARENT); }
}

// ==========================================
// 7. MOCK SYSTEMS
// ==========================================
class GameCore
{
    public static var settings:SettingsMock = new SettingsMock();
    public static var audio:AudioMock = new AudioMock();
    public static var language:LanguageMock = new LanguageMock();
    public static var gameState:GameStateMock = new GameStateMock();
}

class SettingsMock
{
    public var productVersion:String = "1.0.0";
    public var productCopyright:String = "Leef 6010 2020";
    public var websiteEnabled:Bool = true;
    public var websiteCaption:String = "Website";
    public var websiteLink:String = "https://example.com";
    public var newGameEvent:String = "start_ch1";
    
    public var translationBaseLocale:String = "English";
    public var translationExtraEnabled:Bool = false;
    
    public function new() {}
}

class AudioMock
{
    public function playBgm(path:String):Void { }
    
    public function playSystemSound(path:String):Void 
    { 
        LilyAssets.play(path); 
    }
    
    public function new() {}
}

class LanguageMock
{
    public function getTranslatorCredit():String { return "Fan Translation by ArkoseLabsOfficial"; }
    
    public function getAvailableLanguages():Array<String> { return ["English", "Spanish", "German"]; }
    public function getExtraLanguages():Array<String> { return ["Turkish", "French", "Italian", "Russian"]; }
    
    public function loadLanguage(lang:String):Void { /* Language Swap Logic */ }
    
    public function new() {}
}

class GameStateMock
{
    public function anySaveExists():Bool { return true; }
    public function new() {}
}