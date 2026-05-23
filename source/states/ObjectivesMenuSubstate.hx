package states;

import flixel.FlxSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import openfl.utils.Assets;

import backend.Language;
import backend.Controls;
import backend.Objective;
import ui.TitledMenuFrame;

class ObjectivesMenuSubstate extends FlxSubState {
    
    // Using the exact 1080p panel dimensions established in InventorySubState
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
        
        // We need a dedicated camera just like the inventory so we can overlay it cleanly
        camObjectives = new FlxCamera();
        camObjectives.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(camObjectives, false);
        this.cameras = [camObjectives];
        camObjectives.scroll.set(-230, 230); // much easier and useful way to move ui

        // Centering math (same as inventory: panels + separation)
        var separation = 20;
        var separationRight = 5;
        var totalWidth = MAIN_PANEL_W + separation + DESC_PANEL_W;
        var startX = (FlxG.width - totalWidth) / 2 + 10;
        var startY = (FlxG.height - MAIN_PANEL_H) / 2;

        // 1. Objectives List Frame (Left)
        var mainFrame = new TitledMenuFrame(startX, startY, MAIN_PANEL_W, MAIN_PANEL_H, Language.GetCaption("system.menu.objectives"), "assets/img/ui/divider_md.png", "");
        add(mainFrame);

        // 2. Description Frame (Right)
        var descX = startX + MAIN_PANEL_W + separationRight;
        descFrame = new TitledMenuFrame(descX, startY, DESC_PANEL_W, DESC_PANEL_H, "", "assets/img/ui/divider_sm.png", "assets/img/ui/menu_bg_decor.png");
        add(descFrame);

        descText = new FlxText(descX + 30, startY + 140, DESC_PANEL_W - 60, "", 28);
        descText.font = "assets/fonts/AlegreyaSC-Regular.ttf";
        add(descText);

        // 3. The selection highlight (matches PauseSubState style)
        highlightBox = new FlxSprite(startX + 15, 0).makeGraphic(MAIN_PANEL_W - 30, 46, 0xFF4A4A4A);
        highlightBox.alpha = 0.6;
        add(highlightBox);

        // Fetch our active objectives. 
        // Note: Assuming you instantiated ObjectiveManager in PlayState (PlayState.instance.objectives)
        activeObjectives = PlayState.instance.objectives.getCurrentObjectives();

        var listStartY = startY + 140; // Safely below the title and divider

        // If we have no objectives, hide the highlight and show the empty message
        if (activeObjectives.length == 0) {
            var emptyText = new FlxText(startX, listStartY + 100, MAIN_PANEL_W, Language.GetCaption("system.menu.objectives.empty"), 36);
            emptyText.font = "assets/fonts/AlegreyaSC-Regular.ttf";
            emptyText.color = FlxColor.GRAY;
            emptyText.alignment = CENTER;
            add(emptyText);
            
            highlightBox.visible = false;
        } else {
            // Build the scrolling text list
            for (i in 0...activeObjectives.length) {
                var obj = activeObjectives[i];
                var itemTxt = new FlxText(startX + 45, listStartY + (i * 60), MAIN_PANEL_W - 90, "• " + obj.name, 36);
                itemTxt.font = "assets/fonts/AlegreyaSC-Regular.ttf";
                objectiveTexts.push(itemTxt);
                add(itemTxt);
            }
            highlightSelection(); // Snap to the first item
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        // Only allow scrolling if we actually have objectives to scroll through
        if (activeObjectives.length > 0) {
            if (Controls.UP_P) moveSelection(-1);
            if (Controls.DOWN_P) moveSelection(1);
        }

        // Close menu (Matches Inventory/Pause behavior)
        if (Controls.CANCEL_P) {
            FlxG.sound.play("assets/sfx/ui_navigation2.ogg");
            close();
        }
    }

    function moveSelection(change:Int) {
        FlxG.sound.play("assets/sfx/ui_navigation.ogg");
        
        curSelected += change;
        
        // Loop around cleanly
        if (curSelected < 0) curSelected = activeObjectives.length - 1;
        if (curSelected >= activeObjectives.length) curSelected = 0;
        
        highlightSelection();
    }

    function highlightSelection() {
        if (activeObjectives.length == 0) return;

        // Visually snap the highlight box behind the newly selected text
        var activeText = objectiveTexts[curSelected];
        highlightBox.y = activeText.y + (activeText.height / 2) - (highlightBox.height / 2);

        // Update the description panel
        var obj = activeObjectives[curSelected];
        
        // Unhide the title and divider in the right panel and set it to the objective's name
        descFrame.setTitle(obj.name); 

        var finalText = obj.description + "\n";

        // If this objective has sub-tasks, list them below the main description
        if (obj.hasChildren()) {
            for (child in obj.children) {
                // HaxeFlixel FlxText doesn't support BBCode strikethrough natively like Godot.
                // So instead, we use a classic "[ BİTTİ ]" prefix for completed sub-tasks.
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
        // Always clean up custom cameras to prevent memory leaks!
        FlxG.cameras.remove(camObjectives);
        camObjectives.destroy();
        super.destroy();
    }
}