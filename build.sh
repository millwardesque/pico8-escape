#!/bin/bash

CODE_ROOT=`pwd`
PICOTOOL_DIR=$CODE_ROOT/../../picotool

> debug.log.p8l
$PICOTOOL_DIR/p8tool build escape.p8 --lua game.lua --lua-path="$CODE_ROOT/?;$CODE_ROOT/?.lua;$CODE_ROOT/lib/?.lua;$CODE_ROOT/src/?.lua"
