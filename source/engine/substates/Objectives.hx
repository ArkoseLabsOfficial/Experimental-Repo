package engine.substates;

class Objectives extends SubStateBackend {
    static inline var MAIN_PANEL_W:Int = 900;
    static inline var MAIN_PANEL_H:Int = 600;
    static inline var DESC_PANEL_W:Int = 546;
    static inline var DESC_PANEL_H:Int = 600;

    var curSelected:Int = 0;
    var activeObjectives:Array<Objective> = [];
    var objectiveTexts:Array<FlxText> = [];

    var descFrame:MenuFrameNode;
    var descText:FlxText;
    var highlightBox:FlxSprite;

    override public function create() {
        super.create();
        camMenu.scroll.set(-230, 230);

        var separation = 20;
        var separationRight = 5;
        var totalWidth = MAIN_PANEL_W + separation + DESC_PANEL_W;
        var startX = (FlxG.width - totalWidth) / 2 + 10;
        var startY = (FlxG.height - MAIN_PANEL_H) / 2;

        var mainFrame = new MenuFrameNode(startX, startY, MAIN_PANEL_W, MAIN_PANEL_H, 2);
        mainFrame.setTitle(Game.instance.language.getCaption("system.menu.objectives"));
        mainFrame.divider = new FlxSprite(0, 0, LilyAssets.image("ui/dividers/divider_md"));
        add(mainFrame);

        var descX = startX + MAIN_PANEL_W + separationRight;
        descFrame = new MenuFrameNode(descX, startY, DESC_PANEL_W, DESC_PANEL_H, 1);
        descFrame.divider = new FlxSprite(0, 0, LilyAssets.image("ui/dividers/divider_sm"));
        descFrame.nodeFrame.decorBgTexture = "ui/decors/menu_bg_decor";
        add(descFrame);

        descText = new FlxText(descX + 30, startY + 40, DESC_PANEL_W - 60, "", 28);
        descText.alignment = LEFT;
        add(descText);

        highlightBox = new FlxSprite(startX + 150, 0).makeGraphic(MAIN_PANEL_W - 300, 46, 0xFF4A4A4A);
        highlightBox.alpha = 0.6;
        add(highlightBox);

        activeObjectives = BaseRoom.instance.objectives.getCurrentObjectives();
        var listStartY = startY + 140;

        if (activeObjectives.length == 0) {
            var emptyText = new FlxText(startX, listStartY + 100, MAIN_PANEL_W, Game.instance.language.getCaption("system.menu.objectives.empty"), 36);
            emptyText.alignment = CENTER; // Added alignment missing from custom parser
            emptyText.color = FlxColor.GRAY;
            add(emptyText);
            highlightBox.visible = false;
        } else {
            for (i in 0...activeObjectives.length) {
                var obj = activeObjectives[i];
                var itemTxt = new FlxText(startX + 155, listStartY + (i * 60), MAIN_PANEL_W - 190, "• " + obj.name, 36);
                itemTxt.alignment = LEFT;
                objectiveTexts.push(itemTxt);
                add(itemTxt);
            }
            highlightSelection();
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (activeObjectives.length > 0) {
            if (Controls.UP_P)
                moveSelection(-1);
            if (Controls.DOWN_P)
                moveSelection(1);
        }

        if (Controls.CANCEL) {
            LilyAssets.play(LilyAssets.CANCEL);
            close();
        }
    }

    function moveSelection(change:Int) {
        LilyAssets.play(LilyAssets.NAVIGATE);
        curSelected += change;
        if (curSelected < 0)
            curSelected = activeObjectives.length - 1;
        if (curSelected >= activeObjectives.length)
            curSelected = 0;
        highlightSelection();
    }

    function highlightSelection() {
        if (activeObjectives.length == 0)
            return;
        var activeText = objectiveTexts[curSelected];
        highlightBox.y = activeText.y + (activeText.height / 2) - (highlightBox.height / 2);

        var obj = activeObjectives[curSelected];
        descFrame.setTitle(obj.name);
        var finalText = obj.description + "\n";

        if (obj.hasChildren()) {
            for (child in obj.children) {
                if (BaseRoom.instance.objectives.isObjectiveCompleted(child.id)) {
                    finalText += "\n[x] " + child.name;
                } else {
                    finalText += "\n[ ] " + child.name;
                }
            }
        }
        descText.text = finalText;
    }
}