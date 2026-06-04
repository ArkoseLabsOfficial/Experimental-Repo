package engine.backend;

class Controls {
    private inline static function checkAction(action:String, justPressed:Bool):Bool {
        var baseResult = checkKeyboardAndGamepad(action, justPressed);

        #if FEATURE_TOUCH_CONTROLS
        var mobile = getMobileFromState();
        var mobilePressed = false;

        if (mobile != null && mobile.mobilePad != null) {
            var pad = justPressed ? mobile.mobilePad.justPressed : mobile.mobilePad.pressed;
            var btnName = switch(action) {
                case "UP": "buttonUp";
                case "DOWN": "buttonDown";
                case "LEFT": "buttonLeft";
                case "RIGHT": "buttonRight";
                case "ACCEPT": "buttonA";
                case "CANCEL": "buttonB";
                case "MENU": "buttonC";
                case "RUN": "buttonX";
                default: action.toLowerCase();
            };
            mobilePressed = Reflect.field(pad, btnName) == true;
        }

        if (mobile != null && mobile.controls.joyStick != null && mobilePressed == false) {
            mobilePressed = justPressed ? joyStickJustPressed(action.toLowerCase()) : joyStickPressed(action.toLowerCase());
        }
        #end

        return baseResult #if FEATURE_TOUCH_CONTROLS || mobilePressed #end;
    }

    #if FEATURE_TOUCH_CONTROLS
    private inline static function joyStickPressed(key:String):Bool
	{
        var justPressed:Bool = false;
		if (key != null && getMobileFromState().controls.joyStick != null)
			if (getMobileFromState().controls.joyStick.pressed(key) == true)
				justPressed = true;

		return justPressed;
	}

	private inline static function joyStickJustPressed(key:String):Bool
	{
        var pressed:Bool = false;
		if (key != null && getMobileFromState().controls.joyStick != null)
			if (getMobileFromState().controls.joyStick.justPressed(key) == true)
				pressed = true;

		return pressed;
	}
    #end

    private inline static function checkKeyboardAndGamepad(action:String, justPressed:Bool):Bool {
        var binds:Array<String> = GamePrefs.keybinds.get(action);
        if (binds == null || binds.length < 2) return false;
        
        // Index 0 is Keyboard, Index 1 is Gamepad
        var kbKey:FlxKey = FlxKey.fromString(binds[0]);
        var gpBtn:FlxGamepadInputID = FlxGamepadInputID.fromString(binds[1]);

        var kbPressed:Bool = false;
        if (kbKey != FlxKey.NONE) {
            kbPressed = justPressed ? FlxG.keys.anyJustPressed([kbKey]) : FlxG.keys.anyPressed([kbKey]);
        }

        var gpPressed:Bool = false;
        if (gpBtn != FlxGamepadInputID.NONE) {
            var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
            if (gamepad != null) {
                gpPressed = justPressed ? gamepad.anyJustPressed([gpBtn]) : gamepad.anyPressed([gpBtn]);
            }
        }

        return kbPressed || gpPressed;
    }

    #if FEATURE_TOUCH_CONTROLS
    private inline static function getMobileFromState():Dynamic {
        var current:Dynamic = FlxG.state;
        while (Reflect.field(current, "subState") != null) {
            current = Reflect.field(current, "subState");
        }
        return Reflect.field(current, "mobile");
    }
    #end

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
    public static var RUN_P(get, never):Bool;
    inline static function get_RUN_P() return checkAction("RUN", true);
    public static var MENU_P(get, never):Bool;
    inline static function get_MENU_P() return checkAction("MENU", true);

    public static var UP(get, never):Bool;
    inline static function get_UP() return checkAction("UP", false);
    public static var DOWN(get, never):Bool;
    inline static function get_DOWN() return checkAction("DOWN", false);
    public static var LEFT(get, never):Bool;
    inline static function get_LEFT() return checkAction("LEFT", false);
    public static var RIGHT(get, never):Bool;
    inline static function get_RIGHT() return checkAction("RIGHT", false);
    public static var RUN(get, never):Bool;
    inline static function get_RUN() return checkAction("RUN", false);
    public static var MENU(get, never):Bool;
    inline static function get_MENU() return checkAction("MENU", false);
}