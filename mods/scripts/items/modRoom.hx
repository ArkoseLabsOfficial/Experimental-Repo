package export.release.linux.bin.mods.scripts.items;

function onInteracted(name) {
    switch(name) {
        case "misc_table":
            addItem("potion_health", 1);
            Save.setSave("kralmod.itemused", false);
    }
}