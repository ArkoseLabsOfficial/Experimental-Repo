package ui;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUI9SliceSprite;
import backend.Controls;
import backend.UIUtil;

class DialogSelection extends FlxTypedGroup<FlxSprite> {
    var bgBoxBorder:FlxUI9SliceSprite;
    var selector:FlxSprite;
    var options:Array<String>;
    var optionTexts:Array<FlxText> = [];
    var selectedIndex:Int = 0;
    
    public var activeMenu:Bool = false;
    public var onSelect:Int->Void;

    var optionSpacing:Float = 35;
    var boxPaddingX:Float = 60;

    public function new() {
        super();
        
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
        if (bgBoxBorder != null) {
            remove(bgBoxBorder, true);
            bgBoxBorder.destroy();
        }
        
        var maxTextWidth:Float = 200; 
        for (opt in options) {
            var tempText = UIUtil.createText(0, 0, 0, opt, 40);
            tempText.scale.set(0.5, 0.5);
            tempText.updateHitbox();
            
            if (tempText.width > maxTextWidth) maxTextWidth = tempText.width;
            tempText.destroy();
        }
        
        var boxWidth = maxTextWidth + boxPaddingX; 
        var boxHeight = 40 + (options.length * optionSpacing);
        
        bgBoxBorder = UIUtil.create9SliceSprite("assets/img/ui/frame_menu.png", 0, 0, boxWidth, boxHeight, 1.0);
        bgBoxBorder.scrollFactor.set(0, 0); 
        bgBoxBorder.screenCenter();

        selector.setGraphicSize(Std.int(boxWidth - 20), 30);
        selector.updateHitbox();
        selector.x = bgBoxBorder.x + 10;

        add(bgBoxBorder);

        var layoutY = bgBoxBorder.y + 20;

        for (i in 0...options.length) {
            var txt = UIUtil.createText(0, layoutY, 0, options[i], 40);
            txt.scale.set(0.5, 0.5);
            txt.updateHitbox();
            txt.x = bgBoxBorder.x + ((bgBoxBorder.width - txt.width) / 2);
            txt.scrollFactor.set(0, 0);
            txt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5); 
            
            add(txt); 
            optionTexts.push(txt);
            
            layoutY += optionSpacing;
        }

        add(selector);

        visible = true;
        activeMenu = true;
        changeSelection(0);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (!activeMenu) return;

        if (Controls.UP_P) {
            UIUtil.playNavSound();
            changeSelection(-1);
        }
        if (Controls.DOWN_P) {
            UIUtil.playNavSound();
            changeSelection(1);
        }
        
        if (Controls.ACCEPT_P) {
            UIUtil.playConfirmSound();
            visible = false;
            activeMenu = false;
            if (onSelect != null) onSelect(selectedIndex);
        }
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