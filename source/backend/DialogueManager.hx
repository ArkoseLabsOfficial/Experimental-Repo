package backend;

import flixel.FlxSubState;
import flixel.FlxG;
import haxe.xml.Access;
import ui.DialogBox;
import ui.DialogSelection;
import flixel.FlxCamera;

class DialogueManager extends FlxSubState {
    var dialogBox:DialogBox;
    var selectionMenu:DialogSelection;
    var dialogCamera:FlxCamera;
    
    var xmlData:Access;
    var currentEntries:Array<Access> = [];
    var entryIndex:Int = 0;
    
    var onCompleteCallback:Void->Void;
    var waitingForInput:Bool = false;

    public function new(xmlPath:String, startDialogId:String, ?onComplete:Void->Void) {
        super(0x00000000); 
        onCompleteCallback = onComplete;
        
        var rawXML = openfl.utils.Assets.getText(xmlPath);
        rawXML = StringTools.replace(rawXML, "<!DOCTYPE lacie-engine-dialog>", ""); 
        xmlData = new Access(Xml.parse(rawXML).firstElement());
        
        jumpToDialog(startDialogId);
    }

    override public function create():Void {
        super.create();

        dialogCamera = new FlxCamera();
        dialogCamera.bgColor.alpha = 0;
        FlxG.cameras.add(dialogCamera, false);
        camera = dialogCamera;
        
        dialogBox = new DialogBox();
        add(dialogBox);
        
        selectionMenu = new DialogSelection();
        add(selectionMenu);

        playCurrentEntry();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (waitingForInput && !selectionMenu.activeMenu && Controls.ACCEPT_P) {
            if (dialogBox.advance()) {
                handleEntryEnd(currentEntries[entryIndex]);
            }
        }
    }

    function jumpToDialog(id:String):Void {
        entryIndex = 0;
        currentEntries = [];

        for (dialog in xmlData.nodes.dialog) {
            if (dialog.att.id == id) {
                for (entry in dialog.nodes.entry) currentEntries.push(entry);
                break;
            }
        }
    }

    function playCurrentEntry():Void {
        if (entryIndex >= currentEntries.length) {
            closeDialogue();
            return;
        }

        var entry = currentEntries[entryIndex];
        
        var canShow = true;
        if (entry.has.resolve("if")) canShow = evaluateLogic(entry.att.resolve("if"));
        if (entry.has.unless) canShow = !evaluateLogic(entry.att.unless);

        if (!canShow) {
            entryIndex++;
            playCurrentEntry();
            return;
        }

        if (entry.has.setFlag) applySetFlag(entry.att.setFlag);

        var charName = entry.has.name ? entry.att.name : "";
        var textKey = entry.has.text ? entry.att.text : "";
        var localizedText = Language.GetCaption(textKey);

        var leftPath = "";
        if (entry.has.leftChar && entry.att.leftChar != "none") {
            var baseChar = entry.att.leftChar.split("_")[0];
            leftPath = "assets/img/bust/" + entry.att.leftChar + ".png";
            if (!openfl.utils.Assets.exists(leftPath)) leftPath = "assets/img/bust/" + entry.att.leftChar + ".png";
        }

        var rightPath = "";
        if (entry.has.rightChar && entry.att.rightChar != "none") {
            var baseChar = entry.att.rightChar.split("_")[0];
            rightPath = "assets/img/bust/" + entry.att.rightChar + ".png";
            if (!openfl.utils.Assets.exists(rightPath)) rightPath = "assets/img/bust/" + entry.att.rightChar + ".png";
        }

        dialogBox.show(charName, localizedText, leftPath, rightPath);
        waitingForInput = true;
    }

    function handleEntryEnd(entry:Access):Void {
        waitingForInput = false;

        if (entry.has.hasSelection && entry.att.hasSelection == "true") {
            showSelections(entry);
            return;
        }

        if (entry.has.closeTheBox && entry.att.closeTheBox == "true") {
            closeDialogue();
            return;
        }
        if (entry.has.resolve("return")) {
            jumpToDialog(entry.att.resolve("return"));
            playCurrentEntry();
            return;
        }

        entryIndex++;
        playCurrentEntry();
    }

    function showSelections(entry:Access):Void {
        var options:Array<String> = [];
        var validItems:Array<Access> = [];

        if (entry.hasNode.selections) {
            for (item in entry.node.selections.nodes.item) {
                var canShow = true;
                if (item.has.resolve("if")) canShow = evaluateLogic(item.att.resolve("if"));
                if (item.has.unless) canShow = !evaluateLogic(item.att.unless);
                
                if (canShow) {
                    options.push(Language.GetCaption(item.att.text));
                    validItems.push(item);
                }
            }
        }

        selectionMenu.show(options, function(choiceIndex:Int) {
            var chosenItem = validItems[choiceIndex];
            
            // --- ID SAVING ---
            // Saves the item's ID as true in GameState
            if (chosenItem.has.id) GameState.setFlag(chosenItem.att.id, true);
            
            if (chosenItem.has.setFlag) applySetFlag(chosenItem.att.setFlag);

            jumpToDialog(chosenItem.att.selectionConfirmed);
            playCurrentEntry();
        });
    }

    // --- NEW SET FLAG PARSER ---
    // Parses strings like "has_room_key = true" or "is_tired = false"
    function applySetFlag(flagStr:String):Void {
        var parts = flagStr.split("=");
        var key = StringTools.trim(parts[0]);
        var val = true; // Default to true if no "=" is present
        
        if (parts.length > 1) {
            var valStr = StringTools.trim(parts[1]).toLowerCase();
            if (valStr == "false") val = false;
        }
        
        GameState.setFlag(key, val);
    }

    function closeDialogue():Void {
        if (onCompleteCallback != null) onCompleteCallback();
        close(); 
    }

    function evaluateLogic(condition:String):Bool {
        if (condition == null || condition == "") return true;
        condition = StringTools.replace(condition, " ", "");
        if (condition.indexOf("||") != -1) {
            var parts = condition.split("||");
            for (p in parts) if (evalSingle(p)) return true;
            return false;
        }
        if (condition.indexOf("&&") != -1) {
            var parts = condition.split("&&");
            for (p in parts) if (!evalSingle(p)) return false;
            return true;
        }
        return evalSingle(condition);
    }

    function evalSingle(cond:String):Bool {
        var invert = StringTools.startsWith(cond, "!");
        if (invert) cond = cond.substring(1);
        var val = GameState.getFlag(cond);
        return invert ? !val : val;
    }
}