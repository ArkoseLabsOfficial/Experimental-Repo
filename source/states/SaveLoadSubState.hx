package states;

import flixel.FlxSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.utils.Assets;
import backend.SaveManager;
import ui.TitledMenuFrame;

class SaveLoadSubState extends FlxSubState {
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
        var frame = new TitledMenuFrame(startX, startY, MAIN_PANEL_W, MAIN_PANEL_H, titleTxt, "assets/img/ui/divider_lg.png");
        add(frame);

        var arrowY = startY + (MAIN_PANEL_H / 2) - 30;
        var arrowL = new FlxSprite(startX - 60, arrowY).loadGraphic("assets/img/ui/arrow_up.png");
        arrowL.angle = -90;
        add(arrowL);

        var arrowR = new FlxSprite(startX + MAIN_PANEL_W + 20, arrowY).loadGraphic("assets/img/ui/arrow_up.png");
        arrowR.angle = 90;
        add(arrowR);

        slotGroup = new FlxSpriteGroup(startX + 178, startY + 120);
        add(slotGroup);

        buildPage();
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

    function safePlaySound(path:String) {
        if (Assets.exists(path)) {
            FlxG.sound.play(path);
        } else {
            FlxG.log.warn("Missing sound file: " + path);
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (isPaginating) return;

        if (Controls.UP_P) moveSelection(-1);
        if (Controls.DOWN_P) moveSelection(1);
        
        if (Controls.LEFT_P) paginate(-1);
        if (Controls.RIGHT_P) paginate(1);
        
        if (Controls.CANCEL_P) {
            safePlaySound("assets/sfx/ui_navigation2.ogg");
            close();
        }

        if (Controls.ACCEPT_P) {
            var selectedInfo = entries[curSelected].info;
            
            if (isSavingMode) {
                safePlaySound("assets/sfx/ui_start.ogg");
                SaveManager.saveGame(selectedInfo.slotNum);
                buildPage(); 
            } else {
                if (!selectedInfo.isEmpty) {
                    safePlaySound("assets/sfx/ui_start.ogg");
                    if (SaveManager.loadGame(selectedInfo.slotNum)) {
                        FlxG.switchState(new PlayState(true, SaveManager.currentRoomPath)); 
                    }
                } else {
                    safePlaySound("assets/sfx/ui_bad.ogg"); 
                }
            }
        }
    }

    function moveSelection(change:Int) {
        safePlaySound("assets/sfx/ui_navigation.ogg");
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
        safePlaySound("assets/sfx/ui_navigation.ogg");

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
    
    public var info:backend.SaveManager.SaveSlotData;
    
    var bg:FlxSprite;
    var decor:FlxSprite;
    var slotNumTxt:FlxText;
    var primaryColor:Int = 0xFFBD274D;

    public function new(x:Float, y:Float, info:backend.SaveManager.SaveSlotData) {
        super(x, y);
        this.info = info;

        bg = new FlxSprite(0, 0);
        add(bg);

        if (info.isEmpty) {
            if (Assets.exists("assets/img/ui/save_slot_empty.png")) bg.loadGraphic("assets/img/ui/save_slot_empty.png");
            else bg.makeGraphic(SLOT_W, SLOT_H, 0xFF2A0D1B);
            
            var lbl = new FlxText(0, 40, SLOT_W, Language.GetCaption("system.menu.file") + " " + info.slotNum, 36);
            lbl.alignment = CENTER;
            add(lbl);
            
        } else {
            if (Assets.exists("assets/img/ui/save_slot.png")) bg.loadGraphic("assets/img/ui/save_slot.png");
            else bg.makeGraphic(SLOT_W, SLOT_H, 0xFF441829);

            decor = new FlxSprite(12, 12);
            if (Assets.exists("assets/img/ui/save_decor.png")) decor.loadGraphic("assets/img/ui/save_decor.png");
            add(decor);

            slotNumTxt = new FlxText(15, 5, 100, Std.string(info.slotNum), 30);
            add(slotNumTxt);

            var roomTxt = new FlxText(150, 10, 500, info.location, 36);
            add(roomTxt);

            var timeTxt = new FlxText(150, 60, 500, formatTime(info.playtime), 24);
            timeTxt.color = 0xFFAAAAAA;
            add(timeTxt);

            var locImg = new FlxSprite(870, 6);
            var locPath = info.image != "" ? info.image : "assets/img/ui/save/unknown.png";
            if (Assets.exists(locPath)) locImg.loadGraphic(locPath);
            else locImg.makeGraphic(150, 90, 0xFF14080E);
            add(locImg);

            var chrOffset = 600;
            for (i in 0...info.party.length) {
                var portrait = new FlxSprite(chrOffset + (i * 80), 10);
                var pPath = "assets/img/ui/chr_face/" + info.party[i] + ".png";
                if (Assets.exists(pPath)) portrait.loadGraphic(pPath);
                
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
        var tex = info.isEmpty ? "assets/img/ui/save_slot_empty_selected.png" : "assets/img/ui/save_slot_selected.png";
        if (Assets.exists(tex)) bg.loadGraphic(tex);
        else bg.makeGraphic(SLOT_W, SLOT_H, 0xFF882244); 
        bg.setGraphicSize(SLOT_W, SLOT_H);
        bg.updateHitbox();

        if (!info.isEmpty && decor != null) {
            decor.visible = false;
            slotNumTxt.color = primaryColor;
        }
    }

    public function deselect() {
        var tex = info.isEmpty ? "assets/img/ui/save_slot_empty.png" : "assets/img/ui/save_slot.png";
        if (Assets.exists(tex)) bg.loadGraphic(tex);
        else bg.makeGraphic(SLOT_W, SLOT_H, info.isEmpty ? 0xFF2A0D1B : 0xFF441829);
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