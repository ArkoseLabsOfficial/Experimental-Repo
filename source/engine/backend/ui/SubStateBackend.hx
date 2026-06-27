package engine.backend.ui;

class SubStateBackend extends FlxSubState {
	// put your codes there
	#if FEATURE_TOUCH_CONTROLS
	public function new(bgColor:FlxColor = FlxColor.TRANSPARENT) {
		super(bgColor);
		Main.mobileControls.resetAllInputs();
	}
	#end
    var camMenu:FlxCamera;
    override function create() {
        super.create();
        camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;
		FlxG.cameras.add(camMenu, false);
		cameras = [camMenu];
		camMenu.zoom = 1;
    }
}
