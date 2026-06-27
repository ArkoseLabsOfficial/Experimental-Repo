package engine.substates;

class Inventory extends SubStateBackend {
    static inline var MAIN_PANEL_W:Int = 900;
    static inline var MAIN_PANEL_H:Int = 600;
    static inline var DESC_PANEL_W:Int = 546;
    static inline var DESC_PANEL_H:Int = 600;

    var entries:Array<InventoryMenuEntry> = [];
    var curSelected:Int = 0;
    var maxCols:Int = 5;

    var descFrame:MenuFrameNode;
    var descText:FlxText;

    override public function create() {
        super.create();
        camMenu.scroll.set(-230, 230);

        var separation = 6;
        var totalWidth = MAIN_PANEL_W + separation + DESC_PANEL_W;
        var startX = (FlxG.width - totalWidth) / 2;
        var startY = (FlxG.height - MAIN_PANEL_H) / 2;

        var invFrame = new MenuFrameNode(startX, startY, MAIN_PANEL_W, MAIN_PANEL_H, 2);
        invFrame.setTitle(Game.instance.language.getCaption("system.menu.items"));
        invFrame.divider.loadGraphic(LilyAssets.image("ui/dividers/divider_md"));
        add(invFrame);

        var descX = startX + MAIN_PANEL_W + separation;
        descFrame = new MenuFrameNode(descX, startY, DESC_PANEL_W, DESC_PANEL_H, 2);
        descFrame.nodeFrame.decorBgTexture = "ui/decors/menu_bg_decor";
        descFrame.divider.loadGraphic(LilyAssets.image("ui/dividers/divider_sm"));
        descFrame.divider.updateHitbox();
        descFrame.divider.x = descX + (DESC_PANEL_W - descFrame.divider.width) / 2;
        add(descFrame);

        descText = new FlxText(descX + 45, startY + 130, DESC_PANEL_W - 90, "", 24);
        descText.alignment = LEFT;
        add(descText);

        var ownedItemIDs = [];
        for (id in Game.instance.items.inventory.keys())
            ownedItemIDs.push(id);

        var rawCount = ownedItemIDs.length;
        var totalSlots = Std.int(Math.max(15, 5 * Math.ceil(rawCount / 5.0)));

        var gridStartX = startX + 75;
        var gridStartY = startY + 120;
        var iconSize = 120;
        var gap = 30;
        var stride = iconSize + gap;

        for (i in 0...totalSlots) {
            var cx = gridStartX + (i % maxCols) * stride;
            var cy = gridStartY + Math.floor(i / maxCols) * stride;

            var entry:InventoryMenuEntry;
            if (i < rawCount) {
                var id = ownedItemIDs[i];
                entry = new InventoryMenuEntry(cx, cy, id, Game.instance.items.getOwnedAmount(id));
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

        if (Controls.UP_P)
            moveSelection(-maxCols, false);
        if (Controls.DOWN_P)
            moveSelection(maxCols, false);
        if (Controls.LEFT_P)
            moveSelection(-1, true);
        if (Controls.RIGHT_P)
            moveSelection(1, true);

        if (Controls.CANCEL) {
            LilyAssets.play(LilyAssets.CANCEL);
            close();
        }

        if (Controls.ACCEPT) {
            var activeEntry = entries[curSelected];
            if (!activeEntry.isEmpty) {
                LilyAssets.play(LilyAssets.CONFIRM);
                var itemData = Game.instance.items.items.get(activeEntry.itemId);

                trace(itemData.scriptPath);
                if (itemData != null && itemData.scriptPath != "") {
                    Game.instance.items.runItemScript(itemData.scriptPath);
                    Game.instance.items.removeItem(activeEntry.itemId, 1);
                }
                close();
            } else {
                LilyAssets.play(LilyAssets.ERROR);
            }
        }
    }

    function moveSelection(change:Int, isHorizontal:Bool) {
        LilyAssets.play(LilyAssets.NAVIGATE);
        if (isHorizontal) {
            var oldCol = curSelected % maxCols;
            curSelected += change;
            if (change == -1 && oldCol == 0)
                curSelected += maxCols;
            else if (change == 1 && oldCol == maxCols - 1)
                curSelected -= maxCols;
        } else {
            curSelected += change;
            if (curSelected < 0)
                curSelected += entries.length;
            if (curSelected >= entries.length)
                curSelected %= maxCols;
        }
        highlightSelection();
    }

    function highlightSelection() {
        for (entry in entries)
            entry.deselect();
        descFrame.setTitle("");
        descText.text = "";
        descFrame.divider.visible = false;

        if (curSelected > -1 && curSelected < entries.length) {
            var activeEntry = entries[curSelected];
            activeEntry.select();

            if (!activeEntry.isEmpty) {
                var itemData = Game.instance.items.items.get(activeEntry.itemId);
                descFrame.setTitle(Game.instance.language.getCaption(itemData.name));
                descText.text = Game.instance.language.getCaption(itemData.desc);
                descFrame.divider.visible = true;
            }
        }
    }
}

class InventoryMenuEntry extends FlxSpriteGroup {
    static inline var ICON_SIZE:Int = 120;

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
            var itemData = Game.instance.items.items.get(id);
            itemIcon = new FlxSprite(0, 0);
            var iconPath = (itemData != null ? itemData.iconPath : id);

            if (LilyAssets.fileExists("images/" + iconPath + ".png"))
                itemIcon.loadGraphic(LilyAssets.image(iconPath));
            else
                itemIcon.makeGraphic(ICON_SIZE, ICON_SIZE, FlxColor.TRANSPARENT);

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
        var tex = isEmpty ? LilyAssets.image("ui/items/item_icon_bg_empty_selected") : LilyAssets.image("ui/items/item_icon_bg_selected");
        bgTextureRect.loadGraphic(tex);
        bgTextureRect.setGraphicSize(ICON_SIZE, ICON_SIZE);
        bgTextureRect.updateHitbox();
        if (nQtyLabel != null) {
            nQtyLabel.color = 0xFFBD274D;
            nQtyLabel.borderColor = FlxColor.WHITE;
        }
    }

    public function deselect() {
        var tex = isEmpty ? LilyAssets.image("ui/items/item_icon_bg_empty") : LilyAssets.image("ui/items/item_icon_bg");
        bgTextureRect.loadGraphic(tex);
        bgTextureRect.setGraphicSize(ICON_SIZE, ICON_SIZE);
        bgTextureRect.updateHitbox();
        if (nQtyLabel != null) {
            nQtyLabel.color = FlxColor.WHITE;
            nQtyLabel.borderColor = 0xFFBD274D;
        }
    }
}