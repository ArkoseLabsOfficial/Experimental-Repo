package states.options.substates;

import flixel.FlxG;
import backend.GamePrefs;
import states.options.BaseOptionSubstate;
import states.options.OptionsHubSubState;

class AudioSettingsSubState extends BaseOptionSubstate {
    override public function create():Void {
        super.create();
        layoutY = bgBoxFill.y + 100;
        
        addOption("audio_master", Std.string(Math.round(GamePrefs.volume * 100)) + "%", function(d:Int){});
        addOption("audio_bgm", "100%", function(d:Int){});
        addOption("audio_sfx", "100%", function(d:Int){});
        
        layoutY = bgBoxFill.y + bgBoxFill.height - 100;
        addOption("menu_back", "", function(d:Int) { 
            if(d==0) { close(); FlxG.state.openSubState(new OptionsHubSubState()); }
        }, true);
        
        changeSelection(0);
    }
}