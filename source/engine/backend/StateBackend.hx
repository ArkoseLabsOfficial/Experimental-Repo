package engine.backend;

import flixel.FlxState;
#if FEATURE_TOUCH_CONTROLS
import engine.backend.Mobile;
#end
import flixel.FlxSubState;

class StateBackend extends FlxState {
    #if FEATURE_TOUCH_CONTROLS
    public var mobile:Mobile;
    public function new() {
        super();
        mobile = new Mobile(this);
        add(mobile);
    }

    var lastActionName:String = "NONE";
    var lastDPadName:String = "NONE";
    override public function openSubState(subState:FlxSubState):Void {
        super.openSubState(subState);
        lastDPadName = mobile.controls.mobilePad.lastDPadName;
        lastActionName = mobile.controls.mobilePad.lastActionName;
        mobile.controls.removeMobilePad();
    }

    override public function closeSubState():Void {
        super.closeSubState();

        if (mobile != null) {
            mobile.controls.addMobilePad(lastDPadName, lastActionName);
            mobile.controls.addMobilePadCamera();
        }
    }
    #end
}