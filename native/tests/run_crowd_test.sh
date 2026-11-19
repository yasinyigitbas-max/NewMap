#!/bin/bash
# Builds and runs the walking crowd's console test (no Godot): bash native/tests/run_crowd_test.sh [seed]
set -u
cd "$(dirname "$0")/.." || exit 1
GAME=${GAME:-/c/coronado_b17int19_hud_onelap_rebake1_treevis1_mobilevk1_actprobe1_src6_source}
MINGW=${MINGW:-$GAME/tools_native/llvm-mingw-20261104-ucrt-x86_64/bin}
mkdir -p build/tests
"$MINGW/g++" -std=c++17 -O2 -Wall -static -ftrivial-auto-var-init=zero -o build/tests/crowd_test.exe tests/crowd_test.cpp src/ped_crowd.cpp src/ped_goals.cpp src/ped_party.cpp src/ped_life.cpp src/street_build.cpp || { echo "CROWD_TEST build failed"; exit 2; }
./build/tests/crowd_test.exe "$@"
