package backend;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

class Controls {
    private static function checkAction(action:String, justPressed:Bool):Bool {
        var keys:Array<String> = GamePrefs.keybinds.get(action);
        if (keys == null || keys.length == 0) return false;
        
        var flxKeys:Array<FlxKey> = [];
        for (k in keys) flxKeys.push(FlxKey.fromString(k));

        return justPressed ? FlxG.keys.anyJustPressed(flxKeys) : FlxG.keys.anyPressed(flxKeys);
    }

    public static var UP_P(get, never):Bool;
    inline static function get_UP_P() return checkAction("UP", true);

    public static var DOWN_P(get, never):Bool;
    inline static function get_DOWN_P() return checkAction("DOWN", true);

    public static var LEFT_P(get, never):Bool;
    inline static function get_LEFT_P() return checkAction("LEFT", true);

    public static var RIGHT_P(get, never):Bool;
    inline static function get_RIGHT_P() return checkAction("RIGHT", true);

    public static var ACCEPT_P(get, never):Bool;
    inline static function get_ACCEPT_P() return checkAction("ACCEPT", true);

    public static var CANCEL_P(get, never):Bool;
    inline static function get_CANCEL_P() return checkAction("CANCEL", true);

    public static var UP(get, never):Bool; inline static function get_UP() return checkAction("UP", false);
    public static var DOWN(get, never):Bool; inline static function get_DOWN() return checkAction("DOWN", false);
    public static var LEFT(get, never):Bool; inline static function get_LEFT() return checkAction("LEFT", false);
    public static var RIGHT(get, never):Bool; inline static function get_RIGHT() return checkAction("RIGHT", false);
    public static var RUN(get, never):Bool; inline static function get_RUN() return checkAction("RUN", false);
    public static var SPECIAL(get, never):Bool; inline static function get_SPECIAL() return checkAction("SPECIAL", false);
}