package states;

import flixel.FlxSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import backend.Language;
import backend.Controls;
import backend.Objective;
import backend.UIUtil;
import ui.TitledMenuFrame;

class ObjectivesMenuSubstate extends SubStateBackend {
    static inline var MAIN_PANEL_W:Int = 900;
    static inline var MAIN_PANEL_H:Int = 600;
    static inline var DESC_PANEL_W:Int = 546;
    static inline var DESC_PANEL_H:Int = 600;

    var curSelected:Int = 0;
    var activeObjectives:Array<Objective> = [];
    var objectiveTexts:Array<FlxText> = [];

    var descFrame:TitledMenuFrame;
    var descText:FlxText;
    var highlightBox:FlxSprite;
    var camObjectives:FlxCamera;

    override public function create() {
        super.create();
        
        camObjectives = new FlxCamera();
        camObjectives.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(camObjectives, false);
        this.cameras = [camObjectives];
        camObjectives.scroll.set(-230, 230); 

        var separation = 20;
        var separationRight = 5;
        var totalWidth = MAIN_PANEL_W + separation + DESC_PANEL_W;
        var startX = (FlxG.width - totalWidth) / 2 + 10;
        var startY = (FlxG.height - MAIN_PANEL_H) / 2;

        var mainFrame = new TitledMenuFrame(startX, startY, MAIN_PANEL_W, MAIN_PANEL_H, Language.GetCaption("system.menu.objectives"), LilyAssets.image("img/ui/divider_md"), "");
        add(mainFrame);

        var descX = startX + MAIN_PANEL_W + separationRight;
        descFrame = new TitledMenuFrame(descX, startY, DESC_PANEL_W, DESC_PANEL_H, "", LilyAssets.image("img/ui/divider_sm"), "img/ui/menu_bg_decor");
        add(descFrame);

        descText = UIUtil.createText(descX + 30, startY + 140, DESC_PANEL_W - 60, "", 28, LEFT);
        add(descText);

        highlightBox = UIUtil.createHighlightBox(startX + 15, 0, MAIN_PANEL_W - 30, 46, 0.6);
        add(highlightBox);

        activeObjectives = PlayState.instance.objectives.getCurrentObjectives();
        var listStartY = startY + 140; 

        if (activeObjectives.length == 0) {
            var emptyText = UIUtil.createText(startX, listStartY + 100, MAIN_PANEL_W, Language.GetCaption("system.menu.objectives.empty"), 36);
            emptyText.color = FlxColor.GRAY;
            add(emptyText);
            highlightBox.visible = false;
        } else {
            for (i in 0...activeObjectives.length) {
                var obj = activeObjectives[i];
                var itemTxt = UIUtil.createText(startX + 45, listStartY + (i * 60), MAIN_PANEL_W - 90, "• " + obj.name, 36, LEFT);
                objectiveTexts.push(itemTxt);
                add(itemTxt);
            }
            highlightSelection(); 
        }

        mobile.controls.addMobilePad("UP_DOWN", "A_B");
        mobile.controls.addMobilePadCamera();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (activeObjectives.length > 0) {
            if (Controls.UP_P) moveSelection(-1);
            if (Controls.DOWN_P) moveSelection(1);
        }

        if (Controls.CANCEL_P) {
            UIUtil.playCancelSound();
            close();
        }
    }

    function moveSelection(change:Int) {
        UIUtil.playNavSound();
        curSelected += change;
        if (curSelected < 0) curSelected = activeObjectives.length - 1;
        if (curSelected >= activeObjectives.length) curSelected = 0;
        highlightSelection();
    }

    function highlightSelection() {
        if (activeObjectives.length == 0) return;
        var activeText = objectiveTexts[curSelected];
        highlightBox.y = activeText.y + (activeText.height / 2) - (highlightBox.height / 2);

        var obj = activeObjectives[curSelected];
        descFrame.setTitle(obj.name); 
        var finalText = obj.description + "\n";

        if (obj.hasChildren()) {
            for (child in obj.children) {
                if (PlayState.instance.objectives.isObjectiveCompleted(child.id)) {
                    finalText += "\n[x] " + child.name; 
                } else {
                    finalText += "\n[ ] " + child.name;
                }
            }
        }
        descText.text = finalText;
    }

    override public function destroy() {
        FlxG.cameras.remove(camObjectives);
        camObjectives.destroy();
        super.destroy();
    }
}