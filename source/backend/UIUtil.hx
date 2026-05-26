package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.graphics.FlxGraphic;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import flixel.util.FlxColor;

class UIUtil {
    public static function playNavSound(isBack:Bool = false):Void {
        FlxG.sound.play(isBack ? "assets/sfx/ui_navigation2.ogg" : "assets/sfx/ui_navigation.ogg");
    }

    public static function playConfirmSound():Void {
        FlxG.sound.play("assets/sfx/ui_start.ogg");
    }

    public static function playErrorSound():Void {
        FlxG.sound.play("assets/sfx/ui_bad.ogg");
    }

    public static function createText(X:Float, Y:Float, Width:Float, Text:String, Size:Int = 24, Align:FlxTextAlign = CENTER):FlxText {
        var txt = new FlxText(X, Y, Width, Text, Size);
        txt.font = "assets/fonts/AlegreyaSC-Regular.ttf";
        txt.alignment = Align;
        return txt;
    }

    public static function create9SliceSprite(frameImage:String, X:Float, Y:Float, Width:Float, Height:Float, scaleFactor:Float = 1.0):FlxUI9SliceSprite {
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
        var sliceRect:Array<Int> = [cutX, cutY, Std.int(finalGraphic.width - cutX), Std.int(finalGraphic.height - cutY)];
        return new FlxUI9SliceSprite(X, Y, finalGraphic, new Rectangle(0, 0, Width, Height), sliceRect);
    }

    public static function createPanel(frameImage:String, X:Float, Y:Float, Width:Float, Height:Float, scaleFactor:Float = 0.66):FlxSpriteGroup {
        var grp = new FlxSpriteGroup(X, Y);
        var bgPadding:Int = 4;
        var bg = new FlxSprite(bgPadding, bgPadding, "assets/img/ui/frame_menu_bg.png");
        bg.setGraphicSize(Std.int(Width - (bgPadding * 2)), Std.int(Height - (bgPadding * 2)));
        bg.updateHitbox();
        grp.add(bg);
        var hud = create9SliceSprite(frameImage, 0, 0, Width, Height, scaleFactor);
        grp.add(hud);
        return grp;
    }

    public static function createInfoBox(frameImage:String, X:Float, Y:Float, Width:Float, Height:Float, scaleFactor:Float = 0.66):FlxSpriteGroup {
        var grp = new FlxSpriteGroup(X, Y);
        var bgPadding:Int = -30;
        var bg = new FlxSprite(bgPadding, bgPadding + 20, "assets/img/ui/frame_menu_bg.png");
        bg.setGraphicSize(Std.int(Width) * 1.3, Std.int(Height) * 1.3);
        bg.updateHitbox();
        grp.add(bg);
        var hud = create9SliceSprite(frameImage, 0, 0, Width, Height, scaleFactor);
        grp.add(hud);
        grp.scale.set(1.3, 1.3);
        return grp;
    }

    public static function createHighlightBox(X:Float, Y:Float, Width:Float, Height:Float = 36, Alpha:Float = 1.0):FlxSprite {
        var box = new FlxSprite(X, Y).makeGraphic(Std.int(Width), Std.int(Height), 0xFFFFFFFF);
        box.color = 0xFF4A4A4A;
        box.alpha = Alpha;
        return box;
    }

    /**
     * Creates an entry sprite that combines a 9-slice background with content.
     * @param frameImage Asset for the background
     * @param content A FlxSprite or group to display on top
     * @param Width, Height Target size
     * @param margins The [left, top, right, bottom] padding from the Godot .tscn file
     */
    public static function create9SliceOptionSprite(
        frameImage:String, 
        X:Float, 
        Y:Float, 
        Width:Float, 
        Height:Float, 
        m:Array<Int>
    ) {
        var sliceRect = [
            m[0], 
            m[1], 
            300 - (m[0] + m[2]), 
            300 - (m[1] + m[3])
        ];

        return new FlxUI9SliceSprite(
            X, 
            Y, 
            frameImage, 
            new Rectangle(0, 0, Width, Height), 
            sliceRect
        );
    }
}   