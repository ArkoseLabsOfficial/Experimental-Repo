package engine.substates;

class StartupLanguage extends SimpleVerticalMenu {
    var extraLanguages:Bool;
    var languageContainer:Language;

    public function new(extraLanguages:Bool, languageContainer:Language) {
        super();
        this.extraLanguages = extraLanguages;
        this.languageContainer = languageContainer;

        this.itemWidth = 792;
        this.itemFontSize = 36;
        
        buildEntries();
    }

    public function buildEntries():Void {
        entries = [];
        var langs = extraLanguages ? Game.instance.language.getUnofficialLanguages() : Game.instance.language.officialLanguages;
        
        for (lang in langs) {
            var caption = Game.instance.language.getCaption("system.settings.language." + lang);
            if (caption == "system.settings.language." + lang)
                caption = lang;
            
            addEntry(caption, function() {
                languageContainer.closeMenu();
                LilyAssets.play(LilyAssets.CONFIRM);
                Game.instance.language.loadLanguage(lang);
            });
        }
        
        if (!extraLanguages && Game.instance.language.getUnofficialLanguages().length > 0) {
            addEntry(Game.instance.language.getCaption("system.settings.language.more"), function() {
                LilyAssets.play(LilyAssets.CONFIRM);
                if (languageContainer.frame != null) {
                    languageContainer.frame.setTitle(Game.instance.language.getCaption("system.settings.language.unofficial"));
                }
                var newMenu = new StartupLanguage(true, languageContainer);
                languageContainer.setMenu(newMenu);
            });
        }
        buildVisualList(72);
    }

    override public function handleInput():Void {
        super.handleInput();
        if (Controls.CANCEL) {
            LilyAssets.play(LilyAssets.CANCEL);
            if (extraLanguages) {
                if (languageContainer.frame != null) {
                    languageContainer.frame.setTitle(Game.instance.language.getCaption("system.settings.language.select"));
                }
                var newMenu = new StartupLanguage(false, languageContainer);
                languageContainer.setMenu(newMenu);
            } else {
                languageContainer.closeMenu();
            }
        }
    }
}

class Language extends SubStateBackend {
    public var frame:MenuFrameNode;
    public var currentMenu:SimpleVerticalMenu;
    public var onClose:Void->Void;

    var frameWidth:Float = 900;
    var frameHeight:Float = 400;

    public function new(?onClose:Void->Void) {
        super();
        this.onClose = onClose;
    }

    override public function create():Void {
        super.create();
        var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xB3000000);
        add(overlay);

        var px = (FlxG.width - frameWidth) / 2;
        var py = (FlxG.height - frameHeight) / 2;
        frame = new MenuFrameNode(px, py, frameWidth, frameHeight, 2);
        frame.setTitle(Game.instance.language.getCaption("system.settings.language.select"));
        frame.divider = new FlxSprite(0, 0, LilyAssets.image("img/ui/divider_md"));
        add(frame);

        var startupMenu = new StartupLanguage(false, this);
        setMenu(startupMenu);
    }

    public function setMenu(menu:SimpleVerticalMenu):Void {
        if (currentMenu != null)
            remove(currentMenu);
        currentMenu = menu;
        menu.x = frame.x + 50;
        menu.y = frame.y + 160;
        add(menu);
    }

    public function closeMenu():Void {
        if (onClose != null)
            onClose();
        close();
    }
}