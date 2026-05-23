package scripting;

import scripting.events.CancellableEvent;

class ScriptHandler {
    public var scripts:Array<GameScript> = [];

    public function new() {}

    /**
     * Initializes and adds a script to the handler, passing an optional parent.
     */
    public function loadScript(path:String, ?parent:Dynamic):GameScript {
        var script = new GameScript(path, parent);
        if (script.active) {
            scripts.push(script);
            script.call("onCreate"); 
        }
        return script;
    }

    /**
     * Re-assigns the parent object for all actively loaded scripts.
     */
    public function setParentForAll(parent:Dynamic) {
        for (script in scripts) {
            script.setParent(parent);
        }
    }

    public function setGlobal(name:String, value:Dynamic):Void {
        for (script in scripts) {
            script.set(name, value);
        }
    }

    public function call(funcName:String, ?args:Array<Dynamic>):Void {
        var i:Int = 0;
        while (i < scripts.length) {
            var script = scripts[i];
            if (script != null && script.active) {
                script.call(funcName, args);
            }
            i++;
        }
    }

    public function fireEvent<T:CancellableEvent>(funcName:String, eventClass:Class<T>, ?setup:T->Void):T {
        var event:T = EventManager.get(eventClass);
        
        if (setup != null) setup(event);

        for (script in scripts) {
            if (!script.active) continue;

            script.call(funcName, [event]);

            // If the script cancelled it, stop iterating immediately
            if (event.cancelled && !event.__continueCalls) {
                break;
            }
        }
        return event;
    }

    public function destroy():Void {
        var i:Int = 0;
        while (i < scripts.length) {
            var script = scripts[i];
            if (script != null) {
                script.call("onDestroy");
                script.destroy();
            }
            i++;
        }
        scripts = [];
    }
}