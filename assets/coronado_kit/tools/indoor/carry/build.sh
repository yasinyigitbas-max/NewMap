#!/bin/bash
# carry props: same pipeline as tools/indoor/i_build.sh, scratch kit copy; one Blender box-wide via flock (bl.sh rule)
set -euo pipefail
ROOT=/workspace/coronado_kit_v2/_staging/carry
export IN_KIT=$ROOT/kit TMPDIR=/tmp BLENDER_USER_SCRIPTS=/tmp/blender_user_scripts_carry
mkdir -p "$BLENDER_USER_SCRIPTS"
cd "$IN_KIT/props/_tools"
while pgrep -f "tools/blender/blender" >/dev/null; do sleep 5; done
echo "BUILD $*  $(date '+%F %T %Z')" >> "$ROOT/logs/build.log"
flock /tmp/coronado_blender_box.lock nice -n 19 /workspace/tools/blender/blender -b -noaudio -t 2 --python-exit-code 1 -P run.py -- "$@"
