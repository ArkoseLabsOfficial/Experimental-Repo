import backend.Controls;
import states.SaveLoadSubState;
import test.Stats;

function postUpdate(elapsed:Float) {
    var box = room.activePlayer.getInteractionBox();
    if (room.activePlayer != null && Controls.ACCEPT_P && !this.interactable && box.overlaps(this.getHitbox())) {
        openSubState(new SaveLoadSubState(true, true));
        trace("Lily Engine Script Import Test: " + stats.attack);
    }
}