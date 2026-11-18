#!/bin/bash
# Build the listed pieces with the real renderer (MultiMesh data needs it), then split their prop batches into cells
# (split_props.gd). REFUSES locked pieces (lock.py status): a locked piece changes only with Yasin's word
# (python3 -I tools/city/pilot/lock.py unlock <piece> --by=Yasin), is rebuilt, re-checked and relocked.
# Usage (repo root): tools/city/run/build.sh <piece> [<piece> ...]      logs: .godot/logs_<piece>.txt
cd "$(dirname "$0")/../../.."
mkdir -p .godot
for p in "$@"; do
  if python3 -I -c "import json,sys; d=json.load(open('map_dc/coronado/city_kit/locked.json')); sys.exit(0 if sys.argv[1] in d.get('pieces',{}) else 1)" "$p"; then
    echo "$p REFUSED: locked (needs Yasin's word + lock.py unlock)"; exit 3
  fi
done
for p in "$@"; do
  timeout 1500 xvfb-run -a -s "-screen 0 640x360x24" godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/pieces/$p.gd > .godot/logs_$p.txt 2>&1
  echo "$p exit $?"; grep -aE "PIECE|tris|MISSING|SCRIPT ERROR|ERROR: Parse|failed to triangulate" .godot/logs_$p.txt | head -8
done
timeout 1200 xvfb-run -a -s "-screen 0 640x360x24" godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/split_props.gd -- "$@" 2>&1 | grep -a "^SPLIT"
