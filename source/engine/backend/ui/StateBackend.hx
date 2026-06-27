package engine.backend.ui;

import flixel.FlxState;
import flixel.FlxSubState;

class StateBackend extends FlxState {
    override function create() {
        super.create();
    }
	// put your codes there
	override public function closeSubState() {
		super.closeSubState();
		#if FEATURE_TOUCH_CONTROLS
		Main.mobileControls.resetAllInputs();
		#end
	}

	/**
     * Call this instead of FlxG.switchState()
     */
    public static function switchState(nextState:FlxState, duration:Float = 0.15):Void {
        FlxG.camera.fade(FlxColor.BLACK, duration, false, function() {
            FlxG.switchState(nextState);
        });
    }
}
