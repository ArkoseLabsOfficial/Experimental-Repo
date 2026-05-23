package;

import backend.Controls;

function postUpdate(elapsed:Float) {
    var box = room.activePlayer.getInteractionBox();
    if (room.activePlayer != null && Controls.ACCEPT_P && !this.interactable && box.overlaps(this.getHitbox())) {
        objectives.add("tutorial_start");
        trace("You got the quests");
    }
}