package io;

import flixel.system.FlxAssets;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import openfl.system.System;
import openfl.media.Sound;
import io.FileSystem;
import io.File;
import flixel.FlxG;

class LilyAssets
{
    public static var CANCEL:String = "sfx/ui_navigation2";
    public static var CONFIRM:String = "sfx/ui_start";
    public static var NAVIGATE:String = "sfx/ui_navigation";
    public static var ERROR:String = "sfx/ui_bad";

    public static final IMAGE_EXT:String = "png";
    public static final SOUND_EXTS:Array<String> = ['ogg', 'opus', 'mp3', 'flac', 'wav'];
    public static var LOADOLD:Bool = false;

    public static final dumpExclusions:Array<String> = [
        'images/ui/cursor.$IMAGE_EXT',
        'images/ui/cursorCross.$IMAGE_EXT'
    ];

    public static final currentTrackedAssets:Map<String, FlxGraphic> = [];
    public static final currentTrackedSounds:Map<String, Sound> = [];
    public static var localTrackedAssets:Array<String> = [];

    public static function excludeAsset(key:String):Void
    {
        if (!dumpExclusions.contains(key))
            dumpExclusions.push(key);
    }

    public static function clearUnusedMemory():Void
    {
        for (key in currentTrackedAssets.keys())
        {
            if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
            {
                var obj = currentTrackedAssets.get(key);
                @:privateAccess
                if (obj != null)
                {
                    FlxG.bitmap._cache.remove(key);
                    openfl.Assets.cache.removeBitmapData(key);
                    currentTrackedAssets.remove(key);

                    obj.persist = false; 
                    obj.destroyOnNoUse = true;
                    obj.destroy();
                }
            }
        }
        System.gc();
        #if cpp
        cpp.NativeGc.run(true);
        #end
    }

    public static function clearStoredMemory():Void
    {
        @:privateAccess
        for (key in FlxG.bitmap._cache.keys())
        {
            var obj = FlxG.bitmap._cache.get(key);
            if (obj != null && !currentTrackedAssets.exists(key))
            {
                openfl.Assets.cache.removeBitmapData(key);
                FlxG.bitmap._cache.remove(key);
                obj.destroy();
            }
        }

        for (key => asset in currentTrackedSounds)
        {
            if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
            {
                Assets.cache.clear(key);
                currentTrackedSounds.remove(key);
            }
        }

        localTrackedAssets = [];
    }

    /**
     * The core path solver. Automatically checks `mods/` then `assets/`.
     */
    public static function getPath(file:String):String
    {
        var modPath = 'mods/$file';
        if (FileSystem.exists(modPath)) return modPath;

        var assetPath = 'assets/$file';
        if (FileSystem.exists(assetPath)) return assetPath;

        return file;
    }

    inline public static function font(key:String):String return getPath('$key');

    public static function fileExists(key:String):Bool
    {
        return FileSystem.exists(getPath(key));
    }

    public static function getImageAssetType(ext:String):AssetType
    {
        return switch (ext.toLowerCase())
        {
            case 'png' | 'jpg' | 'jpeg': IMAGE;
            default: BINARY;
        }
    }

    public static function image(key:String, prefix:String = "images/"):FlxGraphic
    {
        var bitmap:BitmapData = null;
        var file:String = null;
        var exts:Array<String> = [];
        key = '$prefix$key';

        exts.push(IMAGE_EXT);

        for (ext in exts)
        {
            file = getPath('$key.$ext');
            if (currentTrackedAssets.exists(file))
            {
                if (!localTrackedAssets.contains(file)) localTrackedAssets.push(file);
                return currentTrackedAssets.get(file);
            }
            else if (FileSystem.exists(file))
            {
                bitmap = #if html5 openfl.Assets.getBitmapData(file) #else BitmapData.fromBytes(File.getBytes(file)) #end;
            }

            if (bitmap != null) break;
        }

        if (bitmap != null)
        {
            var retVal = cacheBitmap(file, bitmap);
            if (retVal != null) return retVal;
        }

        trace('Failed to load image: $file');
        
        if (currentTrackedAssets.exists('__flixel_logo'))
        {
            if (!localTrackedAssets.contains('__flixel_logo')) localTrackedAssets.push('__flixel_logo');
            return currentTrackedAssets.get('__flixel_logo');
        }

        return cacheBitmap('__flixel_logo', FlxAssets.getBitmapFromClass(GraphicLogo));
    }

    public static function cacheBitmap(file:String, ?bitmap:BitmapData = null):FlxGraphic
    {
        if (bitmap == null)
        {
            if (FileSystem.exists(file)) bitmap = BitmapData.fromBytes(File.getBytes(file));
            if (bitmap == null) return null;
        }

        if (!localTrackedAssets.contains(file)) localTrackedAssets.push(file);

        var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
        newGraphic.persist = true;
        newGraphic.destroyOnNoUse = false;
        currentTrackedAssets.set(file, newGraphic);
        return newGraphic;
    }

    public static function getTextFromFile(key:String):String
    {
        var path:String = getPath(key);
        if (FileSystem.exists(path)) return File.getContent(path);
        return null;
    }

    inline public static function play(path:String) {
        FlxG.sound.play(sound(path));
    }

    public static function sound(key:String):Sound return returnSound('sounds', key);
    inline public static function soundRandom(key:String, min:Int, max:Int):Sound return sound(key + FlxG.random.int(min, max));
    inline public static function music(key:String):Sound return returnSound('music', key);

    public static function returnSound(path:Null<String>, key:String):Sound
    {
        for (ext in SOUND_EXTS)
        {
            var gottenPath:String = '$key.$ext';
            if (path != null) gottenPath = (path != '' && path != null) ? '$path/' + gottenPath : gottenPath;
            
            var resolvedPath = getPath(gottenPath);

            if (!currentTrackedSounds.exists(gottenPath))
            {
                if (FileSystem.exists(resolvedPath))
                    currentTrackedSounds.set(gottenPath, #if html5 openfl.Assets.getSound(resolvedPath) #else Sound.fromBytes(File.getBytes(resolvedPath)) #end);
            }

            if (currentTrackedSounds.exists(gottenPath))
            {
                if (!localTrackedAssets.contains(gottenPath)) localTrackedAssets.push(gottenPath);
                return currentTrackedSounds.get(gottenPath);
            }
        }
        return null;
    }

    public static function getAtlas(key:String):FlxAtlasFrames
    {
        var imageLoaded:FlxGraphic = image(key);

        var xmlPath:String = getPath('images/$key.xml');
        if (FileSystem.exists(xmlPath)) return FlxAtlasFrames.fromSparrow(imageLoaded, File.getContent(xmlPath));

        var jsonPath:String = getPath('images/$key.json');
        if (FileSystem.exists(jsonPath)) return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, File.getContent(jsonPath));

        return getPackerAtlas(key);
    }

    public static function getSparrowAtlas(key:String):FlxAtlasFrames
    {
        var imageLoaded:FlxGraphic = image(key);
        var xmlPath:String = getPath('images/$key.xml');
        return FlxAtlasFrames.fromSparrow(imageLoaded, File.getContent(xmlPath));
    }

    public static function getPackerAtlas(key:String):FlxAtlasFrames
    {
        var imageLoaded:FlxGraphic = image(key);
        var txtPath:String = getPath('images/$key.txt');
        return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, File.getContent(txtPath));
    }

    public static function getAsepriteAtlas(key:String):FlxAtlasFrames
    {
        var imageLoaded:FlxGraphic = image(key);
        var jsonPath:String = getPath('images/$key.json');
        return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, File.getContent(jsonPath));
    }
}