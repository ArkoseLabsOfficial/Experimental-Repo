package engine.substates;

class SaveLoadSubState extends SubStateBackend {
    public var isSavingMode:Bool;
    
    static inline var MAIN_PANEL_W:Int = 1452; 
    static inline var MAIN_PANEL_H:Int = 600; 
    
    var slotGroup:FlxSpriteGroup;
    var entries:Array<SaveLoadSlotEntry> = [];
    
    var curSelected:Int = 0;
    var currentPage:Int = 0; 
    var isPaginating:Bool = false;
    var fromMain:Bool = false;

    public function new(isSavingMode:Bool = true, fromMain:Bool = false) {
        super();
        this.isSavingMode = isSavingMode;
        this.fromMain = fromMain;
    }

    override public function create() {
        super.create();
        var camPause = new flixel.FlxCamera();
        camPause.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(camPause, false);
        this.cameras = [camPause];
        if (!fromMain) camPause.scroll.set(-230, 230);

        if (fromMain) {
            var pauseBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
            pauseBG.scrollFactor.set(0, 0);
            add(pauseBG);
        }

        var startX = (FlxG.width - MAIN_PANEL_W) / 2;
        var startY = (FlxG.height - MAIN_PANEL_H) / 2;

        var titleTxt = Language.GetCaption(isSavingMode ? "system.menu.savegame" : "system.menu.loadgame");
        var frame = new TitledMenuFrame(startX, startY, MAIN_PANEL_W, MAIN_PANEL_H, titleTxt, LilyAssets.image("img/ui/divider_lg"));
        add(frame);

        var arrowY = startY + (MAIN_PANEL_H / 2) - 30;
        var arrowL = new FlxSprite(startX - 60, arrowY).loadGraphic(LilyAssets.image("img/ui/arrow_up"));
        arrowL.angle = -90;
        add(arrowL);

        var arrowR = new FlxSprite(startX + MAIN_PANEL_W + 20, arrowY).loadGraphic(LilyAssets.image("img/ui/arrow_up"));
        arrowR.angle = 90;
        add(arrowR);

        slotGroup = new FlxSpriteGroup(startX + 178, startY + 120);
        add(slotGroup);

        buildPage();

        #if FEATURE_TOUCH_CONTROLS
        mobile.controls.addMobilePad("FULL", "A_B");
        mobile.controls.addMobilePadCamera();
        #end
    }

    function buildPage() {
        slotGroup.clear();
        entries = [];

        for (i in 0...3) {
            var slotNum = (currentPage * 3) + i + 1;
            var info = SaveManager.getSlotInfo(slotNum);
            
            var entry = new SaveLoadSlotEntry(0, i * 140, info);
            entries.push(entry);
            slotGroup.add(entry);
        }

        if (curSelected >= entries.length) curSelected = 0;
        highlightSelection();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (isPaginating) return;

        if (Controls.UP_P) moveSelection(-1);
        if (Controls.DOWN_P) moveSelection(1);
        
        if (Controls.LEFT_P) paginate(-1);
        if (Controls.RIGHT_P) paginate(1);
        
        if (Controls.CANCEL_P) {
            UIUtil.playCancelSound();
            close();
        }

        if (Controls.ACCEPT_P) {
            var selectedInfo = entries[curSelected].info;
            
            if (isSavingMode) {
                UIUtil.playConfirmSound();
                SaveManager.saveGame(selectedInfo.slotNum);
                buildPage(); 
            } else {
                if (!selectedInfo.isEmpty) {
                    UIUtil.playConfirmSound();
                    if (SaveManager.loadGame(selectedInfo.slotNum)) {
                        FlxG.switchState(new PlayState(true, SaveManager.currentRoomPath)); 
                    }
                } else {
                    UIUtil.playErrorSound();
                }
            }
        }
    }

    function moveSelection(change:Int) {
        UIUtil.playNavSound();
        curSelected += change;
        if (curSelected < 0) curSelected = entries.length - 1;
        if (curSelected >= entries.length) curSelected = 0;
        highlightSelection();
    }

    function highlightSelection() {
        for (i in 0...entries.length) {
            if (i == curSelected) entries[i].select();
            else entries[i].deselect();
        }
    }

    function paginate(dir:Int) {
        isPaginating = true;
        UIUtil.playNavSound();

        currentPage += dir;
        if (currentPage > 9) currentPage = 0;
        if (currentPage < 0) currentPage = 9;

        var slideOutOffset = dir * -200;
        var slideInOffset = dir * 200;

        FlxTween.tween(slotGroup, {x: slotGroup.x + slideOutOffset, alpha: 0}, 0.15, {
            ease: FlxEase.quadOut,
            onComplete: function(t) {
                buildPage();
                slotGroup.x -= (slideOutOffset + slideInOffset); 
                
                FlxTween.tween(slotGroup, {x: slotGroup.x + slideInOffset, alpha: 1}, 0.15, {
                    ease: FlxEase.quadOut,
                    onComplete: function(t) { isPaginating = false; }
                });
            }
        });
    }
}

class SaveLoadSlotEntry extends FlxSpriteGroup {
    static inline var SLOT_W:Int = 1095; 
    static inline var SLOT_H:Int = 114;  
    
    public var info:SaveManager.SaveSlotData;
    
    var bg:FlxSprite;
    var decor:FlxSprite;
    var slotNumTxt:FlxText;
    var primaryColor:Int = 0xFFBD274D;

    public function new(x:Float, y:Float, info:SaveManager.SaveSlotData) {
        super(x, y);
        this.info = info;

        bg = new FlxSprite(0, 0);
        add(bg);

        if (info.isEmpty) {
            bg.loadGraphic(LilyAssets.image("img/ui/save_slot_empty"));
            
            var lbl = new FlxText(0, 40, SLOT_W, Language.GetCaption("system.menu.file") + " " + info.slotNum, 36);
            lbl.alignment = CENTER;
            add(lbl);
            
        } else {
            bg.loadGraphic(LilyAssets.image("img/ui/save_slot"));

            decor = new FlxSprite(12, 12);
            decor.loadGraphic(LilyAssets.image("img/ui/save_decor"));
            add(decor);

            slotNumTxt = new FlxText(15, 5, 100, Std.string(info.slotNum), 30);
            add(slotNumTxt);

            var roomTxt = new FlxText(150, 10, 500, info.location, 36);
            add(roomTxt);

            var timeTxt = new FlxText(150, 60, 500, formatTime(info.playtime), 24);
            timeTxt.color = 0xFFAAAAAA;
            add(timeTxt);

            var locImg = new FlxSprite(870, 6);
            var locPath = info.image != "" ? info.image : "img/ui/save/unknown";
            locImg.loadGraphic(LilyAssets.image(locPath));
            add(locImg);

            var chrOffset = 600;
            for (i in 0...info.party.length) {
                var portrait = new FlxSprite(chrOffset + (i * 80), 10);
                var pPath = "img/ui/chr_face/" + info.party[i];
                portrait.loadGraphic(LilyAssets.image(pPath));
                portrait.antialiasing = false;
                
                portrait.setGraphicSize(80, 80);
                portrait.updateHitbox();
                add(portrait);
            }
        }

        bg.setGraphicSize(SLOT_W, SLOT_H);
        bg.updateHitbox();
        deselect();
    }

    public function select() {
        var tex = info.isEmpty ? "img/ui/save_slot_empty_selected" : "img/ui/save_slot_selected";
        bg.loadGraphic(LilyAssets.image(tex));
        bg.setGraphicSize(SLOT_W, SLOT_H);
        bg.updateHitbox();

        if (!info.isEmpty && decor != null) {
            decor.visible = false;
            slotNumTxt.color = primaryColor;
        }
    }

    public function deselect() {
        var tex = info.isEmpty ? "img/ui/save_slot_empty" : "img/ui/save_slot";
        bg.loadGraphic(LilyAssets.image(tex));
        bg.setGraphicSize(SLOT_W, SLOT_H);
        bg.updateHitbox();

        if (!info.isEmpty && decor != null) {
            decor.visible = true;
            slotNumTxt.color = FlxColor.WHITE;
        }
    }

    function formatTime(seconds:Float):String {
        var hrs = Math.floor(seconds / 3600);
        var mins = Math.floor((seconds % 3600) / 60);
        var secs = Math.floor(seconds % 60);
        
        var minStr = (mins < 10 && hrs > 0) ? "0" + mins : Std.string(mins);
        var secStr = secs < 10 ? "0" + secs : Std.string(secs);
        
        if (hrs > 0) return hrs + ":" + minStr + ":" + secStr;
        return minStr + ":" + secStr;
    }
}