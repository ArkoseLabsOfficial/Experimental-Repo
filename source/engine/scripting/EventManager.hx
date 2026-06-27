package engine.scripting;

import engine.scripting.events.CancellableEvent;

class EventManager {
	public static var eventValues:Array<CancellableEvent> = [];
	public static var eventKeys:Array<Class<CancellableEvent>> = [];

	/**
	 * Gets a pooled event, recycles it, and prepares it for dispatch.
	 */
	public static function get<T:CancellableEvent>(cl:Class<T>):T {
		var c:Class<CancellableEvent> = cast cl;
		var index = eventKeys.indexOf(c);

		if (index < 0) {
			eventKeys.push(c);
			var newEvent = Type.createInstance(c, []);
			eventValues.push(newEvent);
			return cast newEvent;
		}

		var ev = eventValues[index];
		ev.recycleBase(); // Reset cancelled state and data
		return cast ev;
	}

	/**
	 * Call this when switching states to clear out old events from memory.
	 */
	public static function reset():Void {
		for (v in eventValues) {
			v.destroy();
		}
		eventValues = [];
		eventKeys = [];
	}
}
