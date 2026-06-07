package engine.ui;

class SpecialNinePatch extends FlxSpriteGroup
{
    public var texture:FlxGraphicAsset;
    public var bgTexture:FlxGraphicAsset;
    public var bgMaskTexture:FlxGraphicAsset;
    public var decorTexture:FlxGraphicAsset;
    public var decorBgTexture:FlxGraphicAsset;

    public var patchMarginLeft:Int = 0;
    public var patchMarginTop:Int = 0;
    public var patchMarginRight:Int = 0;
    public var patchMarginBottom:Int = 0;
    public var decorMarginTop:Float = 0;
    public var decorMarginBottom:Float = 0;
    public var scaleFactor:Float = 1.0;
    public var bgModulate:FlxColor = FlxColor.WHITE;
    public var drawCenter:Bool = true;

    private var targetWidth:Int;
    private var targetHeight:Int;

    public function new(X:Float = 0, Y:Float = 0) { super(X, Y); }

    public function setSizeEx(width:Float, height:Float):Void
    {
        targetWidth = Math.round(width);
        targetHeight = Math.round(height);
        render();
    }

    public function render():Void
    {
        clear();
        if (targetWidth <= 0 || targetHeight <= 0) return;

        if (bgTexture != null)
        {
            var bgSprite = new FlxSprite(0, 0);
            var bgGraphic = FlxG.bitmap.add(bgTexture);

            if (bgGraphic != null)
            {
                var finalBgBmp = new BitmapData(targetWidth, targetHeight, true, 0x00000000);

                var bgMat = new Matrix();
                bgMat.scale(targetWidth / bgGraphic.width, targetHeight / bgGraphic.height);
                finalBgBmp.draw(bgGraphic.bitmap, bgMat, null, null, null, true);

                if (bgMaskTexture != null)
                {
                    var maskGraphic = FlxG.bitmap.add(bgMaskTexture);
                    if (maskGraphic != null)
                    {
                        var maskBmp = new BitmapData(targetWidth, targetHeight, true, 0x00000000);
                        
                        var x0:Int = 0;
                        var x1:Int = Math.round(patchMarginLeft * scaleFactor);
                        var x2:Int = targetWidth - Math.round(patchMarginRight * scaleFactor);
                        var x3:Int = targetWidth;

                        var y0:Int = 0;
                        var y1:Int = Math.round(patchMarginTop * scaleFactor);
                        var y2:Int = targetHeight - Math.round(patchMarginBottom * scaleFactor);
                        var y3:Int = targetHeight;

                        var w0 = x1 - x0;
                        var w1 = x2 - x1;
                        var w2 = x3 - x2;

                        var h0 = y1 - y0;
                        var h1 = y2 - y1;
                        var h2 = y3 - y2;

                        var rS = maskGraphic.width - patchMarginRight;
                        var bS = maskGraphic.height - patchMarginBottom;
                        var mX = maskGraphic.width - patchMarginLeft - patchMarginRight;
                        var mY = maskGraphic.height - patchMarginTop - patchMarginBottom;

                        function drawMaskPiece(rx:Float, ry:Float, rw:Float, rh:Float, dw:Int, dh:Int, px:Int, py:Int) {
                            if (dw <= 0 || dh <= 0 || rw <= 0 || rh <= 0) return;
                            
                            var irw = Math.round(rw);
                            var irh = Math.round(rh);
                            var pieceBmp = new BitmapData(irw, irh, true, 0x00000000);
                            pieceBmp.copyPixels(maskGraphic.bitmap, new Rectangle(rx, ry, irw, irh), new Point(0, 0));
                            
                            var mat = new Matrix();
                            mat.scale(dw / irw, dh / irh);
                            mat.translate(px, py);
                            
                            maskBmp.draw(pieceBmp, mat, null, null, null, true);
                            pieceBmp.dispose();
                        }

                        drawMaskPiece(0, 0, patchMarginLeft, patchMarginTop, w0, h0, x0, y0);
                        drawMaskPiece(patchMarginLeft, 0, mX, patchMarginTop, w1, h0, x1, y0);
                        drawMaskPiece(rS, 0, patchMarginRight, patchMarginTop, w2, h0, x2, y0);
                        drawMaskPiece(0, patchMarginTop, patchMarginLeft, mY, w0, h1, x0, y1);
                        drawMaskPiece(patchMarginLeft, patchMarginTop, mX, mY, w1, h1, x1, y1); 
                        drawMaskPiece(rS, patchMarginTop, patchMarginRight, mY, w2, h1, x2, y1);
                        drawMaskPiece(0, bS, patchMarginLeft, patchMarginBottom, w0, h2, x0, y2);
                        drawMaskPiece(patchMarginLeft, bS, mX, patchMarginBottom, w1, h2, x1, y2);
                        drawMaskPiece(rS, bS, patchMarginRight, patchMarginBottom, w2, h2, x2, y2);

                        finalBgBmp.copyChannel(maskBmp, maskBmp.rect, new Point(0, 0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
                        maskBmp.dispose();
                    }
                }

                bgSprite.loadGraphic(finalBgBmp);
                bgSprite.updateHitbox();
                bgSprite.color = bgModulate;
                bgSprite.antialiasing = true;
                add(bgSprite);
            }
        }

        if (decorBgTexture != null)
        {
            var decorBg = new FlxSprite(0, 0);
            decorBg.loadGraphic(decorBgTexture);
            if (decorBg.graphic != null)
            {
                decorBg.origin.set(0, 0);
                decorBg.scale.set(scaleFactor, scaleFactor);
                decorBg.x = Math.round((targetWidth - (decorBg.width * scaleFactor)) / 2);
                decorBg.y = Math.round((targetHeight - (decorBg.height * scaleFactor)) / 2);
                decorBg.antialiasing = true;
                add(decorBg);
            }
        }

        if (texture != null)
        {
            var g = FlxG.bitmap.add(texture);
            if (g != null)
            {
                var x0:Int = 0;
                var x1:Int = Math.round(patchMarginLeft * scaleFactor);
                var x2:Int = targetWidth - Math.round(patchMarginRight * scaleFactor);
                var x3:Int = targetWidth;

                var y0:Int = 0;
                var y1:Int = Math.round(patchMarginTop * scaleFactor);
                var y2:Int = targetHeight - Math.round(patchMarginBottom * scaleFactor);
                var y3:Int = targetHeight;

                var w0 = x1 - x0;
                var w1 = x2 - x1;
                var w2 = x3 - x2;

                var h0 = y1 - y0;
                var h1 = y2 - y1;
                var h2 = y3 - y2;

                var rS = g.width - patchMarginRight;
                var bS = g.height - patchMarginBottom;
                var mX = g.width - patchMarginLeft - patchMarginRight;
                var mY = g.height - patchMarginTop - patchMarginBottom;

                function addF(rx:Float, ry:Float, rw:Float, rh:Float, dw:Int, dh:Int, px:Int, py:Int) {
                    if (dw <= 0 || dh <= 0) return;
                    var f = new FlxSprite(px, py);
                    f.frames = FlxImageFrame.fromRectangle(g, FlxRect.get(rx, ry, rw, rh));
                    f.setGraphicSize(dw, dh);
                    f.updateHitbox();
                    f.antialiasing = true;
                    add(f);
                }

                addF(0, 0, patchMarginLeft, patchMarginTop, w0, h0, x0, y0);
                addF(patchMarginLeft, 0, mX, patchMarginTop, w1, h0, x1, y0);
                addF(rS, 0, patchMarginRight, patchMarginTop, w2, h0, x2, y0);
                addF(0, patchMarginTop, patchMarginLeft, mY, w0, h1, x0, y1);
                if (drawCenter) addF(patchMarginLeft, patchMarginTop, mX, mY, w1, h1, x1, y1);
                addF(rS, patchMarginTop, patchMarginRight, mY, w2, h1, x2, y1);
                addF(0, bS, patchMarginLeft, patchMarginBottom, w0, h2, x0, y2);
                addF(patchMarginLeft, bS, mX, patchMarginBottom, w1, h2, x1, y2);
                addF(rS, bS, patchMarginRight, patchMarginBottom, w2, h2, x2, y2);
            }
        }
    }
}

class MenuFrameNode extends FlxSpriteGroup
{
    public var nodeFrame:SpecialNinePatch;
    private var titleText:FlxText;
    private var divider:FlxSprite;
    private var hasTitle:Bool = false;

    /**
     * modes:
     * 0 = default frame texture.
     * 1 = second frame texture.
     * 2 = second frame texture with title.
    **/
    public function new(X:Float = 0, Y:Float = 0, targetWidth:Float, targetHeight:Float, mode:Int = 0)
    {
        super(X, Y);
        hasTitle = mode == 2;
        
        nodeFrame = new SpecialNinePatch();
        
        if (mode == 1 || mode == 2)
        {
            nodeFrame.texture = LilyAssets.image("img/ui/frame_menu_2");
            nodeFrame.bgTexture = LilyAssets.image("img/ui/frame_menu_bg");
            nodeFrame.bgMaskTexture = null;
            nodeFrame.patchMarginLeft = 50;
            nodeFrame.patchMarginTop = 50;
            nodeFrame.patchMarginRight = 50;
            nodeFrame.patchMarginBottom = 50;
            nodeFrame.scaleFactor = 0.75;
            
            if (mode == 2) {
                titleText = new FlxText(0, 30, Std.int(targetWidth), 48);
                titleText.alignment = CENTER;
                
                divider = new FlxSprite(0, 90);
                divider.loadGraphic(LilyAssets.image("img/ui/divider_md"));
                divider.scale.set(0.75, 0.75);
                divider.updateHitbox();
                divider.x = (targetWidth - divider.width) / 2;
            }
        }
        else
        {
            nodeFrame.texture = LilyAssets.image("img/ui/frame_default");
            nodeFrame.bgTexture = LilyAssets.image("img/ui/frame_default_bg");
            nodeFrame.bgMaskTexture = LilyAssets.image("img/ui/frame_default_bg_mask");
            nodeFrame.patchMarginLeft = 123;
            nodeFrame.patchMarginTop = 142;
            nodeFrame.patchMarginRight = 123;
            nodeFrame.patchMarginBottom = 120;
            nodeFrame.scaleFactor = 0.45; 
        }

        nodeFrame.setSizeEx(targetWidth, targetHeight);
        add(nodeFrame);
        
        if (mode == 2)
        {
            add(titleText);
            add(divider);
        }
    }

    public function setTitle(text:String):Void
    {
        if (hasTitle && titleText != null) 
        {
            titleText.text = text;
            
            var showTitle = (text != null && text.length > 0);
            titleText.visible = showTitle;
            divider.visible = showTitle;
        }
    }

    public function addMenu(menu:FlxSpriteGroup):Void
    {
        menu.x = 54; 
        menu.y = hasTitle && titleText.visible ? 130 : 36; 
        add(menu);
    }
}

class SimpleVerticalMenu extends FlxSpriteGroup
{
    public var selection:Int = 0;
    private var entries:Array<{caption:String, action:Void->Void}> = [];
    private var visualItems:Array<MenuVisualEntry> = [];

    public function new() { super(); }
    public function drawContent():Void { }

    public function addEntry(caption:String, action:Void->Void):Void
    {
        entries.push({caption: caption, action: action});
    }

    public function buildVisualList(separation:Float = 72):Void
    {
        for (i in 0...entries.length)
        {
            var item = new MenuVisualEntry(0, i * separation, entries[i].caption, 492, Std.int(separation));
            visualItems.push(item);
            add(item);
        }
        highlightSelection();
    }

    public function handleInput():Void
    {
        if (FlxG.keys.anyJustPressed([UP, W]))
        {
            LilyAssets.play("sfx/ui_navigation");
            selection--;
            if (selection < 0) selection = entries.length - 1;
            highlightSelection();
        }
        else if (FlxG.keys.anyJustPressed([DOWN, S]))
        {
            LilyAssets.play("sfx/ui_navigation");
            selection++;
            if (selection >= entries.length) selection = 0;
            highlightSelection();
        }
        else if (FlxG.keys.anyJustPressed([ENTER, SPACE, Z]))
        {
            if (entries[selection] != null) entries[selection].action();
        }
    }

    public function highlightSelection():Void { for (i in 0...visualItems.length) visualItems[i].setHighlight(i == selection); }
    public function resetSelection():Void { selection = 0; highlightSelection(); }
}

class MenuVisualEntry extends FlxSpriteGroup
{
    private var bg:FlxSprite;
    private var label:FlxText;
    private static inline var SELECT_COLOR:FlxColor = 0x33EDDEDE; 

    public function new(X:Float, Y:Float, text:String, width:Float, height:Float)
    {
        super(X, Y);
        bg = new FlxSprite(0, 0);
        bg.makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT);
        add(bg);

        label = new FlxText(0, (height - 48) / 2, width, text, 48);
        label.alignment = CENTER;
        add(label);
    }

    public function setHighlight(isActive:Bool):Void { bg.makeGraphic(Std.int(bg.width), Std.int(bg.height), isActive ? SELECT_COLOR : FlxColor.TRANSPARENT); }
}