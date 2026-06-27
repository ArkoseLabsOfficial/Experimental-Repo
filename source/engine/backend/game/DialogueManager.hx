package engine.backend.game;

class DialogueManager extends SubStateBackend {
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

		xmlData = SimpleParser.loadXML('dialogues/$xmlPath.xml', "<!DOCTYPE lily-engine-dialog>");
		if (xmlData != null)
			jumpToDialog(startDialogId);
	}

	override public function create():Void {
		super.create();
		#if FEATURE_TOUCH_CONTROLS
		Main.mobileControls.removeButton();
		Main.mobileControls.removeDPad();
		Main.mobileControls.removeJoyStick();
		#end

		dialogCamera = new FlxCamera();
		dialogCamera.bgColor.alpha = 0;
		FlxG.cameras.add(dialogCamera, false);
		cameras = [dialogCamera];
		dialogCamera.zoom = 1;

		dialogBox = new DialogBox();
		add(dialogBox);

		selectionMenu = new DialogSelection(this);
		add(selectionMenu);

		playCurrentEntry();
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		var pointerJustPressed = false;
		var touchJustPressed = false;

		#if FLX_MOUSE
		if (FlxG.mouse.justPressed)
			pointerJustPressed = true;
		#end

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
			if (touch.justPressed)
				touchJustPressed = true;
		#end

		if (waitingForInput && !selectionMenu.activeMenu && (Controls.ACCEPT || pointerJustPressed || touchJustPressed)) {
			if (dialogBox.advance()) {
				handleEntryEnd(currentEntries[entryIndex]);
			}
		}
	}

	function jumpToDialog(id:String):Void {
		entryIndex = 0;
		currentEntries = [];

		if (xmlData == null)
			return;

		for (dialog in xmlData.nodes.dialog) {
			if (dialog.att.id == id) {
				for (entry in dialog.nodes.entry)
					currentEntries.push(entry);
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

		if (entry.has.resolve("if"))
			canShow = evaluateLogic(entry.att.resolve("if"));
		if (entry.has.unless)
			canShow = !evaluateLogic(entry.att.unless);

		if (!canShow) {
			entryIndex++;
			playCurrentEntry();
			return;
		}

		if (entry.has.setFlag)
			applySetFlag(entry.att.setFlag);

		var charName = entry.has.name ? entry.att.name : "";
		var textKey = entry.has.text ? entry.att.text : "";
		var localizedText = Game.instance.language.getCaption(textKey);

		if (Game.instance.language.getStoryCaption(textKey)[1] == true) {
			localizedText = Game.instance.language.getStoryCaption(textKey)[0];
		}

		var leftPath = "";
		if (entry.has.leftChar && entry.att.leftChar != "none") {
			leftPath = "dialogs/characters/" + entry.att.leftChar;
		}

		var rightPath = "";
		if (entry.has.rightChar && entry.att.rightChar != "none") {
			rightPath = "dialogs/characters/" + entry.att.rightChar;
		}

		var leftAnim = entry.has.leftCharAnim ? entry.att.leftCharAnim : "none";
		var rightAnim = entry.has.rightCharAnim ? entry.att.rightCharAnim : "none";
		dialogBox.show(charName, localizedText, leftPath, rightPath, leftAnim, rightAnim);
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
				if (item.has.resolve("if"))
					canShow = evaluateLogic(item.att.resolve("if"));
				if (item.has.unless)
					canShow = !evaluateLogic(item.att.unless);

				if (canShow) {
					var textKey = item.has.text ? item.att.text : "";
					var localizedText = Game.instance.language.getCaption(textKey);
					if (Game.instance.language.getStoryCaption(textKey)[1] == true) {
						localizedText = Game.instance.language.getStoryCaption(textKey)[0];
					}
					options.push(localizedText);
					validItems.push(item);
				}
			}
		}

		selectionMenu.show(options, function(choiceIndex:Int) {
			var chosenItem = validItems[choiceIndex];

			if (chosenItem.has.id)
				Game.instance.save.setFlag(chosenItem.att.id, true);
			if (chosenItem.has.setFlag)
				applySetFlag(chosenItem.att.setFlag);

			jumpToDialog(chosenItem.att.selectionConfirmed);
			playCurrentEntry();
		});
	}

	function applySetFlag(flagStr:String):Void {
		var parts = flagStr.split("=");
		var key = StringTools.trim(parts[0]);
		var val = true;

		if (parts.length > 1) {
			var valStr = StringTools.trim(parts[1]).toLowerCase();
			if (valStr == "false")
				val = false;
		}

		Game.instance.save.setFlag(key, val);
	}

	function closeDialogue():Void {
		dialogBox.hide(function() {
			if (onCompleteCallback != null)
				onCompleteCallback();
			close();
		});
	}

	function evaluateLogic(condition:String):Bool {
		if (condition == null || condition == "")
			return true;
		condition = StringTools.replace(condition, " ", "");
		if (condition.indexOf("||") != -1) {
			var parts = condition.split("||");
			for (p in parts)
				if (evalSingle(p))
					return true;
			return false;
		}
		if (condition.indexOf("&&") != -1) {
			var parts = condition.split("&&");
			for (p in parts)
				if (!evalSingle(p))
					return false;
			return true;
		}
		return evalSingle(condition);
	}

	function evalSingle(cond:String):Bool {
		var invert = StringTools.startsWith(cond, "!");
		if (invert)
			cond = cond.substring(1);
		var val = Game.instance.save.getFlag(cond);
		return invert ? !val : val;
	}
}
