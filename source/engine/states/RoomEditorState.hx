package engine.states;

enum EditorMode { BUILD; EDIT; DELETE; }
enum EditorTool { PLAYER; NPC; FOLLOWER; SPRITE; ANIM_SPRITE; SOLID; TILE; }

class PlacedElement {
    public var type:EditorTool;
    public var x:Float;
    public var y:Float;
    public var z:Int;
    public var sprite:FlxSprite;
    public var props:Map<String, String>;
    
    public function new(t:EditorTool, px:Float, py:Float, pz:Int, s:FlxSprite, p:Map<String, String>) { 
        type = t; x = px; y = py; z = pz; sprite = s; props = p;
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
        label.x = x; label.y = y + (height - label.height) / 2;
        var cam = (cameras != null && cameras.length > 0) ? cameras[0] : FlxG.camera;
        var screenPos = FlxG.mouse.getScreenPosition(cam);
        var isHovered = (screenPos.x >= x && screenPos.x <= x + width && screenPos.y >= y && screenPos.y <= y + height);
        alpha = isHovered ? 0.7 : 1.0;
        if (isHovered && FlxG.mouse.justPressed && onClick != null) onClick();
        screenPos.put();
    }
    
    override public function draw() { super.draw(); label.draw(); }
    override public function set_camera(cam:FlxCamera):FlxCamera { label.camera = cam; return super.set_camera(cam); }
    function get_text():String return label.text;
    function set_text(val:String):String return label.text = val;
}

class RoomEditorState extends FlxState {
    var mode:EditorMode = BUILD;
    var currentTool:EditorTool = PLAYER;
    var elements:Array<PlacedElement> = [];
    var ghostCursor:FlxSprite;
    var originCrosshair:FlxSprite;
    var gridBg:FlxSprite;
    
    var snapGrid:Int = 32;
    var snapEnabled:Bool = true;
    var lastSpriteStr:String = "";
    var lastScaleX:Float = 1.0;
    var lastScaleY:Float = 1.0;
    
    var workspaceCam:FlxCamera;
    var uiCamera:FlxCamera;
    
    var propWindowBg:FlxSprite;
    var propWindowTop:FlxSprite;
    var tileWindowBg:FlxSprite;
    var tileWindowTop:FlxSprite;
    var tileWinTitle:FlxText;
    
    var isDraggingWindow:Bool = false;
    var isDraggingTileWin:Bool = false;
    var dragOffset:FlxPoint = FlxPoint.get();
    
    var uiGroup:FlxGroup;
    var nudgeGroup:FlxGroup;
    var animBtnGroup:FlxGroup;
    var tilePaletteGroup:FlxGroup;
    var tileButtons:FlxGroup;
    
    var browseBtn:EditorButton;
    var btnLoadTres:EditorButton;
    var btnPrevTile:EditorButton;
    var btnNextTile:EditorButton;
    
    var loadedTresNames:Array<String> = [];
    var loadedTresData:Map<String, Array<{name:String, path:String}>> = new Map();
    var currentTresIndex:Int = -1;
    var txtTresName:FlxText;
    var btnPrevTres:EditorButton;
    var btnNextTres:EditorButton;
    var tilePage:Int = 0;

    var animCountText:FlxText;
    var currentAnimIndex:Int = 0;
    var templateAnimData:String = "idle,Idle Dance,24,true"; 

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
        FlxG.mouse.useSystemCursor = true;
        FlxG.mouse.visible = true;

        workspaceCam = new FlxCamera();
        workspaceCam.bgColor = 0xFF1A365D; 
        FlxG.cameras.reset(workspaceCam);
        FlxCamera.defaultCameras = [workspaceCam];

        uiCamera = new FlxCamera();
        uiCamera.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(uiCamera, false);

        gridBg = new FlxSprite(0, 0).makeGraphic(4000, 4000, 0xFF1A365D);
        for (i in 0...Std.int(4000/32)) {
            FlxSpriteUtil.drawLine(gridBg, i*32, 0, i*32, 4000, {thickness: 1, color: 0xFF2B6CB0});
            FlxSpriteUtil.drawLine(gridBg, 0, i*32, 4000, i*32, {thickness: 1, color: 0xFF2B6CB0});
        }
        add(gridBg);
        
        ghostCursor = new FlxSprite();
        add(ghostCursor);
        
        originCrosshair = new FlxSprite().makeGraphic(3, 3, FlxColor.RED);
        add(originCrosshair);

        uiGroup = new FlxGroup(); uiGroup.cameras = [uiCamera]; add(uiGroup);
        nudgeGroup = new FlxGroup(); nudgeGroup.cameras = [uiCamera]; add(nudgeGroup);
        animBtnGroup = new FlxGroup(); animBtnGroup.cameras = [uiCamera]; add(animBtnGroup);
        tilePaletteGroup = new FlxGroup(); tilePaletteGroup.cameras = [uiCamera]; add(tilePaletteGroup);
        tileButtons = new FlxGroup(); tileButtons.cameras = [uiCamera]; tilePaletteGroup.add(tileButtons);

        buildGDUI();
        buildDraggablePropertyWindow();
        buildTilePaletteWindow();
        setTool(PLAYER);
        saveState();
    }

    function buildGDUI():Void {
        var topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 40, 0xDD000000);
        uiGroup.add(topBar);

        createBtn(10, 5, 60, 30, "BUILD", 0xFF225588, function() { setMode(BUILD); });
        createBtn(75, 5, 60, 30, "EDIT", 0xFF225588, function() { setMode(EDIT); });
        createBtn(140, 5, 60, 30, "DEL", 0xFF882222, function() { setMode(DELETE); });
        
        createBtn(220, 5, 60, 30, "PLAYER", 0xFF555555, function() { setTool(PLAYER); });
        createBtn(285, 5, 50, 30, "NPC", 0xFF555555, function() { setTool(NPC); });
        createBtn(340, 5, 70, 30, "FOLLOW", 0xFF555555, function() { setTool(FOLLOWER); });
        createBtn(415, 5, 60, 30, "SPRITE", 0xFF555555, function() { setTool(SPRITE); });
        createBtn(480, 5, 60, 30, "ANIM", 0xFF555555, function() { setTool(ANIM_SPRITE); });
        createBtn(545, 5, 60, 30, "SOLID", 0xFF555555, function() { setTool(SOLID); });
        createBtn(610, 5, 60, 30, "TILE", 0xFF8855AA, function() { setTool(TILE); });
        
        createBtn(FlxG.width - 380, 5, 80, 30, "LOAD TSCN", 0xFF225588, loadTSCN);
        createBtn(FlxG.width - 290, 5, 80, 30, "SAVE XML", 0xFF228822, saveXML);
        createBtn(FlxG.width - 200, 5, 80, 30, "LOAD XML", 0xFF885522, loadXML);
        createBtn(FlxG.width - 110, 5, 100, 30, "PLAYTEST", 0xFF22AAAA, runPlaytest);
    }

    function createBtn(x:Float, y:Float, w:Int, h:Int, txt:String, color:Int, cb:Void->Void, ?grp:FlxGroup):EditorButton {
        var btn = new EditorButton(x, y, w, h, txt, color, cb);
        if (grp != null) grp.add(btn); else uiGroup.add(btn);
        return btn;
    }

    function buildDraggablePropertyWindow() {
        propWindowBg = new FlxSprite(FlxG.width - 320, 60).makeGraphic(300, 600, 0xEE222222);
        uiGroup.add(propWindowBg);
        
        propWindowTop = new FlxSprite(propWindowBg.x, propWindowBg.y).makeGraphic(300, 30, 0xFF444444);
        uiGroup.add(propWindowTop);
        uiGroup.add(new FlxText(propWindowTop.x + 10, propWindowTop.y + 5, 0, "PROPERTIES (Drag Here)", 12));
        
        createBtn(propWindowBg.x, propWindowBg.y + 30, 100, 25, "ROOM", 0xFF444444, function() { switchTab("ROOM"); });
        createBtn(propWindowBg.x + 100, propWindowBg.y + 30, 100, 25, "OBJECT", 0xFF444444, function() { switchTab("OBJECT"); });
        createBtn(propWindowBg.x + 200, propWindowBg.y + 30, 100, 25, "ANIMS", 0xFF444444, function() { switchTab("ANIMATIONS"); });

        createInputField("name", "Name:", "", 10, 70);
        createInputField("sprite", "Sprite:", "", 10, 110, 120);
        browseBtn = createBtn(propWindowBg.x + 220, propWindowBg.y + 110, 65, 24, "BROWSE", 0xFF225588, openAssetBrowser);

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
        
        createBtn(propWindowBg.x + 10, propWindowBg.y + 70, 30, 30, "<", 0xFF555555, cycleAnimPrev, animBtnGroup);
        animCountText = new FlxText(propWindowBg.x + 50, propWindowBg.y + 75, 200, "Anim 1 / 1", 16);
        animCountText.alignment = CENTER;
        animBtnGroup.add(animCountText);
        createBtn(propWindowBg.x + 260, propWindowBg.y + 70, 30, 30, ">", 0xFF555555, cycleAnimNext, animBtnGroup);

        createInputField("fnf_name", "Anim Name:", "idle", 10, 110);
        createInputField("fnf_prefix", "Prefix/Frames:", "Idle Dance", 10, 150);
        createInputField("fnf_fps", "Framerate:", "24", 10, 190);
        createInputField("fnf_loop", "Looping:", "true", 10, 230);
        
        createInputField("hframes", "H-Frames:", "1", 10, 270, 40, 65);
        createInputField("vframes", "V-Frames:", "1", 135, 270, 40, 65);

        createBtn(propWindowBg.x + 10, propWindowBg.y + 310, 135, 30, "ADD ANIM", 0xFF228822, addNewAnim, animBtnGroup);
        createBtn(propWindowBg.x + 155, propWindowBg.y + 310, 135, 30, "DEL ANIM", 0xFF882222, deleteCurrentAnim, animBtnGroup);
        createBtn(propWindowBg.x + 10, propWindowBg.y + 350, 135, 30, "PLAY PREVIEW", 0xFF225588, playPreviewAnim, animBtnGroup);
        createBtn(propWindowBg.x + 155, propWindowBg.y + 350, 135, 30, "EXPORT GRID XML", 0xFF2255AA, exportGridXML, animBtnGroup);

        createBtn(10, 520, 65, 20, "Left (1)", 0xFF555555, function() { nudge(-snapGrid, 0); }, nudgeGroup);
        createBtn(80, 520, 65, 20, "Right (1)", 0xFF555555, function() { nudge(snapGrid, 0); }, nudgeGroup);
        createBtn(150, 520, 65, 20, "Up (1)", 0xFF555555, function() { nudge(0, -snapGrid); }, nudgeGroup);
        createBtn(220, 520, 65, 20, "Down (1)", 0xFF555555, function() { nudge(0, snapGrid); }, nudgeGroup);

        switchTab("OBJECT");
    }

    function buildTilePaletteWindow() {
        tileWindowBg = new FlxSprite(10, 60).makeGraphic(200, 530, 0xEE222222);
        tilePaletteGroup.add(tileWindowBg);
        
        tileWindowTop = new FlxSprite(tileWindowBg.x, tileWindowBg.y).makeGraphic(200, 30, 0xFF444444);
        tilePaletteGroup.add(tileWindowTop);
        
        tileWinTitle = new FlxText(tileWindowTop.x + 10, tileWindowTop.y + 5, 0, "TILE PALETTE (Drag)", 12);
        tilePaletteGroup.add(tileWinTitle);
        
        btnLoadTres = createBtn(tileWindowBg.x + 10, tileWindowBg.y + 40, 180, 25, "LOAD .TRES", 0xFF8855AA, openTresBrowser, tilePaletteGroup);
        
        btnPrevTres = createBtn(tileWindowBg.x + 10, tileWindowBg.y + 75, 20, 20, "<", 0xFF555555, cycleTresPrev, tilePaletteGroup);
        txtTresName = new FlxText(tileWindowBg.x + 35, tileWindowBg.y + 78, 130, "No Tres Loaded", 10);
        txtTresName.alignment = CENTER; tilePaletteGroup.add(txtTresName);
        btnNextTres = createBtn(tileWindowBg.x + 170, tileWindowBg.y + 75, 20, 20, ">", 0xFF555555, cycleTresNext, tilePaletteGroup);
        
        btnPrevTile = createBtn(tileWindowBg.x + 10, tileWindowBg.y + 495, 85, 25, "PREV", 0xFF444444, function() { if (tilePage > 0) { tilePage--; refreshTilePalette(); } }, tilePaletteGroup);
        btnNextTile = createBtn(tileWindowBg.x + 105, tileWindowBg.y + 495, 85, 25, "NEXT", 0xFF444444, function() { if (currentTresIndex >= 0 && (tilePage + 1) * 8 < loadedTresData.get(loadedTresNames[currentTresIndex]).length) { tilePage++; refreshTilePalette(); } }, tilePaletteGroup);
        
        tilePaletteGroup.visible = false;
    }

    function createInputField(id:String, labelStr:String, def:String, offsetX:Float, offsetY:Float, inputW:Int = 180, labelW:Int = 80) {
        var format = new TextFormat("Arial", 14, 0x000000);
        var input = new TextField();
        input.type = TextFieldType.INPUT;
        inputOffsetsX.set(input, offsetX + labelW + 5);
        inputOffsetsY.set(input, offsetY);
        input.width = inputW; input.height = 24;
        input.background = true; input.backgroundColor = 0xFFFFFF;
        input.text = def; input.name = id; input.defaultTextFormat = format;
        
        var lbl = new FlxText(0, 0, labelW, labelStr, 12);
        lbl.alignment = RIGHT; 
        uiGroup.add(lbl);
        inputLabels.set(input, lbl);
        
        FlxG.stage.addChild(input);
        inputs.set(id, input); 
        nativeUIGroup.push(input);
    }

    function getActiveAnimArray():Array<String> {
        var str = (editingElement != null && editingElement.props.exists("anim_data")) ? editingElement.props.get("anim_data") : templateAnimData;
        var arr = str != "" ? str.split("|") : [];
        if (arr.length == 0) arr.push("idle,Idle Dance,24,true");
        return arr;
    }
    function setActiveAnimArray(anims:Array<String>) {
        var str = anims.join("|");
        if (editingElement != null) editingElement.props.set("anim_data", str); else templateAnimData = str;
    }
    function saveAnimFromUI() {
        if (!inputs.exists("fnf_name") || !inputs.get("fnf_name").visible) return;
        var anims = getActiveAnimArray();
        if (currentAnimIndex >= 0 && currentAnimIndex < anims.length) {
            anims[currentAnimIndex] = '${inputs.get("fnf_name").text},${inputs.get("fnf_prefix").text},${inputs.get("fnf_fps").text},${inputs.get("fnf_loop").text}';
            setActiveAnimArray(anims);
        }
    }
    function loadAnimToUI() {
        var anims = getActiveAnimArray();
        if (currentAnimIndex >= anims.length) currentAnimIndex = Math.floor(Math.max(0, anims.length - 1));
        if (currentAnimIndex < 0) currentAnimIndex = 0;
        animCountText.text = 'Anim ${currentAnimIndex + 1} / ${anims.length}';
        if (anims.length > 0) {
            var parts = anims[currentAnimIndex].split(",");
            showField("fnf_name", parts.length > 0 ? parts[0] : "idle"); 
            showField("fnf_prefix", parts.length > 1 ? parts[1] : "Idle Dance");
            showField("fnf_fps", parts.length > 2 ? parts[2] : "24"); 
            showField("fnf_loop", parts.length > 3 ? parts[3] : "true");
        }
    }
    function cycleAnimPrev() { saveAnimFromUI(); currentAnimIndex--; loadAnimToUI(); playPreviewAnim(); }
    function cycleAnimNext() { saveAnimFromUI(); currentAnimIndex++; loadAnimToUI(); playPreviewAnim(); }
    function addNewAnim() { saveAnimFromUI(); var anims = getActiveAnimArray(); anims.push("newAnim,New Prefix,24,true"); setActiveAnimArray(anims); currentAnimIndex = anims.length - 1; loadAnimToUI(); }
    function deleteCurrentAnim() { var anims = getActiveAnimArray(); if (anims.length > 1) { anims.splice(currentAnimIndex, 1); setActiveAnimArray(anims); loadAnimToUI(); } }
    
    function exportGridXML() {
        applyCurrentInputs();
        var spriteStr = inputs.get("sprite").text;
        if (spriteStr == "") return;
        var basePath = roomProps.get("folder") != "" ? roomProps.get("folder") + "/" : "";
        var pathPng = "assets/" + basePath + spriteStr + ".png";
        if (openfl.utils.Assets.exists("assets/" + spriteStr + ".png")) pathPng = "assets/" + spriteStr + ".png";
        if (!openfl.utils.Assets.exists(pathPng)) return;
        
        var bmp = openfl.utils.Assets.getBitmapData(pathPng);
        var hf = inputs.exists("hframes") ? Std.parseInt(inputs.get("hframes").text) : 1;
        var vf = inputs.exists("vframes") ? Std.parseInt(inputs.get("vframes").text) : 1;
        if (hf == null || hf < 1) hf = 1; if (vf == null || vf < 1) vf = 1;
        
        var fw = Math.floor(bmp.width / hf);
        var fh = Math.floor(bmp.height / vf);
        var total = hf * vf;
        var prefix = inputs.exists("fnf_prefix") ? inputs.get("fnf_prefix").text : "frame";
        
        var xml = '<?xml version="1.0" encoding="utf-8"?>\n<TextureAtlas imagePath="${spriteStr.split("/").pop()}.png">\n';
        for (i in 0...total) {
            var px = (i % hf) * fw;
            var py = Math.floor(i / hf) * fh;
            var num = StringTools.lpad(Std.string(i), "0", 4);
            xml += '  <SubTexture name="${prefix}${num}" x="${px}" y="${py}" width="${fw}" height="${fh}" frameX="0" frameY="0" frameWidth="${fw}" frameHeight="${fh}" />\n';
        }
        xml += '</TextureAtlas>';
        
        var fr = new FileReference();
        fr.save(xml, spriteStr.split("/").pop() + ".xml");
    }

    function playPreviewAnim() {
        saveAnimFromUI();
        var spriteStr = inputs.get("sprite").text;
        var basePath = roomProps.get("folder") != "" ? roomProps.get("folder") + "/" : "";
        var pathPng = "assets/" + basePath + spriteStr + ".png";
        if (openfl.utils.Assets.exists("assets/" + spriteStr + ".png")) pathPng = "assets/" + spriteStr + ".png";
        var pathXml = "assets/" + basePath + spriteStr + ".xml";

        var hframes = inputs.exists("hframes") ? Std.parseInt(inputs.get("hframes").text) : 1;
        var vframes = inputs.exists("vframes") ? Std.parseInt(inputs.get("vframes").text) : 1;
        if (hframes == null || hframes < 1) hframes = 1; if (vframes == null || vframes < 1) vframes = 1;

        if (openfl.utils.Assets.exists(pathPng)) {
            var anims = getActiveAnimArray();
            ghostCursor.frames = null;
            ghostCursor.animation.destroyAnimations();

            if (hframes > 1 || vframes > 1) {
                var tempBmp = openfl.utils.Assets.getBitmapData(pathPng);
                var fw = Math.floor(tempBmp.width / hframes); var fh = Math.floor(tempBmp.height / vframes);
                ghostCursor.loadGraphic(pathPng, true, fw, fh);
                for (a in anims) {
                    var parts = a.split(",");
                    if (parts.length >= 4) {
                        var indices = [];
                        for (s in parts[1].split(" ")) if (Std.parseInt(s) != null) indices.push(Std.parseInt(s));
                        ghostCursor.animation.add(parts[0], indices, Std.parseInt(parts[2]), parts[3] == "true");
                    }
                }
            } else if (openfl.utils.Assets.exists(pathXml)) {
                ghostCursor.frames = FlxAtlasFrames.fromSparrow(pathPng, pathXml);
                for (a in anims) {
                    var parts = a.split(",");
                    if (parts.length >= 4) ghostCursor.animation.addByPrefix(parts[0], parts[1], Std.parseInt(parts[2]), parts[3] == "true");
                }
            } else ghostCursor.loadGraphic(pathPng);

            if (anims.length > 0 && ghostCursor.animation.getByName(anims[currentAnimIndex].split(",")[0]) != null) {
                ghostCursor.animation.play(anims[currentAnimIndex].split(",")[0], true);
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

        if (FlxG.mouse.wheel != 0 && !isMouseOverUI()) {
            workspaceCam.zoom += FlxG.mouse.wheel * 0.1;
            if (workspaceCam.zoom < 0.25) workspaceCam.zoom = 0.25; 
            if (workspaceCam.zoom > 5.0) workspaceCam.zoom = 5.0;
            roomProps.set("zoom", Std.string(workspaceCam.zoom));
            if (currentTab == "ROOM" && inputs.exists("zoom") && inputs.get("zoom").visible) inputs.get("zoom").text = Std.string(workspaceCam.zoom);
        }
        
        if (FlxG.keys.justPressed.LBRACKET) snapGrid = Std.int(Math.max(1, snapGrid / 2));
        if (FlxG.keys.justPressed.RBRACKET) snapGrid = snapGrid * 2;
        if (FlxG.keys.justPressed.G) snapEnabled = !snapEnabled;
        
        gridBg.visible = snapEnabled;
        handleWindowDragging();
        updateNativeTextFieldPositions();
        
        var mouseWorld = FlxG.mouse.getWorldPosition(workspaceCam);
        var mx = snapEnabled ? Math.floor(mouseWorld.x / snapGrid) * snapGrid : mouseWorld.x;
        var my = snapEnabled ? Math.floor(mouseWorld.y / snapGrid) * snapGrid : mouseWorld.y;
        
        ghostCursor.x = mx; ghostCursor.y = my;
        originCrosshair.x = mx - 1; originCrosshair.y = my - 1;
        updateGhostCursor();
        
        if (!isTyping && !isMouseOverUI() && !isDraggingWindow && !isDraggingTileWin && subState == null) {
            if (mode == BUILD) {
                if (currentTool == TILE && FlxG.mouse.pressed) placeObject(mx, my);
                else if (FlxG.mouse.justPressed) placeObject(mx, my);
            } 
            else if (mode == EDIT && FlxG.mouse.justPressed) selectObjectToEdit(mouseWorld);
            else if (mode == DELETE) {
                if (currentTool == TILE && FlxG.mouse.pressed) deleteObject(mouseWorld);
                else if (FlxG.mouse.justPressed) deleteObject(mouseWorld);
            }
        }
        mouseWorld.put();
    }

    function updateGhostCursor() {
        if (mode != BUILD || isMouseOverUI() || subState != null) { 
            ghostCursor.visible = false; originCrosshair.visible = false; return; 
        }
        ghostCursor.visible = true; originCrosshair.visible = true;

        var spriteStr = inputs.exists("sprite") ? StringTools.trim(inputs.get("sprite").text) : "";
        var sx = inputs.exists("scale_x") && inputs.get("scale_x").visible ? Std.parseFloat(inputs.get("scale_x").text) : 1.0;
        var sy = inputs.exists("scale_y") && inputs.get("scale_y").visible ? Std.parseFloat(inputs.get("scale_y").text) : 1.0;
        if (Math.isNaN(sx)) sx = 1.0; if (Math.isNaN(sy)) sy = 1.0;

        if (spriteStr != lastSpriteStr || sx != lastScaleX || sy != lastScaleY) {
            lastSpriteStr = spriteStr; lastScaleX = sx; lastScaleY = sy;
            var basePath = roomProps.get("folder") != "" ? roomProps.get("folder") + "/" : "";
            var pathPng = "assets/" + basePath + spriteStr + ".png";
            if (openfl.utils.Assets.exists("assets/" + spriteStr + ".png")) pathPng = "assets/" + spriteStr + ".png";
            
            ghostCursor.frames = null; ghostCursor.animation.destroyAnimations();
            
            if (currentTool == ANIM_SPRITE) playPreviewAnim();
            else if (openfl.utils.Assets.exists(pathPng)) {
                var hframes = inputs.exists("hframes") ? Std.parseInt(inputs.get("hframes").text) : 1;
                var vframes = inputs.exists("vframes") ? Std.parseInt(inputs.get("vframes").text) : 1;
                if (hframes == null || hframes < 1) hframes = 1; if (vframes == null || vframes < 1) vframes = 1;
                
                if (hframes > 1 || vframes > 1) {
                    var tempBmp = openfl.utils.Assets.getBitmapData(pathPng);
                    ghostCursor.loadGraphic(pathPng, true, Math.floor(tempBmp.width/hframes), Math.floor(tempBmp.height/vframes));
                } else ghostCursor.loadGraphic(pathPng);
            } else ghostCursor.makeGraphic(32, 32, FlxColor.YELLOW);
            
            ghostCursor.alpha = 0.5; ghostCursor.scale.set(sx, sy); ghostCursor.updateHitbox();
            
            ghostCursor.offset.set(0,0); ghostCursor.origin.set(0,0);
        }
    }

    function placeObject(x:Float, y:Float) {
        applyCurrentInputs();
        if (currentTool == TILE) for (el in elements) if (el.type == TILE && el.x == x && el.y == y) return; 

        saveState();
        var targetZ:Int = inputs.exists("z") && inputs.get("z").visible ? Std.parseInt(inputs.get("z").text) : (currentTool == TILE ? 0 : 10);
        var propsData = new Map<String, String>();
        
        var showList = [];
        if (currentTool == SOLID) showList = ["solid_w", "solid_h"];
        else if (currentTool == SPRITE || currentTool == PLAYER || currentTool == NPC || currentTool == TILE) showList = ["name", "sprite", "z", "scale_x", "scale_y", "collision", "interactable", "dialog"];
        else if (currentTool == ANIM_SPRITE) showList = ["name", "sprite", "z", "scale_x", "scale_y", "hframes", "vframes", "collision", "interactable"];
        else if (currentTool == FOLLOWER) showList = ["name", "sprite", "z", "scale_x", "scale_y", "target", "distance"];
        
        for (key in showList) if (inputs.exists(key)) propsData.set(key, StringTools.trim(inputs.get(key).text));
        if (currentTool == ANIM_SPRITE) propsData.set("anim_data", getActiveAnimArray().join("|"));

        var sName = propsData.exists("name") ? propsData.get("name") : (currentTool == TILE ? 'tile_${x}_${y}' : "obj");
        if (currentTool != TILE) {
            var finalName = sName; var suffixCount = 1; var nameExists = true;
            while(nameExists) {
                nameExists = false;
                for (el in elements) if (el.props.exists("name") && el.props.get("name") == finalName) { nameExists = true; break; }
                if (nameExists) finalName = sName + "_" + suffixCount++;
            }
            propsData.set("name", finalName); sName = finalName;
            if (inputs.exists("name") && inputs.get("name").visible) inputs.get("name").text = finalName;
        }

        var basePath = roomProps.get("folder") != "" ? "/" + roomProps.get("folder") : "";
        var spriteName = propsData.exists("sprite") ? propsData.get("sprite") : "";
        var placedSprite:FlxSprite = null;

        if (currentTool == SOLID) {
            placedSprite = new CollisionBlock(x, y, Std.parseInt(propsData.get("solid_w")), Std.parseInt(propsData.get("solid_h")));
            placedSprite.makeGraphic(Std.int(placedSprite.width), Std.int(placedSprite.height), FlxColor.TRANSPARENT);
            FlxSpriteUtil.drawRect(placedSprite, 0, 0, placedSprite.width, placedSprite.height, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.RED});
        } else if (currentTool == PLAYER) {
            var p = new Player(x, y, targetZ, sName); p.loadEntity(basePath, spriteName); p.canMove = false; p.moves = false; placedSprite = p;
        } else if (currentTool == NPC) {
            var n = new CharacterEntity(x, y, targetZ, sName); n.loadEntity(basePath, spriteName); n.moves = false; placedSprite = n;
        } else if (currentTool == FOLLOWER) {
            var f = new Follower(x, y, targetZ, sName); f.loadEntity(basePath, spriteName); f.moves = false; placedSprite = f;
        } else {
            var o = new WorldObject(x, y, targetZ, sName); o.loadEntity(basePath, spriteName); placedSprite = o;
        }
        
        var sx = propsData.exists("scale_x") ? Std.parseFloat(propsData.get("scale_x")) : 1.0;
        var sy = propsData.exists("scale_y") ? Std.parseFloat(propsData.get("scale_y")) : 1.0;
        if (Math.isNaN(sx)) sx = 1.0; if (Math.isNaN(sy)) sy = 1.0;
        placedSprite.scale.set(sx, sy);
        if (Std.isOfType(placedSprite, WorldObject)) cast(placedSprite, WorldObject).updateHitbox();

        placedSprite.cameras = [workspaceCam];
        insert(members.indexOf(uiGroup), placedSprite);
        elements.push(new PlacedElement(currentTool, x, y, targetZ, placedSprite, propsData));
    }

    function selectObjectToEdit(mouseWorld:FlxPoint) {
        applyCurrentInputs();
        for (el in elements) {
            if (el.sprite.overlapsPoint(mouseWorld, true, workspaceCam)) {
                editingElement = el; currentTool = el.type; switchTab(currentTab == "ANIMATIONS" ? "ANIMATIONS" : "OBJECT", true); return;
            }
        }
        editingElement = null; nudgeGroup.visible = false; switchTab(currentTab, true);
    }
    
    function deleteObject(mouseWorld:FlxPoint) { 
        for (i in 0...elements.length) { 
            if (elements[i].sprite.overlapsPoint(mouseWorld, true, workspaceCam)) { 
                saveState(); elements[i].sprite.destroy(); elements.splice(i, 1); break; 
            } 
        } 
    }

    function switchTab(tab:String, skipApply:Bool = false) {
        if (!skipApply) applyCurrentInputs();
        currentTab = tab;
        
        for (tf in nativeUIGroup) { tf.visible = false; inputLabels.get(tf).visible = false; }
        nudgeGroup.visible = false; animBtnGroup.visible = false; browseBtn.visible = false;
        tilePaletteGroup.visible = (currentTool == TILE);
        
        if (tab == "ROOM") {
            showField("room_name", roomProps.get("room_name")); showField("folder", roomProps.get("folder")); showField("zoom", roomProps.get("zoom"));
        } else if (tab == "ANIMATIONS") {
            if (currentTool == ANIM_SPRITE || (editingElement != null && editingElement.type == ANIM_SPRITE)) { animBtnGroup.visible = true; loadAnimToUI(); }
        } else {
            var showList = [];
            if (currentTool == SOLID) showList = ["solid_w", "solid_h"];
            else if (currentTool == SPRITE || currentTool == PLAYER || currentTool == NPC || currentTool == TILE) showList = ["name", "sprite", "z", "scale_x", "scale_y", "collision", "interactable", "dialog"];
            else if (currentTool == ANIM_SPRITE) showList = ["name", "sprite", "z", "scale_x", "scale_y", "collision", "interactable"];
            else if (currentTool == FOLLOWER) showList = ["name", "sprite", "z", "scale_x", "scale_y", "target", "distance"];
            
            var defaults = editingElement != null ? editingElement.props : new Map<String, String>();
            var yOffset = 70;
            for (key in showList) {
                var def = defaults.exists(key) ? defaults.get(key) : (inputs.exists(key) ? inputs.get(key).text : "");
                showField(key, def, yOffset); yOffset += 40;
            }
            if (showList.indexOf("sprite") != -1) browseBtn.visible = true;
            if (mode == EDIT && editingElement != null) nudgeGroup.visible = true;
        }
    }

    function showField(id:String, val:String, ?newY:Float) {
        if (!inputs.exists(id)) return;
        var tf = inputs.get(id); tf.visible = true; tf.text = val; inputLabels.get(tf).visible = true;
        if (newY != null) inputOffsetsY.set(tf, newY);
    }
    
    function applyCurrentInputs() {
        if (currentTab == "ROOM") {
            if (inputs.exists("room_name")) roomProps.set("room_name", inputs.get("room_name").text);
            if (inputs.exists("folder")) roomProps.set("folder", inputs.get("folder").text);
            if (inputs.exists("zoom")) { 
                roomProps.set("zoom", inputs.get("zoom").text); 
                var zVal = Std.parseFloat(inputs.get("zoom").text); 
                if (!Math.isNaN(zVal) && zVal > 0) workspaceCam.zoom = zVal; 
            }
        } else if (currentTab == "ANIMATIONS") {
            if (currentTool == ANIM_SPRITE || (editingElement != null && editingElement.type == ANIM_SPRITE)) saveAnimFromUI();
        } 
        
        if (editingElement != null) {
            for (key in inputs.keys()) if (inputs.get(key).visible && !StringTools.startsWith(key, "fnf_")) editingElement.props.set(key, inputs.get(key).text);
            if (editingElement.type == SOLID && inputs.get("solid_w").visible) {
                var sw = Std.parseInt(inputs.get("solid_w").text); var sh = Std.parseInt(inputs.get("solid_h").text);
                if (sw > 0 && sh > 0) { editingElement.sprite.makeGraphic(sw, sh, FlxColor.TRANSPARENT); FlxSpriteUtil.drawRect(editingElement.sprite, 0, 0, sw, sh, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.RED}); }
            }
            if (inputs.exists("scale_x") && inputs.get("scale_x").visible) {
                var sx = Std.parseFloat(inputs.get("scale_x").text); var sy = Std.parseFloat(inputs.get("scale_y").text);
                if (Math.isNaN(sx)) sx = 1.0; if (Math.isNaN(sy)) sy = 1.0;
                editingElement.sprite.scale.set(sx, sy); if (Std.isOfType(editingElement.sprite, WorldObject)) cast(editingElement.sprite, WorldObject).updateHitbox();
            }
        }
    }
    
    function setMode(newMode:EditorMode) { if (newMode != EDIT) { applyCurrentInputs(); editingElement = null; switchTab(currentTab, true); } mode = newMode; nudgeGroup.visible = (mode == EDIT && editingElement != null && currentTab == "OBJECT"); }
    function setTool(tool:EditorTool) {
        var oldSprite = inputs.get("sprite").text; currentTool = tool; setMode(BUILD); switchTab("OBJECT"); inputs.get("sprite").text = oldSprite; lastSpriteStr = ""; lastScaleX = 1.0; lastScaleY = 1.0;
    }

    function cycleTresPrev() { if (loadedTresNames.length == 0) return; currentTresIndex--; if(currentTresIndex < 0) currentTresIndex = loadedTresNames.length - 1; tilePage = 0; refreshTilePalette(); }
    function cycleTresNext() { if (loadedTresNames.length == 0) return; currentTresIndex++; if(currentTresIndex >= loadedTresNames.length) currentTresIndex = 0; tilePage = 0; refreshTilePalette(); }

    function refreshTilePalette() {
        tileButtons.clear();
        if (currentTresIndex < 0 || loadedTresNames.length == 0) { txtTresName.text = "No Tres Loaded"; return; }
        
        var curTres = loadedTresNames[currentTresIndex];
        txtTresName.text = curTres.split("/").pop();
        var tList = loadedTresData.get(curTres);

        var itemsPerPage = 8;
        var start = tilePage * itemsPerPage;
        var end = Std.int(Math.min(start + itemsPerPage, tList.length));
        
        var idx = 0;
        for (i in start...end) {
            var t = tList[i];
            var btnY = tileWindowBg.y + 105 + (idx * 48);
            var btn = new EditorButton(tileWindowBg.x + 10, btnY, 180, 42, t.name, 0xFF333333, function() {
                if (inputs.exists("sprite")) inputs.get("sprite").text = t.path;
                lastSpriteStr = "";
                applyCurrentInputs();
            });
            btn.label.alignment = LEFT; btn.label.x += 40; btn.cameras = [uiCamera];
            tileButtons.add(btn);
            
            if (openfl.utils.Assets.exists("assets/" + t.path + ".png")) {
                var prev = new FlxSprite(btn.x + 5, btn.y + 5).loadGraphic("assets/" + t.path + ".png");
                prev.setGraphicSize(32, 32); prev.updateHitbox(); prev.cameras = [uiCamera];
                tileButtons.add(prev);
            }
            idx++;
        }
    }

    function generateXMLString():String {
        applyCurrentInputs();
        var xml = '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE lily-engine-room>\n<room name="${roomProps.get("room_name")}" folder="${roomProps.get("folder")}">\n    <camera zoom="${roomProps.get("zoom")}" />\n\n';
        
        for (el in elements) {
            var p = el.props; 
            var interactStr = (p.exists("interactable") && p.get("interactable") == "true") ? '\n        <interaction interactable="true" dialog="${p.get("dialog")}" />' : "";
            var scaleStr = ""; var animStr = ""; var gridStr = "";

            if (p.exists("scale_x") && p.exists("scale_y") && (p.get("scale_x") != "1.0" || p.get("scale_y") != "1.0")) scaleStr = '\n        <scale x="${p.get("scale_x")}" y="${p.get("scale_y")}" />';
            if (p.exists("hframes") && p.exists("vframes") && (p.get("hframes") != "1" || p.get("vframes") != "1")) gridStr = ' hframes="${p.get("hframes")}" vframes="${p.get("vframes")}"';
            
            if (el.type == ANIM_SPRITE && p.exists("anim_data")) {
                for (a in p.get("anim_data").split("|")) { 
                    var parts = a.split(","); 
                    if (parts.length >= 4 && parts[0] != "") animStr += '\n        <anim name="${StringTools.trim(parts[0])}" anim="${StringTools.trim(parts[1])}" fps="${StringTools.trim(parts[2])}" loop="${StringTools.trim(parts[3])}" />'; 
                }
            }

            var colStr = (p.exists("collision") && p.get("collision") == "false") ? ' collision="false"' : '';
            var innerContent = scaleStr + animStr + interactStr; 
            var closing = innerContent == "" ? " />\n" : ">" + innerContent + "\n    </" + getTagName(el.type) + ">\n";
            
            switch (el.type) {
                case PLAYER, NPC, SPRITE, ANIM_SPRITE: xml += '    <${getTagName(el.type)} name="${p.get("name")}" x="${el.x}" y="${el.y}" z="${el.z}" sprite="${p.get("sprite")}"${gridStr}${colStr}$closing';
                case TILE: xml += '    <sprite name="${p.get("name")}" x="${el.x}" y="${el.y}" z="${el.z}" sprite="${p.get("sprite")}" layer="bg"${gridStr}${colStr}$closing';
                case FOLLOWER: xml += '    <follower name="${p.get("name")}" x="${el.x}" y="${el.y}" z="${el.z}" sprite="${p.get("sprite")}"${gridStr}${colStr}>\n        <target name="${p.get("target")}" distance="${p.get("distance")}" />$innerContent\n    </follower>\n';
                case SOLID: xml += '    <solid x="${el.x}" y="${el.y}" width="${p.get("solid_w")}" height="${p.get("solid_h")}" />\n';
            }
        }
        return xml + "</room>";
    }

    function saveState() { undoStack.push(generateXMLString()); if (undoStack.length > 50) undoStack.shift(); redoStack = []; }
    function undo() { if (undoStack.length > 1) { redoStack.push(undoStack.pop()); parseLoadedXML(undoStack[undoStack.length - 1], false); } }
    function redo() { if (redoStack.length > 0) { var state = redoStack.pop(); undoStack.push(state); parseLoadedXML(state, false); } }
    function nudge(dx:Float, dy:Float) { if (editingElement != null) { saveState(); editingElement.x += dx; editingElement.y += dy; editingElement.sprite.x = editingElement.x; editingElement.sprite.y = editingElement.y; } }
    function saveXML() { var fr = new FileReference(); fr.save(generateXMLString(), roomProps.get("room_name") + ".xml"); }
    function loadXML() { fileOpener = new FileReference(); fileOpener.addEventListener(Event.SELECT, function(e) { fileOpener.load(); }); fileOpener.addEventListener(Event.COMPLETE, function(e) { saveState(); parseLoadedXML(fileOpener.data.toString(), true); }); fileOpener.browse([new FileFilter("XML Files", "*.xml")]); }
    
    function loadTSCN() { 
        var tscnFile = new FileReference(); 
        tscnFile.addEventListener(Event.SELECT, function(e) { tscnFile.load(); }); 
        tscnFile.addEventListener(Event.COMPLETE, function(e) { saveState(); parseTSCN(tscnFile.data.toString()); }); 
        tscnFile.browse([new FileFilter("Godot Scene", "*.tscn")]); 
    }

    function parseTSCN(data:String) {
        var lines = data.split("\n"); var extMap = new Map<String, String>();
        var nodes = []; var curNode:Dynamic = null;

        for (line in lines) {
            line = StringTools.trim(line);
            if (StringTools.startsWith(line, "[ext_resource")) {
                var id = extractGodotAttr(line, "id");
                var path = extractGodotAttr(line, "path");
                path = StringTools.replace(StringTools.replace(path, "res://", ""), ".png", "");
                extMap.set(id, path);
            } else if (StringTools.startsWith(line, "[node")) {
                if (curNode != null && curNode.tex != null) nodes.push(curNode);
                curNode = {name: extractGodotAttr(line, "name"), type: extractGodotAttr(line, "type"), x: 0.0, y: 0.0, sx: 1.0, sy: 1.0, tex: null, hframes: 1, vframes: 1, z: 10};
            } else if (curNode != null) {
                if (StringTools.startsWith(line, "position = Vector2(")) {
                    var vals = extractVector2(line); curNode.x = vals[0]; curNode.y = vals[1];
                } else if (StringTools.startsWith(line, "scale = Vector2(")) {
                    //var vals = extractsVector2(line); curNode.sx = vals[0]; curNode.sy = vals[1];
                } else if (StringTools.startsWith(line, "z_index = ")) curNode.z = Std.parseInt(line.split("=")[1]);
                else if (StringTools.startsWith(line, "texture = ExtResource(")) curNode.tex = extMap.get(line.split('"')[1]);
                else if (StringTools.startsWith(line, "hframes = ")) curNode.hframes = Std.parseInt(line.split("=")[1]);
                else if (StringTools.startsWith(line, "vframes = ")) curNode.vframes = Std.parseInt(line.split("=")[1]);
            }
        }
        if (curNode != null && curNode.tex != null) nodes.push(curNode);

        for (n in nodes) {
            var props = new Map<String, String>();
            props.set("name", n.name); props.set("sprite", StringTools.replace(n.tex, "assets/", ""));
            props.set("scale_x", Std.string(n.sx)); props.set("scale_y", Std.string(n.sy));
            props.set("hframes", Std.string(n.hframes)); props.set("vframes", Std.string(n.vframes));
            props.set("z", Std.string(n.z));

            var spr = new WorldObject(n.x, n.y, n.z, n.name);
            spr.loadEntity("", props.get("sprite")); spr.scale.set(n.sx, n.sy); spr.updateHitbox(); spr.cameras = [workspaceCam];
            insert(members.indexOf(uiGroup), spr); elements.push(new PlacedElement(SPRITE, n.x, n.y, n.z, spr, props));
        }
        switchTab("ROOM", true);
    }
    
    function extractGodotAttr(line:String, attr:String):String {
        var idx = line.indexOf(attr + '="'); if (idx == -1) return "";
        var start = idx + attr.length + 2; return line.substring(start, line.indexOf('"', start));
    }
    function extractVector2(line:String):Array<Float> {
        var p = line.substring(line.indexOf("(") + 1, line.indexOf(")")).split(","); return [Std.parseFloat(p[0]), Std.parseFloat(p[1])];
    }

    function parseLoadedXML(xmlStr:String, clearOld:Bool = true) {
        if (clearOld) { for (el in elements) { remove(el.sprite); el.sprite.destroy(); } elements = []; }
        editingElement = null; xmlStr = StringTools.replace(xmlStr, "<!DOCTYPE lily-engine-room>", "");
        var parsed = Xml.parse(xmlStr).firstElement(); if (parsed == null) return;
        var xml = new Access(parsed);
        
        roomProps.set("room_name", xml.has.name ? xml.att.name : "custom_room");
        roomProps.set("folder", xml.has.folder ? xml.att.folder : "");
        if (xml.hasNode.camera && xml.node.camera.has.zoom) { roomProps.set("zoom", xml.node.camera.att.zoom); workspaceCam.zoom = Std.parseFloat(xml.node.camera.att.zoom); } else { roomProps.set("zoom", "1.0"); workspaceCam.zoom = 1.0; }

        if (xml.hasNode.solid) {
            for (node in xml.nodes.solid) {
                var props = new Map<String, String>();
                props.set("solid_w", node.has.width ? node.att.width : "32"); props.set("solid_h", node.has.height ? node.att.height : "32");
                var x = node.has.x ? Std.parseFloat(node.att.x) : 0; var y = node.has.y ? Std.parseFloat(node.att.y) : 0; var z = node.has.z ? Std.parseInt(node.att.z) : 10;
                var spr = new CollisionBlock(x, y, Std.parseInt(props.get("solid_w")), Std.parseInt(props.get("solid_h")));
                spr.makeGraphic(Std.int(spr.width), Std.int(spr.height), FlxColor.TRANSPARENT);
                FlxSpriteUtil.drawRect(spr, 0, 0, spr.width, spr.height, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.RED});
                spr.cameras = [workspaceCam]; insert(members.indexOf(uiGroup), spr); elements.push(new PlacedElement(SOLID, x, y, z, spr, props));
            }
        }

        var parseEntity = function(node:Access, type:EditorTool) {
            var props = new Map<String, String>();
            props.set("name", node.has.name ? node.att.name : "obj"); props.set("z", node.has.z ? node.att.z : "10"); props.set("sprite", node.has.sprite ? node.att.sprite : "default");
            props.set("hframes", node.has.hframes ? node.att.hframes : "1"); props.set("vframes", node.has.vframes ? node.att.vframes : "1");
            if (node.has.collision) props.set("collision", node.att.collision);
            if (node.hasNode.scale) { props.set("scale_x", node.node.scale.has.x ? node.node.scale.att.x : "1.0"); props.set("scale_y", node.node.scale.has.y ? node.node.scale.att.y : "1.0"); } else { props.set("scale_x", "1.0"); props.set("scale_y", "1.0"); }
            if (node.hasNode.interaction) { props.set("interactable", node.node.interaction.att.interactable); if (node.node.interaction.has.dialog) props.set("dialog", node.node.interaction.att.dialog); }
            if (node.hasNode.anim) { type = ANIM_SPRITE; var animStrs = []; for (animNode in node.nodes.anim) { var fps = animNode.has.fps ? animNode.att.fps : "24"; var loop = animNode.has.loop ? animNode.att.loop : "true"; animStrs.push('${animNode.att.name},${animNode.att.anim},$fps,$loop'); } props.set("anim_data", animStrs.join("|")); }
            if (type == FOLLOWER && node.hasNode.target) { props.set("target", node.node.target.att.name); props.set("distance", node.node.target.has.distance ? node.node.target.att.distance : "30"); }
            if (node.has.layer && node.att.layer == "bg") type = TILE;

            var x = node.has.x ? Std.parseFloat(node.att.x) : 0; var y = node.has.y ? Std.parseFloat(node.att.y) : 0; var z = node.has.z ? Std.parseInt(node.att.z) : 10;
            var basePath = roomProps.get("folder") != "" ? "/" + roomProps.get("folder") : "";
            var spr:FlxSprite = null;
            if (type == PLAYER) { var p = new Player(x, y, z, props.get("name")); p.loadEntity(basePath, props.get("sprite")); p.canMove = false; p.moves = false; spr = p; } 
            else if (type == NPC) { var n = new CharacterEntity(x, y, z, props.get("name")); n.loadEntity(basePath, props.get("sprite")); n.moves = false; spr = n; } 
            else if (type == FOLLOWER) { var f = new Follower(x, y, z, props.get("name")); f.loadEntity(basePath, props.get("sprite")); f.moves = false; spr = f; } 
            else { var o = new WorldObject(x, y, z, props.get("name")); o.loadEntity(basePath, props.get("sprite")); spr = o; }
            
            var sx = props.exists("scale_x") ? Std.parseFloat(props.get("scale_x")) : 1.0; var sy = props.exists("scale_y") ? Std.parseFloat(props.get("scale_y")) : 1.0;
            spr.scale.set(sx, sy); if (Std.isOfType(spr, WorldObject)) cast(spr, WorldObject).updateHitbox();
            
            spr.cameras = [workspaceCam]; insert(members.indexOf(uiGroup), spr); elements.push(new PlacedElement(type, x, y, z, spr, props));
        };

        if (xml.hasNode.sprite) for (node in xml.nodes.sprite) parseEntity(node, SPRITE);
        if (xml.hasNode.player) for (node in xml.nodes.player) parseEntity(node, PLAYER);
        if (xml.hasNode.npc) for (node in xml.nodes.npc) parseEntity(node, NPC);
        if (xml.hasNode.follower) for (node in xml.nodes.follower) parseEntity(node, FOLLOWER);
        
        switchTab("ROOM", true);
    }

    function isMouseOverUI():Bool { 
        var screenPos = FlxG.mouse.getScreenPosition(uiCamera); 
        var overProp = screenPos.y < 40 || (screenPos.x >= propWindowBg.x && screenPos.x <= propWindowBg.x + 300 && screenPos.y >= propWindowBg.y && screenPos.y <= propWindowBg.y + 600);
        var overTile = (currentTool == TILE) && (screenPos.x >= tileWindowBg.x && screenPos.x <= tileWindowBg.x + 200 && screenPos.y >= tileWindowBg.y && screenPos.y <= tileWindowBg.y + 530);
        screenPos.put(); return overProp || overTile; 
    }
    
    function handleCameraMovement() { 
        if (FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A) workspaceCam.scroll.x -= 15 / workspaceCam.zoom; 
        if (FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D) workspaceCam.scroll.x += 15 / workspaceCam.zoom; 
        if (FlxG.keys.pressed.UP || FlxG.keys.pressed.W) workspaceCam.scroll.y -= 15 / workspaceCam.zoom; 
        if (FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S) workspaceCam.scroll.y += 15 / workspaceCam.zoom; 
        if (FlxG.mouse.justPressedMiddle) isDraggingWindow = true; else if (FlxG.mouse.releasedMiddle) { isDraggingWindow = false; isDraggingTileWin = false; }
    }
    
    function handleWindowDragging() { 
        var screenPos = FlxG.mouse.getScreenPosition(uiCamera); 
        
        if (FlxG.mouse.justPressed) {
            if (screenPos.y >= propWindowTop.y && screenPos.y <= propWindowTop.y + 30 && screenPos.x >= propWindowTop.x && screenPos.x <= propWindowTop.x + 300) { 
                isDraggingWindow = true; dragOffset.set(screenPos.x - propWindowBg.x, screenPos.y - propWindowBg.y); 
            } else if (currentTool == TILE && screenPos.y >= tileWindowTop.y && screenPos.y <= tileWindowTop.y + 30 && screenPos.x >= tileWindowTop.x && screenPos.x <= tileWindowTop.x + 200) {
                isDraggingTileWin = true; dragOffset.set(screenPos.x - tileWindowBg.x, screenPos.y - tileWindowBg.y);
            }
        }
        
        if (FlxG.mouse.justReleased) { isDraggingWindow = false; isDraggingTileWin = false; }
        
        if (isDraggingWindow && FlxG.mouse.pressed) { 
            propWindowBg.x = screenPos.x - dragOffset.x; propWindowBg.y = screenPos.y - dragOffset.y; 
            propWindowTop.x = propWindowBg.x; propWindowTop.y = propWindowBg.y; 
            for (member in uiGroup) { 
                if (Std.isOfType(member, EditorButton)) { var btn:EditorButton = cast member; if (btn.text == "ROOM" || btn.text == "OBJECT" || btn.text == "ANIMS") { btn.x = propWindowBg.x + (btn.text == "ROOM" ? 0 : (btn.text == "OBJECT" ? 100 : 200)); btn.y = propWindowBg.y + 30; } } 
                else if (Std.isOfType(member, FlxText) && cast(member, FlxText).text == "PROPERTIES (Drag Here)") { cast(member, FlxText).x = propWindowBg.x + 10; cast(member, FlxText).y = propWindowBg.y + 5; } 
            } 
            if (browseBtn != null) { browseBtn.x = propWindowBg.x + 220; browseBtn.y = propWindowBg.y + 110; } 
            var cIdx = 0; for (member in nudgeGroup) { if (Std.isOfType(member, EditorButton)) { var btn:EditorButton = cast member; btn.x = propWindowBg.x + 10 + ((cIdx % 4) * 70); btn.y = propWindowBg.y + 520 + (Math.floor(cIdx / 4) * 30); cIdx++; } } 
            for (member in animBtnGroup) { if (Std.isOfType(member, EditorButton)) { var btn:EditorButton = cast member; if (btn.text == "<") { btn.x = propWindowBg.x + 10; btn.y = propWindowBg.y + 70; } else if (btn.text == ">") { btn.x = propWindowBg.x + 260; btn.y = propWindowBg.y + 70; } else if (btn.text == "ADD ANIM") { btn.x = propWindowBg.x + 10; btn.y = propWindowBg.y + 310; } else if (btn.text == "DEL ANIM") { btn.x = propWindowBg.x + 155; btn.y = propWindowBg.y + 310; } else if (btn.text == "PLAY PREVIEW") { btn.x = propWindowBg.x + 10; btn.y = propWindowBg.y + 350; } else if (btn.text == "EXPORT GRID XML") { btn.x = propWindowBg.x + 155; btn.y = propWindowBg.y + 350; } } else if (Std.isOfType(member, FlxText)) { cast(member, FlxText).x = propWindowBg.x + 50; cast(member, FlxText).y = propWindowBg.y + 75; } } 
        } else if (isDraggingTileWin && FlxG.mouse.pressed) {
            tileWindowBg.x = screenPos.x - dragOffset.x; tileWindowBg.y = screenPos.y - dragOffset.y; 
            tileWindowTop.x = tileWindowBg.x; tileWindowTop.y = tileWindowBg.y;
            tileWinTitle.x = tileWindowBg.x + 10; tileWinTitle.y = tileWindowBg.y + 5;
            btnLoadTres.x = tileWindowBg.x + 10; btnLoadTres.y = tileWindowBg.y + 40;
            btnPrevTres.x = tileWindowBg.x + 10; btnPrevTres.y = tileWindowBg.y + 75;
            txtTresName.x = tileWindowBg.x + 35; txtTresName.y = tileWindowBg.y + 78;
            btnNextTres.x = tileWindowBg.x + 170; btnNextTres.y = tileWindowBg.y + 75;
            btnPrevTile.x = tileWindowBg.x + 10; btnPrevTile.y = tileWindowBg.y + 495;
            btnNextTile.x = tileWindowBg.x + 105; btnNextTile.y = tileWindowBg.y + 495;
            refreshTilePalette();
        }
        screenPos.put(); 
    }

    function updateNativeTextFieldPositions() { 
        var sX = FlxG.scaleMode.scale.x; var sY = FlxG.scaleMode.scale.y; 
        for (tf in nativeUIGroup) { 
            if (tf.visible) { 
                var px = propWindowBg.x + inputOffsetsX.get(tf); var py = propWindowBg.y + inputOffsetsY.get(tf); 
                tf.x = (px * sX) + FlxG.scaleMode.offset.x; tf.y = (py * sY) + FlxG.scaleMode.offset.y; tf.scaleX = sX; tf.scaleY = sY; inputLabels.get(tf).x = propWindowBg.x + 5; inputLabels.get(tf).y = py + 4; 
            } 
        } 
    }

    function openAssetBrowser() {
        for (tf in nativeUIGroup) tf.visible = false;
        openSubState(new AssetBrowserSubState("", function(selectedPath:String) {
            if (selectedPath != "") inputs.get("sprite").text = selectedPath;
            switchTab(currentTab, true);
        }));
    }

    function openTresBrowser() {
        for (tf in nativeUIGroup) tf.visible = false;
        openSubState(new AssetBrowserSubState(".tres", function(selectedPath:String) {
            if (selectedPath != "") parseAndOpenTilePicker(selectedPath);
            else switchTab(currentTab, true);
        }));
    }

    function parseAndOpenTilePicker(tresPath:String) {
        var raw = openfl.utils.Assets.getText(tresPath + ".tres");
        if (raw == null) { switchTab(currentTab, true); return; }
        
        var extMap = new Map<String, String>();
        var lines = raw.split("\n");
        for (line in lines) {
            if (line.indexOf("[ext_resource") != -1 && line.indexOf("type=\"Texture\"") != -1) {
                var pArr = line.split('path="res://');
                if(pArr.length > 1) { 
                    var p = pArr[1].split('"')[0]; var idArr = line.split('id='); 
                    if(idArr.length > 1) { extMap.set(idArr[1].split(']')[0], p); } 
                }
            }
        }
        
        var parsedTiles = new Array<{name:String, path:String}>();
        var curId = ""; var curName = "";
        for (line in lines) {
            if (line.indexOf("/name = ") != -1) { curId = line.split("/name")[0]; curName = line.split('"')[1]; }
            if (line.indexOf("/texture = ExtResource(") != -1) {
                if (line.split("/texture")[0] == curId) {
                    var extId = line.split('ExtResource( ')[1].split(' )')[0];
                    if (extMap.exists(extId)) {
                        var p = StringTools.replace(StringTools.replace(extMap.get(extId), "assets/", ""), ".png", "");
                        parsedTiles.push({name: curName, path: p});
                    }
                }
            }
        }
        
        if (!loadedTresData.exists(tresPath)) loadedTresNames.push(tresPath);
        loadedTresData.set(tresPath, parsedTiles);
        currentTresIndex = loadedTresNames.indexOf(tresPath);
        tilePage = 0;
        switchTab(currentTab, true);
        refreshTilePalette();
    }

    function runPlaytest() {
        applyCurrentInputs();
        for (tf in nativeUIGroup) tf.visible = false;
        openSubState(new PlaytestSubState(generateXMLString(), function() { switchTab(currentTab, true); }));
    }

    function getTagName(type:EditorTool):String { return switch(type) { case PLAYER: "player"; case NPC: "npc"; case FOLLOWER: "follower"; case SPRITE, ANIM_SPRITE, TILE: "sprite"; case SOLID: "solid"; } }
    override public function destroy():Void { for (tf in nativeUIGroup) FlxG.stage.removeChild(tf); super.destroy(); }
}

class AssetBrowserSubState extends FlxSubState {
    var onSelect:String->Void;
    var filterExt:String;
    var allFiles:Array<String> = [];
    var currentPath:String = "";
    
    var page:Int = 0;
    var itemsPerPage:Int;
    var uiCam:FlxCamera;
    var buttons:FlxGroup;
    
    public function new(ext:String, callback:String->Void) { super(); filterExt = ext; onSelect = callback; }

    override public function create() {
        super.create();
        uiCam = new FlxCamera(); uiCam.bgColor = 0xEE000000; FlxG.cameras.add(uiCam, false); cameras = [uiCam];

        add(new FlxSprite(50, 50).makeGraphic(FlxG.width - 100, FlxG.height - 100, 0xFF222222));
        add(new FlxText(60, 60, 0, "Asset Browser", 20));
        add(new EditorButton(FlxG.width - 100, 60, 40, 24, "X", 0xFF882222, function() { onSelect(""); close(); }));

        buttons = new FlxGroup(); add(buttons);
        itemsPerPage = Math.floor((FlxG.height - 200) / 24);

        var rawAssets = openfl.utils.Assets.list(openfl.utils.AssetType.IMAGE).concat(openfl.utils.Assets.list(openfl.utils.AssetType.TEXT));
        for (p in rawAssets) {
            if (filterExt == "" || p.indexOf(filterExt) != -1) {
                var clean = StringTools.replace(p, "assets/", "");
                if (filterExt != "") clean = StringTools.replace(clean, filterExt, "");
                allFiles.push(clean);
            }
        }
        
        add(new EditorButton(60, FlxG.height - 80, 80, 24, "PREV", 0xFF444444, function() { if (page > 0) { page--; refreshList(); } }));
        add(new EditorButton(FlxG.width - 140, FlxG.height - 80, 80, 24, "NEXT", 0xFF444444, function() { page++; refreshList(); }));

        refreshList();
    }

    function refreshList() {
        buttons.clear();
        var items = [];
        if (currentPath != "") items.push({name: "[.. BACK]", isDir: true, path: ""});
        
        var dirs = new Map<String, Bool>();
        for(f in allFiles) {
            if (f.indexOf(currentPath) == 0) {
                var rem = f.substring(currentPath.length);
                var slashIdx = rem.indexOf("/");
                if (slashIdx != -1) {
                    var dirName = rem.substring(0, slashIdx);
                    if (!dirs.exists(dirName)) { dirs.set(dirName, true); items.push({name: "[DIR] " + dirName, isDir: true, path: currentPath + dirName + "/"}); }
                } else {
                    items.push({name: rem, isDir: false, path: f});
                }
            }
        }

        var start = page * itemsPerPage; 
        var end = Std.int(Math.min(start + itemsPerPage, items.length));
        
        for (i in start...end) {
            var it = items[i];
            var row = i - start;
            var w = FlxG.width - 120;
            
            var btn = new EditorButton(60, 100 + (row * 24), Std.int(w), 22, it.name, it.isDir ? 0xFF225588 : 0xFF333333, function() {
                if (it.name == "[.. BACK]") { var p = currentPath.substring(0, currentPath.length - 1); currentPath = p.substring(0, p.lastIndexOf("/") + 1); page = 0; refreshList(); }
                else if (it.isDir) { currentPath = it.path; page = 0; refreshList(); }
                else { onSelect(it.path); close(); }
            });
            btn.label.alignment = LEFT; btn.label.x += 10; buttons.add(btn);
        }
    }
    
    override public function destroy() { FlxG.cameras.remove(uiCam); super.destroy(); }
}

class PlaytestSubState extends FlxSubState {
    var room:RoomManager; var rawXML:String; var onClose:Void->Void; var ptCam:FlxCamera;
    public function new(xml:String, closeCallback:Void->Void) { super(); rawXML = xml; onClose = closeCallback; }
    override public function create() {
        super.create();
        ptCam = new FlxCamera(); ptCam.bgColor = 0xFF000000; FlxG.cameras.add(ptCam, false); cameras = [ptCam];
        room = new RoomManager(); room.loadRoomFromString(rawXML); add(room); add(room.solids);
        if (room.activePlayer != null) { ptCam.follow(room.activePlayer, TOPDOWN, 0.1); ptCam.zoom = room.roomZoom; }
        
        var uiTestCam = new FlxCamera(); uiTestCam.bgColor = FlxColor.TRANSPARENT; FlxG.cameras.add(uiTestCam, false); 
        var hintText = new FlxText(10, 10, 0, "PLAYTESTING - Press ESC to return", 24); hintText.cameras = [uiTestCam]; add(hintText);
    }
    
    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (FlxG.keys.justPressed.ESCAPE) { ptCam.target = null; ptCam.follow(null); FlxG.cameras.remove(ptCam); room.destroy(); remove(room); if (onClose != null) onClose(); close(); }
    }
}