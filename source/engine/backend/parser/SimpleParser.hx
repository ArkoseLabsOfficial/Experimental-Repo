package engine.backend.parser;

class SimpleParser {
	public static function loadXML(path:String, ?doctypeToRemove:String):Access {
		if (!LilyAssets.fileExists(path)) {
			flixel.FlxG.log.warn('XML not found: $path');
			return null;
		}

		var rawXML = LilyAssets.getTextFromFile(path);
		if (doctypeToRemove != null && doctypeToRemove != "") {
			rawXML = StringTools.replace(rawXML, doctypeToRemove, "");
		}

		try {
			var parsed = Xml.parse(rawXML).firstElement();
			return new Access(parsed);
		} catch (e:Dynamic) {
			flixel.FlxG.log.error('Failed to parse XML at $path: $e');
			return null;
		}
	}

	public static function loadJSON(path:String):Dynamic {
		if (!LilyAssets.fileExists(path)) {
			flixel.FlxG.log.warn('JSON not found: $path');
			return null;
		}

		var rawText = LilyAssets.getTextFromFile(path);
		try {
			return Json.parse(rawText);
		} catch (e:Dynamic) {
			flixel.FlxG.log.error('Failed to parse JSON at $path: $e');
			return null;
		}
	}
}
