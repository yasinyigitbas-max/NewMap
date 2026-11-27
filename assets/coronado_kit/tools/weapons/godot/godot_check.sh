#!/bin/bash
# godot_check.sh <godot binary>: copy the weapons + atlas page into a scratch project, import, run test_weapons.gd.
set -e
G=${1:-godot}
HERE=$(cd "$(dirname "$0")" && pwd)
KIT=$(cd "$HERE/../../.." && pwd)            # assets/coronado_kit
P=$(mktemp -d)
mkdir -p "$P/assets/coronado_kit/props/weapons" "$P/assets/coronado_kit/atlases"
cp "$KIT"/props/weapons/*.glb "$P/assets/coronado_kit/props/weapons/"
cp "$KIT"/atlases/props_g_*.png "$P/assets/coronado_kit/atlases/"
cp "$HERE/test_weapons.gd" "$P/"
printf 'config_version=5\n[application]\nconfig/name="weapons_check"\n[rendering]\nrenderer/rendering_method="mobile"\ntextures/vram_compression/import_etc2_astc=true\n' > "$P/project.godot"
"$G" --headless --path "$P" --import >/dev/null 2>&1 || true
"$G" --headless --path "$P" -s test_weapons.gd 2>&1 | grep -E "WEAPON|FAIL|ERROR"
rm -rf "$P"
