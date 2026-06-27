package engine.ui;

class DialogBox extends FlxSpriteGroup {
    var bg:FlxSprite;
    var portraitLeft:FlxSprite;
    var portraitRight:FlxSprite;
    var nameText:FlxText;
    var nameSeperator:FlxSprite;
    var bodyText:FlxTypeText;
    var continueIcon:FlxSprite;
    
    public var isTyping:Bool = false;

    var currentLeftPath:String = "";
    var currentRightPath:String = "";

    var leftBaseX:Float = 0;
    var leftBaseY:Float = 0;
    var rightBaseX:Float = 1400;
    var rightBaseY:Float = 0;

    public function new() {
        super();

        portraitLeft = new FlxSprite(leftBaseX, leftBaseY);
        portraitLeft.antialiasing = true;
        portraitLeft.scrollFactor.set(0, 0);
        add(portraitLeft);

        portraitRight = new FlxSprite(rightBaseX, rightBaseY);
        portraitRight.antialiasing = true;
        portraitRight.flipX = true; 
        portraitRight.scrollFactor.set(0, 0);
        add(portraitRight);

        bg = new FlxSprite(0, 0).loadGraphic(LilyAssets.image("ui/dialogs/dialogue"));
        bg.screenCenter(X);
        bg.y = FlxG.height - bg.height - 20; 
        bg.scrollFactor.set(0, 0);
        add(bg);

        nameText = new FlxText(bg.x + 120, bg.y + 45, 400, "", 36);
	    nameText.font = LilyAssets.font("AlegreyaSC-Regular");
    	nameText.alignment = LEFT;
        nameText.scrollFactor.set(0, 0);
        add(nameText);

        nameSeperator = new FlxSprite(bg.x + 100, bg.y + 80);
        nameSeperator.loadGraphic(LilyAssets.image("ui/dialogs/name_seperator"));
        nameSeperator.scale.set(1.025, 1.025);
        nameSeperator.scrollFactor.set(0, 0);
        add(nameSeperator);

        bodyText = new FlxTypeText(bg.x + 120, bg.y + 105, Std.int(bg.width - 160), "", 33);
        bodyText.font = LilyAssets.font("fonts/AlegreyaSC-Regular.ttf"); 
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
        continueIcon.loadGraphic(LilyAssets.image("ui/dialogs/continue_indicator"), true, 95, 95);
        continueIcon.animation.add("blink", [0, 1, 2, 1], 6, true);
        continueIcon.scrollFactor.set(0, 0);
        add(continueIcon);
    }

    public function show(name:String, text:String, leftPath:String = "", rightPath:String = "", leftAnim:String = "leftToRight", rightAnim:String = "rightToLeft"):Void {
        isTyping = true;
        continueIcon.visible = false;
        
        nameText.text = name;

        if (name == null || name == "") {
            nameText.visible = false;
            nameSeperator.visible = false;
            bodyText.y = bg.y + 55;
        } else {
            nameText.visible = true;
            nameSeperator.visible = true;
            bodyText.y = bg.y + 105;
        }

        animateCharacter(portraitLeft, currentLeftPath, leftPath, leftAnim, leftBaseX, leftBaseY);
        currentLeftPath = leftPath;

        animateCharacter(portraitRight, currentRightPath, rightPath, rightAnim, rightBaseX, rightBaseY);
        currentRightPath = rightPath;

        this.visible = true;
        this.active = true;

        bodyText.resetText(text);
        bodyText.start(0.03, true);
    }

    public function hide(onComplete:Void->Void):Void {
        visible = false;
        onComplete();
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

    private function animateCharacter(sprite:FlxSprite, oldPath:String, newPath:String, animType:String, baseX:Float, baseY:Float):Void {
        if (oldPath == newPath) return; 
        
        FlxTween.cancelTweensOf(sprite);

        if (newPath == "") {
            if (animType != "none") {
                var offsets = getMoveOffsets(animType, sprite.width, sprite.height);
                FlxTween.tween(sprite, {x: baseX + offsets.x, y: baseY + offsets.y}, 0.1, {ease: FlxEase.quadOut, onComplete: function(_) {
                    sprite.visible = false;
                }});
            } else {
                sprite.visible = false;
            }
        } else {
            var swapGraphic = function() {
                sprite.loadGraphic(LilyAssets.image(newPath));
                sprite.updateHitbox();
                sprite.visible = true;

                if (animType != "none") {
                    var offsets = getMoveOffsets(animType, sprite.width, sprite.height);
                    sprite.x = baseX + offsets.x; 
                    sprite.y = baseY + offsets.y;
                    FlxTween.tween(sprite, {x: baseX, y: baseY}, 0.1, {ease: FlxEase.quadOut});
                } else {
                    sprite.x = baseX;
                    sprite.y = baseY;
                }
            };

            if (oldPath != "") {
                if (animType != "none") {
                    var offsets = getMoveOffsets(animType, sprite.width, sprite.height);
                    FlxTween.tween(sprite, {x: baseX + offsets.x, y: baseY + offsets.y}, 0.05, {ease: FlxEase.quadOut, onComplete: function(_) {
                        swapGraphic();
                    }});
                } else {
                    swapGraphic();
                }
            } else {
                swapGraphic();
            }
        }
    }

    private function getMoveOffsets(anim:String, objWidth:Float, objHeight:Float):{x:Float, y:Float} {
        var w = objWidth + 20; 
        var h = objHeight + 20;
        
        switch(anim) {
            case "downToUp": return {x: 0, y: h};     
            case "upToDown": return {x: 0, y: -h};    
            case "leftToRight": return {x: -w, y: 0}; 
            case "rightToLeft": return {x: w, y: 0};  
            default: return {x: 0, y: 0};
        }
    }
}