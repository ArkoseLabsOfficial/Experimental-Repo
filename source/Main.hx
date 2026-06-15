package;

import flixel.FlxGame;
import openfl.display.Sprite;
import engine.states.MainMenuState;
import flixel.system.FlxAssets;
import flixel.FlxSprite;
#if FEATURE_TOUCH_CONTROLS
import mobile.MobileConfig;
#end
import openfl.Assets;
import haxe.io.Bytes;
#if sys
import sys.FileSystem as SysFileSystem;
import sys.io.File as SysFile;
#end
#if cpp
import cpp.cppia.Host;
import cpp.cppia.Module;
#end

class Main extends Sprite {
    public function new() {
        super();
        #if android
        Sys.setCwd(haxe.io.Path.addTrailingSlash(android.content.Context.getExternalFilesDir()));
        #elseif ios
        Sys.setCwd(lime.system.System.documentsDirectory);
        #end
        FlxAssets.FONT_DEFAULT = "assets/font/NotoSans-Regular.ttf";
        FlxSprite.defaultAntialiasing = true;
        #if FEATURE_TOUCH_CONTROLS
        MobileConfig.init('MobileControls', "ArkoseLabs/LilyEngine", 'mobile/',
			[
				['MobilePad/DPadModes', ButtonModes.DPAD],
				['MobilePad/ActionModes', ButtonModes.ACTION]
			]
		);
        #end
		loadAllMods();
		if (loadedFiles.get("MainMenu")) {
			var cl = Type.resolveClass("MainMenu");
			var menuInstance = Type.createInstance(cl, []);
			addChild(new FlxGame(1920, 1080, cast menuInstance, 144, 144, true));
		} else {
			addChild(new FlxGame(1920, 1080, MainMenuState, 144, 144, true));
		}
		#if html5
		FlxG.fixedTimestep = false;
		#end

		#if OLD_DISCORD_ALLOWED
		DiscordClient.prepare();
		#end
    }

	static var loadedFiles = new Map<String, Bool>();

	/**
	 * A cppia loader.
	**/
	public static function loadAllMods() {
		#if (!cppia && cpp)
        var modDir = "mods/";
        if (!FileSystem.exists(modDir)) return;

        for (file in FileSystem.readDirectory(modDir)) {
            if (file.endsWith(".cppia")) {
                var bytes = modDir + file;
                Host.runFile(bytes);
				loadedFiles.set(file.replace(".cppia", ""), true);
                trace("Mod yüklendi: " + file);
            }
        }
		#end
    }

    #if sys
    public static function copySpesificFileFromAssets(filePathInAssets:String, copyTo:String, ?changeable:Bool)
	{
		try {
			if (Assets.exists(filePathInAssets)) {
				var fileData:Bytes = Assets.getBytes(filePathInAssets);
				if (fileData != null) {
					if (SysFileSystem.exists(copyTo) && changeable) {
						var existingFileData:Bytes = File.getBytes(filePathInAssets);
						if (existingFileData != fileData && existingFileData != null)
							SysFile.saveBytes(copyTo, fileData);
					}
					else if (!SysFileSystem.exists(copyTo))
						SysFile.saveBytes(copyTo, fileData);

					trace('Copied: $filePathInAssets -> $copyTo');
				} else {
					var textData = Assets.getText(filePathInAssets);
					if (textData != null) {
						if (SysFileSystem.exists(copyTo) && changeable) {
							var existingTxtData = SysFile.getContent(filePathInAssets);
							if (existingTxtData != textData && existingTxtData != null)
								SysFile.saveContent(copyTo, textData);
						}
						else if (!SysFileSystem.exists(copyTo))
							SysFile.saveContent(copyTo, textData);
						trace('Copied (text): $filePathInAssets -> $copyTo');
					}
				}
			}
		} catch (e:Dynamic) {
			trace('Error copying file $filePathInAssets: $e');
		}
	}
    #end
}