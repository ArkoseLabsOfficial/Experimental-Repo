package engine.backend;

import mobile.openfl.controls.MobileControls;

class Game {
	public static var instance:Game;

	public var items:ItemManager;
	public var objectives:ObjectiveManager;
	public var language:LanguageManager;
	public var save:SaveManager;

	public static var mobileC(get, never):MobileControls;

	public static function get_mobileC()
		return Main.mobileControls;

	public function new() {
		instance = this;
		language = new LanguageManager();
		items = new ItemManager();
		objectives = new ObjectiveManager();
		save = new SaveManager();

		trace("items loading");
		items.load();
	}

	public function playDialogue(xmlPath:String, startId:String, ?onComplete:Void->Void):Void {
		var dialogue = new DialogueManager(xmlPath, startId, onComplete);
		FlxG.state.openSubState(dialogue);
	}

	public function bindToScript(script:Dynamic):Void {
		script.setGlobal("Game", this);
		script.setGlobal("Items", this.items);
		script.setGlobal("Objectives", this.objectives);
		script.setGlobal("Language", this.language);
		script.setGlobal("Save", this.save);
		script.setGlobal("playDialogue", playDialogue);
	}

	public static function resetState():Void {
		instance = new Game();
	}
}
