package;

import MainMenu;
import flixel.FlxG;

class CppiaStartup {
    public static function main() {
        FlxG.switchState(new MainMenu());
    }
}