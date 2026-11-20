#!/bin/bash
# One Blender box-wide: -t 2, nice 19, --python-exit-code 1, no /dev/shm (TMPDIR=/tmp).
cd "$(dirname "$0")"
export TMPDIR=/tmp
while pgrep -f "tools/blender/blender" >/dev/null; do sleep 5; done
exec flock /tmp/coronado_blender_box.lock nice -n 19 /workspace/tools/blender/blender -b -noaudio -t 2 --python-exit-code 1 -P "$1" -- "${@:2}"
