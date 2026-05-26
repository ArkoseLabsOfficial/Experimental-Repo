package backend;

import haxe.Json;
import backend.GamePrefs; // Assuming you store save data here
import backend.Language;  // Assuming your translation system is here
import flixel.FlxG;
import backend.Objective;

class ObjectiveManager {
    public var objectives:Map<String, Objective>;
    private var _objectivesUpdated:Bool = false;

    // We'll store active/completed/failed lists in the save data, but reference them here for clean code
    private var currentObjectives(get, never):Array<String>;
    private function get_currentObjectives() return GamePrefs.currentObjectives;

    private var completedObjectives(get, never):Array<String>;
    private function get_completedObjectives() return GamePrefs.completedObjectives;

    private var failedObjectives(get, never):Array<String>;
    private function get_failedObjectives() return GamePrefs.failedObjectives;

    public function new() {
        init();
    }

    public function init():Void {
        objectives = new Map<String, Objective>();
        var order:Int = 0;

        // In HaxeFlixel, it's safer to read a manifest or know your file paths explicitly, 
        // but let's assume we have an array of objective JSON file paths.
        var jsonPaths = ["data/objectives/story.json", "data/objectives/sidequests.json"];

        for (path in jsonPaths) {
            if (!LilyAssets.fileExists(path)) continue;

            var rawText = LilyAssets.getTextFromFile(path);
            var parsedFile:{Objectives:Array<ObjectiveData>} = Json.parse(rawText);
            
            // Extract the group name from the filename (e.g., "story.json" -> "story")
            var groupName = path.substring(path.lastIndexOf("/") + 1, path.lastIndexOf("."));

            // Let's build the objective tree!
            for (objDto in parsedFile.Objectives) {
                parseObjectiveFromDto(objDto, objDto.Id, groupName, null, order);
                order++; // Keeping track of the order they were parsed in
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

        // Recursively build children if they exist
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
        // Hey, if this objective has a parent, make sure the parent is added first!
        if (objective.hasParent()) {
            addObjectiveObj(objective.parent);
            if (!currentObjectives.contains(objective.parent.id)) return;
        }

        // Only add it if it's completely new to the player
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
        // Stop if we've already dealt with this one
        if (completedObjectives.contains(objective.id) || failedObjectives.contains(objective.id)) return;

        currentObjectives.remove(objective.id);
        completedObjectives.push(objective.id);

        // Chain reaction! Complete all active children automatically
        if (objective.hasChildren()) {
            for (child in objective.children) {
                if (currentObjectives.contains(child.id)) completeObjectiveObj(child);
            }
        }

        // If completing this finishes the parent's last child, complete the parent too!
        if (objective.hasParent() && !objectiveHasPendingChildren(objective.parent)) {
            completeObjectiveObj(objective.parent);
        }

        // Trigger any follow-up objectives
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
            // We only show top-level, non-hidden objectives in the menu
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