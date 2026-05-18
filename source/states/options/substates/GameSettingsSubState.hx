package states.options.substates;

import flixel.FlxG;
import states.options.BaseOptionSubstate;
import states.options.OptionsHubSubState;

class GameSettingsSubState extends BaseOptionSubstate {
    override public function create():Void {
        super.create();
        layoutY = bgBoxFill.y + 100;
        
        addOption("game_text_speed", "Normal", function(d:Int){});
        addOption("game_auto_forward", "Hayır", function(d:Int){});
        addOption("game_screen_shake", "Evet", function(d:Int){});
        
        layoutY = bgBoxFill.y + bgBoxFill.height - 100;
        addOption("menu_back", "", function(d:Int) { 
            if(d==0) { close(); FlxG.state.openSubState(new OptionsHubSubState()); }
        }, true);
        
        changeSelection(0);
    }
}