package states.options;

import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import backend.Language;
import backend.Controls;

class BaseOptionSubstate extends FlxSubState {
    public var bgBoxFill:FlxSprite;   
    public var bgBoxBorder:FlxSprite; 
    public var selector:FlxSprite;
    public var options:FlxTypedGroup<Option>;
    public var selectedIndex:Int = 0;
    
    public var layoutY:Float = 0;
    public var layoutSpacing:Float = 48; // Scaled gap for 1080p

    public function new() {
        super(0x99000000); 
    }

    override public function create():Void {
        super.create();
        options = new FlxTypedGroup<Option>();
        
        // Settings Box scaled for 1080p
        bgBoxFill = new FlxSprite(0, 0).loadGraphic("assets/img/ui/frame_menu.png");
        bgBoxFill.setGraphicSize(1300, 1000);
        bgBoxFill.updateHitbox();
        bgBoxFill.screenCenter();

        // Thick selector for 1080p
        selector = new FlxSprite().makeGraphic(Std.int(bgBoxFill.width - 60), 38, 0x66FFFFFF);

        add(bgBoxFill);
        add(selector);
        add(options);

        layoutY = bgBoxFill.y + 60;
        Language.onLanguageUpdate.push(refreshText);
    }

    public function addOption(transKey:String, val:String, action:Int->Void, centered:Bool = false):Option {
        var opt = new Option(transKey, val, action);
        
        if (centered) {
            opt.labelText.x = bgBoxFill.x;
            opt.labelText.fieldWidth = bgBoxFill.width;
            opt.labelText.alignment = "center";
            opt.valueText.visible = false;
        } else {
            opt.labelText.x = bgBoxFill.x + 40;
            opt.valueText.x = bgBoxFill.x + bgBoxFill.width - 340;
        }
        
        opt.labelText.y = layoutY + 60;
        opt.valueText.y = layoutY + 60;
        
        options.add(opt);
        layoutY += layoutSpacing; 
        return opt;
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (Controls.UP_P) changeSelection(-1);
        if (Controls.DOWN_P) changeSelection(1);
        
        if (options.members[selectedIndex] != null) {
            if (Controls.ACCEPT_P) options.members[selectedIndex].action(0);
            else if (Controls.LEFT_P) options.members[selectedIndex].action(-1);
            else if (Controls.RIGHT_P) options.members[selectedIndex].action(1);
        }
        
        if (Controls.CANCEL_P) close();
    }

    public function changeSelection(change:Int = 0):Void {
        if (options.length == 0) return;

        selectedIndex += change;
        if (selectedIndex < 0) selectedIndex = options.length - 1;
        if (selectedIndex >= options.length) selectedIndex = 0;
        
        selector.x = bgBoxFill.x + 30;
        selector.y = options.members[selectedIndex].labelText.y - 4; 
    }

    function refreshText():Void {
        for (opt in options) if (opt != null) opt.updateText();
    }

    override public function destroy():Void {
        Language.onLanguageUpdate.remove(refreshText);
        super.destroy();
    }
}