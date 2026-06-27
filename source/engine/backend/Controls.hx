package engine.backend;

class Controls {
	private static var _initializedSignals:Bool = false;
	private static var _lastActiveState:Dynamic = null;
	private static var _blockTimer:Int = 0;

	private static function getActiveState():Dynamic {
		if (FlxG.state == null)
			return null;
		var current:Dynamic = FlxG.state;
		while (Reflect.field(current, "subState") != null) {
			current = Reflect.field(current, "subState");
		}
		return current;
	}

	private static function initSignals() {
		if (_initializedSignals)
			return;
		_initializedSignals = true;

		FlxG.signals.preUpdate.add(function() {
			var currentState = getActiveState();
			if (_lastActiveState != currentState) {
				_lastActiveState = currentState;
				_blockTimer = 2;
			} else if (_blockTimer > 0) {
				_blockTimer--;
			}
		});
	}

	private inline static function checkAction(action:String, justPressed:Bool):Bool {
		initSignals();

		if (justPressed && _blockTimer > 0) {
			return false;
		}

		var baseResult = checkKeyboardAndGamepad(action, justPressed);
		var mobilePressed = false;

		#if FEATURE_TOUCH_CONTROLS
		if (Game.mobileC != null) {
			var type = justPressed ? "justPressed" : "pressed";
			var btnName = action.toUpperCase();
			mobilePressed = Game.mobileC.checkState(btnName, type);
		}
		#end

		return baseResult || mobilePressed;
	}

	private inline static function checkKeyboardAndGamepad(action:String, justPressed:Bool):Bool {
		var binds:Array<String> = GamePrefs.keybinds.get(action);
		if (binds == null || binds.length < 2)
			return false;

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

	public static var UP_P(get, never):Bool;

	inline static function get_UP_P()
		return checkAction("UP", true);

	public static var DOWN_P(get, never):Bool;

	inline static function get_DOWN_P()
		return checkAction("DOWN", true);

	public static var LEFT_P(get, never):Bool;

	inline static function get_LEFT_P()
		return checkAction("LEFT", true);

	public static var RIGHT_P(get, never):Bool;

	inline static function get_RIGHT_P()
		return checkAction("RIGHT", true);

	public static var ACCEPT(get, never):Bool;

	inline static function get_ACCEPT()
		return checkAction("ACCEPT", true);

	public static var CANCEL(get, never):Bool;

	inline static function get_CANCEL()
		return checkAction("CANCEL", true);

	public static var RUN_P(get, never):Bool;

	inline static function get_RUN_P()
		return checkAction("RUN", true);

	public static var MENU_P(get, never):Bool;

	inline static function get_MENU_P()
		return checkAction("MENU", true);

	public static var UP(get, never):Bool;

	inline static function get_UP()
		return checkAction("UP", false);

	public static var DOWN(get, never):Bool;

	inline static function get_DOWN()
		return checkAction("DOWN", false);

	public static var LEFT(get, never):Bool;

	inline static function get_LEFT()
		return checkAction("LEFT", false);

	public static var RIGHT(get, never):Bool;

	inline static function get_RIGHT()
		return checkAction("RIGHT", false);

	public static var RUN(get, never):Bool;

	inline static function get_RUN()
		return checkAction("RUN", false);

	public static var MENU(get, never):Bool;

	inline static function get_MENU()
		return checkAction("MENU", false);
}
