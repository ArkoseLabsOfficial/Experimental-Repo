package backend;

import flixel.FlxG;

class GamePrefs {
    public static var volume:Float = 1.0;
    public static var fullscreen:Bool = false;
    public static var resolution:String = "1920x1080";
    public static var language:String = "Türkçe";
    
    public static var keybinds:Map<String, Array<String>> = [
        "UP" => ["UP", "W"], "DOWN" => ["DOWN", "S"],
        "LEFT" => ["LEFT", "A"], "RIGHT" => ["RIGHT", "D"],
        "ACCEPT" => ["Z", "ENTER", "SPACE"], "CANCEL" => ["X", "ESCAPE"],
        "RUN" => ["SHIFT"], "SPECIAL" => ["C"], "MENU" => ["X", "ESCAPE"]
    ];

    public static function loadSettings():Void {
        FlxG.save.bind("PaperLilyPrefs");

        if (FlxG.save.data.volume != null) volume = FlxG.save.data.volume;
        if (FlxG.save.data.fullscreen != null) fullscreen = FlxG.save.data.fullscreen;
        if (FlxG.save.data.resolution != null) resolution = FlxG.save.data.resolution;
        if (FlxG.save.data.language != null) language = FlxG.save.data.language;
        
        if (FlxG.save.data.keybinds != null) {
            var savedBinds:Dynamic = FlxG.save.data.keybinds;
            for (action in keybinds.keys()) {
                if (Reflect.hasField(savedBinds, action)) {
                    keybinds.set(action, Reflect.field(savedBinds, action));
                }
            }
        }
    }

    public static function saveSettings():Void {
        FlxG.save.data.volume = volume;
        FlxG.save.data.fullscreen = fullscreen;
        FlxG.save.data.resolution = resolution;
        FlxG.save.data.language = language;
        
        var bindsObj:Dynamic = {};
        for (key in keybinds.keys()) Reflect.setField(bindsObj, key, keybinds.get(key));
        FlxG.save.data.keybinds = bindsObj;

        FlxG.save.flush();
    }
}