package states;

import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.net.FileReference;
import openfl.net.FileFilter;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import haxe.xml.Access;
import objects.*;

enum EditorMode { BUILD; EDIT; DELETE; }
enum EditorTool { PLAYER; NPC; FOLLOWER; SPRITE; ANIM_SPRITE; SOLID; }

class PlacedElement {
    public var type:EditorTool;
    public var x:Float;
    public var y:Float;
    public var z:Int;
    public var sprite:FlxSprite;
    public var props:Map<String, String>;
    public function new(t:EditorTool, px:Float, py:Float, pz:Int, s:FlxSprite, p:Map<String, String>) { 
        type = t;
        x = px; y = py; z = pz; sprite = s; props = p;
    }
}

class EditorButton extends FlxSprite {
    public var label:FlxText;
    public var onClick:Void->Void;
    var baseColor:Int;
    public var text(get, set):String;
    public function new(x:Float, y:Float, w:Int, h:Int, txt:String, color:Int, cb:Void->Void) {
        super(x, y);
        makeGraphic(w, h, color);
        baseColor = color;
        onClick = cb;
        label = new FlxText(x, y, w, txt, 12);
        label.alignment = CENTER;
        label.color = 0xFFFFFFFF;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        label.x = x; 
        label.y = y + (height - label.height) / 2;
        var cam = (cameras != null && cameras.length > 0) ? cameras[0] : FlxG.camera;
        var mx = FlxG.mouse.getScreenPosition(cam).x;
        var my = FlxG.mouse.getScreenPosition(cam).y;
        var isHovered = (mx >= x && mx <= x + width && my >= y && my <= y + height);
        alpha = isHovered ? 0.7 : 1.0;
        if (isHovered && FlxG.mouse.justPressed && onClick != null) onClick();
    }

    override public function draw() {
        super.draw();
        label.draw();
    }
    
    override public function set_camera(cam:flixel.FlxCamera):flixel.FlxCamera {
        label.camera = cam;
        return super.set_camera(cam);
    }

    function get_text():String return label.text;
    function set_text(val:String):String return label.text = val;
}

class RoomEditorState extends FlxState {
    var mode:EditorMode = BUILD;
    var currentTool:EditorTool = PLAYER;
    var elements:Array<PlacedElement> = [];
    var ghostCursor:FlxSprite;
    
    var snapGrid:Int = 32;
    var snapEnabled:Bool = true;
    var lastSpriteStr:String = "";
    
    var lastScaleX:Float = 1.0;
    var lastScaleY:Float = 1.0;
    var templateAnimData:String = "";
    
    var uiCamera:flixel.FlxCamera;
    
    var propWindowBg:FlxSprite;
    var propWindowTop:FlxSprite;
    var isDraggingWindow:Bool = false;
    var dragOffset:FlxPoint = FlxPoint.get();
    
    var uiGroup:flixel.group.FlxGroup;
    var nudgeGroup:flixel.group.FlxGroup;
    var animBtnGroup:flixel.group.FlxGroup;
    var addAnimBtn:EditorButton;
    
    var inputs:Map<String, TextField> = new Map();
    var nativeUIGroup:Array<TextField> = [];
    var inputLabels:Map<TextField, FlxText> = new Map();
    var inputOffsetsX:Map<TextField, Float> = new Map();
    var inputOffsetsY:Map<TextField, Float> = new Map();

    var currentTab:String = "OBJECT"; 
    var editingElement:PlacedElement = null;
    var fileOpener:FileReference;
    var roomProps:Map<String, String> = ["room_name" => "custom_room", "folder" => "rooms/custom", "zoom" => "1.0"];
    
    var undoStack:Array<String> = [];
    var redoStack:Array<String> = [];

    override public function create():Void {
        super.create();
        FlxG.camera.bgColor = 0xFF1A365D;
        FlxG.mouse.useSystemCursor = true;
        
        uiCamera = new flixel.FlxCamera();
        uiCamera.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(uiCamera, false);

        var gridBg = new FlxSprite(0, 0).makeGraphic(4000, 4000, 0xFF1A365D);
        for (i in 0...Std.int(4000/32)) {
            FlxSpriteUtil.drawLine(gridBg, i*32, 0, i*32, 4000, {thickness: 1, color: 0xFF2B6CB0});
            FlxSpriteUtil.drawLine(gridBg, 0, i*32, 4000, i*32, {thickness: 1, color: 0xFF2B6CB0});
        }
        add(gridBg);
        ghostCursor = new FlxSprite();
        add(ghostCursor);

        uiGroup = new flixel.group.FlxGroup();
        uiGroup.cameras = [uiCamera];
        add(uiGroup);
        
        nudgeGroup = new flixel.group.FlxGroup();
        nudgeGroup.cameras = [uiCamera];
        add(nudgeGroup);

        animBtnGroup = new flixel.group.FlxGroup();
        animBtnGroup.cameras = [uiCamera];
        add(animBtnGroup);

        buildGDUI();
        buildDraggablePropertyWindow();
        setTool(PLAYER);
        
        saveState();
    }

    function buildGDUI():Void {
        var topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 40, 0xDD000000);
        uiGroup.add(topBar);

        createBtn(10, 5, 80, 30, "BUILD", 0xFF225588, function() { setMode(BUILD); });
        createBtn(100, 5, 80, 30, "EDIT", 0xFF225588, function() { setMode(EDIT); });
        createBtn(190, 5, 80, 30, "DELETE", 0xFF882222, function() { setMode(DELETE); });
        createBtn(320, 5, 70, 30, "PLAYER", 0xFF555555, function() { setTool(PLAYER); });
        createBtn(400, 5, 70, 30, "NPC", 0xFF555555, function() { setTool(NPC); });
        createBtn(480, 5, 80, 30, "FOLLOWER", 0xFF555555, function() { setTool(FOLLOWER); });
        createBtn(570, 5, 70, 30, "SPRITE", 0xFF555555, function() { setTool(SPRITE); });
        createBtn(650, 5, 70, 30, "ANIM", 0xFF555555, function() { setTool(ANIM_SPRITE); });
        createBtn(730, 5, 70, 30, "SOLID", 0xFF555555, function() { setTool(SOLID); });
        createBtn(FlxG.width - 290, 5, 80, 30, "SAVE XML", 0xFF228822, saveXML);
        createBtn(FlxG.width - 200, 5, 80, 30, "LOAD XML", 0xFF885522, loadXML);
        createBtn(FlxG.width - 110, 5, 100, 30, "PLAYTEST", 0xFF22AAAA, runPlaytest);
    }

    function createBtn(x:Float, y:Float, w:Int, h:Int, txt:String, color:Int, cb:Void->Void, ?grp:flixel.group.FlxGroup):EditorButton {
        var btn = new EditorButton(x, y, w, h, txt, color, cb);
        if (grp != null) grp.add(btn); else uiGroup.add(btn);
        return btn;
    }

    function buildDraggablePropertyWindow() {
        propWindowBg = new FlxSprite(FlxG.width - 320, 60).makeGraphic(300, 600, 0xEE222222);
        uiGroup.add(propWindowBg);

        propWindowTop = new FlxSprite(propWindowBg.x, propWindowBg.y).makeGraphic(300, 30, 0xFF444444);
        uiGroup.add(propWindowTop);
        var title = new FlxText(propWindowTop.x + 10, propWindowTop.y + 5, 0, "PROPERTIES (Drag Here)", 12);
        uiGroup.add(title);
        
        createBtn(propWindowBg.x, propWindowBg.y + 30, 100, 25, "ROOM", 0xFF444444, function() { switchTab("ROOM"); });
        createBtn(propWindowBg.x + 100, propWindowBg.y + 30, 100, 25, "OBJECT", 0xFF444444, function() { switchTab("OBJECT"); });
        createBtn(propWindowBg.x + 200, propWindowBg.y + 30, 100, 25, "ANIMS", 0xFF444444, function() { switchTab("ANIMATIONS"); });

        createInputField("name", "Name:", "", 10, 70);
        createInputField("sprite", "Sprite:", "", 10, 110);
        createInputField("z", "Z-Index:", "10", 10, 150);
        createInputField("scale_x", "Scale X:", "1.0", 10, 190);
        createInputField("scale_y", "Scale Y:", "1.0", 10, 230);
        createInputField("collision", "Collision:", "true", 10, 270);
        createInputField("interactable", "Interact:", "false", 10, 310);
        createInputField("dialog", "Dialog XML:", "", 10, 350);
        
        createInputField("target", "Target Name:", "lacie", 10, 390);
        createInputField("distance", "Follow Dist:", "30", 10, 430);
        createInputField("solid_w", "Width:", "32", 10, 470);
        createInputField("solid_h", "Height:", "32", 10, 510);
        
        createInputField("room_name", "Room ID:", "custom", 10, 70);
        createInputField("folder", "Folder:", "rooms/custom", 10, 110);
        createInputField("zoom", "Zoom:", "1.0", 10, 150);
        
        // ANIMATIONS TAB POOL
        for (i in 0...6) {
            var yOff = 70 + (i * 65);
            createInputField('anim_name_$i', 'Name:', '', 10, yOff, 70, 40);
            createInputField('anim_prefix_$i', 'Prefix:', '', 130, yOff, 70, 40);
            createInputField('anim_fps_$i', 'FPS:', '12', 10, yOff + 25, 40, 40);
            createInputField('anim_loop_$i', 'Loop:', 'true', 100, yOff + 25, 40, 40);
            createBtn(240, yOff + 10, 40, 25, "DEL", 0xFF882222, function() {
                deleteAnim(i);
            }, animBtnGroup);
        }
        
        addAnimBtn = createBtn(propWindowBg.x + 10, propWindowBg.y + 470, 100, 25, "ADD ANIM", 0xFF228822, function() {
            if (currentTool == ANIM_SPRITE || (editingElement != null && editingElement.type == ANIM_SPRITE)) {
                applyCurrentInputs();
                var anims = getActiveAnimData();
                if (anims.length < 6) {
                    anims.push("new,new,12,true");
                    setActiveAnimData(anims);
                    switchTab("ANIMATIONS", true);
                }
            }
        });
        uiGroup.add(addAnimBtn);

        createBtn(10, 520, 65, 20, "Left (1)", 0xFF555555, function() { nudge(-snapGrid, 0); }, nudgeGroup);
        createBtn(80, 520, 65, 20, "Right (1)", 0xFF555555, function() { nudge(snapGrid, 0); }, nudgeGroup);
        createBtn(150, 520, 65, 20, "Up (1)", 0xFF555555, function() { nudge(0, -snapGrid); }, nudgeGroup);
        createBtn(220, 520, 65, 20, "Down (1)", 0xFF555555, function() { nudge(0, snapGrid); }, nudgeGroup);
        createBtn(10, 550, 65, 20, "Left (.5)", 0xFF555555, function() { nudge(-snapGrid/2, 0); }, nudgeGroup);
        createBtn(80, 550, 65, 20, "Right (.5)", 0xFF555555, function() { nudge(snapGrid/2, 0); }, nudgeGroup);
        createBtn(150, 550, 65, 20, "Up (.5)", 0xFF555555, function() { nudge(0, -snapGrid/2); }, nudgeGroup);
        createBtn(220, 550, 65, 20, "Down (.5)", 0xFF555555, function() { nudge(0, snapGrid/2); }, nudgeGroup);

        switchTab("OBJECT");
    }

    function createInputField(id:String, labelStr:String, def:String, offsetX:Float, offsetY:Float, inputW:Int = 180, labelW:Int = 80) {
        var format = new TextFormat("Arial", 14, 0x000000);
        var input = new TextField();
        input.type = TextFieldType.INPUT;
        
        inputOffsetsX.set(input, offsetX + labelW + 10);
        inputOffsetsY.set(input, offsetY);
        
        input.width = inputW;
        input.height = 24;
        input.background = true;
        input.backgroundColor = 0xFFFFFF;
        input.text = def;
        input.name = id; 
        input.defaultTextFormat = format;
        var lbl = new FlxText(0, 0, labelW, labelStr, 12);
        lbl.alignment = RIGHT;
        uiGroup.add(lbl);
        inputLabels.set(input, lbl);

        FlxG.stage.addChild(input);
        inputs.set(id, input);
        nativeUIGroup.push(input);
    }
    
    function getActiveAnimData():Array<String> {
        var str = (editingElement != null && editingElement.props.exists("anim_data")) ? editingElement.props.get("anim_data") : templateAnimData;
        return str != "" ? str.split("|") : [];
    }

    function setActiveAnimData(anims:Array<String>) {
        var str = anims.join("|");
        if (editingElement != null) editingElement.props.set("anim_data", str);
        else templateAnimData = str;
    }

    function deleteAnim(index:Int) {
        if (currentTab == "ANIMATIONS") {
            applyCurrentInputs();
            var anims = getActiveAnimData();
            if (index < anims.length) {
                anims.splice(index, 1);
                setActiveAnimData(anims);
                switchTab("ANIMATIONS", true);
            }
        }
    }
    
    function saveState() {
        undoStack.push(generateXMLString());
        if (undoStack.length > 50) undoStack.shift(); 
        redoStack = [];
    }

    function undo() {
        if (undoStack.length > 1) { 
            redoStack.push(undoStack.pop());
            parseLoadedXML(undoStack[undoStack.length - 1], false);
        }
    }

    function redo() {
        if (redoStack.length > 0) {
            var state = redoStack.pop();
            undoStack.push(state);
            parseLoadedXML(state, false);
        }
    }

    function nudge(dx:Float, dy:Float) {
        if (editingElement != null) {
            saveState();
            editingElement.x += dx;
            editingElement.y += dy;
            editingElement.sprite.x = editingElement.x;
            editingElement.sprite.y = editingElement.y;
        }
    }

    function switchTab(tab:String, skipApply:Bool = false) {
        if (!skipApply) applyCurrentInputs();
        currentTab = tab;
        
        for (tf in nativeUIGroup) {
            tf.visible = false;
            inputLabels.get(tf).visible = false;
        }
        nudgeGroup.visible = false;
        animBtnGroup.visible = false;
        addAnimBtn.visible = false;
        
        if (tab == "ROOM") {
            showField("room_name", roomProps.get("room_name"));
            showField("folder", roomProps.get("folder"));
            showField("zoom", roomProps.get("zoom"));
        } else if (tab == "ANIMATIONS") {
            if (currentTool == ANIM_SPRITE || (editingElement != null && editingElement.type == ANIM_SPRITE)) {
                addAnimBtn.visible = true;
                animBtnGroup.visible = true;
                
                var anims = getActiveAnimData();
                var cIdx = 0;
                for (btn in animBtnGroup.members) {
                    var b:EditorButton = cast btn;
                    if (b != null) b.visible = (cIdx < anims.length);
                    cIdx++;
                }

                for (i in 0...6) {
                    if (i < anims.length) {
                        var parts = anims[i].split(",");
                        showField('anim_name_$i', parts.length > 0 ? parts[0] : "");
                        showField('anim_prefix_$i', parts.length > 1 ? parts[1] : "");
                        showField('anim_fps_$i', parts.length > 2 ? parts[2] : "12");
                        showField('anim_loop_$i', parts.length > 3 ? parts[3] : "true");
                    }
                }
            }
        } else {
            var showList = [];
            if (currentTool == SOLID) showList = ["solid_w", "solid_h"];
            else if (currentTool == SPRITE || currentTool == PLAYER || currentTool == NPC) showList = ["name", "sprite", "z", "scale_x", "scale_y", "collision", "interactable", "dialog"];
            else if (currentTool == ANIM_SPRITE) showList = ["name", "sprite", "z", "scale_x", "scale_y", "collision", "interactable"];
            else if (currentTool == FOLLOWER) showList = ["name", "sprite", "z", "scale_x", "scale_y", "target", "distance"];
            
            var defaults = editingElement != null ? editingElement.props : new Map<String, String>();
            for (i in 0...showList.length) {
                var key = showList[i];
                var def = defaults.exists(key) ? defaults.get(key) : (inputs.exists(key) ? inputs.get(key).text : "");
                showField(key, def, 70 + (i * 35));
            }
            if (mode == EDIT && editingElement != null) nudgeGroup.visible = true;
        }
    }

    function showField(id:String, val:String, ?newY:Float) {
        if (!inputs.exists(id)) return;
        var tf = inputs.get(id);
        tf.visible = true;
        tf.text = val;
        inputLabels.get(tf).visible = true;
        if (newY != null) inputOffsetsY.set(tf, newY);
    }

    function applyCurrentInputs() {
        if (currentTab == "ROOM") {
            if (inputs.exists("room_name")) roomProps.set("room_name", inputs.get("room_name").text);
            if (inputs.exists("folder")) roomProps.set("folder", inputs.get("folder").text);
            if (inputs.exists("zoom")) roomProps.set("zoom", inputs.get("zoom").text);
            
            var zVal = Std.parseFloat(inputs.get("zoom").text);
            if (!Math.isNaN(zVal) && zVal > 0) FlxG.camera.zoom = zVal;
            
        } else if (currentTab == "ANIMATIONS") {
            if (currentTool == ANIM_SPRITE || (editingElement != null && editingElement.type == ANIM_SPRITE)) {
                var animStrs = [];
                for (i in 0...6) {
                    if (inputs.exists('anim_name_$i') && inputs.get('anim_name_$i').visible) {
                        var n = inputs.get('anim_name_$i').text;
                        var p = inputs.get('anim_prefix_$i').text;
                        var f = inputs.get('anim_fps_$i').text;
                        var l = inputs.get('anim_loop_$i').text;
                        animStrs.push('$n,$p,$f,$l');
                    }
                }
                setActiveAnimData(animStrs);
            }
        } 
        
        if (editingElement != null) {
            for (key in inputs.keys()) {
                if (inputs.get(key).visible && !StringTools.startsWith(key, "anim_")) {
                    editingElement.props.set(key, inputs.get(key).text);
                }
            }
            if (editingElement.type == SOLID && inputs.get("solid_w").visible) {
                var sw = Std.parseInt(inputs.get("solid_w").text);
                var sh = Std.parseInt(inputs.get("solid_h").text);
                if (sw > 0 && sh > 0) {
                    editingElement.sprite.makeGraphic(sw, sh, FlxColor.TRANSPARENT);
                    FlxSpriteUtil.drawRect(editingElement.sprite, 0, 0, sw, sh, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.RED});
                }
            }
            
            if (inputs.exists("scale_x") && inputs.get("scale_x").visible) {
                var sx = Std.parseFloat(inputs.get("scale_x").text);
                var sy = Std.parseFloat(inputs.get("scale_y").text);
                if (Math.isNaN(sx)) sx = 1.0;
                if (Math.isNaN(sy)) sy = 1.0;
                editingElement.sprite.scale.set(sx, sy);
                if (Std.isOfType(editingElement.sprite, WorldObject)) {
                    cast(editingElement.sprite, WorldObject).updateHitbox();
                }
            }
        }
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        var isTyping = false;
        for (tf in nativeUIGroup) if (FlxG.stage.focus == tf && tf.visible) isTyping = true;
        
        if (!isTyping) handleCameraMovement();
        
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z) { undo(); return; }
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y) { redo(); return; }

        if (FlxG.mouse.wheel != 0) {
            FlxG.camera.zoom += FlxG.mouse.wheel * 0.1;
            if (FlxG.camera.zoom < 0.25) FlxG.camera.zoom = 0.25;
            if (FlxG.camera.zoom > 5.0) FlxG.camera.zoom = 5.0;
            roomProps.set("zoom", Std.string(FlxG.camera.zoom));
            if (currentTab == "ROOM" && inputs.exists("zoom") && inputs.get("zoom").visible) {
                inputs.get("zoom").text = Std.string(FlxG.camera.zoom);
            }
        }
        
        if (FlxG.keys.justPressed.LBRACKET) snapGrid = Std.int(Math.max(1, snapGrid / 2));
        if (FlxG.keys.justPressed.RBRACKET) snapGrid = snapGrid * 2;
        if (FlxG.keys.justPressed.G) snapEnabled = !snapEnabled;
        
        var screenX = FlxG.mouse.getScreenPosition(uiCamera).x;
        var screenY = FlxG.mouse.getScreenPosition(uiCamera).y;

        if (FlxG.mouse.justPressed && screenY >= propWindowTop.y && screenY <= propWindowTop.y + 30 && screenX >= propWindowTop.x && screenX <= propWindowTop.x + 300) {
            isDraggingWindow = true;
            dragOffset.set(screenX - propWindowBg.x, screenY - propWindowBg.y);
        }
        if (FlxG.mouse.justReleased) isDraggingWindow = false;
        if (isDraggingWindow) {
            propWindowBg.x = screenX - dragOffset.x;
            propWindowBg.y = screenY - dragOffset.y;
            propWindowTop.x = propWindowBg.x;
            propWindowTop.y = propWindowBg.y;
            
            var cIdx = 0;
            for (member in uiGroup) {
                if (Std.isOfType(member, EditorButton)) {
                    var btn:EditorButton = cast member;
                    if (btn.text == "ROOM" || btn.text == "OBJECT" || btn.text == "ANIMS") {
                        var bx = btn.text == "ROOM" ? 0 : (btn.text == "OBJECT" ? 100 : 200);
                        btn.x = propWindowBg.x + bx;
                        btn.y = propWindowBg.y + 30;
                    }
                } else if (Std.isOfType(member, FlxText) && cast(member, FlxText).text == "PROPERTIES (Drag Here)") {
                    cast(member, FlxText).x = propWindowBg.x + 10;
                    cast(member, FlxText).y = propWindowBg.y + 5;
                }
            }
            
            for (member in nudgeGroup) {
                if (Std.isOfType(member, EditorButton)) {
                    var btn:EditorButton = cast member;
                    var bx = cIdx % 4; var by = Math.floor(cIdx / 4);
                    btn.x = propWindowBg.x + 10 + (bx * 70);
                    btn.y = propWindowBg.y + 520 + (by * 30);
                    cIdx++;
                }
            }
            
            if (addAnimBtn != null) {
                addAnimBtn.x = propWindowBg.x + 10;
                addAnimBtn.y = propWindowBg.y + 470;
            }
            var acIdx = 0;
            for (member in animBtnGroup) {
                var btn:EditorButton = cast member;
                btn.x = propWindowBg.x + 240;
                btn.y = propWindowBg.y + 70 + (acIdx * 65) + 10;
                acIdx++;
            }
        }

        var sX = FlxG.scaleMode.scale.x;
        var sY = FlxG.scaleMode.scale.y;
        for (tf in nativeUIGroup) {
            if (tf.visible) {
                var px = propWindowBg.x + inputOffsetsX.get(tf);
                var py = propWindowBg.y + inputOffsetsY.get(tf);
                tf.x = (px * sX) + FlxG.scaleMode.offset.x;
                tf.y = (py * sY) + FlxG.scaleMode.offset.y;
                tf.scaleX = sX; tf.scaleY = sY;
                
                var lbl = inputLabels.get(tf);
                lbl.x = propWindowBg.x + 5;
                lbl.y = py + 4;
            }
        }
        
        // Real-time object scaling
        if (editingElement != null && inputs.exists("scale_x") && inputs.get("scale_x").visible) {
            var sx = Std.parseFloat(inputs.get("scale_x").text);
            var sy = Std.parseFloat(inputs.get("scale_y").text);
            if (!Math.isNaN(sx) && !Math.isNaN(sy)) {
                if (editingElement.sprite.scale.x != sx || editingElement.sprite.scale.y != sy) {
                    editingElement.sprite.scale.set(sx, sy);
                    if (Std.isOfType(editingElement.sprite, WorldObject)) {
                        cast(editingElement.sprite, WorldObject).updateHitbox();
                    }
                }
            }
        }

        var mousePos = FlxG.mouse.getWorldPosition(FlxG.camera);
        var mx = snapEnabled ? Math.floor(mousePos.x / snapGrid) * snapGrid : mousePos.x;
        var my = snapEnabled ? Math.floor(mousePos.y / snapGrid) * snapGrid : mousePos.y;
        
        ghostCursor.x = mx;
        ghostCursor.y = my;
        ghostCursor.visible = (mode == BUILD && !isMouseOverUI());
        
        if (mode == BUILD && (currentTab == "OBJECT" || currentTab == "ANIMATIONS") && inputs.exists("sprite") && inputs.get("sprite").visible) {
            var spriteStr = StringTools.trim(inputs.get("sprite").text);
            
            var sx = inputs.exists("scale_x") && inputs.get("scale_x").visible ? Std.parseFloat(inputs.get("scale_x").text) : 1.0;
            var sy = inputs.exists("scale_y") && inputs.get("scale_y").visible ? Std.parseFloat(inputs.get("scale_y").text) : 1.0;
            if (Math.isNaN(sx)) sx = 1.0;
            if (Math.isNaN(sy)) sy = 1.0;
            
            if (spriteStr != lastSpriteStr || sx != lastScaleX || sy != lastScaleY) {
                lastSpriteStr = spriteStr;
                lastScaleX = sx;
                lastScaleY = sy;
                
                var basePath = roomProps.get("folder") != "" ? roomProps.get("folder") + "/" : "";
                var pathPng = "assets/" + basePath + spriteStr + ".png";
                var pathXml = "assets/" + basePath + spriteStr + ".xml";
                
                ghostCursor.frames = null;
                if (openfl.utils.Assets.exists(pathXml)) {
                    ghostCursor.frames = FlxAtlasFrames.fromSparrow(pathPng, pathXml);
                    if (ghostCursor.frames != null) {
                        if (ghostCursor.animation.getByName("editor_preview") == null) ghostCursor.animation.addByPrefix("editor_preview", "", 12, true);
                        ghostCursor.animation.play("editor_preview");
                    }
                } else if (openfl.utils.Assets.exists(pathPng)) {
                    ghostCursor.loadGraphic(pathPng);
                } else {
                    ghostCursor.makeGraphic(32, 32, FlxColor.YELLOW);
                }
                
                ghostCursor.scale.set(sx, sy);
                ghostCursor.updateHitbox();
                
                if (currentTool == PLAYER || currentTool == NPC || currentTool == FOLLOWER) {
                    ghostCursor.offset.set(ghostCursor.width / 2, ghostCursor.height);
                } else if (currentTool != SOLID) {
                    var boxHeight = ghostCursor.height * 0.825;
                    var yOffset = ghostCursor.height - boxHeight;
                    ghostCursor.setSize(ghostCursor.width, boxHeight);
                    ghostCursor.offset.set(0, yOffset);
                } else {
                    ghostCursor.offset.set(0, 0);
                }
            }
        }
        
        if (!isTyping && FlxG.mouse.justPressed && !isMouseOverUI() && !isDraggingWindow) {
            if (mode == BUILD) placeObject(mx, my);
            else if (mode == EDIT) selectObjectToEdit(mousePos);
            else if (mode == DELETE) deleteObject(mousePos);
        }
    }

    function isMouseOverUI():Bool {
        var screenY = FlxG.mouse.getScreenPosition(uiCamera).y;
        var screenX = FlxG.mouse.getScreenPosition(uiCamera).x;
        var overTop = screenY < 40;
        var overWindow = screenX >= propWindowBg.x && screenX <= propWindowBg.x + 300 && screenY >= propWindowBg.y && screenY <= propWindowBg.y + 600;
        return overTop || overWindow;
    }

    function placeObject(x:Float, y:Float) {
        saveState();
        applyCurrentInputs();
        
        var targetZ:Int = inputs.exists("z") && inputs.get("z").visible ? Std.parseInt(inputs.get("z").text) : 10;
        for (el in elements) {
            if (el.x == x && el.y == y) targetZ = Std.int(Math.max(targetZ, el.z + 1));
        }
        if (inputs.exists("z") && inputs.get("z").visible) inputs.get("z").text = Std.string(targetZ);
        
        var placedSprite:FlxSprite = null;
        var propsData = new Map<String, String>();
        
        var showList = [];
        if (currentTool == SOLID) showList = ["solid_w", "solid_h"];
        else if (currentTool == SPRITE || currentTool == PLAYER || currentTool == NPC) showList = ["name", "sprite", "z", "scale_x", "scale_y", "collision", "interactable", "dialog"];
        else if (currentTool == ANIM_SPRITE) showList = ["name", "sprite", "z", "scale_x", "scale_y", "collision", "interactable"];
        else if (currentTool == FOLLOWER) showList = ["name", "sprite", "z", "scale_x", "scale_y", "target", "distance"];
        
        for (key in showList) {
            if (inputs.exists(key)) propsData.set(key, StringTools.trim(inputs.get(key).text));
        }
        if (currentTool == ANIM_SPRITE) {
            propsData.set("anim_data", templateAnimData);
        }

        var sName = propsData.exists("name") ? propsData.get("name") : "obj";
        
        // Auto-increment name logic to prevent duplicates
        var finalName = sName;
        var suffixCount = 1;
        var nameExists = true;
        while(nameExists) {
            nameExists = false;
            for (el in elements) {
                if (el.props.exists("name") && el.props.get("name") == finalName) {
                    nameExists = true;
                    break;
                }
            }
            if (nameExists) {
                finalName = sName + "_" + suffixCount;
                suffixCount++;
            }
        }
        propsData.set("name", finalName);
        sName = finalName;
        if (inputs.exists("name") && inputs.get("name").visible) {
            inputs.get("name").text = finalName;
        }

        var basePath = roomProps.get("folder") != "" ? "/" + roomProps.get("folder") : "";
        var spriteName = propsData.exists("sprite") ? propsData.get("sprite") : "";

        if (currentTool == SOLID) {
            placedSprite = new CollisionBlock(x, y, Std.parseInt(propsData.get("solid_w")), Std.parseInt(propsData.get("solid_h")));
            placedSprite.makeGraphic(Std.int(placedSprite.width), Std.int(placedSprite.height), FlxColor.TRANSPARENT);
            FlxSpriteUtil.drawRect(placedSprite, 0, 0, placedSprite.width, placedSprite.height, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.RED});
        } else if (currentTool == PLAYER) {
            var p = new Player(x, y, targetZ, sName);
            p.loadEntity(basePath, spriteName);
            p.canMove = false; p.moves = false; 
            placedSprite = p;
        } else if (currentTool == NPC) {
            var n = new CharacterEntity(x, y, targetZ, sName);
            n.loadEntity(basePath, spriteName);
            n.moves = false;
            placedSprite = n;
        } else if (currentTool == FOLLOWER) {
            var f = new Follower(x, y, targetZ, sName);
            f.loadEntity(basePath, spriteName);
            f.moves = false;
            placedSprite = f;
        } else {
            var o = new WorldObject(x, y, targetZ, sName);
            o.loadEntity(basePath, spriteName);
            placedSprite = o;
        }
        
        var sx = propsData.exists("scale_x") ? Std.parseFloat(propsData.get("scale_x")) : 1.0;
        var sy = propsData.exists("scale_y") ? Std.parseFloat(propsData.get("scale_y")) : 1.0;
        if (Math.isNaN(sx)) sx = 1.0;
        if (Math.isNaN(sy)) sy = 1.0;
        placedSprite.scale.set(sx, sy);
        if (Std.isOfType(placedSprite, WorldObject)) cast(placedSprite, WorldObject).updateHitbox();

        insert(members.indexOf(uiGroup), placedSprite);
        elements.push(new PlacedElement(currentTool, x, y, targetZ, placedSprite, propsData));
    }

    function isOverlappedManual(el:PlacedElement, pt:FlxPoint):Bool {
        var w = el.sprite.frameWidth > 0 ? el.sprite.frameWidth : el.sprite.width;
        var h = el.sprite.frameHeight > 0 ? el.sprite.frameHeight : el.sprite.height;
        var ox = el.sprite.offset.x;
        var oy = el.sprite.offset.y;
        
        return (pt.x >= el.sprite.x - ox) && (pt.x <= el.sprite.x - ox + w) && 
               (pt.y >= el.sprite.y - oy) && (pt.y <= el.sprite.y - oy + h);
    }

    function selectObjectToEdit(mousePos:FlxPoint) {
        applyCurrentInputs();
        for (el in elements) {
            if (isOverlappedManual(el, mousePos)) {
                editingElement = el;
                currentTool = el.type; 
                switchTab(currentTab == "ANIMATIONS" ? "ANIMATIONS" : "OBJECT", true); 
                return;
            }
        }
        editingElement = null;
        nudgeGroup.visible = false;
        switchTab(currentTab, true);
    }

    function deleteObject(mousePos:FlxPoint) {
        for (i in 0...elements.length) {
            if (isOverlappedManual(elements[i], mousePos)) {
                saveState();
                elements[i].sprite.destroy();
                elements.splice(i, 1);
                break;
            }
        }
    }

    function setMode(newMode:EditorMode) {
        if (newMode != EDIT) {
            applyCurrentInputs();
            editingElement = null; 
            switchTab(currentTab, true);
        }
        mode = newMode;
        ghostCursor.visible = (mode == BUILD);
        nudgeGroup.visible = (mode == EDIT && editingElement != null && currentTab == "OBJECT");
    }

    function setTool(tool:EditorTool) {
        var oldSprite = inputs.get("sprite").text;
        currentTool = tool;
        setMode(BUILD);
        switchTab("OBJECT");
        
        inputs.get("sprite").text = oldSprite;
        ghostCursor.makeGraphic(32, 32, 0xFFFFFFFF);
        ghostCursor.alpha = 0.5;
        switch (currentTool) {
            case PLAYER: ghostCursor.color = FlxColor.BLUE;
            case NPC: ghostCursor.color = FlxColor.GREEN;
            case FOLLOWER: ghostCursor.color = FlxColor.CYAN;
            case SPRITE: ghostCursor.color = FlxColor.YELLOW;
            case ANIM_SPRITE: ghostCursor.color = FlxColor.ORANGE;
            case SOLID: 
                ghostCursor.makeGraphic(32, 32, FlxColor.TRANSPARENT);
                FlxSpriteUtil.drawRect(ghostCursor, 0, 0, 32, 32, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.RED});
        }
        lastSpriteStr = "";
        lastScaleX = 1.0;
        lastScaleY = 1.0;
    }

    function handleCameraMovement() {
        if (FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A) FlxG.camera.scroll.x -= 15;
        if (FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D) FlxG.camera.scroll.x += 15;
        if (FlxG.keys.pressed.UP || FlxG.keys.pressed.W) FlxG.camera.scroll.y -= 15;
        if (FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S) FlxG.camera.scroll.y += 15;
    }

    override public function destroy():Void {
        for (tf in nativeUIGroup) FlxG.stage.removeChild(tf);
        super.destroy();
    }

    function generateXMLString():String {
        applyCurrentInputs();
        var xml = '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE lacie-engine-room>\n';
        xml += '<room name="${roomProps.get("room_name")}" folder="${roomProps.get("folder")}">\n';
        xml += '    <camera zoom="${roomProps.get("zoom")}" />\n\n';

        for (el in elements) {
            var p = el.props;
            var interactStr = (p.exists("interactable") && p.get("interactable") == "true") ? '\n        <interaction interactable="true" dialog="${p.get("dialog")}" />' : "";
            var animStr = "";
            var scaleStr = "";
            
            if (p.exists("scale_x") && p.exists("scale_y") && (p.get("scale_x") != "1.0" || p.get("scale_y") != "1.0")) {
                scaleStr = '\n        <scale x="${p.get("scale_x")}" y="${p.get("scale_y")}" />';
            }

            if (el.type == ANIM_SPRITE && p.exists("anim_data")) {
                var anims = p.get("anim_data").split("|");
                for (a in anims) {
                    var parts = a.split(",");
                    if (parts.length >= 4 && parts[0] != "") {
                        animStr += '\n        <anim name="${StringTools.trim(parts[0])}" anim="${StringTools.trim(parts[1])}" fps="${StringTools.trim(parts[2])}" loop="${StringTools.trim(parts[3])}" />';
                    }
                }
            }

            var colStr = (p.exists("collision") && p.get("collision") == "false") ? ' collision="false"' : '';
            var innerContent = scaleStr + animStr + interactStr;
            var closing = innerContent == "" ? " />\n" : ">" + innerContent + "\n    </" + getTagName(el.type) + ">\n";
            switch (el.type) {
                case PLAYER, NPC, SPRITE, ANIM_SPRITE: 
                    xml += '    <${getTagName(el.type)} name="${p.get("name")}" x="${el.x}" y="${el.y}" z="${el.z}" sprite="${p.get("sprite")}"${colStr}$closing';
                case FOLLOWER: 
                    xml += '    <follower name="${p.get("name")}" x="${el.x}" y="${el.y}" z="${el.z}" sprite="${p.get("sprite")}"${colStr}>\n        <target name="${p.get("target")}" distance="${p.get("distance")}" />$innerContent\n    </follower>\n';
                case SOLID: 
                    xml += '    <solid x="${el.x}" y="${el.y}" width="${p.get("solid_w")}" height="${p.get("solid_h")}" />\n';
            }
        }
        xml += "</room>";
        return xml;
    }

    function saveXML() {
        var fr = new FileReference();
        fr.save(generateXMLString(), roomProps.get("room_name") + ".xml");
    }

    function loadXML() {
        fileOpener = new FileReference();
        fileOpener.addEventListener(Event.SELECT, function(e) { fileOpener.load(); });
        fileOpener.addEventListener(Event.COMPLETE, function(e) {
            saveState(); 
            parseLoadedXML(fileOpener.data.toString(), true);
        });
        fileOpener.browse([new FileFilter("XML Files", "*.xml")]);
    }

    function parseLoadedXML(xmlStr:String, clearOld:Bool = true) {
        if (clearOld) {
            for (el in elements) { remove(el.sprite); el.sprite.destroy(); }
            elements = [];
        }
        
        editingElement = null;
        xmlStr = StringTools.replace(xmlStr, "<!DOCTYPE lacie-engine-room>", "");
        var parsed = Xml.parse(xmlStr).firstElement();
        if (parsed == null) return;
        var xml = new Access(parsed);
        roomProps.set("room_name", xml.has.name ? xml.att.name : "custom_room");
        roomProps.set("folder", xml.has.folder ? xml.att.folder : "");
        if (xml.hasNode.camera && xml.node.camera.has.zoom) {
            roomProps.set("zoom", xml.node.camera.att.zoom);
            var zVal = Std.parseFloat(xml.node.camera.att.zoom);
            if (!Math.isNaN(zVal) && zVal > 0) FlxG.camera.zoom = zVal;
        } else {
            roomProps.set("zoom", "1.0");
            FlxG.camera.zoom = 1.0;
        }

        if (xml.hasNode.solid) {
            for (node in xml.nodes.solid) {
                var props = new Map<String, String>();
                props.set("solid_w", node.has.width ? node.att.width : "32");
                props.set("solid_h", node.has.height ? node.att.height : "32");
                
                var x = node.has.x ? Std.parseFloat(node.att.x) : 0;
                var y = node.has.y ? Std.parseFloat(node.att.y) : 0;
                var z = node.has.z ? Std.parseInt(node.att.z) : 10;
                var spr = new CollisionBlock(x, y, Std.parseInt(props.get("solid_w")), Std.parseInt(props.get("solid_h")));
                spr.makeGraphic(Std.int(spr.width), Std.int(spr.height), FlxColor.TRANSPARENT);
                FlxSpriteUtil.drawRect(spr, 0, 0, spr.width, spr.height, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.RED});
                
                insert(members.indexOf(uiGroup), spr);
                elements.push(new PlacedElement(SOLID, x, y, z, spr, props));
            }
        }

        inline function parseEntity(node:Access, type:EditorTool) {
            var props = new Map<String, String>();
            props.set("name", node.has.name ? node.att.name : "obj");
            props.set("z", node.has.z ? node.att.z : "10");
            props.set("sprite", node.has.sprite ? node.att.sprite : "default");
            if (node.has.collision) props.set("collision", node.att.collision);
            
            if (node.hasNode.scale) {
                props.set("scale_x", node.node.scale.has.x ? node.node.scale.att.x : "1.0");
                props.set("scale_y", node.node.scale.has.y ? node.node.scale.att.y : "1.0");
            } else {
                props.set("scale_x", "1.0");
                props.set("scale_y", "1.0");
            }
            
            if (node.hasNode.interaction) {
                props.set("interactable", node.node.interaction.att.interactable);
                if (node.node.interaction.has.dialog) props.set("dialog", node.node.interaction.att.dialog);
            }
            if (node.hasNode.anim) {
                type = ANIM_SPRITE;
                var animStrs = [];
                for (animNode in node.nodes.anim) animStrs.push('${animNode.att.name},${animNode.att.anim},${animNode.has.fps?animNode.att.fps:"12"},${animNode.has.loop?animNode.att.loop:"true"}');
                props.set("anim_data", animStrs.join("|"));
            }
            if (type == FOLLOWER && node.hasNode.target) {
                props.set("target", node.node.target.att.name);
                props.set("distance", node.node.target.att.distance);
            }
            
            var x = node.has.x ? Std.parseFloat(node.att.x) : 0;
            var y = node.has.y ? Std.parseFloat(node.att.y) : 0;
            var z = node.has.z ? Std.parseInt(node.att.z) : 10;
            var basePath = roomProps.get("folder") != "" ? "/" + roomProps.get("folder") : "";
            
            var spr:FlxSprite;
            if (type == PLAYER) {
                var p = new Player(x, y, z, props.get("name"));
                p.loadEntity(basePath, props.get("sprite"));
                p.canMove = false; p.moves = false;
                spr = p;
            } else if (type == NPC) {
                var n = new CharacterEntity(x, y, z, props.get("name"));
                n.loadEntity(basePath, props.get("sprite"));
                n.moves = false;
                spr = n;
            } else if (type == FOLLOWER) {
                var f = new Follower(x, y, z, props.get("name"));
                f.loadEntity(basePath, props.get("sprite"));
                f.moves = false;
                spr = f;
            } else {
                var o = new WorldObject(x, y, z, props.get("name"));
                o.loadEntity(basePath, props.get("sprite"));
                spr = o;
            }
            
            spr.scale.set(Std.parseFloat(props.get("scale_x")), Std.parseFloat(props.get("scale_y")));
            if (Std.isOfType(spr, WorldObject)) cast(spr, WorldObject).updateHitbox();
            
            insert(members.indexOf(uiGroup), spr);
            elements.push(new PlacedElement(type, x, y, z, spr, props));
        }

        if (xml.hasNode.sprite) for (node in xml.nodes.sprite) parseEntity(node, SPRITE);
        if (xml.hasNode.player) for (node in xml.nodes.player) parseEntity(node, PLAYER);
        if (xml.hasNode.npc) for (node in xml.nodes.npc) parseEntity(node, NPC);
        if (xml.hasNode.follower) for (node in xml.nodes.follower) parseEntity(node, FOLLOWER);
        
        switchTab("ROOM", true);
    }

    function runPlaytest() {
        applyCurrentInputs();
        for (tf in nativeUIGroup) { tf.visible = false; inputLabels.get(tf).visible = false; }
        openSubState(new PlaytestSubState(generateXMLString()));
    }

    function getTagName(type:EditorTool):String {
        return switch(type) {
            case PLAYER: "player";
            case NPC: "npc";
            case FOLLOWER: "follower";
            case SPRITE, ANIM_SPRITE: "sprite";
            case SOLID: "solid";
        }
    }
}

class PlaytestSubState extends FlxSubState {
    var room:backend.RoomManager;
    var rawXML:String;
    var hintText:FlxText;
    public function new(xml:String) {
        super();
        rawXML = xml;
    }

    override public function create() {
        super.create();
        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        bg.scrollFactor.set(0, 0);
        add(bg);

        room = new backend.RoomManager();
        room.loadRoomFromString(rawXML);
        add(room);
        add(room.solids);
        if (room.activePlayer != null) {
            FlxG.camera.follow(room.activePlayer, TOPDOWN, 0.1);
            FlxG.camera.zoom = room.roomZoom;
        }

        hintText = new FlxText(10, 10, 0, "PLAYTESTING - Press ESC to return to Editor", 24);
        hintText.color = FlxColor.YELLOW;
        hintText.scrollFactor.set(0, 0);
        
        var ptCam = new flixel.FlxCamera();
        ptCam.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(ptCam, false);
        hintText.cameras = [ptCam];
        
        add(hintText);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (FlxG.keys.justPressed.ESCAPE) {
            FlxG.camera.target = null;
            FlxG.camera.follow(null);
            FlxG.camera.zoom = 1.0;
            room.destroy();
            remove(room);
            close();
        }

        if (room != null && room.activePlayer != null && backend.Controls.ACCEPT_P) {
            var box = room.activePlayer.getInteractionBox();
            for (entity in room.entities) {
                if (entity.interactable && box.overlaps(entity.getHitbox())) {
                    openSubState(new backend.DialogueManager("assets/" + entity.dialogPath + ".xml", "start"));
                    break;
                }
            }
            box.put();
        }
    }
}