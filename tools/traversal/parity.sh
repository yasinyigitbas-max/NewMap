#!/bin/bash
# The proof of a layer of the C++ port: the same input on the script version and on the C++ version, compared tick by
# tick. usage: bash tools/traversal/parity.sh <a folder for the files>
# Needs the C++ library built (bash native/traversal/build.sh linux). Three runs: every station walked, run, crouched
# and jumped along its lane; two random runs of 20,000 ticks. Ends with PARITY RESULT PASS or FAIL.
set -u
OUT=${1:?a folder for the files}
mkdir -p "$OUT"
cd "$(dirname "$0")/../../traversal_lab" || exit 1
run() { name=$1; shift
  timeout 1700 godot --headless --fixed-fps 60 --path . -s res://tests/parity_run.gd -- --out="$OUT/${name}_script.bin" "$@" > "$OUT/${name}_script.log" 2>&1 &
  timeout 1700 godot --headless --fixed-fps 60 --path . -s res://tests/parity_run.gd -- --out="$OUT/${name}_native.bin" --native "$@" > "$OUT/${name}_native.log" 2>&1
  wait
  grep -h "body is\|detector is\|moves are" "$OUT/${name}_script.log" "$OUT/${name}_native.log" | tr '\n' ' '; echo; }
# (EXTRA="--npc=npc_04" runs the same three with an NPC body in the player's place)
run lanes --lanes ${EXTRA:-}
run r11 --seed=11 --ticks=20000 --noact ${EXTRA:-}
run r23 --seed=23 --ticks=20000 ${EXTRA:-}
python3 -I ../tools/traversal/parity_compare.py "$OUT" lanes r11 r23
