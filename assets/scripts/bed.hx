import haxe.Timer;

var isSleeping = false;

function postUpdate(elapsed:Float) {
    var box = room.activePlayer.getInteractionBox();
    
    if (room.activePlayer != null && Controls.ACCEPT_P && !this.interactable && box.overlaps(this.getHitbox()) && !isSleeping) {
        goToSleep();
    } else if (room.activePlayer != null && Controls.ACCEPT_P && isSleeping) {
        wakeUp();
    }
}

function goToSleep() {
    isSleeping = true;
    room.activePlayer.playAnim('sleep');
    room.activePlayer.x = this.x + 25;
    room.activePlayer.y = this.y + 30;
    room.activePlayer.canMove = false;
}

function wakeUp() {
    room.activePlayer.playAnim('wakeup');
    
    Timer.delay(function() {
        isSleeping = false;
        room.activePlayer.playAnim('idleDOWN');
        room.activePlayer.canMove = true;
        room.activePlayer.x = this.x + 25;
        room.activePlayer.y = this.y + 60;
    }, 2000);
}