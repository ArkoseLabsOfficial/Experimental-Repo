package engine.scripting;

import crowplexus.hscript.Expr;
import crowplexus.hscript.Parser;
import crowplexus.hscript.Interp;
import crowplexus.iris.Iris;
import crowplexus.hscript.ISharedScript;

class GameScript implements ISharedScript {
	public static var instances:Map<String, GameScript> = new Map();
	private static var currentlyLoading:Array<String> = [];

	// Prevents the engine from re-parsing the same script file for 50 different objects (I know useless but at the same time it's good for my phone)
	public static var exprCache:Map<String, Expr> = new Map();

	public static var defaultImports:Map<String, Dynamic> = [
		"Controls" => Controls,
		"DialogueManager" => DialogueManager,
		"GamePrefs" => GamePrefs,
		"ItemManager" => ItemManager,
		"LanguageManager" => LanguageManager,
		"Objective" => Objective,
		"ObjectiveManager" => ObjectiveManager,
		"RoomManager" => RoomManager,
		"SaveManager" => SaveManager,
		"StateBackend" => StateBackend,
		"SubStateBackend" => SubStateBackend,
		"CharacterEntity" => CharacterEntity,
		"CollisionBlock" => CollisionBlock,
		"Follower" => Follower,
		"Player" => Player,
		"WorldObject" => WorldObject,
		"GameScript" => GameScript,
		"ScriptedSprite" => ScriptedSprite,
		"ScriptedSpriteGroup" => ScriptedSpriteGroup,
		"ScriptedState" => ScriptedState,
		"ScriptedSubState" => ScriptedSubState,
		"ScriptHandler" => ScriptHandler,
		"TitleMenu" => TitleMenu,
		"BaseRoom" => BaseRoom,
		"Inventory" => Inventory,
		"Language" => Language,
		"Objectives" => Objectives,
		"Obtain" => Obtain,
		"Pause" => Pause,
		"SaveLoad" => SaveLoad,
		"Settings" => Settings,
		"DialogBox" => DialogBox,
		"DialogSelection" => DialogSelection,
		"File" => io.File,
		"FileSystem" => io.FileSystem,
		"LilyAssets" => io.LilyAssets,
		"FlxG" => FlxG,
		"FlxSprite" => FlxSprite,
		"FlxGamepad" => flixel.input.gamepad.FlxGamepad,
		"FlxCamera" => FlxCamera,
		"FlxTween" => FlxTween,
		"FlxEase" => FlxEase,
		"FlxText" => FlxText,
		"FlxGroup" => FlxGroup,
		"FlxTypedGroup" => FlxTypedGroup,
		"Math" => Math,
		"Std" => Std,
		"StringTools" => StringTools
	];

	public var standard(get, never):Dynamic;

	public function get_standard():Dynamic
		return this;

	public var interp:Interp;
	public var parser:Parser;
	public var expr:Expr;

	public var path:String;
	public var active:Bool = true;

	public function new(scriptPath:String, ?parent:Dynamic) {
		this.path = scriptPath;
		var cleanPath = haxe.io.Path.withoutExtension(path);

		if (currentlyLoading.indexOf(cleanPath) != -1) {
			flixel.FlxG.log.error('Circular import detected! Script "$path" is trying to import itself.');
			active = false;
			return;
		}

		currentlyLoading.push(cleanPath);

		var code:String = loadCode(path);
		if (code.length == 0) {
			Iris.warn('Script at $path is empty or not found.', cast {fileName: path, lineNumber: 0});
			currentlyLoading.remove(cleanPath);
			active = false;
			return;
		}

		try {
			interp = new Interp();
			interp.importHandler = _importHandler;
			setParent(parent);

			for (importName => importClass in defaultImports) {
				set(importName, importClass);
			}

			set("openSubState", function(subState:flixel.FlxSubState) {
				flixel.FlxG.state.openSubState(subState);
			});
			set("closeSubState", function() {
				flixel.FlxG.state.closeSubState();
			});
			set("trace", Reflect.makeVarArgs(function(args) {
                trace('[Script: ${path}] ' + args.join(", "));
            }));

			instances.set(cleanPath, this);

			// script caching cuz why not also fixes my problem with sit_pc.hx
			// if (exprCache.exists(path)) {
				// expr = exprCache.get(path);
			// } else {
				parser = new Parser();
				parser.allowTypes = parser.allowMetadata = parser.allowJSON = parser.allowInterpolation = true;
				expr = parser.parseString(code, path);
				exprCache.set(path, expr);
			// }

			interp.execute(expr);
		} catch (e:Dynamic) {
			Iris.error(Std.string(e), cast {fileName: path, lineNumber: 0});
			active = false;
		}

		currentlyLoading.remove(cleanPath);
	}

	private function loadCode(path:String):String {
		if (LilyAssets.fileExists(path))
			return LilyAssets.getTextFromFile(path);
		return "";
	}

	public function setParent(parent:Dynamic) {
		if (interp != null)
			interp.parentInstance = parent;
	}

	@:noCompletion
	private function _importHandler(s:String, as:String, ?star:Bool):Bool {
		var cleanName = StringTools.replace(s, ".", "/");
		var importName = (as != null && StringTools.trim(as) != "") ? as : s.substring(s.lastIndexOf(".") + 1);

		for (key => script in instances) {
			if (key.indexOf(cleanName) != -1 && script.active) {
				interp.imports.set(importName, script);
				return true;
			}
		}

		var p = "scripts/" + cleanName + ".hx";
		if (LilyAssets.fileExists(p)) {
			var newScript = new GameScript(p, interp.parentInstance);
			if (newScript.active) {
				interp.imports.set(importName, newScript);
				return true;
			}
		}

		flixel.FlxG.log.warn('HScript Import Error: Could not resolve "$s" in $path');
		return false;
	}

	public function call(funcName:String, ?args:Array<Dynamic>):Dynamic {
		if (!active || interp == null)
			return null;

		var func = get(funcName);
		if (func != null && Reflect.isFunction(func)) {
			try {
				return Reflect.callMethod(null, func, args != null ? args : []);
			} catch (e:Dynamic) {
				Iris.error('Error calling $funcName in $path: $e', cast {fileName: path, lineNumber: 0});
			}
		}
		return null;
	}

	public function set(name:String, value:Dynamic):Void {
		if (active && interp != null) {
			if (value is Class || value is Enum)
				interp.imports.set(name, value);
			else
				interp.variables.set(name, value);
		}
	}

	public function get(name:String):Dynamic {
		if (!active || interp == null)
			return null;
		if (interp.directorFields != null && interp.directorFields.exists(name)) {
			return interp.directorFields.get(name).value;
		}
		return interp.variables.get(name);
	}

	public function hget(name:String, ?e:Expr):Dynamic {
		if (!active || interp == null)
			return null;
		if (interp.directorFields != null && interp.directorFields.exists(name)) {
			var field = interp.directorFields.get(name);
			if (field.isPublic)
				return field.value;

			Iris.warn('Variable "$name" in script "$path" is not public!', cast {fileName: path, lineNumber: 0});
			return null;
		}
		return interp.variables.get(name);
	}

	public function hset(name:String, value:Dynamic, ?e:Expr):Void {
		if (!active || interp == null)
			return;
		if (interp.directorFields != null && interp.directorFields.exists(name)) {
			var field = interp.directorFields.get(name);
			if (field.isPublic) {
				field.value = value;
				return;
			}
			Iris.warn('Cannot set "$name" in "$path" because it is not public!', cast {fileName: path, lineNumber: 0});
			return;
		}
		interp.variables.set(name, value);
	}

	public function destroy():Void {
		active = false;
		var cleanPath = haxe.io.Path.withoutExtension(path);
		if (instances.exists(cleanPath))
			instances.remove(cleanPath);

		interp = null;
		parser = null;
		expr = null;
	}
}
