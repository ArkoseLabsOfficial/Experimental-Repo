package mobile;

import flixel.util.FlxSave;
import mobile.Util;

using StringTools;

enum ButtonModes
{
	ACTION;
	DPAD;
	HITBOX;
}

class MobileConfig {
	public static var actionModes:Map<String, MobileButtonsData> = new Map();
	public static var dpadModes:Map<String, MobileButtonsData> = new Map();
	public static var hitboxModes:Map<String, CustomHitboxData> = new Map();
	public static var mobileFolderPath:String = 'mobile/';

	public static var save:FlxSave;
	public static function init(saveName:String, savePath:String, mobilePath:String = 'mobile/', folders:Array<Array<Dynamic>>)
	{
		save = new FlxSave();
		save.bind(saveName, savePath);
		if (mobilePath != null || mobilePath != '') mobileFolderPath = (mobilePath.endsWith('/') ? mobilePath : mobilePath + '/');

		for (folder in folders) {
			switch (folder[1]) {
				case ACTION:
					Util.setupMaps(mobileFolderPath + folder[0], actionModes, ACTION);
				case DPAD:
					Util.setupMaps(mobileFolderPath + folder[0], dpadModes, DPAD);
				case HITBOX:
					Util.setupMaps(mobileFolderPath + folder[0], hitboxModes, HITBOX);
			}
		}
	}
}

typedef MobileButtonsData =
{
	buttons:Array<ButtonsData>
}

typedef CustomHitboxData =
{
	hints:Array<HitboxData>
}

typedef HitboxData =
{
	button:String, // the button's name for checking pressed directly.
	buttonIDs:Array<String>, // what Hitbox Button IDs should be used.
	buttonUniqueID:Dynamic, // the button's special ID for button
	position:Array<Float>, // the button's X/Y position on screen.
	scale:Array<Int>, // the button's Width/Height on screen.
	color:String, // the button color, default color is white.
	returnKey:String // the button return, default return is nothing but If you're game using a lua scripting this will be useful.
}

typedef ButtonsData =
{
	button:String, // the button's name for checking pressed directly.
	buttonIDs:Array<String>, // what MobileButton Button IDs should be used.
	buttonUniqueID:Dynamic, // the button's special ID for button
	graphic:String, // the graphic of the button, usually can be located in the MobilePad xml.
	position:Array<Null<Float>>, // the button's X/Y position on screen.
	color:String, // the button color, default color is white.
	scale:Null<Float>, //the button scale, default scale is 1.
	returnKey:String // the button return, default return is nothing but If you're game using a lua scripting this will be useful.
}