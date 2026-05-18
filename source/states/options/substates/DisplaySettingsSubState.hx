package states.options.substates;

import flixel.FlxG;
import backend.GamePrefs;
import states.options.BaseOptionSubstate;
import states.options.OptionsHubSubState;

class DisplaySettingsSubState extends BaseOptionSubstate {
    
    var resolutions:Array<String> = ["1280x720", "1600x900", "1920x1080"];
    var currentResIndex:Int = 0;

    override public function create():Void {
        super.create();
        layoutY = bgBoxFill.y + 70;
        
        addOption("disp_fullscreen", GamePrefs.fullscreen ? "Evet" : "Hayır", function(d:Int) {
            GamePrefs.fullscreen = !GamePrefs.fullscreen;
            GamePrefs.saveSettings();
            options.members[selectedIndex].valueText.text = GamePrefs.fullscreen ? "Evet" : "Hayır";
        });
        
        currentResIndex = resolutions.indexOf(GamePrefs.resolution);
        if (currentResIndex == -1) currentResIndex = 2; // Default 1920x1080

        addOption("disp_resolution", GamePrefs.resolution, function(d:Int) {
            var move = (d == 0) ? 1 : d; 
            currentResIndex += move;
            if (currentResIndex >= resolutions.length) currentResIndex = 0;
            if (currentResIndex < 0) currentResIndex = resolutions.length - 1;
            
            GamePrefs.resolution = resolutions[currentResIndex];
            GamePrefs.saveSettings(); 
            options.members[selectedIndex].valueText.text = GamePrefs.resolution;
        });
        
        addOption("disp_internal_res", "2x", function(d:Int){});
        addOption("disp_limit_fps", "V-Sync", function(d:Int){});
        addOption("disp_brightness", "100%", function(d:Int){});
        addOption("disp_contrast", "100%", function(d:Int){});
        addOption("disp_gamma", "0.00", function(d:Int){});
        addOption("disp_hide_mouse", "Hayır", function(d:Int){});
        
        layoutY = bgBoxFill.y + bgBoxFill.height - 100;
        addOption("menu_back", "", function(d:Int) { 
            if (d == 0) { close(); FlxG.state.openSubState(new OptionsHubSubState()); }
        }, true);

        changeSelection(0);
    }
}