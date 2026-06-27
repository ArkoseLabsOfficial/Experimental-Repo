package engine.backend;

typedef ObjectiveData = {
	var Id:String;
	var Name:String;
	var Description:String;
	@:optional var Hidden:Bool;
	@:optional var OnComplete:Array<String>;
	@:optional var Children:Array<ObjectiveData>;
}

class Objective {
	public var id:String;
	public var group:String;
	public var name:String;
	public var description:String;
	public var order:Int;
	public var hidden:Bool;
	public var onComplete:Array<String>;
	public var parent:Objective;
	public var children:Array<Objective>;

	public function new() {
		onComplete = [];
		children = [];
		hidden = false;
		order = 0;
	}

	public function hasParent():Bool {
		return parent != null;
	}

	public function hasChildren():Bool {
		return children != null && children.length > 0;
	}
}
