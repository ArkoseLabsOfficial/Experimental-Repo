package engine.backend;

class Mobile extends FlxBasic {
    #if FEATURE_TOUCH_CONTROLS
    public var controls:MobileControlManager;
    public var mobilePad:MobilePadProxy;

    public function new(instance:Dynamic) {
        super();
        controls = new MobileControlManager(instance);
        mobilePad = new MobilePadProxy();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (mobilePad != null && controls.mobilePad != null) mobilePad.update(controls.mobilePad);
    }
    #end
}

#if FEATURE_TOUCH_CONTROLS
class MobilePadProxy {
    public var justPressed:Dynamic = {};
    public var pressed:Dynamic = {};
    public var justReleased:Dynamic = {};
    public var released:Dynamic = {};

    public function new() {}

    public function update(realPad:MobilePad) {
        for (name in realPad.buttonMap.keys()) {
            var btn = realPad.getButton(name);
            if (btn != null) {
                Reflect.setField(justPressed, name, btn.justPressed == true);
                Reflect.setField(pressed, name, btn.pressed == true);
                Reflect.setField(justReleased, name, btn.justReleased == true);
                Reflect.setField(released, name, btn.released == true);
            }
        }
    }
}
#end