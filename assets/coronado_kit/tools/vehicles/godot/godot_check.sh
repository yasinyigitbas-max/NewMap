#!/bin/bash
# godot_check.sh <godot binary>: copy the vehicles (glbs + maps) into a scratch project, import, run test_vehicles.gd.
set -e
G=${1:-godot}
HERE=$(cd "$(dirname "$0")" && pwd)
KIT=$(cd "$HERE/../../.." && pwd)
P=$(mktemp -d)
mkdir -p "$P/assets/coronado_kit/vehicles/tex"
cp "$KIT"/vehicles/veh_*.glb "$P/assets/coronado_kit/vehicles/"
cp "$KIT"/vehicles/tex/*.png "$P/assets/coronado_kit/vehicles/tex/"
cp "$HERE/test_vehicles.gd" "$P/"
printf 'config_version=5\n[application]\nconfig/name="vehicles_check"\n[rendering]\nrenderer/rendering_method="mobile"\ntextures/vram_compression/import_etc2_astc=true\n' > "$P/project.godot"
"$G" --headless --path "$P" --import >/dev/null 2>&1 || true
"$G" --headless --path "$P" -s test_vehicles.gd 2>&1 | grep -E "VEHICLE|FAIL|ERROR"
rm -rf "$P"
