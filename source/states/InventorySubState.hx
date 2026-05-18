package states;

import flixel.FlxSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import openfl.utils.Assets;
import backend.ItemManager;
import ui.TitledMenuFrame;
import flixel.FlxCamera;

class InventorySubState extends FlxSubState {
    // Exact 3x Godot Dimensions (Vector2(300, 200) & Vector2(182, 200))
    static inline var MAIN_PANEL_W:Int = 900;
    static inline var MAIN_PANEL_H:Int = 600;
    static inline var DESC_PANEL_W:Int = 546;
    static inline var DESC_PANEL_H:Int = 600;
    
    var entries:Array<InventoryMenuEntry> = [];
    var curSelected:Int = 0;
    var maxCols:Int = 5;

    // UI Elements
    var descFrame:TitledMenuFrame;
    var descText:FlxText;
    var camInventory:FlxCamera;

    override public function create() {
        super.create();
        camInventory = new FlxCamera();
        camInventory.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(camInventory, false);
        this.cameras = [camInventory];
        camInventory.scroll.set(-230, 230);
        trace(ItemManager.inventory);

        // Center calculation
        var separation = 6; // HBoxContainer SetSeparation(2) * 3
        var totalWidth = MAIN_PANEL_W + separation + DESC_PANEL_W;
        var startX = (FlxG.width - totalWidth) / 2;
        var startY = (FlxG.height - MAIN_PANEL_H) / 2;

        // --- Build Inventory Frame (Left) ---
        // Title: system.menu.inventory, Divider: divider_md
        var invFrame = new TitledMenuFrame(startX, startY, MAIN_PANEL_W, MAIN_PANEL_H, "Eşyalar", "assets/img/ui/divider_md.png", "");
        add(invFrame);

        // --- Build Description Frame (Right) ---
        // Divider: divider_sm, Decor: menu_bg_decor
        var descX = startX + MAIN_PANEL_W + separation;
        descFrame = new TitledMenuFrame(descX, startY, DESC_PANEL_W, DESC_PANEL_H, "", "assets/img/ui/divider_sm.png", "assets/img/ui/menu_bg_decor.png");
        add(descFrame);

        // Content Margin Top scaled for text
        descText = new FlxText(descX + 45, startY + 130, DESC_PANEL_W - 90, "", 24);
        add(descText);

        // --- Load Inventory Data ---
        var ownedItemIDs = [];
        for (id in ItemManager.inventory.keys()) ownedItemIDs.push(id);
        
        var rawCount = ownedItemIDs.length;
        var totalSlots = Std.int(Math.max(15, 5 * Math.ceil(rawCount / 5.0)));

        // --- Build Entry Grid ---
        var gridStartX = startX + 75; // ContentMarginLeft = 25 * 3
        var gridStartY = startY + 120; // ContentMarginTop + TitleSpace
        var iconSize = 120; // 40f * 3
        var gap = 30; // 10,10 * 3
        var stride = iconSize + gap;

        for (i in 0...totalSlots) {
            var cx = gridStartX + (i % maxCols) * stride;
            var cy = gridStartY + Math.floor(i / maxCols) * stride;

            var entry:InventoryMenuEntry;
            if (i < rawCount) {
                var id = ownedItemIDs[i];
                entry = new InventoryMenuEntry(cx, cy, id, ItemManager.getOwnedAmount(id));
            } else {
                entry = new InventoryMenuEntry(cx, cy, "", 0);
            }
            
            entries.push(entry);
            add(entry);
        }

        highlightSelection();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.UP) moveSelection(-maxCols, false);
        if (FlxG.keys.justPressed.DOWN) moveSelection(maxCols, false);
        if (FlxG.keys.justPressed.LEFT) moveSelection(-1, true);
        if (FlxG.keys.justPressed.RIGHT) moveSelection(1, true);
        
        if (FlxG.keys.justPressed.X || FlxG.keys.justPressed.ESCAPE) {
            FlxG.sound.play("assets/sfx/ui_navigation2.ogg");
            close();
        }

        if (FlxG.keys.justPressed.Z || FlxG.keys.justPressed.ENTER) {
            var activeEntry = entries[curSelected];
            if (!activeEntry.isEmpty) {
                FlxG.sound.play("assets/sfx/ui_start.ogg");
                var itemData = ItemManager.items.get(activeEntry.itemId);
                
                if (itemData != null && itemData.scriptPath != "") {
                    ItemManager.runItemScript(itemData.scriptPath);
                    trace("item selected and script runned");
                    ItemManager.removeItem(activeEntry.itemId, 1);
                }
                close();
            } else {
                FlxG.sound.play("assets/sfx/ui_bad.ogg");
            }
        }
    }

    function moveSelection(change:Int, isHorizontal:Bool) {
        FlxG.sound.play("assets/sfx/ui_navigation.ogg");
        
        if (isHorizontal) {
            var oldCol = curSelected % maxCols;
            curSelected += change;
            if (change == -1 && oldCol == 0) curSelected += maxCols;
            else if (change == 1 && oldCol == maxCols - 1) curSelected -= maxCols;
        } else {
            curSelected += change;
            if (curSelected < 0) curSelected += entries.length;
            if (curSelected >= entries.length) curSelected %= maxCols;
        }
        
        highlightSelection();
    }

    function highlightSelection() {
        for (entry in entries) entry.deselect();
        
        descFrame.setTitle("");
        descText.text = "";

        if (curSelected > -1 && curSelected < entries.length) {
            var activeEntry = entries[curSelected];
            activeEntry.select();

            if (!activeEntry.isEmpty) {
                var itemData = ItemManager.items.get(activeEntry.itemId);
                descFrame.setTitle(itemData.name); // Automatically un-hides title and divider
                descText.text = itemData.desc;
            }
        }
    }
}

// ==============================================================================
// ENTRY SPRITE LOGIC (Scaled 3x)
// ==============================================================================
class InventoryMenuEntry extends FlxSpriteGroup {
    static inline var ICON_SIZE:Int = 120; // 40f * 3
    
    var bgTextureRect:FlxSprite;
    var itemIcon:FlxSprite;
    var nQtyLabel:FlxText;
    
    public var itemId:String;
    public var amount:Int;
    public var isEmpty:Bool;

    public function new(x:Float, y:Float, id:String, amt:Int) {
        super(x, y);
        itemId = id;
        amount = amt;
        isEmpty = (id == ""); 

        bgTextureRect = new FlxSprite(0, 0);
        add(bgTextureRect);

        if (!isEmpty) {
            var itemData = ItemManager.items.get(id);
            itemIcon = new FlxSprite(0, 0);
            var iconPath = "assets/" + (itemData != null ? itemData.iconPath : id) + ".png";
            
            if (Assets.exists(iconPath)) itemIcon.loadGraphic(iconPath);
            else itemIcon.makeGraphic(ICON_SIZE, ICON_SIZE, FlxColor.TRANSPARENT); 
            
            itemIcon.setGraphicSize(ICON_SIZE, ICON_SIZE);
            itemIcon.updateHitbox();
            add(itemIcon);

            if (amount > 1) {
                nQtyLabel = new FlxText(0, ICON_SIZE - 35, ICON_SIZE, Std.string(amount), 24);
                nQtyLabel.alignment = RIGHT;
                nQtyLabel.color = FlxColor.WHITE;
                nQtyLabel.borderColor = 0xFFBD274D; 
                nQtyLabel.borderStyle = OUTLINE;
                nQtyLabel.borderSize = 3;
                add(nQtyLabel);
            }
        }
        deselect(); 
    }

    public function select() {
        var tex = isEmpty ? "assets/img/ui/item_icon_bg_empty_selected.png" : "assets/img/ui/item_icon_bg_selected.png";
        if (Assets.exists(tex)) bgTextureRect.loadGraphic(tex);
        else bgTextureRect.makeGraphic(ICON_SIZE, ICON_SIZE, 0xFFFF0000); 
        
        bgTextureRect.setGraphicSize(ICON_SIZE, ICON_SIZE);
        bgTextureRect.updateHitbox();

        if (nQtyLabel != null) {
            nQtyLabel.color = 0xFFBD274D;
            nQtyLabel.borderColor = FlxColor.WHITE;
        }
    }

    public function deselect() {
        var tex = isEmpty ? "assets/img/ui/item_icon_bg_empty.png" : "assets/img/ui/item_icon_bg.png";
        if (Assets.exists(tex)) bgTextureRect.loadGraphic(tex);
        else bgTextureRect.makeGraphic(ICON_SIZE, ICON_SIZE, 0xFF444444); 
        
        bgTextureRect.setGraphicSize(ICON_SIZE, ICON_SIZE);
        bgTextureRect.updateHitbox();

        if (nQtyLabel != null) {
            nQtyLabel.color = FlxColor.WHITE;
            nQtyLabel.borderColor = 0xFFBD274D;
        }
    }
}