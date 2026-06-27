#if !macro

/* Source Code */
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

/* Objective */
import engine.backend.Objective.ObjectiveData;

/* BACKEND */
import engine.backend.game.*;
import engine.backend.parser.*;
import engine.backend.save.*;
import engine.backend.ui.*;
import engine.backend.*;

/* UI */
import engine.ui.*;
import engine.ui.LacieUIExperimental.MenuFrameNode;
import engine.ui.LacieUIExperimental.MenuVisualEntry;
import engine.ui.LacieUIExperimental.SimpleVerticalMenu;
import engine.ui.SpecialNinePatch;


/* Scripted Classes */
#if FEATURE_HSCRIPT
import engine.scripting.ScriptedSprite;
import engine.scripting.ScriptedSpriteGroup;
import engine.scripting.ScriptedState;
import engine.scripting.ScriptedSubState;
#end

/* Assets */
import io.File;
import io.FileSystem;
import io.LilyAssets;

/* Flixel */
import flixel.util.FlxCollision;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxG;
import flixel.util.FlxSort;
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
import flixel.util.FlxDestroyUtil;
import flixel.text.FlxText;
import flixel.system.FlxAssets;
import flixel.util.FlxSave;
import flixel.graphics.frames.FlxImageFrame;

/* Haxe */
import haxe.xml.Access;
import haxe.Json;

/* Lime */
import lime.system.System;

/* OpenFL */
import openfl.geom.ColorTransform;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.geom.Point;


using StringTools;
#end