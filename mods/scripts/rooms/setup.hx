package rooms;

import engine.backend.Game;

function create() {
    Save.init("LilyEngine/myMod");
    Objectives.add("sitPC");
}

function update(elapsed) {
    furniture_bookshelf.visible = !Save.getSave("healUsed");
}