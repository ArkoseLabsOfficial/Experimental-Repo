package;

import states.PlayState;

function postUpdate(elapsed) {
    if (PlayState.instance.mobile.mobilePad.justPressed.buttonCan) {
        trace("PlayState.instance.mobile.mobilePad.justPressed.buttonCan Test: " + PlayState.instance.mobile.mobilePad.justPressed.buttonCan);
    }
}