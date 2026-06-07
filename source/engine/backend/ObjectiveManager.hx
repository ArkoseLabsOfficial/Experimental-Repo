package engine.backend;

class ObjectiveManager {
    public var objectives:Map<String, Objective>;
    private var _objectivesUpdated:Bool = false;

    private var currentObjectives(get, never):Array<String>;
    private function get_currentObjectives() return SaveManager.currentObjectives;

    private var completedObjectives(get, never):Array<String>;
    private function get_completedObjectives() return SaveManager.completedObjectives;

    private var failedObjectives(get, never):Array<String>;
    private function get_failedObjectives() return SaveManager.failedObjectives;

    public function new() {
        init();
    }

    public function init():Void {
        objectives = new Map<String, Objective>();
        var order:Int = 0;

        var jsonPaths = ["objectives/story.json", "objectives/sidequests.json"];

        for (path in jsonPaths) {
            if (!LilyAssets.fileExists(path)) continue;

            var rawText = LilyAssets.getTextFromFile(path);
            var parsedFile:{Objectives:Array<ObjectiveData>} = Json.parse(rawText);
            var groupName = path.substring(path.lastIndexOf("/") + 1, path.lastIndexOf("."));

            for (objDto in parsedFile.Objectives) {
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

    public function add(objectiveId:String):Void {
        if (!isObjectiveValid(objectiveId)) {
            trace('Error: Attempting to add an invalid objective -> $objectiveId');
            return;
        }
        addObjectiveObj(objectives.get(objectiveId));
    }

    private function addObjectiveObj(objective:Objective):Void {
        if (objective.hasParent()) {
            addObjectiveObj(objective.parent);
            if (!currentObjectives.contains(objective.parent.id)) return;
        }

        if (!currentObjectives.contains(objective.id) && !completedObjectives.contains(objective.id) && !failedObjectives.contains(objective.id)) {
            currentObjectives.push(objective.id);
            _objectivesUpdated = true;
        }
    }

    public function complete(objectiveId:String):Void {
        if (!isObjectiveValid(objectiveId)) return;
        completeObjectiveObj(objectives.get(objectiveId));
    }

    private function completeObjectiveObj(objective:Objective):Void {
        if (completedObjectives.contains(objective.id) || failedObjectives.contains(objective.id)) return;

        currentObjectives.remove(objective.id);
        completedObjectives.push(objective.id);

        if (objective.hasChildren()) {
            for (child in objective.children) {
                if (currentObjectives.contains(child.id)) completeObjectiveObj(child);
            }
        }

        if (objective.hasParent() && !objectiveHasPendingChildren(objective.parent)) {
            completeObjectiveObj(objective.parent);
        }

        for (triggeredId in objective.onComplete) {
            add(triggeredId);
        }
    }

    public function fail(objectiveId:String):Void {
        if (!isObjectiveValid(objectiveId)) return;
        failObjectiveObj(objectives.get(objectiveId));
    }

    private function failObjectiveObj(objective:Objective):Void {
        if (completedObjectives.contains(objective.id) || failedObjectives.contains(objective.id)) return;

        currentObjectives.remove(objective.id);
        failedObjectives.push(objective.id);

        if (objective.hasChildren()) {
            for (child in objective.children) {
                if (currentObjectives.contains(child.id)) failObjectiveObj(child);
            }
        }

        if (objective.hasParent() && !objectiveHasPendingChildren(objective.parent)) {
            failObjectiveObj(objective.parent);
        }
    }

    public function getCurrentObjectives():Array<Objective> {
        var activeList:Array<Objective> = [];
        for (objId in currentObjectives) {
            var obj = objectives.get(objId);
            if (obj != null && !obj.hidden && !obj.hasParent()) {
                activeList.push(obj);
            }
        }
        activeList.sort(function(x, y) return x.order - y.order);
        return activeList;
    }

    public function isObjectiveValid(objectiveId:String):Bool {
        return objectives.exists(objectiveId);
    }
    
    public function isObjectiveCompleted(objectiveId:String):Bool {
        return completedObjectives.contains(objectiveId);
    }

    public function isObjectiveFailed(objectiveId:String):Bool {
        return failedObjectives.contains(objectiveId);
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

    public function applyTranslationOverrides():Void {
        for (obj in objectives) {
            obj.name = Language.GetCaption('objectives.name.${obj.name}');
            obj.description = Language.GetCaption('objectives.desc.${obj.description}');
        }
    }
}