package engine.backend.game;

class ItemData {
	public var id:String;
	public var name:String;
	public var desc:String;
	public var iconPath:String;
	public var scriptPath:String;

	public function new(id:String, name:String, desc:String, iconPath:String, scriptPath:String) {
		this.id = id;
		this.name = name;
		this.desc = desc;
		this.iconPath = iconPath;
		this.scriptPath = scriptPath;
	}
}

class ItemManager {
	public var items:Map<String, ItemData> = new Map();
	public var inventory:Map<String, Int> = new Map();

	public function new() {}

	public function load():Void {
		var path = "items.xml";
		var xml = SimpleParser.loadXML(path, "<!DOCTYPE lily-engine-item>");
		if (xml == null)
			return;

		var iter = (xml.name == "items") ? xml.nodes.item : (xml.hasNode.items ? xml.node.items.nodes.item : xml.nodes.item);

		for (node in iter) {
			var id = node.has.id ? node.att.id : (node.has.name ? node.att.name : "");

			if (id == "")
				continue;

			items.set(id,
				new ItemData(id, node.has.name ? node.att.name : id, node.has.desc ? node.att.desc : "",
					node.has.sprite ? node.att.sprite : "ui/item_icon_bg_empty", node.has.script ? node.att.script : ""));
		}
	}

	public function getOwnedAmount(id:String):Int {
		return inventory.exists(id) ? inventory.get(id) : 0;
	}

	public function addItem(id:String, amount:Int = 1):Void {
		if (items.exists(id)) {
			var cur = getOwnedAmount(id);
			inventory.set(id, cur + amount);
		}
	}

	public function removeItem(id:String, amount:Int = 1):Void {
		if (inventory.exists(id)) {
			var cur = inventory.get(id) - amount;
			if (cur <= 0)
				inventory.remove(id);
			else
				inventory.set(id, cur);
		}
	}

	public function runItemScript(scriptPath:String):Void {
		trace("scripts/" + scriptPath);
		if (scriptPath == "")
			return;
		var fullPath = scriptPath + ".hx";
		trace("scripts/" + fullPath);

		//if (!LilyAssets.fileExists(fullPath))
			//return;

		#if FEATURE_HSCRIPT
		trace("scripts/" + fullPath);
		var itemScript = RoomManager.instance.scripts.loadScript("item", "scripts/" + fullPath);
		RoomManager.instance.injectScriptVariables();
		itemScript.call("onUse");
		#end
	}
}
