#!/bin/bash
# CITY LIGHT (look uplift, 28 Nov): the island's sky and height maps, made from the runtime bake. Run after every bake
# (phone_rig.sh bake does). Writes runtime/far/city_ao.res, city_hg.res, city_light.json (+ previews). ~2-3 minutes.
#   bash tools/city/look/city_light.sh            (GODOT=... to pick the engine; python with numpy, scipy, Pillow)
set -e
cd "$(dirname "$0")/../../.."
GODOT=${GODOT:-/c/Users/yasin/Godot_v4.7.2-stable_win64.exe}
PY=$(command -v python || command -v python3 || command -v py)
"$GODOT" --path . --render-thread safe --rendering-method mobile --resolution 640x360 -s res://tools/city/look/city_light_bake.gd 2>&1 | grep -a "^CITYLIGHT"
"$PY" -I tools/city/look/make_city_light.py map_dc/coronado/city_kit/runtime | grep -a "^CITYLIGHT"
"$GODOT" --headless --path . -s res://tools/city/look/city_light_bake.gd -- --pack 2>&1 | grep -a "^CITYLIGHT"
test -f map_dc/coronado/city_kit/runtime/far/city_ao.res && echo "CITYLIGHT_DONE"
