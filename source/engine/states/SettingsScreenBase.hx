package engine.states;

typedef XmlOption = {
    var label:String;
    var type:String;
    @:optional var target:String;
    @:optional var variable:String;
    @:optional var values:Array<String>;
    @:optional var keyPath:String; 
    @:optional var min:Float;
    @:optional var max:Float;
    @:optional var step:Float;
    @:optional var onChanged:Dynamic->Void;
    @:optional var onClicked:Void->Void;
    @:optional var valueText:FlxText;
    @:optional var keySprites:Array<FlxSprite>; 
    @:optional var curArrayIdx:Int;
}

class SettingsScreenBase extends SubStateBackend {
    public var uiScale:Float = 1.0;
    public var textSize:Int = 20;
    public var optionGap:Float = 45; 
    public var fromPause:Bool = false;
    public var itemGroup:FlxSpriteGroup;
    public var highlight:FlxSprite;
    public var overlay:FlxUI9SliceSprite;
    public var bg:FlxUI9SliceSprite;
    public var backButton:FlxText;
    public var curSelected:Int = 0;
    public var options:Array<XmlOption> = [];
    public var menuItems:Array<FlxText> = [];
    var currentMenuId:String;
    var isListening:Bool = false;

    public function new(menuId:String = "main", fromPause:Bool = false) {
        super(0x99000000); 
        currentMenuId = menuId;
        this.fromPause = fromPause;
    }

    override public function create():Void {
        super.create();
        var camPause = new flixel.FlxCamera();
        camPause.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(camPause, false);
        this.cameras = [camPause];
        if (fromPause) camPause.scroll.set(-230, 40);

        parseXML(currentMenuId);

        uiScale = fromPause ? 1.5 : 1.0; 
        textSize = Std.int(20 * uiScale);
        optionGap = 45 * uiScale;
        var highlightWidth = Std.int(510 * uiScale);

        var totalHeight:Float = ((options.length + 1) * optionGap) + (40 * uiScale); 
        var totalWeight:Float = 550 * uiScale;
        
        if (fromPause) {
            totalHeight = 715;
            totalWeight = 1452;
        }
        
        bg = UIUtil.create9SliceSprite(LilyAssets.image("img/ui/frame_default_bg"), 0, 0, totalWeight, totalHeight + (70 * uiScale), 1);
        bg.screenCenter();

        overlay = UIUtil.create9SliceSprite(LilyAssets.image("img/ui/frame_menu_2"), 0, 0, totalWeight, totalHeight + (70 * uiScale), 0.66);
        overlay.screenCenter();

        itemGroup = new FlxSpriteGroup();
        highlight = UIUtil.createHighlightBox(0, 0, highlightWidth, Std.int(optionGap - 5), 0.4);
        highlight.screenCenter(X);
        itemGroup.add(highlight);

        var numItems = options.length + (currentMenuId != "main" ? 1 : 0);
        var listHeight = numItems * optionGap;
        var startY = overlay.y + (overlay.height - listHeight) / 2;

        for (i in 0...options.length) {
            var opt = options[i];
            var text = UIUtil.createText(0, startY + (i * optionGap), 0, Language.GetCaption(opt.label), textSize);
            text.y += (optionGap - text.height) / 2;
            
            if (currentMenuId == "main") {
                text.screenCenter(X);
            } else {
                text.x = highlight.x + (15 * uiScale);
                text.alignment = LEFT;
            }
            
            menuItems.push(text);
            itemGroup.add(text);

            if (currentMenuId != "main") {
                setupOptionVisuals(opt, i, startY);
            }
        }

        if (currentMenuId != "main") {
            backButton = UIUtil.createText(0, startY + (options.length * optionGap), 0, Language.GetCaption("system.settings.game.back"), textSize);
            backButton.y += (optionGap - backButton.height) / 2;
            backButton.screenCenter(X);
            itemGroup.add(backButton);
        }

        add(bg);
        add(itemGroup);
        add(overlay);

        changeSelection(0);

        #if FEATURE_TOUCH_CONTROLS
        mobile.controls.addMobilePad("UP_DOWN", "A_B");
        mobile.controls.addMobilePadCamera();
        #end
    }   

    public function getOptionByLabel(targetLabel:String):XmlOption {
        for (opt in options) {
            if (opt.label == targetLabel) return opt;
        }
        return null;
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (isListening) {
            var opt = options[curSelected];
            var bindHandled:Bool = false;
            var kbKey:FlxKey = FlxG.keys.firstJustPressed();
            
            if (kbKey != FlxKey.NONE) {
                if (kbKey == FlxKey.ESCAPE) {
                    bindHandled = true; 
                } else if (kbKey == FlxKey.BACKSPACE || kbKey == FlxKey.DELETE) {
                    GamePrefs.keybinds.get(opt.variable)[0] = "NONE";
                    bindHandled = true;
                } else {
                    GamePrefs.keybinds.get(opt.variable)[0] = kbKey.toString();
                    bindHandled = true;
                }
            } else if (FlxG.gamepads.lastActive != null) {
                var gpBtn = FlxG.gamepads.lastActive.firstJustPressedID();
                if (gpBtn != FlxGamepadInputID.NONE) {
                    if (gpBtn == FlxGamepadInputID.BACK) {
                        GamePrefs.keybinds.get(opt.variable)[1] = "NONE";
                        bindHandled = true;
                    } else {
                        GamePrefs.keybinds.get(opt.variable)[1] = gpBtn.toString();
                        bindHandled = true;
                    }
                }
            }

            if (bindHandled) {
                GamePrefs.saveSettings();
                if (opt.onChanged != null) opt.onChanged(GamePrefs.keybinds.get(opt.variable));
                updateVisualText(opt);
                isListening = false;
                highlight.color = 0xFFFFFF; 
            }
            return;
        }

        if (Controls.UP_P) {
            UIUtil.playNavSound();
            changeSelection(-1);
        }
        if (Controls.DOWN_P) {
            UIUtil.playNavSound();
            changeSelection(1);
        }
        if (Controls.ACCEPT_P) {
            UIUtil.playConfirmSound();
            acceptSelection();
        }
        if (Controls.CANCEL_P) {
            UIUtil.playCancelSound();
            close();
        }

        if (curSelected < options.length && currentMenuId != "main") {
            var opt = options[curSelected];
            if (Controls.LEFT_P) adjustOption(opt, -1);
            if (Controls.RIGHT_P) adjustOption(opt, 1);
        }
    }

    function changeSelection(change:Int):Void {
        curSelected += change;
        if (curSelected < 0) curSelected = options.length - (currentMenuId == "main" ? 1 : 0);
        if (curSelected > options.length - (currentMenuId == "main" ? 1 : 0)) curSelected = 0;
        var targetText = (curSelected == options.length && currentMenuId != "main") ? backButton : menuItems[curSelected];
        highlight.y = targetText.y + (targetText.height / 2) - (highlight.height / 2);
    }

    function acceptSelection():Void {
        if (curSelected == options.length) {
            GamePrefs.saveSettings();
            close();
            return;
        }
        var opt = options[curSelected];
        if (opt.onClicked != null) opt.onClicked();
        
        if (currentMenuId == "main") {
            if (opt.target == "language") openSubState(new LanguageMenu());
            else openSubState(new SettingsScreenBase(opt.target, fromPause)); 
        } else {
            if (opt.type == "bool") adjustOption(opt, 1); 
            if (opt.type == "keybind") {
                isListening = true;
                highlight.color = 0xFFD700; 
                opt.valueText.text = "? Waiting ?";
                opt.valueText.x = highlight.x + highlight.width - opt.valueText.width - (15 * uiScale);
                opt.valueText.visible = true;
                if (opt.keySprites != null) {
                    for (spr in opt.keySprites) spr.visible = false;
                }
            }
        }
    }

    function adjustOption(opt:XmlOption, dir:Int):Void {
        var curVal:Dynamic = getData(opt.variable);
        switch(opt.type) {
            case "bool": 
                saveData(opt.variable, !(curVal == true));
            case "array":
                opt.curArrayIdx += dir;
                if (opt.curArrayIdx < 0) opt.curArrayIdx = opt.values.length - 1;
                if (opt.curArrayIdx >= opt.values.length) opt.curArrayIdx = 0;
                saveData(opt.variable, opt.values[opt.curArrayIdx]);
            case "int", "float", "percent":
                var numVal:Float = Std.parseFloat(Std.string(curVal));
                if (Math.isNaN(numVal)) numVal = opt.min; 
                numVal += (opt.step * dir);
                if (numVal < opt.min) numVal = opt.min;
                if (numVal > opt.max) numVal = opt.max;
                if (opt.type != "int") numVal = Math.round(numVal * 100) / 100;
                saveData(opt.variable, opt.type == "int" ? Std.int(numVal) : numVal);
        }
        if (opt.onChanged != null) opt.onChanged(getData(opt.variable));
        updateVisualText(opt);
    }

    function setupOptionVisuals(opt:XmlOption, index:Int, startY:Float):Void {
        if (opt.type != "button" && opt.type != "category") {
            ensureDefaultData(opt); 
            opt.valueText = UIUtil.createText(0, startY + (index * optionGap), 0, "", textSize);
            opt.valueText.y += (optionGap - opt.valueText.height) / 2;
            itemGroup.add(opt.valueText);
            
            if (opt.type == "keybind" && opt.keyPath != null) {
                opt.keySprites = [new FlxSprite(0, opt.valueText.y), new FlxSprite(0, opt.valueText.y)];
                itemGroup.add(opt.keySprites[0]);
                itemGroup.add(opt.keySprites[1]);
            }
            updateVisualText(opt);
        }
    }

    function updateVisualText(opt:XmlOption):Void {
        if (opt.valueText == null) return;
        var curVal:Dynamic = getData(opt.variable);
        switch(opt.type) {
            case "bool": opt.valueText.text = (curVal == true) ? "< ON >" : "< OFF >"; 
            case "array", "int", "float": opt.valueText.text = "< " + Std.string(curVal) + " >";
            case "percent": opt.valueText.text = "< " + Std.string(curVal) + "% >";
            case "keybind":
                var binds:Array<String> = GamePrefs.keybinds.get(opt.variable);
                var kbStr = binds[0];
                var gpStr = binds[1];
                var displayText = "";

                if (opt.keyPath != null) {
                    var kbImgPath = getInputImagePath(kbStr, false, opt.keyPath);
                    var gpImgPath = getInputImagePath(gpStr, true, opt.keyPath);

                    if (kbImgPath != "" && FileSystem.exists(kbImgPath)) {
                        opt.keySprites[0].loadGraphic(kbImgPath);
                        opt.keySprites[0].scale.set(0.5, 0.5);
                        opt.keySprites[0].updateHitbox(); 
                        opt.keySprites[0].visible = true;
                        displayText += "[ IMG ]"; 
                    } else {
                        opt.keySprites[0].visible = false;
                        displayText += "[ " + kbStr + " ]";
                    }
                    displayText += " / ";
                    if (gpImgPath != "" && FileSystem.exists(gpImgPath)) {
                        opt.keySprites[1].loadGraphic(gpImgPath);
                        opt.keySprites[1].scale.set(0.5, 0.5);
                        opt.keySprites[1].updateHitbox(); 
                        opt.keySprites[1].visible = true;
                        displayText += "[ IMG ]";
                    } else {
                        opt.keySprites[1].visible = false;
                        displayText += "[ " + gpStr + " ]";
                    }
                    opt.valueText.text = StringTools.replace(displayText, "[ IMG ]", "      ");
                } else {
                    opt.valueText.text = "[ " + kbStr + " ] / [ " + gpStr + " ]";
                }
        }
        
        opt.valueText.x = highlight.x + highlight.width - opt.valueText.width - (15 * uiScale);
        opt.valueText.visible = true;
        
        if (opt.type == "keybind" && opt.keyPath != null) {
            if (opt.keySprites[0].visible) {
                opt.keySprites[0].x = opt.valueText.x - (5 * uiScale);
                opt.keySprites[0].y = opt.valueText.y + (opt.valueText.height / 2) - (opt.keySprites[0].height / 2);
            }
            if (opt.keySprites[1].visible) {
                opt.keySprites[1].x = opt.valueText.x + (80 * uiScale); 
                opt.keySprites[1].y = opt.valueText.y + (opt.valueText.height / 2) - (opt.keySprites[1].height / 2);
            }
        }
    }

    function getInputImagePath(inputStr:String, isGamepad:Bool, basePath:String):String {
        if (inputStr == null || inputStr == "NONE" || inputStr == "") return "";
        var fileName:String = "";
        var raw = inputStr.toUpperCase();
        if (!isGamepad) {
            if (raw.length == 1 && raw.charCodeAt(0) >= 65 && raw.charCodeAt(0) <= 90) {
                fileName = "keyboard_letter_" + raw.toLowerCase();
            } else {
                fileName = switch(raw) {
                    case "ZERO", "NUMPADZERO": "keyboard_number_0";
                    case "ONE", "NUMPADONE": "keyboard_number_1";
                    case "TWO", "NUMPADTWO": "keyboard_number_2";
                    case "THREE", "NUMPADTHREE": "keyboard_number_3";
                    case "FOUR", "NUMPADFOUR": "keyboard_number_4";
                    case "FIVE", "NUMPADFIVE": "keyboard_number_5";
                    case "SIX", "NUMPADSIX": "keyboard_number_6";
                    case "SEVEN", "NUMPADSEVEN": "keyboard_number_7";
                    case "EIGHT", "NUMPADEIGHT": "keyboard_number_8";
                    case "NINE", "NUMPADNINE": "keyboard_number_9";
                    case "MINUS": "keyboard_minus";
                    case "PLUS": "keyboard_plus";
                    case "SLASH": "keyboard_slash";
                    case "SPACE": "keyboard_space";
                    case "TAB": "keyboard_tab";
                    case "SHIFT": "keyboard_shift";
                    case "PAGEUP": "keyboard_page_up";
                    case "PAGEDOWN": "keyboard_page_down";
                    case "SEMICOLON": "keyboard_semicolon";
                    case "QUOTE": "keyboard_quotes";
                    case "PERIOD": "keyboard_period";
                    default: "keyboard_" + raw.toLowerCase(); 
                }
            }
        } else {
            var prefix = "xbone_"; 
            fileName = switch(raw) {
                case "A", "B", "X", "Y": prefix + raw.toLowerCase();
                case "DPAD_UP": prefix + "dpad_up";
                case "DPAD_DOWN": prefix + "dpad_down";
                case "DPAD_LEFT": prefix + "dpad_left";
                case "DPAD_RIGHT": prefix + "dpad_right";
                case "LEFT_SHOULDER": prefix + "lb";
                case "RIGHT_SHOULDER": prefix + "rb";
                case "LEFT_TRIGGER": prefix + "lt";
                case "RIGHT_TRIGGER": prefix + "rt";
                case "LEFT_STICK_CLICK": prefix + "ls";
                case "RIGHT_STICK_CLICK": prefix + "rs";
                case "BACK": prefix + "view"; 
                case "START": prefix + "menu"; 
                default: prefix + raw.toLowerCase();
            }
        }
        return basePath + fileName + ".png";
    }

    function saveData(variable:String, value:Dynamic):Void {
        if (variable == null || variable == "") return;
        GamePrefs.setOption(variable, value);
    }
    
    function getData(variable:String):Dynamic {
        if (variable == null || variable == "") return null;
        return GamePrefs.getOption(variable);
    }

    function ensureDefaultData(opt:XmlOption):Void {
        if (opt.type == "keybind") return; 
        if (getData(opt.variable) == null) {
            switch(opt.type) {
                case "bool": saveData(opt.variable, false);
                case "array": 
                    saveData(opt.variable, opt.values[0]);
                    opt.curArrayIdx = 0;
                case "int", "float", "percent": 
                    saveData(opt.variable, opt.min != null ? opt.min : 0);
            }
        } else {
            if (opt.type == "array") {
                opt.curArrayIdx = opt.values.indexOf(Std.string(getData(opt.variable)));
                if (opt.curArrayIdx == -1) opt.curArrayIdx = 0;
            }
        }
    }

    function parseXML(menuId:String):Void {
        var xmlString = LilyAssets.getTextFromFile("settings.xml");
        var xml = new Access(Xml.parse(xmlString).firstElement());
        for (menuNode in xml.nodes.menu) {
            if (menuNode.att.id == menuId) {
                if (menuId == "main") {
                    for (cat in menuNode.nodes.category) {
                        options.push({ label: cat.att.label, target: cat.att.target, type: "category" });
                    }
                } else {
                    for (opt in menuNode.nodes.option) {
                        var newOpt:XmlOption = {
                            label: opt.att.label,
                            type: opt.att.type,
                            variable: opt.has.variable ? opt.att.variable : ""
                        };
                        if (opt.has.values) newOpt.values = opt.att.values.split(",");
                        if (opt.has.min) newOpt.min = Std.parseFloat(opt.att.min);
                        if (opt.has.max) newOpt.max = Std.parseFloat(opt.att.max);
                        if (opt.has.step) newOpt.step = Std.parseFloat(opt.att.step);
                        if (newOpt.type == "keybind" && newOpt.variable != "") {
                            if (opt.has.keyPath) newOpt.keyPath = opt.att.keyPath;
                        }
                        options.push(newOpt);
                    }
                }
                break;
            }
        }
    }
}