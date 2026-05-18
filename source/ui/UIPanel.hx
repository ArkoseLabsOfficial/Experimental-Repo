package ui;

import flixel.addons.ui.FlxUI9SliceSprite;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.FlxG;

class UIPanel extends FlxUI9SliceSprite {
    public function new(x:Float, y:Float, w:Float, h:Float, useTabbed:Bool = false) {
        var assetPath = useTabbed ? "assets/img/ui/frame_tabbed.png" : "assets/img/ui/frame_menu_2.png";
        
        // Safely get the image data without rendering it yet
        var bmd:BitmapData = Assets.getBitmapData(assetPath);
        
        if (bmd == null) {
            FlxG.log.error("CRITICAL ERROR: Could not find image at " + assetPath);
            // Fallback: Prevents the game from crashing!
            super(x, y, null, new Rectangle(0, 0, w, h));
            return;
        }

        // The gear corners in your asset are roughly 24x24 pixels
        var cornerSize = 24;
        
        // If tabbed, we push the top stretch border down so the tabs don't get deformed
        var topCut = useTabbed ? 54 : cornerSize; 
        
        var sliceArray:Array<Int> = [
            cornerSize, 
            topCut, 
            bmd.width - cornerSize, 
            bmd.height - cornerSize
        ];

        super(x, y, assetPath, new Rectangle(0, 0, w, h), sliceArray);
        scrollFactor.set(0, 0); 
    }
}