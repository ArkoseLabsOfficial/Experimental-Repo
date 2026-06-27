package engine.ui;

class MenuFrameNode extends FlxSpriteGroup {
    public var nodeFrame:SpecialNinePatch;

    public var titleText:FlxText;
    public var divider:FlxSprite;
    public var hasTitle:Bool = false;

    public function new(X:Float = 0, Y:Float = 0, targetWidth:Float, targetHeight:Float, mode:Int = 0) {
        super(X, Y);
        hasTitle = mode == 2;

        nodeFrame = new SpecialNinePatch();

        if (mode == 1 || mode == 2) {
            nodeFrame.texture = "ui/frames/frame_menu_2";
            nodeFrame.bgTexture = "ui/frames/frame_menu_bg";
            nodeFrame.bgMaskTexture = null;
            nodeFrame.patchMarginLeft = 50;
            nodeFrame.patchMarginTop = 50;
            nodeFrame.patchMarginRight = 50;
            nodeFrame.patchMarginBottom = 50;
            nodeFrame.scaleFactor = 0.75;

            if (mode == 2) {
                titleText = new FlxText(0, 30, Std.int(targetWidth), "", 48);
                titleText.alignment = CENTER;

                divider = new FlxSprite(0, 90);
                divider.loadGraphic(LilyAssets.image("ui/dividers/divider_md"));
                divider.scale.set(0.75, 0.75);
                divider.updateHitbox();
                divider.x = (targetWidth - divider.width) / 2;
            }
        } else {
            nodeFrame.texture = "ui/frames/frame_default";
            nodeFrame.bgTexture = "ui/frames/frame_default_bg";
            nodeFrame.bgMaskTexture = "ui/masks/frame_default_bg_mask";
            nodeFrame.patchMarginLeft = 123;
            nodeFrame.patchMarginTop = 142;
            nodeFrame.patchMarginRight = 123;
            nodeFrame.patchMarginBottom = 120;
            nodeFrame.scaleFactor = 0.45;
        }

        nodeFrame.setSizeEx(targetWidth, targetHeight);
        add(nodeFrame);

        if (mode == 2) {
            add(titleText);
            add(divider);
        }
    }

    public function setTitle(text:String):Void {
        if (hasTitle && titleText != null) {
            titleText.text = text;

            var showTitle = (text != null && text.length > 0);
            titleText.visible = showTitle;
            divider.visible = showTitle;
        }
    }

    public function addMenu(menu:FlxSpriteGroup):Void {
        menu.x = 54;
        menu.y = hasTitle && titleText.visible ? 130 : 36;
        add(menu);
    }
}

class SimpleVerticalMenu extends FlxSpriteGroup {
    public var selection:Int = 0;
    
    public var itemWidth:Float = 492;
    public var itemFontSize:Int = 48;
    public var itemAlignment:flixel.text.FlxText.FlxTextAlign = CENTER;

    private var entries:Array<{caption:String, action:Void->Void}> = [];
    private var visualItems:Array<MenuVisualEntry> = [];

    public function new() {
        super();
    }

    public function drawContent():Void {}

    public function addEntry(caption:String, action:Void->Void):Void {
        entries.push({caption: caption, action: action});
    }

    public function buildVisualList(separation:Float = 72):Void {
        for (i in 0...entries.length) {
            var item = new MenuVisualEntry(0, i * separation, entries[i].caption, itemWidth, Std.int(separation), itemFontSize, itemAlignment);
            visualItems.push(item);
            add(item);
        }
        highlightSelection();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        handleInput();
    }

    public function handleInput():Void {
        if (Controls.UP_P) {
            LilyAssets.play(LilyAssets.NAVIGATE);
            selection--;
            if (selection < 0)
                selection = entries.length - 1;
            highlightSelection();
        } else if (Controls.DOWN_P) {
            LilyAssets.play(LilyAssets.NAVIGATE);
            selection++;
            if (selection >= entries.length)
                selection = 0;
            highlightSelection();
        } else if (Controls.ACCEPT) {
            if (entries[selection] != null)
                entries[selection].action();
        }
    }

    public function highlightSelection():Void {
        for (i in 0...visualItems.length)
            visualItems[i].setHighlight(i == selection);
    }

    public function resetSelection():Void {
        selection = 0;
        highlightSelection();
    }
}

class MenuVisualEntry extends FlxSpriteGroup {
    public var bg:FlxSprite;
    public var label:FlxText;

    private static inline var SELECT_COLOR:FlxColor = 0x33EDDEDE;

    public function new(X:Float, Y:Float, text:String, width:Float, height:Float, fontSize:Int = 48, align:flixel.text.FlxText.FlxTextAlign = CENTER) {
        super(X, Y);
        
        bg = new FlxSprite(0, 0);
        bg.makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT);
        add(bg);

        label = new FlxText(0, 0, width, text, fontSize);
        label.alignment = align;
        add(label);
        
        label.y = this.y + (height - label.height) / 2;
    }

    public function setHighlight(isActive:Bool):Void {
        bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), isActive ? SELECT_COLOR : FlxColor.TRANSPARENT);
    }
}