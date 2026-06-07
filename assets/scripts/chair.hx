var isSitting = false;

function postUpdate(elapsed:Float) {
    var box = room.activePlayer.getInteractionBox();

    if (room.activePlayer != null && Controls.ACCEPT_P && !this.interactable && box.overlaps(this.getHitbox()) && !isSitting) {
        sit();
    } else if (room.activePlayer != null && Controls.ACCEPT_P && isSitting) {
        standUp();
    }
}

function sit() {
    isSitting = true;
    room.activePlayer.canMove = false;
    room.activePlayer.playAnim('sitUP');
    room.activePlayer.x = chair.x + 15;
    room.activePlayer.y = chair.y + 20;
    var data = RoomManager.instance.sortMap.get(room.activePlayer);
    if (data != null) {
        data.z = 30;
    }
}

function standUp() {
    isSitting = false;
    room.activePlayer.x = chair.x + 15;
    room.activePlayer.y = chair.y + 50;
    room.activePlayer.canMove = true;
    var data = RoomManager.instance.sortMap.get(room.activePlayer);
    if (data != null) {
        data.z = 32;
    }
}
