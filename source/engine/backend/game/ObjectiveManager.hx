package engine.backend.game;

class ObjectiveManager {
	public var objectives:Map<String, Objective>;

	private var _objectivesUpdated:Bool = false;

	private var currentObjectives(get, never):Array<String>;

	private function get_currentObjectives()
		return Game.instance.save.currentObjectives;

	private var completedObjectives(get, never):Array<String>;

	private function get_completedObjectives()
		return Game.instance.save.completedObjectives;

	private var failedObjectives(get, never):Array<String>;

	private function get_failedObjectives()
		return Game.instance.save.failedObjectives;

	public function new() {
		init();
	}

	public function init():Void {
		objectives = new Map<String, Objective>();
		var order:Int = 0;
		var jsonPaths = ["objectives/story.json", "objectives/sidequests.json"];

		for (path in jsonPaths) {
			var parsedFile = SimpleParser.loadJSON(path);
			if (parsedFile == null || parsedFile.Objectives == null)
				continue;

			var groupName = path.substring(path.lastIndexOf("/") + 1, path.lastIndexOf("."));

			for (objDto in (parsedFile.Objectives : Array<ObjectiveData>)) {
				parseObjectiveFromDto(objDto, objDto.Id, groupName, null, order);
				order++;
			}
		}
		applyTranslationOverrides();
	}

	private function parseObjectiveFromDto(dto:ObjectiveData, id:String, group:String, parent:Objective, currentOrder:Int):Objective {
		var obj = new Objective();
		obj.id = id;
		obj.group = group;
		obj.order = currentOrder;
		obj.name = dto.Name;
		obj.description = dto.Description;
		obj.hidden = dto.Hidden != null ? dto.Hidden : false;
		obj.onComplete = dto.OnComplete != null ? dto.OnComplete : [];
		obj.parent = parent;

		if (dto.Children != null) {
			for (childDto in dto.Children) {
				obj.children.push(parseObjectiveFromDto(childDto, obj.id + "." + childDto.Id, group, obj, currentOrder));
			}
		}

		objectives.set(obj.id, obj);
		return obj;
	}

	public function applyTranslationOverrides():Void {
		for (obj in objectives) {
			obj.name = Game.instance.language.getCaption('objectives.name.${obj.id}');
			obj.description = Game.instance.language.getCaption('objectives.desc.${obj.id}');
		}
	}

	public function add(objectiveId:String):Void {
		if (!isObjectiveValid(objectiveId)) {
			flixel.FlxG.log.error("Attempting to add an invalid objective: " + objectiveId);
			return;
		}
		addObj(objectives.get(objectiveId));
	}

	private function addObj(objective:Objective):Void {
		if (objective.hasParent()) {
			addObj(objective.parent);
			if (!currentObjectives.contains(objective.parent.id))
				return;
		}
		if (!currentObjectives.contains(objective.id)
			&& !completedObjectives.contains(objective.id)
			&& !failedObjectives.contains(objective.id)) {
			currentObjectives.push(objective.id);
			_objectivesUpdated = true;
		}
	}

	public function remove(objectiveId:String):Void {
		if (!isObjectiveValid(objectiveId)) {
			flixel.FlxG.log.error("Attempting to remove an invalid objective: " + objectiveId);
			return;
		}
		removeObj(objectives.get(objectiveId));
	}

	private function removeObj(objective:Objective):Void {
		currentObjectives.remove(objective.id);
		if (objective.hasChildren()) {
			for (child in objective.children) {
				if (currentObjectives.contains(child.id))
					removeObj(child);
			}
		}
		if (objective.hasParent() && !objectiveHasPendingChildren(objective.parent)) {
			removeObj(objective.parent);
		}
	}

	public function complete(objectiveId:String):Void {
		if (!isObjectiveValid(objectiveId)) {
			flixel.FlxG.log.error("Attempting to complete an invalid objective: " + objectiveId);
			return;
		}
		completeObj(objectives.get(objectiveId));
	}

	private function completeObj(objective:Objective):Void {
		if (completedObjectives.contains(objective.id) || failedObjectives.contains(objective.id))
			return;

		currentObjectives.remove(objective.id);
		completedObjectives.push(objective.id);

		if (objective.hasChildren()) {
			for (child in objective.children) {
				if (currentObjectives.contains(child.id))
					completeObj(child);
			}
		}
		if (objective.hasParent() && !objectiveHasPendingChildren(objective.parent)) {
			completeObj(objective.parent);
		}
		for (triggeredId in objective.onComplete) {
			add(triggeredId);
		}
	}

	public function fail(objectiveId:String):Void {
		if (!isObjectiveValid(objectiveId)) {
			flixel.FlxG.log.error("Attempting to fail an invalid objective: " + objectiveId);
			return;
		}
		failObj(objectives.get(objectiveId));
	}

	private function failObj(objective:Objective):Void {
		if (completedObjectives.contains(objective.id) || failedObjectives.contains(objective.id))
			return;
		currentObjectives.remove(objective.id);
		failedObjectives.push(objective.id);

		if (objective.hasChildren()) {
			for (child in objective.children) {
				if (currentObjectives.contains(child.id))
					failObj(child);
			}
		}
		if (objective.hasParent() && !objectiveHasPendingChildren(objective.parent)) {
			failObj(objective.parent);
		}
	}

	public function getCurrentObjectives():Array<Objective> {
		var activeList:Array<Objective> = [];
		for (objId in currentObjectives) {
			if (objectives.exists(objId)) {
				var obj = objectives.get(objId);
				if (!obj.hidden && !obj.hasParent()) {
					activeList.push(obj);
				}
			}
		}
		activeList.sort(function(x, y) return x.order - y.order);
		return activeList;
	}

	public function getAllObjectives():Array<Objective> {
		var list:Array<Objective> = [];
		for (obj in objectives)
			list.push(obj);
		list.sort(function(x, y) return x.order - y.order);
		return list;
	}

	public function clearObjectives():Void {
		while (currentObjectives.length > 0)
			currentObjectives.pop();
	}

	public function silenceNotifications():Void {
		_objectivesUpdated = false;
	}

	public function showNotification():Void {
		if (GamePrefs.getOption("objectiveNotifications") && _objectivesUpdated) {
			flixel.FlxG.log.notice("Objectives Updated!");
			// this can be replaced with a generic UI flyout later!
		}
		_objectivesUpdated = false;
	}

	public function isObjectiveInProgress(objectiveId:String):Bool {
		return currentObjectives.contains(objectiveId);
	}

	public function isObjectiveCompleted(objectiveId:String):Bool {
		return completedObjectives.contains(objectiveId);
	}

	public function isObjectiveFailed(objectiveId:String):Bool {
		return failedObjectives.contains(objectiveId);
	}

	public function isObjectiveValid(objectiveId:String):Bool {
		return objectives.exists(objectiveId);
	}

	public function objectiveHasPendingChildren(objective:Objective):Bool {
		if (objective.hasChildren()) {
			for (child in objective.children) {
				if (!isObjectiveCompleted(child.id) && !isObjectiveFailed(child.id)) {
					return true;
				}
			}
		}
		return false;
	}
}
