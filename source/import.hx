#if !macro

/* Source Code */
import engine.backend.*;
import macros.*;
#if FEATURE_TOUCH_CONTROLS
import mobile.*;
#end
import engine.objects.*;
import engine.scripting.*;
import engine.scripting.events.*;
import engine.states.*;
import engine.substates.*;
import engine.ui.*;


/* Scripted Classes */
import engine.scripting.ScriptedSprite;
import engine.scripting.ScriptedSpriteGroup;
import engine.scripting.ScriptedState;
import engine.scripting.ScriptedSubState;

/* Assets */
import io.File;
import io.FileSystem;
import io.LilyAssets;

/* Flixel */
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import engine.states.options.*;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.text.FlxTypeText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.text.FlxText;

/* Haxe */
import haxe.xml.Access;

/* Lime */
import lime.system.System;

/* OpenFL */
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;


using StringTools;
#end