import engine.substates.SaveLoad;

function onInteracted(name) {
    switch(name) {
        case "crow":
            openSubState(new SaveLoad(true, true));
    }
}