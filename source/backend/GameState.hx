package backend;

class GameState {
    // This map holds EVERYTHING that needs to be saved/loaded.
    // It tracks logic variables and dialogue choices.
    public static var fallbackPlayer:String = "sprite/common/character/lacie/lacie";
    public static var flags:Map<String, Bool> = [
        "has_item" => true,
        "is_tired" => false,
        "is_raining" => true
    ];

    public static var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
    
    // Stores your current party members (using strings to match the sprite loading logic)
    public static var party:Array<String> = ["lacie"];

    public static function setFlag(key:String, value:Bool):Void {
        flags.set(key, value);
    }

    public static function getFlag(key:String):Bool {
        return flags.exists(key) ? flags.get(key) : false;
    }
}