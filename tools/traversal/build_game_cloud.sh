#!/bin/bash
# Linux build of the GAME's module with the traversal classes in it (cloud session only; on Yasin's PC: native/build.sh).
# native/src/*.cpp + native/traversal/src/*.cpp with -DTRAV_IN_GAME -> native/bin/libcoronado_city.linux.x86_64.so.
# A file is compiled again when it, or any header, is newer than its object (FORCE=1: everything).
set -e
R=$(cd "$(dirname "$0")/../.." && pwd); N=$R/native
G=${GODOT_CPP:-$R/OUT/native_tools/godot-cpp}
O=$R/OUT/native_tools/game_obj; mkdir -p "$O" "$N/bin"
INC="-I$G/gdextension -I$G/include -I$G/gen/include -I$N/src -I$N/traversal/src"
CF="-std=c++17 -fno-exceptions -fPIC -fvisibility=hidden -O2 -DLINUXBSD_ENABLED -DUNIX_ENABLED -DTHREADS_ENABLED -DHOT_RELOAD_ENABLED -DDEBUG_ENABLED -DNDEBUG -DGDEXTENSION -DTRAV_IN_GAME -Wall -Wno-unused-parameter -Wno-unused-variable -ftrivial-auto-var-init=zero"
NEWEST_H=$(ls -t "$N"/src/*.h "$N"/traversal/src/*.h "$N"/traversal/src/*.inc | head -1)
export O CF INC NEWEST_H FORCE
ls "$N"/src/*.cpp "$N"/traversal/src/*.cpp | xargs -P4 -I{} sh -c 'f={}; o=$O/$(basename $f .cpp).o; if [ ! -f $o ] || [ $f -nt $o ] || [ "$NEWEST_H" -nt $o ] || [ -n "$FORCE" ]; then g++ $CF $INC -c $f -o $o 2>&1 | grep -E "error" | head -5; echo "built $(basename $f)"; fi'
g++ -shared -o "$N/bin/libcoronado_city.linux.x86_64.so" "$O"/*.o "$G/bin/libgodot-cpp.linux.template_debug.x86_64.a" -Wl,--no-undefined -lpthread
sed '/^\[libraries\]/a linux.debug.x86_64 = "res://native/bin/libcoronado_city.linux.x86_64.so"\nlinux.release.x86_64 = "res://native/bin/libcoronado_city.linux.x86_64.so"' "$N/coronado_city.gdextension.in" > "$N/coronado_city.gdextension"
echo "GAME MODULE BUILT"
