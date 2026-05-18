package states.options.substates;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import backend.GamePrefs;
import states.options.BaseOptionSubstate;
import states.options.OptionsHubSubState;

class KeybindsSubState extends BaseOptionSubstate {
    var waitingForInput:Bool = false;
    var bindingAction:String = "";

    override public function create():Void {
        super.create();
        layoutY = bgBoxFill.y + 60;
        
        addOption("keybind_profile", "Klavye: Klasik", function(d:Int){}); 
        addOption("keybind_deadzone", "20%", function(d:Int){});
        addOption("keybind_autoskip", "Evet", function(d:Int){});
        
        layoutY += 20;
        createBind("keybind_up", "UP");
        createBind("keybind_down", "DOWN");
        createBind("keybind_left", "LEFT");
        createBind("keybind_right", "RIGHT");
        createBind("keybind_accept", "ACCEPT");
        createBind("keybind_cancel", "CANCEL");
        createBind("keybind_run", "RUN");
        createBind("keybind_special", "SPECIAL");
        createBind("keybind_menu", "MENU");
        
        layoutY = bgBoxFill.y + bgBoxFill.height - 100;
        addOption("menu_back", "", function(d:Int) { 
            if (d == 0) { close(); FlxG.state.openSubState(new OptionsHubSubState()); }
        }, true);

        changeSelection(0);
    }

    function createBind(transKey:String, actionName:String):Void {
        var keys = GamePrefs.keybinds.get(actionName);
        var displayStr = keys != null ? keys.join(" / ") : "UNBOUND";
        
        addOption(transKey, displayStr, function(d:Int) {
            if (d == 0) { 
                waitingForInput = true;
                bindingAction = actionName;
                options.members[selectedIndex].valueText.text = "...";
            }
        });
    }

    override public function update(elapsed:Float):Void {
        if (waitingForInput) {
            var firstJustPressed:FlxKey = FlxG.keys.firstJustPressed();
            if (firstJustPressed != FlxKey.NONE) {
                var keyName = firstJustPressed.toString();
                GamePrefs.keybinds.set(bindingAction, [keyName]);
                GamePrefs.saveSettings();
                options.members[selectedIndex].valueText.text = keyName;
                waitingForInput = false;
            }
            return;
        }
        super.update(elapsed);
    }
}