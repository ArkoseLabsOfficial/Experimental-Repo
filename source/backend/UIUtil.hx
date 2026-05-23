package backend;

import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.graphics.FlxGraphic;
import flash.geom.Rectangle;
import openfl.geom.Matrix;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;

/**
 * Basic class used for useful UI utilities. -KralOyuncu
*/
class UIUtil {
    /**
     * Most useful thing I ever done. -KralOyuncu
    */
    public static function create9SliceSprite(frameImage:String, X:Float, Y:Float, Width:Float, Height:Float, scaleFactor:Float = 1) {
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
        
        var sliceRect:Array<Int> = [
            cutX, 
            cutY, 
            Std.int(finalGraphic.width - cutX), 
            Std.int(finalGraphic.height - cutY)
        ];

        var frame = new FlxUI9SliceSprite(
            X, 
            Y, 
            finalGraphic, 
            new Rectangle(0, 0, Width, Height), 
            sliceRect
        );
        return frame;
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