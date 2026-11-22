#!/bin/bash
# Indoor-places props (page K, b_inplaces.py): same pipeline as tools/indoor/i_build.sh on a scratch kit copy
# (kit/props/_tools = tools/indoor/builders; kit/atlases/props_atlas.json = repo copy + places/props_k_regions.json merged in;
#  kit/props/_bake_src/props_k_base_* = page-I base copied). One Blender box-wide via flock. Usage: build.sh inplaces [names]
set -euo pipefail
ROOT=${INK_ROOT:-/workspace/coronado_kit_v2/_staging/indoor_k}
export IN_KIT=$ROOT/kit TMPDIR=/tmp BLENDER_USER_SCRIPTS=/tmp/blender_user_scripts_indoor_k
mkdir -p "$BLENDER_USER_SCRIPTS"
cd "$IN_KIT/props/_tools"
while pgrep -f "tools/blender/blender" >/dev/null; do sleep 5; done
flock /tmp/coronado_blender_box.lock nice -n 19 /workspace/tools/blender/blender -b -noaudio -t 2 --python-exit-code 1 -P run.py -- "$@"
python3 "$(dirname "$0")/../i_fix_occ.py" "$IN_KIT"/props/indoor/places/*_clean_near.glb >/dev/null   # occlusionTexture -> ORM (repo convention)
