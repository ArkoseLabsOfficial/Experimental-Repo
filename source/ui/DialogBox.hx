package ui;

import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.addons.text.FlxTypeText;
import flixel.FlxG;

class DialogBox extends FlxSpriteGroup {
    var bg:FlxSprite;
    var portraitLeft:FlxSprite;
    var portraitRight:FlxSprite;
    var nameText:FlxText;
    var nameSeperator:FlxSprite;
    var bodyText:FlxTypeText;
    var continueIcon:FlxSprite;
    
    public var isTyping:Bool = false;

    public function new() {
        super();

        bg = new FlxSprite(0, 0).loadGraphic("assets/img/ui/frame_dialogue.png");
        bg.screenCenter(X);
        bg.y = FlxG.height - bg.height - 20; 
        bg.scrollFactor.set(0, 0);
        add(bg);

        portraitLeft = new FlxSprite(0, 0);
        portraitLeft.antialiasing = true;
        portraitLeft.scrollFactor.set(0, 0);
        add(portraitLeft);

        portraitRight = new FlxSprite(1400, 0);
        portraitRight.antialiasing = true;
        portraitRight.flipX = true; 
        portraitRight.scrollFactor.set(0, 0);
        add(portraitRight);

        nameText = new FlxText(bg.x + 120, bg.y + 45, 400, "", 36);
        nameText.scrollFactor.set(0, 0);
        add(nameText);

        nameSeperator = new FlxSprite(bg.x + 100, bg.y + 80);
        nameSeperator.loadGraphic("assets/img/ui/dialogue_name_separator_2.png");
        nameSeperator.scale.set(1.025, 1.025);
        nameSeperator.scrollFactor.set(0, 0);
        add(nameSeperator);

        bodyText = new FlxTypeText(bg.x + 120, bg.y + 105, Std.int(bg.width - 160), "", 33);
        bodyText.delay = 0.03;
        bodyText.eraseDelay = 0;
        bodyText.showCursor = false;
        bodyText.scrollFactor.set(0, 0);
        bodyText.completeCallback = function() { 
            isTyping = false; 
            continueIcon.visible = true;
            continueIcon.animation.play("blink");
        };
        add(bodyText);

        continueIcon = new FlxSprite(bg.x + bg.width - 200, bg.y + bg.height - 125);
        continueIcon.loadGraphic("assets/img/ui/continue_indicator.png", true, 95, 95);
        continueIcon.animation.add("blink", [0, 1, 2, 1], 6, true);
        continueIcon.scrollFactor.set(0, 0);
        add(continueIcon);
    }

    public function show(name:String, text:String, leftPath:String = "", rightPath:String = ""):Void {
        visible = true;
        active = true;
        isTyping = true;
        continueIcon.visible = false;
        
        nameText.text = name;
        
        if (leftPath != "") {
            portraitLeft.loadGraphic(leftPath);
            portraitLeft.updateHitbox();
            portraitLeft.visible = true;
        } else portraitLeft.visible = false;

        if (rightPath != "") {
            portraitRight.loadGraphic(rightPath);
            portraitRight.updateHitbox();
            portraitRight.visible = true;
        } else portraitRight.visible = false;

        bodyText.resetText(text);
        bodyText.start(0.03, true);
    }

    public function advance():Bool {
        if (isTyping) {
            bodyText.skip();
            isTyping = false;
            continueIcon.visible = true;
            continueIcon.animation.play("blink");
            return false; 
        }
        return true; 
    }
}