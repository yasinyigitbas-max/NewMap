#!/bin/bash
# audition.sh <kind: walk|run> <takes...>: bake each take as KM_Walk / KM_Run and run the study audit with it
S=/tmp/claude-0/-home-user-NewMap/a169f1dd-5d07-5ed7-a403-bd21503051a4/scratchpad; G=$S/godot/Godot_v4.7.2-stable_linux.x86_64
cd /home/user/NewMap/traversal_lab
kind=$1; shift
name=KM_Walk; [ "$kind" = run ] && name=KM_Run
for t in "$@"; do
  cp $S/kimodo/out/$t/fixed.fbx assets_src/clips/$name.fbx
  timeout 100 $G --headless --path . --import >/dev/null 2>&1
  timeout 100 $G --headless --path . -s res://tools/build_clips.gd 2>&1 | grep "^$name \|stride cut" | cut -c1-110
  echo "=== $t"
  timeout 100 $G --headless --path . --fixed-fps 60 -s res://tests/test_study.gd -- --$kind=$name 2>&1 | grep -A16 -- "--- $kind" | grep "FAIL\|at .* m/s" | cut -c1-150
done
