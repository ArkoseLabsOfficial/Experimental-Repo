package states.options.substates;

import openfl.utils.Assets;
import haxe.Json;
import flixel.FlxG;
import backend.Language;
import states.options.BaseOptionSubstate;

class UnofficialLanguageSubState extends BaseOptionSubstate {
    override public function create():Void {
        super.create();
        layoutY = bgBoxFill.y + 70;

        var allAssets = Assets.list(TEXT);
        for (assetPath in allAssets) {
            if (StringTools.startsWith(assetPath, "assets/languages/") && StringTools.endsWith(assetPath, ".json")) {
                var content = Assets.getText(assetPath);
                var data:Dynamic = Json.parse(content);
                
                if (data.name != "English" && data.name != "日本語") {
                    var label = data.name;
                    if (data.translator != null) label += " - by " + data.translator;

                    var opt = addOption("", label, function(d:Int) { if(d==0) Language.loadLanguage(data.name); }, true);
                    opt.labelText.text = label; 
                }
            }
        }
        
        layoutY = bgBoxFill.y + bgBoxFill.height - 100;
        addOption("menu_back", "", function(d:Int){ 
            if(d==0) { close(); FlxG.state.openSubState(new LanguageSubState()); } 
        }, true);

        changeSelection(0);
    }
}