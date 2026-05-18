package;

import flixel.FlxGame;
import openfl.display.Sprite;
import states.MainMenuState;
import flixel.system.FlxAssets;
import flixel.FlxSprite;

class Main extends Sprite {
    public function new() {
        super();
        // Set explicitly to 1920x1080
        FlxAssets.FONT_DEFAULT = "assets/fonts/NotoSans-Regular.ttf";
        FlxSprite.defaultAntialiasing = true;
        addChild(new FlxGame(1920, 1080, MainMenuState, 144, 144, true));
    }
}