#!/bin/bash

CODE_ROOT=`pwd`
PICOTOOL_DIR=$CODE_ROOT/../../picotool
GAME_FILE=game.lua

if [ "$1" != "" ]; then
    GAME_FILE=$1
fi

> debug.log.p8l
$PICOTOOL_DIR/p8tool build escape.p8 --lua $GAME_FILE --lua-path="$CODE_ROOT/?;$CODE_ROOT/?.lua;$CODE_ROOT/lib/?.lua;$CODE_ROOT/src/?.lua"
