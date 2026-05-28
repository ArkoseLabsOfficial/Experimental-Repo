package;

import engine.backend.Controls;
import engine.backend.ItemManager;

function postUpdate(elapsed:Float) {
    var box = room.activePlayer.getInteractionBox();
    if (room.activePlayer != null && Controls.ACCEPT_P && !this.interactable && box.overlaps(this.getHitbox())) {
        objectives.add("tutorial_start");
        ItemManager.addItem("potion_health", 1);
    }
}