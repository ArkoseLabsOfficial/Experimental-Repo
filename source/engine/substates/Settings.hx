package engine.substates;

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
    @:optional var curArrayIdx:Int;
}

class Settings extends SubStateBackend {
    public var uiScale:Float = 1.0;
    public var optionGap:Float = 72;
    public var fromPause:Bool = false;

    public var menuFrame:MenuFrameNode;
    public var optionContainer:FlxSpriteGroup;
    public var visualItems:Array<SettingsVisualEntry> = [];

    public var options:Array<XmlOption> = [];
    public var curSelected:Int = 0;

    var currentMenuId:String;
    var isListening:Bool = false;

    public function new(menuId:String = "main", fromPause:Bool = false) {
        super(0x99000000);
        currentMenuId = menuId;
        this.fromPause = fromPause;
    }

    override public function create():Void {
        super.create();
        Game.instance.language.onLanguageUpdate.push(refreshText);

        // The position shit
        if (fromPause && currentMenuId == "main")
            camMenu.scroll.set(-230, 40);

        parseXML(currentMenuId);

        uiScale = fromPause ? 1.3 : 1.0;
        optionGap = 72 * uiScale;

        var numItems = options.length + (currentMenuId != "main" ? 1 : 0);

        var targetWidth = fromPause ? 1452.0 : (600.0 * uiScale);
        var targetHeight = fromPause ? 985.0 : ((numItems * optionGap) + (150.0 * uiScale));
        var entryWidth = targetWidth * 0.85;

        var useTitle = currentMenuId != "main";
        menuFrame = new MenuFrameNode(0, 0, targetWidth, targetHeight, useTitle ? 2 : 0);

        menuFrame.screenCenter();
        if (fromPause)
            menuFrame.y += 2.5;

        if (useTitle) {
            menuFrame.setTitle(Game.instance.language.getCaption(options[0] != null ? "system.settings.category." + currentMenuId : "Settings"));
        }

        add(menuFrame);

        optionContainer = new FlxSpriteGroup();

        for (i in 0...options.length) {
            var opt = options[i];
            var entry = new SettingsVisualEntry(0, i * optionGap, opt, entryWidth, optionGap, uiScale);
            visualItems.push(entry);
            optionContainer.add(entry);

            if (currentMenuId != "main" && opt.type != "category" && opt.type != "button") {
                ensureDefaultData(opt);
                entry.updateVisuals(getData(opt.variable));
            }
        }

        if (currentMenuId != "main") {
            var backOpt:XmlOption = {label: "system.settings.game.back", type: "button", variable: ""};
            var backEntry = new SettingsVisualEntry(0, options.length * optionGap, backOpt, entryWidth, optionGap, uiScale);
            visualItems.push(backEntry);
            optionContainer.add(backEntry);
        }

        menuFrame.addMenu(optionContainer);

        optionContainer.x = menuFrame.x + (targetWidth - entryWidth) / 2;
        optionContainer.y = menuFrame.y + (targetHeight - (numItems * optionGap)) / 2;
        if (useTitle)
            optionContainer.y += (30 * uiScale);

        updateHighlight();
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
                if (opt.onChanged != null)
                    opt.onChanged(GamePrefs.keybinds.get(opt.variable));
                visualItems[curSelected].updateVisuals(null);
                isListening = false;
                updateHighlight();
            }
            return;
        }

        if (Controls.UP_P) {
            LilyAssets.play(LilyAssets.NAVIGATE);
            changeSelection(-1);
        }
        if (Controls.DOWN_P) {
            LilyAssets.play(LilyAssets.NAVIGATE);
            changeSelection(1);
        }
        if (Controls.ACCEPT) {
            LilyAssets.play(LilyAssets.CONFIRM);
            acceptSelection();
        }
        if (Controls.CANCEL) {
            LilyAssets.play(LilyAssets.CANCEL);
            close();
        }

        if (curSelected < options.length && currentMenuId != "main") {
            var opt = options[curSelected];
            if (Controls.LEFT_P)
                adjustOption(opt, -1);
            if (Controls.RIGHT_P)
                adjustOption(opt, 1);
        }
    }

    function changeSelection(change:Int):Void {
        curSelected += change;
        if (curSelected < 0)
            curSelected = visualItems.length - 1;
        if (curSelected >= visualItems.length)
            curSelected = 0;
        updateHighlight();
    }

    function updateHighlight():Void {
        for (i in 0...visualItems.length) {
            visualItems[i].setHighlight(i == curSelected);
        }
    }

    function acceptSelection():Void {
        if (curSelected == options.length) {
            GamePrefs.saveSettings();
            close();
            return;
        }
        var opt = options[curSelected];
        if (opt.onClicked != null)
            opt.onClicked();

        if (currentMenuId == "main") {
            if (opt.target == "language")
                openSubState(new Language());
            else
                openSubState(new Settings(opt.target, fromPause));
        } else {
            if (opt.type == "bool")
                adjustOption(opt, 1);
            if (opt.type == "keybind") {
                isListening = true;
                visualItems[curSelected].setListeningState();
            }
        }
    }

    function adjustOption(opt:XmlOption, dir:Int):Void {
        var curVal:Dynamic = getData(opt.variable);
        switch (opt.type) {
            case "bool":
                saveData(opt.variable, !(curVal == true));
            case "array":
                opt.curArrayIdx += dir;
                if (opt.curArrayIdx < 0)
                    opt.curArrayIdx = opt.values.length - 1;
                if (opt.curArrayIdx >= opt.values.length)
                    opt.curArrayIdx = 0;
                saveData(opt.variable, opt.values[opt.curArrayIdx]);
            case "int", "float", "percent":
                var numVal:Float = Std.parseFloat(Std.string(curVal));
                if (Math.isNaN(numVal))
                    numVal = opt.min;
                numVal += (opt.step * dir);
                if (numVal < opt.min)
                    numVal = opt.min;
                if (numVal > opt.max)
                    numVal = opt.max;
                if (opt.type != "int")
                    numVal = Math.round(numVal * 100) / 100;
                saveData(opt.variable, opt.type == "int" ? Std.int(numVal) : numVal);
        }

        var newVal = getData(opt.variable);
        if (opt.onChanged != null)
            opt.onChanged(newVal);
        visualItems[curSelected].updateVisuals(newVal);
    }

    function saveData(variable:String, value:Dynamic):Void {
        if (variable == null || variable == "")
            return;
        GamePrefs.setOption(variable, value);
    }

    function getData(variable:String):Dynamic {
        if (variable == null || variable == "")
            return null;
        return GamePrefs.getOption(variable);
    }

    function ensureDefaultData(opt:XmlOption):Void {
        if (opt.type == "keybind")
            return;
        if (getData(opt.variable) == null) {
            switch (opt.type) {
                case "bool":
                    saveData(opt.variable, false);
                case "array":
                    saveData(opt.variable, opt.values[0]);
                    opt.curArrayIdx = 0;
                case "int", "float", "percent":
                    saveData(opt.variable, opt.min != null ? opt.min : 0);
            }
        } else {
            if (opt.type == "array") {
                opt.curArrayIdx = opt.values.indexOf(Std.string(getData(opt.variable)));
                if (opt.curArrayIdx == -1)
                    opt.curArrayIdx = 0;
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
                        if (cat.att.label == "system.settings.language" && fromPause)
                            continue;
                        options.push({label: cat.att.label, target: cat.att.target, type: "category"});
                    }
                } else {
                    for (opt in menuNode.nodes.option) {
                        var newOpt:XmlOption = {
                            label: opt.att.label,
                            type: opt.att.type,
                            variable: opt.has.variable ? opt.att.variable : ""
                        };
                        if (opt.has.values)
                            newOpt.values = opt.att.values.split(",");
                        if (opt.has.min)
                            newOpt.min = Std.parseFloat(opt.att.min);
                        if (opt.has.max)
                            newOpt.max = Std.parseFloat(opt.att.max);
                        if (opt.has.step)
                            newOpt.step = Std.parseFloat(opt.att.step);
                        if (newOpt.type == "keybind" && newOpt.variable != "") {
                            if (opt.has.keyPath)
                                newOpt.keyPath = opt.att.keyPath;
                        }
                        options.push(newOpt);
                    }
                }
                break;
            }
        }
    }

    function refreshText():Void {
        for (item in visualItems) {
            item.refreshText();
        }
    }

    override function destroy() {
        super.destroy();
        Game.instance.language.onLanguageUpdate.remove(refreshText);
    }
}

class SettingsVisualEntry extends MenuVisualEntry {
    public var valueText:FlxText;
    public var optionLabel:FlxText;
    public var optData:XmlOption;
    public var keySprites:Array<FlxSprite>;

    private var internalScale:Float;
    private var entryWidth:Float;
    private var entryHeight:Float;

    public function refreshText():Void {
        FlxDestroyUtil.destroy(optionLabel);

        optionLabel = new FlxText(0, 0, 0, Game.instance.language.getCaption(optData.label), Std.int(20 * internalScale));
        add(optionLabel);

        if (optData.type == "category" || optData.type == "button") {
            optionLabel.x = this.x + (entryWidth - optionLabel.width) / 2;
        } else {
            optionLabel.x = this.x + 15 * internalScale;
        }
        optionLabel.y = this.y + (entryHeight - optionLabel.height) / 2;
    }

    public function new(X:Float, Y:Float, opt:XmlOption, width:Float, height:Float, scale:Float) {
        super(X, Y, "", width, height);

        this.optData = opt;
        this.internalScale = scale;
        this.entryWidth = width;
        this.entryHeight = height;

        var ts = Std.int(20 * scale);

        optionLabel = new FlxText(0, 0, 0, Game.instance.language.getCaption(opt.label), ts);
        add(optionLabel);

        if (opt.type == "category" || opt.type == "button") {
            optionLabel.x = this.x + (width - optionLabel.width) / 2;
        } else {
            optionLabel.x = this.x + 15 * scale;
        }
        optionLabel.y = this.y + (height - optionLabel.height) / 2;

        valueText = new FlxText(0, 0, 0, "", ts);
        add(valueText);

        if (opt.type == "keybind" && opt.keyPath != null) {
            keySprites = [new FlxSprite(0, 0), new FlxSprite(0, 0)];
            add(keySprites[0]);
            add(keySprites[1]);
        }
    }

    public function updateVisuals(val:Dynamic):Void {
        if (optData.type == "button" || optData.type == "category")
            return;

        switch (optData.type) {
            case "bool":
                valueText.text = (val == true) ? "< ON >" : "< OFF >";
            case "array", "int", "float":
                valueText.text = "< " + Std.string(val) + " >";
            case "percent":
                valueText.text = "< " + Std.string(val) + "% >";
            case "keybind":
                var binds:Array<String> = GamePrefs.keybinds.get(optData.variable);
                var kbStr = binds[0];
                var gpStr = binds[1];
                var displayText = "";

                if (optData.keyPath != null) {
                    var kbImgPath = getInputImagePath(kbStr, false, optData.keyPath);
                    var gpImgPath = getInputImagePath(gpStr, true, optData.keyPath);

                    if (kbImgPath != "" && FileSystem.exists(kbImgPath)) {
                        keySprites[0].loadGraphic(kbImgPath);
                        keySprites[0].scale.set(0.5 * internalScale, 0.5 * internalScale);
                        keySprites[0].updateHitbox();
                        keySprites[0].visible = true;
                        displayText += "[ IMG ]";
                    } else {
                        keySprites[0].visible = false;
                        displayText += "[ " + kbStr + " ]";
                    }

                    displayText += " / ";

                    if (gpImgPath != "" && FileSystem.exists(gpImgPath)) {
                        keySprites[1].loadGraphic(gpImgPath);
                        keySprites[1].scale.set(0.5 * internalScale, 0.5 * internalScale);
                        keySprites[1].updateHitbox();
                        keySprites[1].visible = true;
                        displayText += "[ IMG ]";
                    } else {
                        keySprites[1].visible = false;
                        displayText += "[ " + gpStr + " ]";
                    }
                    valueText.text = StringTools.replace(displayText, "[ IMG ]", "      ");
                } else {
                    valueText.text = "[ " + kbStr + " ] / [ " + gpStr + " ]";
                }
        }

        valueText.x = this.x + entryWidth - valueText.width - (15 * internalScale);
        valueText.y = this.y + (entryHeight - valueText.height) / 2;

        if (optData.type == "keybind" && optData.keyPath != null) {
            if (keySprites[0].visible) {
                keySprites[0].x = valueText.x - (5 * internalScale);
                keySprites[0].y = valueText.y + (valueText.height / 2) - (keySprites[0].height / 2);
            }
            if (keySprites[1].visible) {
                keySprites[1].x = valueText.x + (80 * internalScale);
                keySprites[1].y = valueText.y + (valueText.height / 2) - (keySprites[1].height / 2);
            }
        }
    }

    public function setListeningState():Void {
        valueText.text = "? Waiting ?";
        
        valueText.x = this.x + entryWidth - valueText.width - (15 * internalScale);
        valueText.y = this.y + (entryHeight - valueText.height) / 2;

        bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), 0x77FFD700);
        if (keySprites != null) {
            keySprites[0].visible = false;
            keySprites[1].visible = false;
        }
    }

    private function getInputImagePath(inputStr:String, isGamepad:Bool, basePath:String):String {
        if (inputStr == null || inputStr == "NONE" || inputStr == "")
            return "";
        var fileName:String = "";
        var raw = inputStr.toUpperCase();
        if (!isGamepad) {
            if (raw.length == 1 && raw.charCodeAt(0) >= 65 && raw.charCodeAt(0) <= 90) {
                fileName = "keyboard_letter_" + raw.toLowerCase();
            } else {
                fileName = switch (raw) {
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
            fileName = switch (raw) {
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
}