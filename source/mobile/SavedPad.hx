package mobile;

import mobile.MobilePad;

class SavedPad extends MobilePad {
    var lastDPadName:String = "NONE";
    var lastActionName:String = "NONE";

    public function new(DPad:String = "NONE", Action:String = "NONE", buttonCreation:Bool = true) {
        this.lastDPadName = DPad;
        this.lastActionName = Action;
        super(DPad, Action, buttonCreation);
    }
}