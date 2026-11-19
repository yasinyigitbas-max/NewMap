#!/bin/bash
# Builds and runs the balancing body's console test (no Godot): bash native/tests/run_ped_test.sh
set -u
cd "$(dirname "$0")/.." || exit 1
GAME=${GAME:-/c/coronado_b17int19_hud_onelap_rebake1_treevis1_mobilevk1_actprobe1_src6_source}
MINGW=${MINGW:-$GAME/tools_native/llvm-mingw-20261104-ucrt-x86_64/bin}
mkdir -p build/tests
"$MINGW/g++" -std=c++17 -O2 -Wall -static -o build/tests/ped_test.exe tests/ped_test.cpp src/ped_body.cpp || { echo "PED_TEST build failed"; exit 2; }
./build/tests/ped_test.exe "$@"
