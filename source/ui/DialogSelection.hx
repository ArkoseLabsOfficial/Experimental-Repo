package ui;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import backend.Controls;
import flixel.util.FlxColor;

class DialogSelection extends FlxTypedGroup<FlxSprite> {
    var bgBoxFill:FlxSprite;
    var bgBoxBorder:FlxSprite;
    var selector:FlxSprite;
    
    var options:Array<String>;
    var optionTexts:Array<FlxText> = [];
    var selectedIndex:Int = 0;
    
    public var activeMenu:Bool = false;
    public var onSelect:Int->Void;

    public function new() {
        super();
        bgBoxBorder = new FlxSprite(0, 0).loadGraphic("assets/img/ui/frame_menu.png");
        bgBoxBorder.scrollFactor.set(0, 0); 
        
        selector = new FlxSprite().makeGraphic(1, 1, 0xFFFFFFFF); 
        selector.alpha = 0.4;
        selector.scrollFactor.set(0, 0);
        
        // Items are added dynamically during the show() function to guarantee layer order
        
        visible = false;
        activeMenu = false;
    }

    public function show(optionsList:Array<String>, callback:Int->Void):Void {
        options = optionsList;
        onSelect = callback;
        
        // Clear all elements to guarantee clean layering
        for (txt in optionTexts) {
            remove(txt, true);
            txt.destroy();
        }
        optionTexts = [];
        
        remove(selector, true);
        remove(bgBoxBorder, true);
        
        // --- DYNAMIC WIDTH AND HEIGHT ---
        var maxTextWidth:Float = 200; // Minimum allowed width
        for (opt in options) {
            var tempText = new FlxText(0, 0, 0, opt, 20);
            if (tempText.width > maxTextWidth) maxTextWidth = tempText.width;
            tempText.destroy();
        }
        
        var boxWidth = maxTextWidth + 30; // Text width + 30px padding on each side
        var boxHeight = 40 + (options.length * 35);
        
        bgBoxBorder.setGraphicSize(Std.int(boxWidth), Std.int(boxHeight)); 
        bgBoxBorder.updateHitbox();
        bgBoxBorder.screenCenter();

        selector.setGraphicSize(Std.int(bgBoxBorder.width - 20), 30);
        selector.updateHitbox();

        // --- LAYER ORDER REBUILD (Fixes first-item missing bug) ---
        // 1. Background
        add(bgBoxBorder);

        // 2. Texts
        var layoutY = bgBoxBorder.y + 20;
        for (i in 0...options.length) {
            var txt = new FlxText(bgBoxBorder.x * 0.81, layoutY - 12, bgBoxBorder.width * 2, options[i], 40);
            txt.scale.set(0.5, 0.5);
            txt.alignment = "center";
            txt.scrollFactor.set(0, 0);
            txt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5); 
            add(txt); 
            optionTexts.push(txt);
            layoutY += 35;
        }

        // 3. Selection Box Highlight
        add(selector);

        visible = true;
        activeMenu = true;
        changeSelection(0);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (!activeMenu) return;

        if (Controls.UP_P) changeSelection(-1);
        if (Controls.DOWN_P) changeSelection(1);
        
        if (Controls.ACCEPT_P) {
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
            selector.x = bgBoxBorder.x + 10;
            selector.y = optionTexts[selectedIndex].y + 12; 
        }
    }
}