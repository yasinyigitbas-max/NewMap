#!/bin/bash
# Builds and runs the physical car's console test (no Godot): bash native/tests/run_veh_test.sh [model]
set -u
cd "$(dirname "$0")/.." || exit 1
GAME=${GAME:-/c/coronado_b17int19_hud_onelap_rebake1_treevis1_mobilevk1_actprobe1_src6_source}
MINGW=${MINGW:-$GAME/tools_native/llvm-mingw-20261104-ucrt-x86_64/bin}
mkdir -p build/tests
"$MINGW/g++" -std=c++17 -O2 -Wall -static -o build/tests/veh_test.exe tests/veh_test.cpp src/veh_dyn.cpp || { echo "VEH_TEST build failed"; exit 2; }
./build/tests/veh_test.exe "$@"
