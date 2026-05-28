package engine.backend;

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
    public static var items:Map<String, ItemData> = new Map();
    public static var inventory:Map<String, Int> = new Map(); 

    public static function loadItems() {
        var path = "items.xml";
        if (!LilyAssets.fileExists(path)) return;
        
        var rawXML = LilyAssets.getTextFromFile(path);
        rawXML = StringTools.replace(rawXML, "<!DOCTYPE lily-engine-item>", "");
        
        var parsedXml = Xml.parse(rawXML).firstElement();
        if (parsedXml == null) return;
        
        var xml = new Access(parsedXml);
        
        var iter = (xml.name == "items") ? xml.nodes.item : (xml.hasNode.items ? xml.node.items.nodes.item : xml.nodes.item);
        
        for (node in iter) {
            var id = node.has.id ? node.att.id : (node.has.name ? node.att.name : "");
            
            if (id == "") {
                trace("Warning: Skipping item node with no valid ID attribute.");
                continue;
            }

            items.set(id, new ItemData(
                id,
                node.has.name ? node.att.name : id, 
                node.has.desc ? node.att.desc : "",
                node.has.sprite ? node.att.sprite : "ui/item_icon_bg_empty",
                node.has.script ? node.att.script : ""
            ));
        }
    }

    public static function getOwnedAmount(id:String):Int {
        return inventory.exists(id) ? inventory.get(id) : 0;
    }

    public static function addItem(id:String, amount:Int = 1) {
        if (items.exists(id)) {
            var cur = getOwnedAmount(id);
            inventory.set(id, cur + amount);
        }
    }

    public static function removeItem(id:String, amount:Int = 1) {
        if (inventory.exists(id)) {
            var cur = inventory.get(id) - amount;
            if (cur <= 0) inventory.remove(id);
            else inventory.set(id, cur);
        }
    }

    public static function runItemScript(scriptPath:String) {
        if (scriptPath == "") return;
        var fullPath = scriptPath + ".hx";
        
        if (!LilyAssets.fileExists(fullPath)) {
            flixel.FlxG.log.warn("Item Script not found at: " + fullPath);
            return;
        }

        if (RoomManager.instance != null && RoomManager.instance.scripts != null) {
            var itemScript = RoomManager.instance.scripts.loadScript(fullPath);
            RoomManager.instance.injectScriptVariables();
            itemScript.call("onUse");
        } else {
            var tempScript = new GameScript(fullPath);
            tempScript.call("onUse");
            tempScript.destroy();
        }
    }
}