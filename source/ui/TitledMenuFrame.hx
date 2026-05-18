package ui;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.FlxSprite;
import openfl.utils.Assets;
import backend.UIUtil;

class TitledMenuFrame extends FlxSpriteGroup {
    public var titleFrame:flixel.addons.ui.FlxUI9SliceSprite;
    public var titleLabel:FlxText;
    public var divider:FlxSprite;
    public var decorBg:FlxSprite;

    // Original C# margins scaled by 3x for 1080p
    static inline var TITLE_MARGIN_TOP:Int = 45; 
    static inline var DIVIDER_MARGIN_TOP:Int = 100;
    static inline var BORDER_PADDING:Int = 12; // Keeps the inner fill inside the frame borders

    public function new(x:Float, y:Float, w:Float, h:Float, titleText:String = "", dividerPath:String = "assets/img/ui/divider_sm.png", decorPath:String = "") {
        super(x, y);

        // 1. Inner Fill (Replaces Godot's BgMaskTexture logic with raw efficiency)
        // Uses the classic Paper Lily burgundy color (UIUtil.MenuBgColor)
        var innerBg = new FlxSprite(BORDER_PADDING, BORDER_PADDING).makeGraphic(Std.int(w - (BORDER_PADDING * 2)), Std.int(h - (BORDER_PADDING * 2)), 0xFF14080E);
        add(innerBg);

        // 2. Decor Background (e.g., menu_bg_decor.png)
        if (decorPath != "" && Assets.exists(decorPath)) {
            decorBg = new FlxSprite(0, 0).loadGraphic(decorPath);
            
            // Scale the decor up 3x to match the 1080p port
            decorBg.setGraphicSize(Std.int(decorBg.width));
            decorBg.updateHitbox();
            
            // LayoutPreset.BottomRight equivalent!
            decorBg.x = w - decorBg.width - BORDER_PADDING;
            decorBg.y = h - decorBg.height - BORDER_PADDING;
            add(decorBg);
        }

        // 3. The 9-Slice Frame (Drawn ON TOP to act as the perfect border/mask)
        var frameImg = "assets/img/ui/frame_menu_2.png";
        if (!Assets.exists(frameImg)) frameImg = "assets/img/ui/frame_main.png"; 
        
        titleFrame = UIUtil.create9SliceSprite(frameImg, 0, 0, w, h, 0.75);
        add(titleFrame);

        // 4. Title Setup
        titleLabel = new FlxText(0, TITLE_MARGIN_TOP, w, titleText, 32);
        titleLabel.alignment = CENTER;
        add(titleLabel);

        // 5. Divider Setup
        divider = new FlxSprite(0, DIVIDER_MARGIN_TOP);
        if (Assets.exists(dividerPath)) {
            divider.loadGraphic(dividerPath);
            // Scale divider 3x to match 1080p natively
            divider.setGraphicSize(Std.int(divider.width));
            divider.updateHitbox();
            divider.x = (w - divider.width) / 2;
        } else {
            divider.makeGraphic(Std.int(w * 0.8), 4, 0xFFE23D6A);
            divider.x = (w - divider.width) / 2;
        }
        add(divider);

        setTitle(titleText);
    }

    public function setTitle(text:String) {
        titleLabel.text = text;
        
        // Hide title elements if the text is empty, mimicking _titleVisible logic
        var isVisible = (text != null && text != "");
        titleLabel.visible = isVisible;
        divider.visible = isVisible;
    }
}