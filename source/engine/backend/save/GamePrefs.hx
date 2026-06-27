package engine.backend.save;

class GamePrefs {
	public static var language:String = "English";

	public static var options:Map<String, Dynamic> = new Map();
	public static var keybinds:Map<String, Array<String>> = new Map();

	public static function loadSettings():Void {
		// Options are now strictly isolated in their own save bind
		FlxG.save.bind("LilyEngine_Prefs");
		if (FlxG.save.data.language != null)
			language = FlxG.save.data.language;

		if (FlxG.save.data.options != null) {
			var savedOptions:Dynamic = FlxG.save.data.options;
			for (field in Reflect.fields(savedOptions)) {
				options.set(field, Reflect.field(savedOptions, field));
			}
		}

		var actions = ["UP", "DOWN", "LEFT", "RIGHT", "ACCEPT", "CANCEL", "RUN", "MENU"];
		var savedBinds:Dynamic = FlxG.save.data.keybinds;

		for (action in actions) {
			var defaultBinds = getDefaultBinds(action);
			if (savedBinds != null && Reflect.hasField(savedBinds, action)) {
				var loadedBinds:Array<String> = Reflect.field(savedBinds, action);
				if (loadedBinds.length < 2)
					loadedBinds.push("NONE");
				keybinds.set(action, loadedBinds);
			} else {
				keybinds.set(action, defaultBinds);
			}
		}
	}

	public static function saveSettings():Void {
		FlxG.save.bind("LilyEngine_Prefs");

		var optObj:Dynamic = {};
		for (key in options.keys())
			Reflect.setField(optObj, key, options.get(key));
		FlxG.save.data.options = optObj;

		var bindsObj:Dynamic = {};
		for (key in keybinds.keys())
			Reflect.setField(bindsObj, key, keybinds.get(key));
		FlxG.save.data.keybinds = bindsObj;
		FlxG.save.data.language = language;

		FlxG.save.flush();
	}

	public static function getOption(variable:String, defaultValue:Dynamic = null):Dynamic {
		if (options.exists(variable))
			return options.get(variable);
		return defaultValue;
	}

	public static function setOption(variable:String, value:Dynamic):Void {
		options.set(variable, value);
	}

	static function getDefaultBinds(action:String):Array<String> {
		return switch (action) {
			case "UP": ["UP", "DPAD_UP"];
			case "DOWN": ["DOWN", "DPAD_DOWN"];
			case "LEFT": ["LEFT", "DPAD_LEFT"];
			case "RIGHT": ["RIGHT", "DPAD_RIGHT"];
			case "ACCEPT": ["Z", "A"];
			case "CANCEL": ["X", "B"];
			case "RUN": ["SHIFT", "X"];
			case "MENU": ["C", "Y"];
			default: ["NONE", "NONE"];
		}
	}
}
