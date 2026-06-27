package engine.backend.game;

import haxe.Json;
import flixel.util.typeLimit.OneOfTwo;

class LanguageManager {
	public var currentLanguage:String = "English";

	private var localePath:String = "languages/";
	private var dictionary:Map<String, String> = new Map();

	public var onLanguageUpdate:Array<Void->Void> = [];
	public var officialLanguages:Array<String> = ["English"];

	public function new() {}

	public function loadLanguage(lang:String = "English"):Void {
		currentLanguage = lang;
		dictionary.clear();

		var path = localePath + lang + ".json";
		var json = SimpleParser.loadJSON(path);
		if (json == null)
			return;

		if (Reflect.hasField(json, "captions")) {
			flattenJson(Reflect.field(json, "captions"), "");
		}

		/*
		if (Reflect.hasField(json, "storyCaptions")) {
			var storyCaps = Reflect.field(json, "storyCaptions");
			for (room in Reflect.fields(storyCaps)) {
				var roomObj = Reflect.field(storyCaps, room);
				for (key in Reflect.fields(roomObj)) {
					var flattenedKey = room + "." + key;
					dictionary.set(flattenedKey, Std.string(Reflect.field(roomObj, key)));
				}
			}
		}
		*/

		for (callback in onLanguageUpdate) {
			if (callback != null)
				callback();
		}
	}

	private function flattenJson(data:Dynamic, prefix:String):Void {
        for (field in Reflect.fields(data)) {
            var value = Reflect.field(data, field);
            var newKey = (prefix == "") ? field : (prefix + "." + field);

            if (Std.isOfType(value, Array)) {
				trace(field);
                flattenJson(value, newKey);
            } else {
                dictionary.set(newKey, Std.string(value));
            }
        }
    }

	public function getCaption(key:String):String {
		if (dictionary.exists(key))
			return dictionary.get(key);
		return key;
	}

	public function getChildCaption(main:String, key:String):String {
		if (dictionary.exists(key))
			return dictionary.get(key);
		return key;
	}

	public function getStoryCaption(key:String):Array<OneOfTwo<String, Bool>> {
		var roomKey = RoomManager.currentRoomName + "." + key;
		if (dictionary.exists(roomKey))
			return [dictionary.get(roomKey), true];
		return [key, false];
	}

	public function getUnofficialLanguages():Array<String> {
		var unofficial:Array<String> = [];

		for (mainPath in ["mods/", "assets/"]) {
			if (FileSystem.exists(mainPath + localePath)) {
				var files = FileSystem.readDirectory(mainPath + localePath);
				for (file in files) {
					var langCode = file.split(".")[0];
					if (!officialLanguages.contains(langCode)) {
						unofficial.push(langCode);
					}
				}
				break;
			}
		}
		return unofficial;
	}
}
