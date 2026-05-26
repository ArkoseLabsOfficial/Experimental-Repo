package mobile;

import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import mobile.MobileConfig.ButtonModes;

/**
 * A modified FlxVirtualPad works with IDs.
 * It's really easy to customize the layout.
 * @author ArkoseLabs
 */
@:access(mobile.MobileButton)
class MobilePad extends MobileInputHandler {
	public var onButtonDown:FlxTypedSignal<(MobileButton, Array<String>, Int) -> Void> = new FlxTypedSignal<(MobileButton, Array<String>, Int) -> Void>();
	public var onButtonUp:FlxTypedSignal<(MobileButton, Array<String>, Int) -> Void> = new FlxTypedSignal<(MobileButton, Array<String>, Int) -> Void>();
	public var instance:MobileInputHandler;
	public var buttons:Array<Array<MobileButton>> = [[], []]; // [dpads], [actions]
	public var buttonMap:Map<String, MobileButton> = [];
    public var lastDPadName:String = "NONE";
    public var lastActionName:String = "NONE";

	public function getButton(name:String):MobileButton
		return buttonMap.get(name);

	public function getIndex(name:String, type:String = "DPad"):Int {
		var btn = buttonMap.get(name);
		if (btn == null) return -1;

		return switch(type.toUpperCase()) {
			case "DPAD":
				buttons[0].indexOf(btn);
			case "ACTION":
				buttons[1].indexOf(btn);
			default:
				0;
		}
	}

	/**
	 * Create a virtual gamepad.
	 *
	 * @param   DPadMode   The D-Pad mode. `"FULL"` for example.
	 * @param   ActionMode   The action buttons mode. `"A_B_C"` for example.
	 * @param   buttonCreation   The button creation.
	 */
	public function new(DPad:String = "NONE", Action:String = "NONE", buttonCreation:Bool = true) {
		super();
        this.lastDPadName = DPad;
        this.lastActionName = Action;

		if (buttonCreation)
		{
			if (DPad != "NONE")
			{
				if (!MobileConfig.dpadModes.exists(DPad))
					throw 'The mobilePad dpadMode "$DPad" doesn\'t exists.';

				for (buttonData in MobileConfig.dpadModes.get(DPad).buttons)
				{
					if (buttonData.scale == null) buttonData.scale = 1.0;
					var btnName:String = buttonData.button;
					var btnIDs:Array<String> = buttonData.buttonIDs;
					var btnUniqueID:Int = (buttonData.buttonUniqueID != null ? buttonData.buttonUniqueID : -1);
					var btnGraphic:String = buttonData.graphic;
					var btnScale:Float = buttonData.scale;
					var btnColor = buttonData.color;
					var btnX:Float = buttonData.position[0];
					var btnY:Float = buttonData.position[1];

					var btnReturn:String = "NONE";
					if (buttonData.returnKey != null) btnReturn = buttonData.returnKey;

					addButton(btnName, btnIDs, btnUniqueID, btnX, btnY, btnGraphic, btnScale, Util.colorFromString(btnColor), btnReturn, DPAD);
				}
			}

			if (Action != "NONE")
			{
				if (!MobileConfig.actionModes.exists(Action))
					throw 'The mobilePad actionMode "$Action" doesn\'t exists.';

				for (buttonData in MobileConfig.actionModes.get(Action).buttons)
				{
					if (buttonData.scale == null) buttonData.scale = 1.0;
					var btnName:String = buttonData.button;
					var btnIDs:Array<String> = buttonData.buttonIDs;
					var btnUniqueID:Int = (buttonData.buttonUniqueID != null ? buttonData.buttonUniqueID : -1);
					var btnGraphic:String = buttonData.graphic;
					var btnColor = buttonData.color;
					var btnScale:Float = buttonData.scale;
					var btnX:Float = buttonData.position[0];
					var btnY:Float = buttonData.position[1];

					var btnReturn:String = "NONE";
					if (buttonData.returnKey != null) btnReturn = buttonData.returnKey;

					addButton(btnName, btnIDs, btnUniqueID, btnX, btnY, btnGraphic, btnScale, Util.colorFromString(btnColor), btnReturn, ACTION);
				}
			}
		}

		scrollFactor.set();
		updateTrackedButtons();

		instance = this;
	}

	public function addButton(name:String, IDs:Array<String>, uniqueID:Int = -1, X:Float, Y:Float, Graphic:String, Scale:Float = 1.0, Color:Int = 0xFFFFFF, returned:String = "NONE", indexType:ButtonModes = DPAD) {
		var button:MobileButton = createVirtualButton(X, Y, Graphic, Scale, Color, returned);
		button.name = name;
		button.uniqueID = uniqueID;
		button.IDs = IDs;
		button.onDown.callback = () -> onButtonDown.dispatch(button, IDs, uniqueID);
		button.onOut.callback = button.onUp.callback = () -> onButtonUp.dispatch(button, IDs, uniqueID);

		add(button);
		buttonMap.set(name, button);
		var groupIndex = (indexType == DPAD) ? 0 : 1;
		buttons[groupIndex].push(button);
	}

	public function createVirtualButton(x:Float, y:Float, framePath:String, ?scale:Float = 1.0, ?ColorS:Int = 0xFFFFFF, ?returned:String):MobileButton {
		var frames:FlxGraphic;

		final path:String = MobileConfig.mobileFolderPath + 'MobilePad/Textures/$framePath.png';
		if(Assets.exists(path))
			frames = FlxGraphic.fromBitmapData(Assets.getBitmapData(path));
		else
			frames = FlxGraphic.fromBitmapData(Assets.getBitmapData(MobileConfig.mobileFolderPath + 'MobilePad/Textures/default.png'));

		var button = new MobileButton(x, y, returned);
		button.scale.set(scale, scale);
		button.frames = FlxTileFrames.fromGraphic(frames, FlxPoint.get(Std.int(frames.width / 2), frames.height));

		button.updateHitbox();
		button.updateLabelPosition();

		button.bounds.makeGraphic(Std.int(button.width - 50), Std.int(button.height - 50), FlxColor.TRANSPARENT);
		button.centerBounds();

		button.immovable = true;
		button.solid = button.moves = false;
		button.antialiasing = true;
		button.tag = framePath.toUpperCase();

		if (ColorS != -1) button.color = ColorS;
		return button;
	}

	/**
	 * Clean up memory.
	 */
	override function destroy():Void
	{
		super.destroy();
		onButtonUp.destroy();
		onButtonDown.destroy();
		buttons = [[], []];
		buttonMap.clear();
	}
}