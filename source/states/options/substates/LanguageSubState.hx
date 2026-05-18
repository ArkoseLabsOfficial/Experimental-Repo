package states.options.substates;

import flixel.FlxG;
import backend.Language;
import states.options.BaseOptionSubstate;
import states.options.OptionsHubSubState;

class LanguageSubState extends BaseOptionSubstate {
    override public function create():Void {
        super.create();
        layoutY = bgBoxFill.y + 100;
        
        addOption("lang_english", "", function(d:Int) { if(d==0) Language.loadLanguage("English"); }, true);
        addOption("lang_japanese", "", function(d:Int) { if(d==0) Language.loadLanguage("日本語"); }, true);
        addOption("lang_more", "", function(d:Int) {
            if (d == 0) { close(); FlxG.state.openSubState(new UnofficialLanguageSubState()); }
        }, true);
        
        layoutY = bgBoxFill.y + bgBoxFill.height - 100;
        addOption("menu_back", "", function(d:Int) { 
            if (d == 0) { close(); FlxG.state.openSubState(new OptionsHubSubState()); }
        }, true);

        changeSelection(0);
    }
}