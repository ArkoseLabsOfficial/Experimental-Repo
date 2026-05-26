package;

import flixel.FlxGame;
import openfl.display.Sprite;
import states.MainMenuState;
import flixel.system.FlxAssets;
import flixel.FlxSprite;
import mobile.MobileConfig;
import openfl.Assets;
import haxe.io.Bytes;
#if sys
import sys.FileSystem as SysFileSystem;
import sys.io.File as SysFile;
#end

class Main extends Sprite {
    public function new() {
        super();
        #if android
        Sys.setCwd(haxe.io.Path.addTrailingSlash(android.content.Context.getExternalFilesDir()));
        #elseif ios
        Sys.setCwd(lime.system.System.documentsDirectory);
        #end
        #if (mobile && sys)
        copySpesificFileFromAssets("assets/fonts/NotoSans-Regular.ttf", Sys.getCwd() + "assets/fonts/NotoSans-Regular.ttf");
        #end
        FlxAssets.FONT_DEFAULT = "assets/fonts/NotoSans-Regular.ttf";
        FlxSprite.defaultAntialiasing = true;
        #if FEATURE_TOUCH_CONTROLS
        MobileConfig.init('MobileControls', "ArkoseLabs/LilyEngine", 'assets/mobile/',
			[
				['MobilePad/DPadModes', ButtonModes.DPAD],
				['MobilePad/ActionModes', ButtonModes.ACTION]
			]
		);
        #end
        addChild(new FlxGame(1920, 1080, MainMenuState, 144, 144, true));
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