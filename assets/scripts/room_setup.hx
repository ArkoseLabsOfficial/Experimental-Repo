function onRoomLoaded() {
    room.activePlayer.canMove = false;
    room.activePlayer.animation.finishCallback = function(name:String) {
        if (name == 'aweking') {
            room.activePlayer.canMove = true;            
            room.activePlayer.playAnim('idleDOWN');
            room.activePlayer.animation.finishCallback = null;
        }
    };
    room.activePlayer.playAnim('aweking', false, true);
}