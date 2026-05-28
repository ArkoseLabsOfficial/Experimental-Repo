package engine.ui;

class DialogSelection extends FlxTypedGroup<FlxSprite> {
    var bgBox:FlxUI9SliceSprite;
    var overlayBox:FlxUI9SliceSprite;
    var selector:FlxSprite;
    var options:Array<String>;
    var optionTexts:Array<FlxText> = [];
    var selectedIndex:Int = 0;
    
    public var activeMenu:Bool = false;
    public var onSelect:Int->Void;

    var optionSpacing:Float = 35;
    var boxPaddingX:Float = 60;

    public var customBoxWidth:Float = 0;
    public var customBoxHeight:Float = 0;
    var parent:Dynamic = null;

    public function new(parent:Dynamic) {
        super();
        this.parent = parent;
        
        selector = UIUtil.createHighlightBox(0, 0, 1, 1, 0.4);
        selector.scrollFactor.set(0, 0);
        
        visible = false;
        activeMenu = false;
    }

    public function show(optionsList:Array<String>, callback:Int->Void):Void {
        options = optionsList;
        onSelect = callback;

        for (txt in optionTexts) {
            remove(txt, true);
            txt.destroy();
        }
        optionTexts = [];
        
        remove(selector, true);
        if (bgBox != null) {
            remove(bgBox, true);
            bgBox.destroy();
        }
        if (overlayBox != null) {
            remove(overlayBox, true);
            overlayBox.destroy();
        }
        
        var maxTextWidth:Float = 200; 
        var textHeight:Float = 20;

        for (opt in options) {
            var tempText = UIUtil.createText(0, 0, 0, opt, 40);
            tempText.scale.set(0.5, 0.5);
            tempText.updateHitbox();
            
            if (tempText.width > maxTextWidth) maxTextWidth = tempText.width;
            textHeight = tempText.height;
            
            tempText.destroy();
        }
        
        var totalTextHeight:Float = ((options.length - 1) * optionSpacing) + textHeight;
        var finalBoxWidth = (customBoxWidth > 0) ? customBoxWidth : (maxTextWidth + boxPaddingX); 
        var finalBoxHeight = (customBoxHeight > 0) ? customBoxHeight : (totalTextHeight + 60); 
        
        bgBox = UIUtil.create9SliceSprite(LilyAssets.image("img/ui/frame_default_bg"), 1300, 561, finalBoxWidth, finalBoxHeight, 1.0);
        bgBox.scrollFactor.set(0, 0); 
        bgBox.screenCenter();

        overlayBox = UIUtil.create9SliceSprite(LilyAssets.image("img/ui/frame_menu_2b"), 1300, 561, finalBoxWidth, finalBoxHeight, 1.0);
        overlayBox.scrollFactor.set(0, 0);
        overlayBox.screenCenter();

        selector.setGraphicSize(Std.int(finalBoxWidth - 20), 30);
        selector.updateHitbox();
        selector.x = bgBox.x + 10;

        add(bgBox);
        add(selector);

        var layoutY = bgBox.y + ((bgBox.height - totalTextHeight) / 2);

        for (i in 0...options.length) {
            var txt = UIUtil.createText(0, layoutY, 0, options[i], 40);
            txt.scale.set(0.5, 0.5);
            txt.updateHitbox();
            txt.x = bgBox.x + ((bgBox.width - txt.width) / 2);
            txt.scrollFactor.set(0, 0);
            txt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5); 
            
            add(txt); 
            optionTexts.push(txt);
            
            layoutY += optionSpacing;
        }

        add(overlayBox);

        visible = true;
        activeMenu = true;
        changeSelection(0);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (!activeMenu) return;

        var pointerMoved = false;
        var pointerJustPressed = false;

        #if FLX_MOUSE
        if (FlxG.mouse.justMoved) pointerMoved = true;
        if (FlxG.mouse.justPressed) pointerJustPressed = true;
        #end

        var touchJustPressed = false;
        for (touch in FlxG.touches.list) {
            pointerMoved = true; 
            if (touch.justPressed) touchJustPressed = true;
        }

        if (pointerMoved || pointerJustPressed || touchJustPressed) {
            for (i in 0...optionTexts.length) {
                var txt = optionTexts[i];
                var overlap = false;

                #if FLX_MOUSE
                if (FlxG.mouse.overlaps(txt, parent.dialogCamera)) overlap = true;
                #end

                for (touch in FlxG.touches.list) {
                    if (touch.overlaps(txt, parent.dialogCamera)) overlap = true;
                }

                if (overlap) {
                    if (selectedIndex != i) {
                        UIUtil.playNavSound();
                        changeSelection(i - selectedIndex); 
                    }
                    if (pointerJustPressed || touchJustPressed) {
                        confirmSelection();
                        return; 
                    }
                }
            }
        }

        if (Controls.UP_P) {
            UIUtil.playNavSound();
            changeSelection(-1);
        }
        if (Controls.DOWN_P) {
            UIUtil.playNavSound();
            changeSelection(1);
        }
        
        if (Controls.ACCEPT_P) {
            confirmSelection();
        }
    }

    function confirmSelection():Void {
        UIUtil.playConfirmSound();
        visible = false;
        activeMenu = false;
        if (onSelect != null) onSelect(selectedIndex);
    }

    function changeSelection(change:Int):Void {
        selectedIndex += change;
        
        if (selectedIndex < 0) selectedIndex = options.length - 1;
        if (selectedIndex >= options.length) selectedIndex = 0;

        if (optionTexts.length > 0) {
            var targetText = optionTexts[selectedIndex];
            selector.y = targetText.y + (targetText.height / 2) - (selector.height / 2);
        }
    }
}