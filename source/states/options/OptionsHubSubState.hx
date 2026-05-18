package states.options;

import flixel.FlxG;
import states.options.substates.*;

class OptionsHubSubState extends BaseOptionSubstate {
    override public function create():Void {
        super.create();
        layoutY = bgBoxFill.y + 80; 
        
        addOption("opt_language", "", function(d:Int){ 
            if (d==0) { close(); FlxG.state.openSubState(new LanguageSubState()); }
        }, true);
        addOption("opt_game", "", function(d:Int){ 
            if (d==0) { close(); FlxG.state.openSubState(new GameSettingsSubState()); }
        }, true);
        addOption("opt_audio", "", function(d:Int){ 
            if (d==0) { close(); FlxG.state.openSubState(new AudioSettingsSubState()); }
        }, true);
        addOption("opt_display", "", function(d:Int){ 
            if (d==0) { close(); FlxG.state.openSubState(new DisplaySettingsSubState()); }
        }, true);
        addOption("opt_controls", "", function(d:Int){ 
            if (d==0) { close(); FlxG.state.openSubState(new KeybindsSubState()); }
        }, true);
        
        layoutY = bgBoxFill.y + bgBoxFill.height - 225;
        addOption("menu_back", "", function(d:Int){ if (d==0) close(); }, true);

        changeSelection(0);
    }
}