package mobile;

import haxe.Json;
import haxe.io.Path;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import mobile.MobileConfig.ButtonModes;
import mobile.MobileConfig.MobileButtonsData;
import mobile.MobileConfig.CustomHitboxData;

using StringTools;
class Util {
	inline public static function colorFromString_FL(color:String):Int {
		var hideChars = ~/[\t\n\r]/g;
		var cleanColor = hideChars.replace(color, "").trim();

		if (cleanColor.startsWith("#")) {
			cleanColor = cleanColor.substring(1);
		} else if (cleanColor.startsWith("0x"))
			cleanColor = cleanColor.substring(cleanColor.length - 6);

		var colorNum = Std.parseInt("0x" + cleanColor);
		return colorNum != null ? colorNum : 0xFFFFFF; 
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	public static function setupMaps(folder:String, map:Dynamic, mode:ButtonModes)
	{
		folder = folder.contains(':') ? folder.split(':')[1] : folder;

		if (FileSystem.exists(LilyAssets.getPath(folder)))
        {
		    for (file in readDirectory(LilyAssets.getPath(folder)))
		    {
                if (Path.extension(file) == 'json')
                {
                    file = Path.join([folder, Path.withoutDirectory(file)]);
                    trace(file);

                    var str:String = LilyAssets.getTextFromFile(file);

                    if (mode == HITBOX) {
                        var json:CustomHitboxData = cast Json.parse(str);
                        var mapKey:String = Path.withoutDirectory(Path.withoutExtension(file));
                        map.set(mapKey, json);
                    }
                    else if (mode == ACTION || mode == DPAD) {
                        var json:MobileButtonsData = cast Json.parse(str);
                        var mapKey:String = Path.withoutDirectory(Path.withoutExtension(file));
                        map.set(mapKey, json);
                    }
                }
            }
        }
	}

	inline public static function readDirectory(directory:String):Array<String>
	{
		return FileSystem.readDirectory(directory);
	}
}