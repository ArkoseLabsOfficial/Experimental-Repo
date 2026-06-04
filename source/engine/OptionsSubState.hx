package engine;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.frames.FlxImageFrame;
import flixel.math.FlxRect;
import openfl.system.System;
import engine.backend.Controls;
import engine.backend.GamePrefs;
import Math;

class OptionsSubState extends FlxSubState
{
    private var bgOverlay:FlxSprite;
    private var defaultFrame:DefaultFrameNode;
    private var menuStack:Array<OptionsMenu> = [];
    public var activeMenu:OptionsMenu;

    public function new(initialMenu:OptionsMenu)
    {
        super();
        
        bgOverlay = new FlxSprite(0, 0);
        bgOverlay.makeGraphic(1920, 1080, 0xB3000000);
        add(bgOverlay);

        defaultFrame = new DefaultFrameNode(0, 0, 900, 750);
        defaultFrame.screenCenter();
        add(defaultFrame);

        switchMenu(initialMenu);
    }

    public function switchMenu(newMenu:OptionsMenu):Void
    {
        if (activeMenu != null)
        {
            menuStack.push(activeMenu);
            defaultFrame.remove(activeMenu);
        }
        
        activeMenu = newMenu;
        activeMenu.parentSubState = this;
        defaultFrame.addMenu(activeMenu);
        activeMenu.resetSelection();
    }

    public function goBack():Void
    {
        if (menuStack.length > 0)
        {
            defaultFrame.remove(activeMenu);
            activeMenu = menuStack.pop();
            defaultFrame.addMenu(activeMenu);
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
        if (activeMenu != null)
        {
            activeMenu.handleInput();
        }
    }
}

class OptionsMenu extends FlxSpriteGroup
{
    public var selection:Int = 0;
    public var parentSubState:OptionsSubState;
    private var entries:Array<OptionEntry> = [];
    private var visualItems:Array<OptionVisualEntry> = [];
    public var isWaitingForInput:Bool = false;
    private var activeBindEntry:KeybindEntry = null;

    public function new()
    {
        super();
    }

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

    public function updateVisuals():Void
    {
        for (item in visualItems)
        {
            item.updateText();
        }
    }

    public function handleInput():Void
    {
        if (isWaitingForInput && activeBindEntry != null)
        {
            var key = FlxG.keys.firstJustPressed();
            if (key != -1 && key != flixel.input.keyboard.FlxKey.ESCAPE)
            {
                activeBindEntry.setNewBind(flixel.input.keyboard.FlxKey.toStringMap.get(key));
                isWaitingForInput = false;
                activeBindEntry = null;
                updateVisuals();
            }
            else if (key == flixel.input.keyboard.FlxKey.ESCAPE)
            {
                isWaitingForInput = false;
                activeBindEntry = null;
                updateVisuals();
            }
            return;
        }

        if (Controls.UP_P)
        {
            selection--;
            if (selection < 0) selection = entries.length - 1;
            highlightSelection();
        }
        else if (Controls.DOWN_P)
        {
            selection++;
            if (selection >= entries.length) selection = 0;
            highlightSelection();
        }
        else if (Controls.LEFT_P)
        {
            if (entries[selection] != null) entries[selection].left();
        }
        else if (Controls.RIGHT_P)
        {
            if (entries[selection] != null) entries[selection].right();
        }
        else if (Controls.ACCEPT_P)
        {
            if (entries[selection] != null) entries[selection].accept();
        }
        else if (Controls.CANCEL_P)
        {
            if (parentSubState != null) parentSubState.goBack();
        }
    }

    public function highlightSelection():Void
    {
        for (i in 0...visualItems.length)
        {
            visualItems[i].setHighlight(i == selection);
        }
    }

    public function resetSelection():Void
    {
        selection = 0;
        highlightSelection();
    }

    public function triggerKeybind(entry:KeybindEntry):Void
    {
        isWaitingForInput = true;
        activeBindEntry = entry;
    }
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

class SubMenuEntry extends OptionEntry
{
    private var targetMenu:OptionsMenu;
    public function new(caption:String, target:OptionsMenu)
    {
        super(caption);
        this.targetMenu = target;
    }
    override public function getValueText():String { return ">"; }
    override public function accept():Void
    {
        if (parentMenu.parentSubState != null) parentMenu.parentSubState.switchMenu(targetMenu);
    }
}

class BackEntry extends OptionEntry
{
    public function new(caption:String = "Back") { super(caption); }
    override public function accept():Void
    {
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
        GamePrefs.setOption(prefKey, !GamePrefs.getOption(prefKey, defaultValue));
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
        var val:Float = GamePrefs.getOption(prefKey);
        val -= step;
        if (val < min) val = min;
        GamePrefs.setOption(prefKey, val);
        parentMenu.updateVisuals();
    }
    override public function right():Void
    {
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
    public function new(caption:String, actionKey:String)
    {
        super(caption);
        this.actionKey = actionKey;
    }
    override public function getValueText():String
    {
        if (parentMenu != null && parentMenu.isWaitingForInput && parentMenu.activeBindEntry == this) return "...";
        var binds = GamePrefs.keybinds.get(actionKey);
        return (binds != null && binds.length > 0) ? binds[0] : "NONE";
    }
    override public function accept():Void
    {
        if (parentMenu != null) parentMenu.triggerKeybind(this);
    }
    public function setNewBind(newKey:String):Void
    {
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

    public function setHighlight(isActive:Bool):Void
    {
        bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), isActive ? SELECT_COLOR : FlxColor.TRANSPARENT);
    }

    public function updateText():Void
    {
        labelRight.text = entryRef.getValueText();
    }
}

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

class DefaultFrameNode extends FlxSpriteGroup
{
    private var frame:SpecialNinePatch;

    public function new(X:Float = 0, Y:Float = 0, targetWidth:Float, targetHeight:Float)
    {
        super(X, Y);
        frame = new SpecialNinePatch();
        frame.texture = "assets/img/ui/frame_default.png";
        frame.bgTexture = "assets/img/ui/frame_default_bg.png";
        frame.bgMaskTexture = "assets/img/ui/frame_default_bg_mask.png";
        frame.patchMarginLeft = 123;
        frame.patchMarginTop = 142;
        frame.patchMarginRight = 123;
        frame.patchMarginBottom = 120;
        frame.scaleFactor = 0.45; 
        frame.setSize(targetWidth, targetHeight);
        add(frame);
    }

    public function addMenu(menu:OptionsMenu):Void
    {
        menu.x = 54; 
        menu.y = 36; 
        add(menu);
    }
}

class LanguageMock
{
    public function getTranslatorCredit():String { return "Fan Translation by ArkoseLabsOfficial"; }
    public function new() {}
}

class MainMenuCreator
{
    public static function createSettingsMenu():OptionsSubState
    {
        var mainMenu = new OptionsMenu();

        var gameMenu = new OptionsMenu();
        gameMenu.addOption(new BoolOptionEntry("Skip Enabled", "skip_enabled", true));
        gameMenu.addOption(new BoolOptionEntry("Objective Notifications", "obj_notif", true));
        gameMenu.addOption(new BackEntry());
        gameMenu.buildVisualList();

        var audioMenu = new OptionsMenu();
        audioMenu.addOption(new NumberOptionEntry("Master Volume", "vol_master", 100, 0, 100, 5));
        audioMenu.addOption(new NumberOptionEntry("BGM Volume", "vol_bgm", 100, 0, 100, 5));
        audioMenu.addOption(new NumberOptionEntry("SFX Volume", "vol_sfx", 100, 0, 100, 5));
        audioMenu.addOption(new BoolOptionEntry("Mute Audio", "mute_audio", false));
        audioMenu.addOption(new BackEntry());
        audioMenu.buildVisualList();

        var inputMenu = new OptionsMenu();
        inputMenu.addOption(new BoolOptionEntry("Auto Switch Input", "input_auto", true));
        inputMenu.addOption(new KeybindEntry("Up", "UP"));
        inputMenu.addOption(new KeybindEntry("Down", "DOWN"));
        inputMenu.addOption(new KeybindEntry("Left", "LEFT"));
        inputMenu.addOption(new KeybindEntry("Right", "RIGHT"));
        inputMenu.addOption(new KeybindEntry("Accept", "ACCEPT"));
        inputMenu.addOption(new KeybindEntry("Cancel", "CANCEL"));
        inputMenu.addOption(new BackEntry());
        inputMenu.buildVisualList();

        mainMenu.addOption(new SubMenuEntry("Game Options", gameMenu));
        mainMenu.addOption(new SubMenuEntry("Audio Options", audioMenu));
        mainMenu.addOption(new SubMenuEntry("Input Options", inputMenu));
        mainMenu.addOption(new BackEntry("Close Settings"));
        mainMenu.buildVisualList();

        return new OptionsSubState(mainMenu);
    }
}