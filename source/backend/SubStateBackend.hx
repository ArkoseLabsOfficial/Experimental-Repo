package backend;

import flixel.FlxSubState;
import backend.Mobile;
import flixel.util.FlxColor;

class SubStateBackend extends FlxSubState {
    public var mobile:Mobile;
    public function new(bgColor:FlxColor = FlxColor.TRANSPARENT) {
        super(bgColor);
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
}