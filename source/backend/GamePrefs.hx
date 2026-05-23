package backend;

import flixel.FlxG;

class GamePrefs {
    public static var language:String = "English";

    // Dynamic map for all XML-supported options
    public static var options:Map<String, Dynamic> = new Map();
    
    // Keybinds are stored as [KeyboardBind, GamepadBind]
    public static var keybinds:Map<String, Array<String>> = new Map();

    public static var currentObjectives(get, set):Array<String>;
    private static function get_currentObjectives() return FlxG.save.data.currentObjectives;
    private static function set_currentObjectives(v) return FlxG.save.data.currentObjectives = v;

    public static var completedObjectives(get, set):Array<String>;
    private static function get_completedObjectives() return FlxG.save.data.completedObjectives;
    private static function set_completedObjectives(v) return FlxG.save.data.completedObjectives = v;

    public static var failedObjectives(get, set):Array<String>;
    private static function get_failedObjectives() return FlxG.save.data.failedObjectives;
    private static function set_failedObjectives(v) return FlxG.save.data.failedObjectives = v;

    public static function loadSettings():Void {
        FlxG.save.bind("PaperLilyPrefs");

        // Load generic options
        if (FlxG.save.data.options != null) {
            var savedOptions:Map<String, Dynamic> = FlxG.save.data.options;
            for (key in savedOptions.keys()) {
                options.set(key, savedOptions.get(key));
            }
        }

        // Load keybinds
        var actions = ["UP", "DOWN", "LEFT", "RIGHT", "ACCEPT", "CANCEL", "RUN", "SPECIAL"];
        var savedBinds:Dynamic = FlxG.save.data.keybinds;
        
        for (action in actions) {
            var defaultBinds = getDefaultBinds(action);
            if (savedBinds != null && Reflect.hasField(savedBinds, action)) {
                var loadedBinds:Array<String> = Reflect.field(savedBinds, action);
                // Ensure it always has exactly 2 elements (KB, GP)
                if (loadedBinds.length < 2) loadedBinds.push("NONE");
                keybinds.set(action, loadedBinds);
            } else {
                keybinds.set(action, defaultBinds);
            }
        }

        if (FlxG.save.data.currentObjectives == null) FlxG.save.data.currentObjectives = [];
        if (FlxG.save.data.completedObjectives == null) FlxG.save.data.completedObjectives = [];
        if (FlxG.save.data.failedObjectives == null) FlxG.save.data.failedObjectives = [];
    }

    public static function saveSettings():Void {
        FlxG.save.data.options = options;
        
        var bindsObj:Dynamic = {};
        for (key in keybinds.keys()) Reflect.setField(bindsObj, key, keybinds.get(key));
        FlxG.save.data.keybinds = bindsObj;

        FlxG.save.flush();
    }

    // Easy accessors for the rest of your game
    public static function getOption(variable:String, defaultValue:Dynamic = null):Dynamic {
        if (options.exists(variable)) return options.get(variable);
        return defaultValue;
    }

    public static function setOption(variable:String, value:Dynamic):Void {
        options.set(variable, value);
    }

    static function getDefaultBinds(action:String):Array<String> {
        // [Keyboard, Gamepad]
        return switch(action) {
            case "UP": ["UP", "DPAD_UP"];
            case "DOWN": ["DOWN", "DPAD_DOWN"];
            case "LEFT": ["LEFT", "DPAD_LEFT"];
            case "RIGHT": ["RIGHT", "DPAD_RIGHT"];
            case "ACCEPT": ["Z", "A"];
            case "CANCEL": ["X", "B"];
            case "RUN": ["SHIFT", "X"];
            case "SPECIAL": ["C", "Y"];
            default: ["NONE", "NONE"];
        }
    }
}