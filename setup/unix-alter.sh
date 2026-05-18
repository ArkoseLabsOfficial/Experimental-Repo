#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..
echo Makking the main haxelib and setuping folder in same time..
haxelib setup ~/haxelib
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git lime https://github.com/ArkoseLabsOfficial/lime main --quiet --global
haxelib install openfl 9.3.3 --quiet --global
haxelib git flixel https://github.com/ArkoseLabsOfficial/flixel-peo peo-mobile --quiet --global
haxelib install flixel-addons 3.3.2 --quiet --global
haxelib install flixel-tools 1.5.1 --quiet --global
haxelib install flixel-ui 2.6.4 --quiet --global
haxelib git hxcpp https://github.com/ShadowEngineTeam/hxcpp --quiet --global
echo Finished!
