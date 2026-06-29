package;

import flixel.FlxGame;
import openfl.display.Sprite;
import engine.states.TitleMenu;
import flixel.system.FlxAssets;
import flixel.FlxSprite;
import openfl.Assets;
import haxe.io.Bytes;
import openfl.display.Bitmap;
#if sys
import sys.FileSystem as SysFileSystem;
import sys.io.File as SysFile;
#end
#if scriptable
import cpp.cppia.Host;
import cpp.cppia.Module;
#end
import openfl.events.MouseEvent;

#if FEATURE_TOUCH_CONTROLS
import mobile.openfl.controls.MobileControls;
#end
import openfl.ui.Mouse;

class Main extends Sprite {
	var game:Game;
	#if FEATURE_TOUCH_CONTROLS
	public static var mobileControls:MobileControls;
	#end
    public function new() {
        super();
        #if android
        Sys.setCwd(haxe.io.Path.addTrailingSlash(android.content.Context.getExternalFilesDir()));
        #elseif ios
        Sys.setCwd(lime.system.System.documentsDirectory);
        #end
        FlxAssets.FONT_DEFAULT = "assets/font/NotoSans-Regular.ttf";
        FlxSprite.defaultAntialiasing = true;


		/* Loading Game Stuffs */
		game = new Game();
		loadAllMods();

		/* Game and Mobile Control Childs */
		#if FEATURE_TOUCH_CONTROLS
		mobileControls = new MobileControls(1920, 1080);
		#end
		addChild(new FlxGame(1920, 1080, TitleMenu, 144, 144, true));
		#if FEATURE_TOUCH_CONTROLS
		addChild(mobileControls);
		#end
		mobile.openfl.screen.ScreenUtil.init(stage);

		FlxG.mouse.useSystemCursor = true;
		FlxG.fixedTimestep = false;

		// Custom Mouse Loading for Desktop Builds
		#if desktop
		var bitmapData = FileSystem.getBitmapData("assets/images/ui/cursor.png");
        var customCursor = new Bitmap(bitmapData);
        addChild(customCursor);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
			Mouse.hide();
			customCursor.x = e.stageX;
			customCursor.y = e.stageY;
		});
		customCursor.scaleX = 0.15;
		customCursor.scaleY = 0.15;
		#end
    }

	static var loadedFiles = new Map<String, Bool>();

	/**
	 * A cppia loader.
	**/
	public static function loadAllMods() {
		#if (!cppia && scriptable)
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
}