package ui;

import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.ItemManager;

class InventoryMenuEntry extends FlxSpriteGroup {
    public var bg:FlxSprite;
    public var icon:FlxSprite;
    public var qtyLabel:FlxText;
    
    public var itemId:String;
    public var amount:Int;
    public var isEmpty:Bool;

    public function new(x:Float, y:Float, id:String, amt:Int) {
        super(x, y);
        itemId = id;
        amount = amt;
        isEmpty = (id == ""); // If ID is empty, it's an InventoryMenuEmptyEntry

        bg = new FlxSprite(0, 0);
        
        // 120x120 is the 3x scaled version of Godot's 40x40 IconSize
        bg.setGraphicSize(120, 120); 
        bg.updateHitbox();
        add(bg);

        if (!isEmpty) {
            var itemData = ItemManager.items.get(id);
            var path = "assets/img/" + itemData.iconPath + ".png";
            
            icon = new FlxSprite(0, 0);
            if (openfl.utils.Assets.exists(path)) icon.loadGraphic(path);
            
            // Center the icon inside the background
            icon.setGraphicSize(120, 120);
            icon.updateHitbox();
            add(icon);

            // Quantity Label Logic (Only if > 1)
            if (amount > 1) {
                qtyLabel = new FlxText(0, 90, 110, Std.string(amount), 24);
                qtyLabel.alignment = RIGHT;
                qtyLabel.color = FlxColor.WHITE;
                qtyLabel.borderColor = 0xFFBD274D; // PrimaryQtyLabelColor from C#
                qtyLabel.borderStyle = OUTLINE;
                qtyLabel.borderSize = 3;
                add(qtyLabel);
            }
        }
        
        deselect(); // Set initial texture state
    }

    public function select() {
        if (isEmpty) {
            bg.loadGraphic("assets/img/ui/item_icon_bg_empty_selected.png");
        } else {
            bg.loadGraphic("assets/img/ui/item_icon_bg_selected.png");
            if (qtyLabel != null) {
                qtyLabel.color = 0xFFBD274D; // Invert colors on select
                qtyLabel.borderColor = FlxColor.WHITE;
            }
        }
    }

    public function deselect() {
        if (isEmpty) {
            bg.loadGraphic("assets/img/ui/item_icon_bg_empty.png");
        } else {
            bg.loadGraphic("assets/img/ui/item_icon_bg.png");
            if (qtyLabel != null) {
                qtyLabel.color = FlxColor.WHITE;
                qtyLabel.borderColor = 0xFFBD274D;
            }
        }
    }
}