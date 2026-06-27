package engine.ui;

class SpecialNinePatch extends FlxSpriteGroup {
	public var texture(default, set):String;
	public var bgTexture(default, set):String;
	public var bgMaskTexture(default, set):String;
	public var decorTexture(default, set):String;
	public var decorBgTexture(default, set):String;

	public var patchMarginLeft:Int = 0;
	public var patchMarginTop:Int = 0;
	public var patchMarginRight:Int = 0;
	public var patchMarginBottom:Int = 0;
	public var decorMarginTop:Float = 0;
	public var decorMarginBottom:Float = 0;
	public var scaleFactor:Float = 1.0;
	public var bgModulate:FlxColor = FlxColor.WHITE;
	public var drawCenter:Bool = true;

	private var targetWidth:Int;
	private var targetHeight:Int;

	public function new(X:Float = 0, Y:Float = 0) {
		super(X, Y);
	}

	public function setSizeEx(width:Float, height:Float):Void {
		targetWidth = Math.round(width);
		targetHeight = Math.round(height);
		render();
	}

	private function set_texture(value:String):String {
		if (texture != value) {
			texture = value;
			render();
		}
		return value;
	}

	private function set_bgTexture(value:String):String {
		if (bgTexture != value) {
			bgTexture = value;
			render();
		}
		return value;
	}

	private function set_bgMaskTexture(value:String):String {
		if (bgMaskTexture != value) {
			bgMaskTexture = value;
			render();
		}
		return value;
	}

	private function set_decorTexture(value:String):String {
		if (decorTexture != value) {
			decorTexture = value;
			render();
		}
		return value;
	}

	private function set_decorBgTexture(value:String):String {
		if (decorBgTexture != value) {
			decorBgTexture = value;
			render();
		}
		return value;
	}

	public function render():Void {
		clear();
		if (targetWidth <= 0 || targetHeight <= 0)
			return;

		if (bgTexture != null && bgTexture != "") {
			var bgSprite = new FlxSprite(0, 0);
			var bgGraphic = LilyAssets.image(bgTexture);

			if (bgGraphic != null) {
				var finalBgBmp = new BitmapData(targetWidth, targetHeight, true, 0x00000000);

				var bgMat = new Matrix();
				bgMat.scale(targetWidth / bgGraphic.width, targetHeight / bgGraphic.height);
				finalBgBmp.draw(bgGraphic.bitmap, bgMat, null, null, null, true);

				if (bgMaskTexture != null && bgMaskTexture != "") {
					var maskGraphic = LilyAssets.image(bgMaskTexture);
					if (maskGraphic != null) {
						var maskBmp = new BitmapData(targetWidth, targetHeight, true, 0x00000000);

						var x0:Int = 0;
						var x1:Int = Math.round(patchMarginLeft * scaleFactor);
						var x2:Int = targetWidth - Math.round(patchMarginRight * scaleFactor);
						var x3:Int = targetWidth;

						var y0:Int = 0;
						var y1:Int = Math.round(patchMarginTop * scaleFactor);
						var y2:Int = targetHeight - Math.round(patchMarginBottom * scaleFactor);
						var y3:Int = targetHeight;

						var w0 = x1 - x0;
						var w1 = x2 - x1;
						var w2 = x3 - x2;

						var h0 = y1 - y0;
						var h1 = y2 - y1;
						var h2 = y3 - y2;

						var rS = maskGraphic.width - patchMarginRight;
						var bS = maskGraphic.height - patchMarginBottom;
						var mX = maskGraphic.width - patchMarginLeft - patchMarginRight;
						var mY = maskGraphic.height - patchMarginTop - patchMarginBottom;

						// clipRect and Matrix translation for avoiding the sub-pixel edge bleeding ;)
						function drawMaskPiece(rx:Float, ry:Float, rw:Float, rh:Float, dw:Int, dh:Int, px:Int, py:Int) {
							if (dw <= 0 || dh <= 0 || rw <= 0 || rh <= 0)
								return;

							var sx = dw / rw;
							var sy = dh / rh;

							var mat = new Matrix();
							mat.scale(sx, sy);
							mat.translate(px - (rx * sx), py - (ry * sy));

							maskBmp.draw(maskGraphic.bitmap, mat, null, null, new Rectangle(px, py, dw, dh), true);
						}

						drawMaskPiece(0, 0, patchMarginLeft, patchMarginTop, w0, h0, x0, y0);
						drawMaskPiece(patchMarginLeft, 0, mX, patchMarginTop, w1, h0, x1, y0);
						drawMaskPiece(rS, 0, patchMarginRight, patchMarginTop, w2, h0, x2, y0);
						drawMaskPiece(0, patchMarginTop, patchMarginLeft, mY, w0, h1, x0, y1);
						drawMaskPiece(patchMarginLeft, patchMarginTop, mX, mY, w1, h1, x1, y1);
						drawMaskPiece(rS, patchMarginTop, patchMarginRight, mY, w2, h1, x2, y1);
						drawMaskPiece(0, bS, patchMarginLeft, patchMarginBottom, w0, h2, x0, y2);
						drawMaskPiece(patchMarginLeft, bS, mX, patchMarginBottom, w1, h2, x1, y2);
						drawMaskPiece(rS, bS, patchMarginRight, patchMarginBottom, w2, h2, x2, y2);

						finalBgBmp.copyChannel(maskBmp, maskBmp.rect, new Point(0, 0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
						maskBmp.dispose();
					}
				}

				bgSprite.loadGraphic(finalBgBmp);
				bgSprite.updateHitbox();
				bgSprite.color = bgModulate;
				bgSprite.antialiasing = true;
				add(bgSprite);
			}
		}

		if (decorBgTexture != null && decorBgTexture != "") {
			var bmp = LilyAssets.image(decorBgTexture);
			if (bmp != null) {
				var decorBg = new FlxSprite(0, 0);
				decorBg.loadGraphic(bmp);
				decorBg.origin.set(0, 0);
				decorBg.x = Math.round((targetWidth - decorBg.width));
				decorBg.y = Math.round((targetHeight - decorBg.height) / 3);
				decorBg.antialiasing = true;
				add(decorBg);
			}
		}

		if (texture != null && texture != "") {
			var g = LilyAssets.image(texture);
			if (g != null) {
				var finalTexBmp = new BitmapData(targetWidth, targetHeight, true, 0x00000000);

				var x0:Int = 0;
				var x1:Int = Math.round(patchMarginLeft * scaleFactor);
				var x2:Int = targetWidth - Math.round(patchMarginRight * scaleFactor);
				var x3:Int = targetWidth;

				var y0:Int = 0;
				var y1:Int = Math.round(patchMarginTop * scaleFactor);
				var y2:Int = targetHeight - Math.round(patchMarginBottom * scaleFactor);
				var y3:Int = targetHeight;

				var w0 = x1 - x0;
				var w1 = x2 - x1;
				var w2 = x3 - x2;

				var h0 = y1 - y0;
				var h1 = y2 - y1;
				var h2 = y3 - y2;

				var rS = g.width - patchMarginRight;
				var bS = g.height - patchMarginBottom;
				var mX = g.width - patchMarginLeft - patchMarginRight;
				var mY = g.height - patchMarginTop - patchMarginBottom;

				function addF(rx:Float, ry:Float, rw:Float, rh:Float, dw:Int, dh:Int, px:Int, py:Int) {
					if (dw <= 0 || dh <= 0 || rw <= 0 || rh <= 0)
						return;

					var sx = dw / rw;
					var sy = dh / rh;

					var mat = new Matrix();
					mat.scale(sx, sy);
					mat.translate(px - (rx * sx), py - (ry * sy));

					finalTexBmp.draw(g.bitmap, mat, null, null, new Rectangle(px, py, dw, dh), true);
				}

				addF(0, 0, patchMarginLeft, patchMarginTop, w0, h0, x0, y0);
				addF(patchMarginLeft, 0, mX, patchMarginTop, w1, h0, x1, y0);
				addF(rS, 0, patchMarginRight, patchMarginTop, w2, h0, x2, y0);
				addF(0, patchMarginTop, patchMarginLeft, mY, w0, h1, x0, y1);
				if (drawCenter)
					addF(patchMarginLeft, patchMarginTop, mX, mY, w1, h1, x1, y1);
				addF(rS, patchMarginTop, patchMarginRight, mY, w2, h1, x2, y1);
				addF(0, bS, patchMarginLeft, patchMarginBottom, w0, h2, x0, y2);
				addF(patchMarginLeft, bS, mX, patchMarginBottom, w1, h2, x1, y2);
				addF(rS, bS, patchMarginRight, patchMarginBottom, w2, h2, x2, y2);

				var texSprite = new FlxSprite(0, 0);
				texSprite.loadGraphic(finalTexBmp);
				texSprite.antialiasing = true;
				add(texSprite);
			}
		}

		if (decorTexture != null && decorTexture != "") {
			var bmp = LilyAssets.image(decorTexture);
			if (bmp != null) {
				var decor = new FlxSprite(0, 0);
				decor.loadGraphic(bmp);
				decor.origin.set(0, 0);
				decor.scale.set(scaleFactor, scaleFactor);
				decor.x = Math.round((targetWidth - (decor.width * scaleFactor)) / 2);

				if (decorMarginTop > 0)
					decor.y = Math.round(decorMarginTop * scaleFactor);
				else if (decorMarginBottom > 0)
					decor.y = Math.round(targetHeight - (decor.height * scaleFactor) - (decorMarginBottom * scaleFactor));
				else
					decor.y = Math.round((targetHeight - (decor.height * scaleFactor)) / 2);

				decor.antialiasing = true;
				add(decor);
			}
		}
	}
}
