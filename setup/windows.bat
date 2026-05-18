@echo off
color 0a
cd ..
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git lime https://github.com/ShadowEngineTeam/lime --quiet
haxelib git openfl https://github.com/FunkinCrew/openfl feature/desktop-angle --quiet
haxelib git flixel https://github.com/ArkoseLabsOfficial/flixel-peo peo-mobile --quiet
haxelib install flixel-addons 3.3.2 --quiet
haxelib install flixel-tools 1.5.1 --quiet
haxelib install flixel-ui 2.6.4 --quiet
haxelib git hxcpp https://github.com/ShadowEngineTeam/hxcpp --quiet
echo Finished!
pause
