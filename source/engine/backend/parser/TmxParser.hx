package engine.backend.parser;

class TmxParser {
	var roomName:String = "Placeholder";
	public static function read(room:RoomManager, rawData:String, fileName:String, targetSpawnId:Int = 0):Void {
		var parsed:Xml = null;
		try {
			if (rawData.charCodeAt(0) == 0xFEFF)
				rawData = rawData.substr(1);
			parsed = Xml.parse(rawData).firstElement();
		} catch (e:Dynamic) {
			flixel.FlxG.log.error('TMX Parse Error in $fileName: $e');
			return;
		}

		if (parsed == null)
			return;

		var map = new Access(parsed);
		RoomManager.currentRoomName = fileName;

		var mapProps = new Map<String, String>();
		if (map.hasNode.properties) {
			for (prop in map.node.properties.nodes.property) {
				mapProps.set(prop.att.name, prop.has.value ? prop.att.value : "");
			}
		}

		if (mapProps.exists("zoom"))
			room.roomZoom = Std.parseFloat(mapProps.get("zoom"));

		if (mapProps.exists("location"))
			Game.instance.save.location = mapProps.get("location");

		var spawnPlayerMap = true;
		if (mapProps.exists("spawnPlayer")) {
			var spVal = mapProps.get("spawnPlayer");
			spawnPlayerMap = (spVal == "true" || spVal == "1");
		}

		#if FEATURE_HSCRIPT
		if (mapProps.exists("script")) {
			var s = mapProps.get("script");
			if (!StringTools.endsWith(s, ".hx"))
				s += ".hx";
			room.scripts.loadScript("room_global", "scripts/" + s);
		} else {
			var dotIndex = fileName.lastIndexOf(".");
			var autoScriptPath = dotIndex != -1 ? fileName.substr(0, dotIndex) + ".hx" : fileName + ".hx";
			if (LilyAssets.fileExists("scripts/" + autoScriptPath)) {
				room.scripts.loadScript("room_global", "scripts/" + autoScriptPath);
			}
		}
		#end

		var tileWidth = Std.parseInt(map.att.tilewidth);
		var tileHeight = Std.parseInt(map.att.tileheight);
		var mapWidth = Std.parseInt(map.att.width);

		var FLAG_H = 2147483648.0;
		var FLAG_V = 1073741824.0;
		var FLAG_D = 536870912.0;

		var tilesets = new Map<Int, {
			path:String,
			rx:Int,
			ry:Int,
			tw:Int,
			th:Int
		}>();

		for (tsNode in map.nodes.tileset) {
			var firstGid = Std.parseInt(tsNode.att.firstgid);
			if (tsNode.hasNode.image) {
				var source = tsNode.node.image.att.source;
				var tsTw = tsNode.has.tilewidth ? Std.parseInt(tsNode.att.tilewidth) : tileWidth;
				var tsTh = tsNode.has.tileheight ? Std.parseInt(tsNode.att.tileheight) : tileHeight;
				var imgW = Std.parseInt(tsNode.node.image.att.width);
				var cols = tsNode.has.columns ? Std.parseInt(tsNode.att.columns) : Std.int(imgW / tsTw);
				var count = tsNode.has.tilecount ? Std.parseInt(tsNode.att.tilecount) : 0;

				for (i in 0...count) {
					var rx = (cols > 0) ? (i % cols) * tsTw : 0;
					var ry = (cols > 0) ? Std.int(i / cols) * tsTh : 0;
					tilesets.set(firstGid + i, {
						path: source,
						rx: rx,
						ry: ry,
						tw: tsTw,
						th: tsTh
					});
				}
			}
			if (tsNode.hasNode.tile) {
				for (tileNode in tsNode.nodes.tile) {
					if (tileNode.hasNode.image) {
						var id = Std.parseInt(tileNode.att.id);
						var source = tileNode.node.image.att.source;
						tilesets.set(firstGid + id, {
							path: source,
							rx: 0,
							ry: 0,
							tw: Std.parseInt(tileNode.node.image.att.width),
							th: Std.parseInt(tileNode.node.image.att.height)
						});
					}
				}
			}
		}

		var currentZIndex = 0;
		var currentTreeIndex = 0;
		var playerZIndex = 1;
		var hasSpawn = false;

		var objectIdMap = new Map<Int, flixel.FlxSprite>();
		var pendingScripts = new Array<{
			target:Dynamic,
			scriptName:String,
			objProps:Map<String, Int>
		}>();

		for (node in map.elements) {
			if (node.name == "layer") {
				var zIndex = getLayerZ(node, currentZIndex);
				var lName = node.has.name ? node.att.name.toLowerCase() : "";
				if (lName != "")
					room.layerIndices.set(lName, zIndex);

				var layerVisible = true;
				if (node.has.visible)
					layerVisible = node.att.visible != "0" && node.att.visible != "false";

				var isAutoCollision = false;
				if (node.hasNode.properties) {
					for (prop in node.node.properties.nodes.property) {
						if (prop.att.name == "autocollision" && prop.att.value == "true")
							isAutoCollision = true;
					}
				}

				if (node.hasNode.data) {
					var csv = "";
					for (child in node.node.data.x.iterator()) {
						if (child.nodeType == Xml.PCData || child.nodeType == Xml.CData)
							csv += child.nodeValue;
					}

					var tokens = csv.split(",");
					for (i in 0...tokens.length) {
						var gidStr = StringTools.trim(tokens[i]);
						if (gidStr == "")
							continue;

						var rawGidFloat = Std.parseFloat(gidStr);
						if (rawGidFloat == 0 || Math.isNaN(rawGidFloat))
							continue;

						var hFlip = false;
						var vFlip = false;
						var dFlip = false;
						if (rawGidFloat >= FLAG_H) {
							hFlip = true;
							rawGidFloat -= FLAG_H;
						}
						if (rawGidFloat >= FLAG_V) {
							vFlip = true;
							rawGidFloat -= FLAG_V;
						}
						if (rawGidFloat >= FLAG_D) {
							dFlip = true;
							rawGidFloat -= FLAG_D;
						}

						var gid = Std.int(rawGidFloat);

						if (gid > 0 && tilesets.exists(gid)) {
							var ts = tilesets.get(gid);
							var tx = (i % mapWidth) * tileWidth;
							var ty = Std.int(i / mapWidth) * tileHeight;

							if (ts.th > tileHeight)
								ty -= (ts.th - tileHeight);

							var tile = new WorldObject(tx, ty, zIndex, "tile_" + tx + "_" + ty);
							tile.loadGraphic(LilyAssets.image(cleanAssetPath(ts.path)), true, ts.tw, ts.th);

							if (tile.graphic != null) {
								var sheetColumns = Std.int(tile.graphic.width / ts.tw);
								if (sheetColumns > 0)
									tile.animation.frameIndex = (Std.int(ts.ry / ts.th) * sheetColumns) + Std.int(ts.rx / ts.tw);
							}

							applyTmxTransform(tile, hFlip, vFlip, dFlip, 0);

							tile.visible = layerVisible;
							if (!layerVisible)
								tile.alpha = 0;

							tile.solidCollision = isAutoCollision;
							tile.allowCollisions = isAutoCollision ? flixel.FlxObject.ANY : flixel.FlxObject.NONE;
							tile.immovable = true;

							room.addEntity(tile);
							room.sortMap.set(tile, {
								sortY: 0,
								treeIndex: currentTreeIndex++,
								z: zIndex,
								isDynamic: false,
								isFlat: true
							});
						}
					}
				}
				currentZIndex++;
			} else if (node.name == "objectgroup") {
				var zIndex = getLayerZ(node, currentZIndex);
				var gName = node.has.name ? node.att.name.toLowerCase() : "";
				if (gName != "")
					room.layerIndices.set(gName, zIndex);

				var gClass = node.x.exists("class") ? node.x.get("class").toLowerCase() : "";

				if (gClass == "player" || gName == "player" || gName == "characters") {
					playerZIndex = zIndex;
				}

				var groupVisible = true;
				if (node.has.visible)
					groupVisible = node.att.visible != "0" && node.att.visible != "false";

				var groupProps = new Map<String, String>();
				if (node.hasNode.properties) {
					for (prop in node.node.properties.nodes.property) {
						groupProps.set(prop.att.name, prop.has.value ? prop.att.value : "");
					}
				}

				for (objNode in node.nodes.object) {
					var objVisible = true;
					if (objNode.has.visible)
						objVisible = objNode.att.visible != "0" && objNode.att.visible != "false";

					var finalVisible = groupVisible && objVisible;

					var type = objNode.has.type ? objNode.att.type : (objNode.x.exists("class") ? objNode.x.get("class") : "");
					var ox = objNode.has.x ? Std.parseFloat(objNode.att.x) : 0;
					var oy = objNode.has.y ? Std.parseFloat(objNode.att.y) : 0;
					var ow = objNode.has.width ? Std.parseFloat(objNode.att.width) : 32;
					var oh = objNode.has.height ? Std.parseFloat(objNode.att.height) : 32;
					var name = objNode.has.name ? objNode.att.name : "obj";
					var objId = objNode.has.id ? Std.parseInt(objNode.att.id) : 0;

					var hasGid = objNode.has.gid;
					var xmlRot = objNode.has.rotation ? Std.parseFloat(objNode.att.rotation) : 0;

					var rad = xmlRot * Math.PI / 180;
					var cosA = Math.cos(rad);
					var sinA = Math.sin(rad);

					var dx = ow / 2;
					var dy = hasGid ? (-oh / 2) : (oh / 2);

					var rotDx = dx * cosA - dy * sinA;
					var rotDy = dx * sinA + dy * cosA;

					var targetCenterX = ox + rotDx;
					var targetCenterY = oy + rotDy;

					var realX = targetCenterX - (ow / 2);
					var realY = targetCenterY - (oh / 2);

					var objProps = new Map<String, Int>();
					var props = new Map<String, String>();
					for (k in groupProps.keys())
						props.set(k, groupProps.get(k));

					if (objNode.hasNode.properties) {
						for (prop in objNode.node.properties.nodes.property) {
							var pName = prop.att.name;
							var pType = prop.has.type ? prop.att.type : "string";
							var pValue = prop.has.value ? prop.att.value : "";

							if (pType == "object") {
								objProps.set(pName, Std.parseInt(pValue));
							} else {
								props.set(pName, pValue);
							}
						}
					}

					var isSolid = props.get("autocollision") == "true" || props.get("autocollision") == "1";
					var isInteract = props.get("interactable") == "true" || props.get("interactable") == "1";

					var nLower = name.toLowerCase();
					var isFlatObj = props.get("isFlat") == "true" || props.get("isFlat") == "1" || nLower.indexOf("floor") != -1
						|| nLower.indexOf("carpet") != -1;

					switch (type) {
						case "SpawnPoint":
							hasSpawn = true;
							var sId = props.exists("id") ? Std.parseInt(props.get("id")) : 0;
							room.spawnPoints.set("spawn_" + sId, {x: ox, y: oy, dir: "down"});

						case "Collision":
							var solid = new CollisionBlock(realX, realY, Std.int(ow), Std.int(oh));
							solid.visible = finalVisible;
							if (!finalVisible)
								solid.alpha = 0;
							if (objId > 0)
								objectIdMap.set(objId, solid);
							room.solids.add(solid);

						case "Exit":
							var targetRoom = props.exists("room") ? props.get("room") : "";
							var exitId = props.exists("exit") ? Std.parseInt(props.get("exit")) : 0;

							var exitObj = new WorldObject(realX, realY, zIndex, name);
							exitObj.tiledID = objId;
							exitObj.makeGraphic(Std.int(ow), Std.int(oh), 0x8000FF00);
							exitObj.visible = finalVisible;
							if (!finalVisible)
								exitObj.alpha = 0;

							exitObj.immovable = true;
							exitObj.solidCollision = false;
							exitObj.allowCollisions = flixel.FlxObject.NONE;

							if (objId > 0)
								objectIdMap.set(objId, exitObj);
							room.addEntity(exitObj);
							room.quitObjects.set(exitObj, {room: targetRoom, spawnId: exitId});

						case "ObjectTrigger":
							var trigger = new WorldObject(realX, realY, zIndex, name);
							trigger.tiledID = objId;
							trigger.makeGraphic(Std.int(ow), Std.int(oh), 0x00000000);

							trigger.visible = finalVisible;
							if (!finalVisible)
								trigger.alpha = 0;

							trigger.applyProperties(props);
							trigger.solidCollision = false;
							trigger.allowCollisions = flixel.FlxObject.NONE;

							if (objId > 0)
								objectIdMap.set(objId, trigger);
							room.addEntity(trigger);
							room.sortMap.set(trigger, {
								sortY: 0,
								treeIndex: currentTreeIndex++,
								z: zIndex,
								isDynamic: false,
								isFlat: isFlatObj
							});

							if (props.exists("script")) {
								trigger.interactable = true;
								pendingScripts.push({target: trigger, scriptName: props.get("script"), objProps: objProps});
							}

						case "Entity":
							var charName = props.exists("character") ? props.get("character") : name.toLowerCase();
							var charSpawnX = realX + (ow / 2);
							var charSpawnY = hasGid ? realY + oh : realY;

							var spr = new CharacterEntity(charSpawnX, charSpawnY, zIndex, name);
							spr.tiledID = objId;
							spr.loadEntity("", "characters/" + charName);

							if (objNode.has.gid) {
								var rawGidFloat = Std.parseFloat(objNode.att.gid);
								var hFlip = false;
								var vFlip = false;
								var dFlip = false;
								if (rawGidFloat >= FLAG_H) {
									hFlip = true;
									rawGidFloat -= FLAG_H;
								}
								if (rawGidFloat >= FLAG_V) {
									vFlip = true;
									rawGidFloat -= FLAG_V;
								}
								if (rawGidFloat >= FLAG_D) {
									dFlip = true;
									rawGidFloat -= FLAG_D;
								}
								if (hFlip)
									spr.flipX = true;
								if (vFlip)
									spr.flipY = true;
							}

							spr.angle = xmlRot;
							spr.visible = finalVisible;
							if (!finalVisible)
								spr.alpha = 0;

							spr.applyProperties(props);

							if (objId > 0)
								objectIdMap.set(objId, spr);
							room.addEntity(spr);
							room.characters.set(spr.xmlName, spr);
							room.sortMap.set(spr, {
								sortY: 0,
								treeIndex: currentTreeIndex++,
								z: zIndex,
								isDynamic: true,
								isFlat: false
							});

							if (props.exists("script")) {
								spr.interactable = true;
								pendingScripts.push({target: spr, scriptName: props.get("script"), objProps: objProps});
							}

						default:
							if (objNode.has.gid) {
								var rawGidFloat = Std.parseFloat(objNode.att.gid);
								var hFlip = false;
								var vFlip = false;
								var dFlip = false;
								if (rawGidFloat >= FLAG_H) {
									hFlip = true;
									rawGidFloat -= FLAG_H;
								}
								if (rawGidFloat >= FLAG_V) {
									vFlip = true;
									rawGidFloat -= FLAG_V;
								}
								if (rawGidFloat >= FLAG_D) {
									dFlip = true;
									rawGidFloat -= FLAG_D;
								}

								var gid = Std.int(rawGidFloat);

								if (tilesets.exists(gid)) {
									var ts = tilesets.get(gid);
									var spr = new WorldObject(realX, realY, zIndex, name);
									spr.tiledID = objId;
									spr.loadGraphic(LilyAssets.image(cleanAssetPath(ts.path)), true, ts.tw, ts.th);

									if (spr.graphic != null) {
										var sheetColumns = Std.int(spr.graphic.width / ts.tw);
										if (sheetColumns > 0)
											spr.animation.frameIndex = (Std.int(ts.ry / ts.th) * sheetColumns) + Std.int(ts.rx / ts.tw);
									}

									applyTmxTransform(spr, hFlip, vFlip, dFlip, xmlRot);

									spr.generateAccurateHitbox();
									spr.x = realX + spr.offset.x;
									spr.y = realY + spr.offset.y;

									spr.visible = finalVisible;
									if (!finalVisible)
										spr.alpha = 0;

									spr.applyProperties(props);

									if (objId > 0)
										objectIdMap.set(objId, spr);
									room.addEntity(spr);
									room.sortMap.set(spr, {
										sortY: 0,
										treeIndex: currentTreeIndex++,
										z: zIndex,
										isDynamic: false,
										isFlat: isFlatObj
									});

									if (props.exists("script")) {
										spr.interactable = true;
										pendingScripts.push({target: spr, scriptName: props.get("script"), objProps: objProps});
									}
								}
							}
					}
				}
				currentZIndex++;
			} else if (node.name == "imagelayer" || node.name == "group") {
				currentZIndex++;
			}
		}

		#if FEATURE_HSCRIPT
		for (def in pendingScripts) {
			var s = def.scriptName;
			if (!StringTools.endsWith(s, ".hx"))
				s += ".hx";
			var objScript = room.scripts.loadScript(def.target.xmlName, "scripts/" + s);

			if (objScript != null) {
				objScript.set("this", def.target);
				objScript.set("obj", def.target);

				for (propName in def.objProps.keys()) {
					var targetId = def.objProps.get(propName);
					if (objectIdMap.exists(targetId)) {
						objScript.set(propName, objectIdMap.get(targetId));
					} else {
						flixel.FlxG.log.error('Script Linking Error: Script $s failed to link object ID $targetId because it does not exist!');
					}
				}
			}
		}
		#end

		if (hasSpawn && spawnPlayerMap) {
			var startX:Float = 0;
			var startY:Float = 0;

			if (room.spawnPoints.exists("spawn_" + targetSpawnId)) {
				var pt = room.spawnPoints.get("spawn_" + targetSpawnId);
				startX = pt.x;
				startY = pt.y;
			} else if (room.spawnPoints.exists("spawn_0")) {
				var pt = room.spawnPoints.get("spawn_0");
				startX = pt.x;
				startY = pt.y;
			}

			if (room.player == null) {
				room.spawnParty(startX, startY, playerZIndex);
			}
		}
	}

	private static function getLayerZ(node:Access, defaultZ:Int):Int {
		if (node.hasNode.properties) {
			for (prop in node.node.properties.nodes.property) {
				if (prop.att.name == "z")
					return Std.parseInt(prop.att.value);
			}
		}
		return defaultZ;
	}

	private static function cleanAssetPath(rawPath:String):String {
		var clean = StringTools.replace(rawPath, "\\", "/");
		if (clean.endsWith(".png"))
			clean = clean.substring(0, clean.length - 4);
		while (clean.indexOf("../") != -1)
			clean = StringTools.replace(clean, "../", "");
		if (clean.startsWith("images/"))
			clean = clean.substr(7);
		return clean;
	}

	private static function applyTmxTransform(spr:flixel.FlxSprite, hFlip:Bool, vFlip:Bool, dFlip:Bool, rotation:Float = 0):Void {
		spr.angle = rotation;
		spr.flipX = false;
		spr.flipY = false;
		if (dFlip) {
			if (hFlip && !vFlip) {
				spr.angle += 90;
			} else if (!hFlip && vFlip) {
				spr.angle -= 90;
			} else if (hFlip && vFlip) {
				spr.angle += 90;
				spr.flipX = true;
			} else if (!hFlip && !vFlip) {
				spr.angle += 90;
				spr.flipY = true;
			}
		} else {
			if (hFlip && vFlip) {
				spr.angle += 180;
			} else {
				spr.flipX = hFlip;
				spr.flipY = vFlip;
			}
		}
	}
}
