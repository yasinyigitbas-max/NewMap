#!/bin/bash
# Builds the rays microbenchmark (Linux, a cloud session): bash tools/perf/bench_rays/build.sh, then
#   bash tools/perf/bench_rays/run.sh [godot binary]   (GodotPhysics3D and Jolt)
set -e
H=$(cd "$(dirname "$0")" && pwd); R=$(cd "$H/../../.." && pwd)
G=${GODOT_CPP:-$R/OUT/native_tools/godot-cpp}
g++ -std=c++17 -fno-exceptions -fPIC -fvisibility=hidden -O2 -DLINUX_ENABLED -DUNIX_ENABLED -DTHREADS_ENABLED -DDEBUG_ENABLED -DNDEBUG -DGDEXTENSION \
  -I"$G/gdextension" -I"$G/include" -I"$G/gen/include" -I"$R/native/traversal/src" -shared "$H/bench_rays.cpp" \
  "$G/bin/libgodot-cpp.linux.template_debug.x86_64.a" -Wl,--no-undefined -o "$H/libbench_rays.so"
echo built "$H/libbench_rays.so"
