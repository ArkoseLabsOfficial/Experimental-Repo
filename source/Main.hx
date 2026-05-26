package;

import flixel.FlxGame;
import openfl.display.Sprite;
import states.MainMenuState;
import flixel.system.FlxAssets;
import flixel.FlxSprite;
import mobile.MobileConfig;

class Main extends Sprite {
    public function new() {
        super();
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
}