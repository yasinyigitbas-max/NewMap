#!/bin/bash
# Phone perf budget gate (<=150 draws, <=300k tris, <=1 GB video at busy spots, High preset). Real render via xvfb.
# usage: tools/perf_budget.sh [--shots DIR] [--hide Cars] [--detail] [--spots a,b]   (from dense_core/; exit 1 = over budget)
# One Godot process per spot (the box is RAM-limited); takes /tmp/godot.lock.citygame unless PERF_NOLOCK=1.
cd "$(dirname "$0")/.."
G=${GODOT:-/workspace/tools/godot472/Godot_v4.7.2-stable_linux.x86_64}
SPOTS=street_start,orange_900_se,orange_900_nw,hotel_del,beach_village
args=(); while [ $# -gt 0 ]; do if [ "$1" = --spots ]; then SPOTS=$2; shift 2; else args+=("$1"); shift; fi; done
[ -z "$PERF_NOLOCK" ] && { exec 9>/tmp/godot.lock.citygame; flock -w 3600 9 || exit 2; }
rc=0
for s in ${SPOTS//,/ }; do
  out=$(timeout ${PERF_TIMEOUT:-2700} xvfb-run -a -s "-screen 0 1280x720x24" $G --rendering-driver opengl3 --resolution 1280x720 --path . -s res://tests/perf/perf_budget.gd -- --budget --spots $s "${args[@]}" 2>&1)
  c=$?; echo "$out" | grep -E "^PERF"; [ $c -ne 0 ] && rc=1
  echo "$out" | grep -q "^PERF_BUDGET" || { echo "PERF_BUDGET ERROR $s (exit $c)"; rc=1; }
done
echo "PERF_BUDGET_ALL $([ $rc = 0 ] && echo PASS || echo FAIL)"; exit $rc
