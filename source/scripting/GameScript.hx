package scripting;

import flixel.FlxG;

import crowplexus.hscript.Expr;
import crowplexus.hscript.Parser;
import crowplexus.hscript.Interp;
import crowplexus.iris.Iris;
import crowplexus.hscript.ISharedScript;

class GameScript implements ISharedScript {
    public static var instances:Map<String, GameScript> = new Map();
    
    public var standard(get, never):Dynamic;
    public function get_standard():Dynamic {
        return this;
    }

    public var interp:Interp;
    public var parser:Parser;
    public var expr:Expr;
    
    public var path:String;
    public var active:Bool = true;

    public function new(scriptPath:String, ?parent:Dynamic) {
        this.path = scriptPath;
        
        var code:String = loadCode(path);
        if (code.length == 0) {
            Iris.warn('Script at $path is empty or not found.', cast {fileName: path, lineNumber: 0});
            return;
        }

        try {
            interp = new Interp();
            parser = new Parser();
            parser.allowTypes = parser.allowMetadata = parser.allowJSON = parser.allowInterpolation = true;
            
            interp.importHandler = _importHandler;
            setParent(parent);

            set("Math", Math);
            set("Std", Std);
            set("StringTools", StringTools);
            set("FlxG", flixel.FlxG);
            set("FlxSprite", flixel.FlxSprite);

            set("trace", Reflect.makeVarArgs(function(args) {
                trace('[Script: ${path}] ' + args.join(", "));
            }));
            
            var cleanPath = haxe.io.Path.withoutExtension(path);
            instances.set(cleanPath, this);

            expr = parser.parseString(code, path);
            interp.execute(expr);

        } catch (e:Dynamic) {
            Iris.error(Std.string(e), cast {fileName: path, lineNumber: 0});
            active = false;
        }
    }

    private function loadCode(path:String):String {
        var code:String = "";
        if (code == "" && LilyAssets.fileExists(path)) code = LilyAssets.getTextFromFile(path);
        return code;
    }

    public function setParent(parent:Dynamic) {
        if (interp != null && parent != null) {
            interp.parentInstance = parent;
        }
    }

    @:noCompletion
    private function _importHandler(s:String, as:String, ?star:Bool):Bool {
        var cleanName = StringTools.replace(s, ".", "/"); 
        var importName = (as != null && StringTools.trim(as) != "") ? as : s.substring(s.lastIndexOf(".") + 1);
        
        // Check if already loaded
        for (key => script in instances) {
            if (key.indexOf(cleanName) != -1 && script.active) {
                interp.imports.set(importName, script);
                return true;
            }
        }

        // Dynamic loading if not found
        var potentialPaths:Array<String> = [
            cleanName + ".hx",
            "data/" + cleanName + ".hx",
            "data/scripts/" + cleanName + ".hx",
            "scripts/" + cleanName + ".hx"
        ];

        for (p in potentialPaths) {
            if (fileExists(p)) {
                var newScript = new GameScript(p, interp.parentInstance);
                if (newScript.active) {
                    interp.imports.set(importName, newScript);
                    return true; 
                }
            }
        }

        trace('Import Error: Could not find script for "$s"');
        return false;
    }

    private function fileExists(filePath:String):Bool {
        return LilyAssets.fileExists(filePath);
    }

    public function call(funcName:String, ?args:Array<Dynamic>):Dynamic {
        if (!active || interp == null) return null;
        var func = get(funcName);
        if (func != null && Reflect.isFunction(func)) {
            try {
                return Reflect.callMethod(null, func, args != null ? args : []);
            } catch(e:Dynamic) {
                Iris.error('Error calling $funcName in $path: $e', cast {fileName: path, lineNumber: 0});
            }
        }
        return null;
    }

    public function set(name:String, value:Dynamic):Void {
        if (active && interp != null) {
            if (value is Class || value is Enum) interp.imports.set(name, value);
            else interp.variables.set(name, value);
        }
    }

    public function get(name:String):Dynamic {
        if (active && interp != null) {
            if (interp.directorFields != null && interp.directorFields.get(name) != null) {
                return interp.directorFields.get(name).value;
            }
            return interp.variables.get(name);
        }
        return null;
    }

    public function hget(name:String, ?e:Expr):Dynamic {
        if (active && interp != null) {
            if (interp.directorFields != null && interp.directorFields.exists(name)) {
                var field = interp.directorFields.get(name);
                if (field.isPublic) {
                    return field.value;
                } else {
                    Iris.warn('Variable "$name" in script "$path" is not public!', cast {fileName: path, lineNumber: 0});
                    return null;
                }
            }
            if (interp.variables.exists(name)) return interp.variables.get(name);
        }
        return null;
    }

    public function hset(name:String, value:Dynamic, ?e:Expr):Void {
        if (active && interp != null) {
            if (interp.directorFields != null && interp.directorFields.exists(name)) {
                var field = interp.directorFields.get(name);
                if (field.isPublic) {
                    field.value = value;
                    return;
                } else {
                    Iris.warn('Cannot set "$name" in "$path" because it is not public!', cast {fileName: path, lineNumber: 0});
                    return;
                }
            }
            interp.variables.set(name, value);
        }
    }

    public function destroy():Void {
        active = false;
        var cleanPath = haxe.io.Path.withoutExtension(path);
        if (instances.exists(cleanPath)) instances.remove(cleanPath);
        
        interp = null;
        parser = null;
        expr = null;
    }
}