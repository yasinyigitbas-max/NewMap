#!/bin/bash
# Runs the rays microbenchmark on both physics engines: bash tools/perf/bench_rays/run.sh [godot binary] [rays]
# (build first: bash tools/perf/bench_rays/build.sh). The engine is chosen by an override.cfg made here, removed after.
H=$(cd "$(dirname "$0")" && pwd); GD=${1:-godot}; N=${2:-20000}
for eng in "GodotPhysics3D" "Jolt Physics"; do
  printf '[physics]\n3d/physics_engine="%s"\n' "$eng" > "$H/override.cfg"
  "$GD" --headless --path "$H" -s res://bench.gd -- --rays=$N 2>&1 | grep "BENCH\|ERROR"
done
rm -f "$H/override.cfg"
