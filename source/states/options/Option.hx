package states.options;

import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import backend.Language;

class Option extends FlxTypedGroup<FlxText> {
    public var labelText:FlxText;
    public var valueText:FlxText;
    public var action:Int->Void;
    public var translationKey:String;

    public function new(key:String, initialValue:String, onClick:Int->Void) {
        super();
        translationKey = key;
        action = onClick;

        // Fonts sized accurately for 1080p
        labelText = new FlxText(0, 0, 500, translationKey == "" ? initialValue : Language.GetCaption(translationKey), 26);
        valueText = new FlxText(0, 0, 300, initialValue, 26);
        valueText.alignment = "right"; 

        add(labelText);
        add(valueText);
    }

    public function updateText():Void {
        if (translationKey != "") labelText.text = Language.GetCaption(translationKey);
    }
}