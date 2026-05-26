package ui;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.FlxSprite;
import backend.UIUtil;
import flixel.graphics.FlxGraphic;

class TitledMenuFrame extends FlxSpriteGroup {
    public var titleFrame:flixel.addons.ui.FlxUI9SliceSprite;
    public var titleLabel:FlxText;
    public var divider:FlxSprite;
    public var decorBg:FlxSprite;

    static inline var TITLE_MARGIN_TOP:Int = 45; 
    static inline var DIVIDER_MARGIN_TOP:Int = 100;
    static inline var BORDER_PADDING:Int = 12;

    public function new(x:Float, y:Float, w:Float, h:Float, titleText:String = "", dividerPath:FlxGraphic, decorPath:String = "") {
        super(x, y);

        var innerBg = new FlxSprite(BORDER_PADDING - 10, BORDER_PADDING - 10).makeGraphic(Std.int(w - (BORDER_PADDING * 2)) + 20, Std.int(h - (BORDER_PADDING * 2)) + 20, 0xFF14080E);
        add(innerBg);

        if (decorPath != "" && LilyAssets.fileExists(decorPath + ".png")) {
            decorBg = new FlxSprite(0, 0).loadGraphic(LilyAssets.image(decorPath));
            decorBg.setGraphicSize(Std.int(decorBg.width));
            decorBg.updateHitbox();
            decorBg.x = w - decorBg.width - BORDER_PADDING;
            decorBg.y = h - decorBg.height - BORDER_PADDING;
            add(decorBg);
        }

        var frameImg = LilyAssets.image("img/ui/frame_menu_2");        
        titleFrame = UIUtil.create9SliceSprite(frameImg, 0, 0, w, h, 0.75);
        add(titleFrame);

        titleLabel = new FlxText(0, TITLE_MARGIN_TOP, w, titleText, 32);
        titleLabel.alignment = CENTER;
        add(titleLabel);

        divider = new FlxSprite(0, DIVIDER_MARGIN_TOP);
        divider.loadGraphic(dividerPath);
        divider.setGraphicSize(Std.int(divider.width));
        divider.updateHitbox();
        divider.x = (w - divider.width) / 2;
        add(divider);

        setTitle(titleText);
    }

    public function setTitle(text:String) {
        titleLabel.text = text;
        var isVisible = (text != null && text != "");
        titleLabel.visible = isVisible;
        divider.visible = isVisible;
    }
}