package backend;

import haxe.Json;
import openfl.utils.Assets;

class Language {
    public static var currentLanguage:String = "English";
    private static var localePath:String = "assets/languages/";
    private static var dictionary:Map<String, String> = new Map();
    public static var onLanguageUpdate:Array<Void->Void> = [];

    public static function loadLanguage(lang:String = "English"):Void {
        currentLanguage = lang;
        dictionary.clear();
        
        var path = "assets/languages/" + lang + ".json";
        if (!Assets.exists(path)) return;
        
        var file = Assets.getText(path);
        var json:Dynamic = Json.parse(file);
        
        // 1. Parse standard captions
        if (Reflect.hasField(json, "captions")) {
            var caps = Reflect.field(json, "captions");
            for (field in Reflect.fields(caps)) {
                dictionary.set(field, Std.string(Reflect.field(caps, field)));
            }
        }
        
        // 2. Parse nested storyCaptions
        if (Reflect.hasField(json, "storyCaptions")) {
            var storyCaps = Reflect.field(json, "storyCaptions");
            for (room in Reflect.fields(storyCaps)) {
                var roomObj = Reflect.field(storyCaps, room);
                for (key in Reflect.fields(roomObj)) {
                    // This flattens the JSON into dictionary keys like "room_homeItems.doorKnocked"
                    var flattenedKey = room + "." + key;
                    dictionary.set(flattenedKey, Std.string(Reflect.field(roomObj, key)));
                }
            }
        }

        for (callback in onLanguageUpdate) if (callback != null) callback();
    }

    public static function GetCaption(key:String):String {
        if (dictionary.exists(key)) {
            return dictionary.get(key);
        }
        // Fallback: If text isn't in JSON, just display the raw key string so you can see what's missing
        return key; 
    }

    public static function getAsset(standardPath:String):String {
        var localizedPath = localePath + currentLanguage + "/" + standardPath.split("assets/")[1];
        if (Assets.exists(localizedPath)) return localizedPath;
        return standardPath;
    }
}