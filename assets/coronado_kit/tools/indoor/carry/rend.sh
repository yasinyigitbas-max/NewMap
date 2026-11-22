#!/bin/bash
cd /workspace/coronado_kit_v2/_staging/carry
while pgrep -f "tools/blender/blender" >/dev/null; do sleep 5; done
TMPDIR=/tmp flock /tmp/coronado_blender_box.lock nice -n 19 /workspace/tools/blender/blender -b -noaudio -t 2 --python-exit-code 1 -P c_render.py -- "$@" 2>&1 | grep -i "error\|Traceback" | tail -8
echo RENDER_DONE
