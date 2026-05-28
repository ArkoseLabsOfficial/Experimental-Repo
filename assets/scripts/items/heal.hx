package;

import engine.backend.DialogueManager;
import engine.states.PlayState;

function onUse() {
	PlayState.instance.openSubState(new DialogueManager("heal", "start"));
}