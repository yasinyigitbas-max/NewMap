#!/bin/bash
# One Blender at a time, -t 2, nice 19. Does not use /dev/shm.
set -euo pipefail
ROOT=/workspace/coronado_kit_v2/_staging/indoor
export IN_KIT=$ROOT/kit
export TMPDIR=/tmp
export BLENDER_USER_SCRIPTS=/tmp/blender_user_scripts_indoor
mkdir -p "$TMPDIR" "$BLENDER_USER_SCRIPTS"
batch=${1:?usage: i_build.sh <batch> [prop names...]}
shift || true
if pgrep -x blender >/dev/null; then
  echo "A Blender process is already running on this box. Wait for it to finish." >&2
  exit 1
fi
cd "$IN_KIT/props/_tools"
echo "BUILD $batch $*  $(date '+%F %T %Z')" | tee -a "$ROOT/logs/build.log"
nice -n 19 /workspace/tools/blender/blender -b -noaudio -t 2 -P run.py -- "$batch" "$@"
echo "DONE $batch  $(date '+%F %T %Z')" | tee -a "$ROOT/logs/build.log"
