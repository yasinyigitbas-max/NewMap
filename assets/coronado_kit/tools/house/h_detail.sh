#!/bin/bash
# One Blender at a time, -t 2, nice 19, --python-exit-code 1. Does not use /dev/shm.
set -euo pipefail
ROOT=/workspace/coronado_kit_v2/_staging/house
export IN_KIT=$ROOT/kit
export TMPDIR=/tmp
export BLENDER_USER_SCRIPTS=/tmp/blender_user_scripts_house
mkdir -p "$TMPDIR" "$BLENDER_USER_SCRIPTS" "$ROOT/logs" "$ROOT/previews/house_decor_detail_tiles"
if pgrep -x blender >/dev/null || pgrep -f '[b]lender ' >/dev/null; then
  echo "A Blender process is already running on this box. Wait for it to finish." >&2
  exit 1
fi
echo "DETAIL start  $(date '+%F %T %Z')" | tee -a "$ROOT/logs/build.log"
nice -n 19 /workspace/tools/blender/blender -b -noaudio -t 2 --python-exit-code 1 -P "$ROOT/tools/h_detail.py" -- "$@"
python3 "$ROOT/tools/h_detail.py" --composite
echo "DETAIL done   $(date '+%F %T %Z')" | tee -a "$ROOT/logs/build.log"
