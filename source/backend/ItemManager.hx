package backend;

import haxe.xml.Access;
import openfl.utils.Assets;

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
    // Maps Item ID -> Amount Owned
    public static var inventory:Map<String, Int> = new Map(); 

    public static function loadItems() {
        var path = "assets/data/items.xml";
        if (!Assets.exists(path)) return;
        
        var rawXML = Assets.getText(path);
        rawXML = StringTools.replace(rawXML, "<!DOCTYPE lacie-engine-item>", "");
        
        // Target the actual root element inside the document
        var parsedXml = Xml.parse(rawXML).firstElement();
        if (parsedXml == null) return;
        
        var xml = new Access(parsedXml);
        
        // Correctly checks if the root tag CONTAINS an <items> child, or is itself the collection
        var iter = (xml.name == "items") ? xml.nodes.item : (xml.hasNode.items ? xml.node.items.nodes.item : xml.nodes.item);
        
        for (node in iter) {
            // SEPARATED ID AND NAME: 
            // Expects 'id="..."' attribute now. Falls back to 'name' if 'id' is missing.
            var id = node.has.id ? node.att.id : (node.has.name ? node.att.name : "");
            
            if (id == "") {
                trace("Warning: Skipping item node with no valid ID attribute.");
                continue;
            }

            trace("Loaded Item ID: " + id);
            
            items.set(id, new ItemData(
                id,
                node.has.name ? node.att.name : id, // Fallback to ID if UI name is empty
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
        trace(id);
        if (items.exists(id)) {
            trace(id);
            var cur = getOwnedAmount(id);
            trace(cur + amount);
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

    // --- HSCRIPT SUPPORT ---
    public static function runItemScript(scriptPath:String) {
        if (scriptPath == "") return;
        var fullPath = "assets/data/" + scriptPath + ".hx";
    }
}