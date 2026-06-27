package engine.scripting;

import engine.scripting.events.CancellableEvent;

class ScriptHandler {
	public var scriptArray:Array<GameScript> = [];
	public var scriptMap:Map<String, GameScript> = new Map();

	public function new() {}

	public function loadScript(id:String, path:String, ?parent:Dynamic):GameScript {
		if (scriptMap.exists(id))
			return scriptMap.get(id);

		var script = new GameScript(path, parent);
		if (script.active) {
			scriptArray.push(script);
			scriptMap.set(id, script);

			var roomContext = RoomManager.currentRoomName;
			if (roomContext != null) {
				var stateKey = roomContext + "_" + id;
				var savedState = Game.instance.save.scriptVariables.get(stateKey);
				if (savedState != null) {
					for (k in Reflect.fields(savedState)) {
						script.set(k, Reflect.field(savedState, k));
					}
				}
			}

			script.call("create");
		}
		return script;
	}

	public function setParentForAll(parent:Dynamic) {
		for (script in scriptArray) {
			if (script != null && script.active)
				script.setParent(parent);
		}
	}

	public function setGlobal(name:String, value:Dynamic):Void {
		for (script in scriptArray) {
			if (script != null && script.active)
				script.set(name, value);
		}
	}

	public function setOn(id:String, name:String, value:Dynamic):Void {
		var script = scriptMap.get(id);
		if (script != null && script.active)
			script.set(name, value);
	}

	public function call(funcName:String, ?args:Array<Dynamic>):Void {
		var i:Int = 0;
		while (i < scriptArray.length) {
			var script = scriptArray[i];

			if (script == null || !script.active) {
				scriptArray.splice(i, 1);
				for (key in scriptMap.keys()) {
					if (scriptMap.get(key) == script)
						scriptMap.remove(key);
				}
				continue;
			}

			script.call(funcName, args);
			i++;
		}
	}

	public function callOn(id:String, funcName:String, ?args:Array<Dynamic>):Dynamic {
		var script = scriptMap.get(id);
		if (script != null && script.active) {
			return script.call(funcName, args);
		}
		return null;
	}

	public function fireEvent<T:CancellableEvent>(funcName:String, eventClass:Class<T>, ?setup:T->Void):T {
		var event:T = EventManager.get(eventClass);
		if (setup != null)
			setup(event);

		var i:Int = 0;
		while (i < scriptArray.length) {
			var script = scriptArray[i];

			if (script == null || !script.active) {
				scriptArray.splice(i, 1);
				continue;
			}

			script.call(funcName, [event]);

			if (event.cancelled && !event.__continueCalls)
				break;
			i++;
		}

		return event;
	}

	public function destroy():Void {
		for (script in scriptArray) {
			if (script != null && script.active) {
				script.call("destroy");
				script.destroy();
			}
		}
		scriptArray = [];
		scriptMap.clear();
	}
}
