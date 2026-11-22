#!/bin/bash
# A Linux x86_64 copy of the native module, for headless tests in a cloud session (the game's own builds are
# native/build.sh on Yasin's PC: Windows + Android; this script changes nothing of theirs).
#   bash native/build_linux.sh          compile native/src/*.cpp -> native/bin/libcoronado_city.linux.x86_64.so
# Needs godot-cpp (branch 4.5 at 27d9dd2, built once: scons platform=linux target=template_debug) in $GODOT_CPP
# (default /root/native_tools/godot-cpp). Writes native/coronado_city.gdextension (not in git) from the template plus
# the linux lines, so `godot --headless` loads the module.
set -u
cd "$(dirname "$0")" || exit 1
NATIVE=$(pwd)
GODOT_CPP=${GODOT_CPP:-/root/native_tools/godot-cpp}
JOBS=${JOBS:-4}
GCLIB=$GODOT_CPP/bin/libgodot-cpp.linux.template_debug.x86_64.a
[ -f "$GCLIB" ] || { echo "NATIVE_BUILD STOP: $GCLIB missing (scons platform=linux target=template_debug in $GODOT_CPP)"; exit 2; }
INC="-I$GODOT_CPP/gdextension -I$GODOT_CPP/include -I$GODOT_CPP/gen/include -I$NATIVE/src"
CFLAGS="-std=c++17 -fno-exceptions -fPIC -fvisibility=hidden -O2 -DLINUXBSD_ENABLED -DUNIX_ENABLED -DTHREADS_ENABLED -DHOT_RELOAD_ENABLED -DDEBUG_ENABLED -DNDEBUG -DGDEXTENSION"
WARN="-Wall -Wno-unused-parameter -Wno-unused-variable -ftrivial-auto-var-init=zero"
B=$NATIVE/build/linux; OUT=$NATIVE/bin/libcoronado_city.linux.x86_64.so
mkdir -p "$B" "$NATIVE/bin"
newest=$(ls -t "$NATIVE"/src/*.cpp "$NATIVE"/src/*.h | head -1)
objs=""; n=0; FAIL=0
for f in "$NATIVE"/src/*.cpp; do
  o=$B/$(basename "${f%.cpp}").o; objs="$objs $o"
  if [ ! -f "$o" ] || [ "$newest" -nt "$o" ] || [ "$f" -nt "$o" ]; then
    ( g++ -o "$o" -c $CFLAGS $WARN $INC "$f" 2> "$o.log" || { cat "$o.log"; rm -f "$o"; exit 1; }; [ -s "$o.log" ] && grep -E "warning|error" "$o.log" | head -20; exit 0 ) &
    n=$((n + 1)); [ $((n % JOBS)) -eq 0 ] && { wait || FAIL=1; }
  fi
done
wait || FAIL=1
for o in $objs; do [ -f "$o" ] || FAIL=1; done
[ "$FAIL" = "0" ] || { echo "NATIVE_BUILD STOP: compile errors"; exit 1; }
g++ -shared -fvisibility=hidden -o "$OUT" $objs "$GCLIB" || { echo "NATIVE_BUILD STOP: link failed"; exit 1; }
{ cat "$NATIVE/coronado_city.gdextension.in"; echo 'linux.debug.x86_64 = "res://native/bin/libcoronado_city.linux.x86_64.so"'; echo 'linux.release.x86_64 = "res://native/bin/libcoronado_city.linux.x86_64.so"'; } > "$NATIVE/coronado_city.gdextension"
L=$NATIVE/../.godot/extension_list.cfg; mkdir -p "$NATIVE/../.godot"; grep -qs "native/coronado_city.gdextension" "$L" || echo "res://native/coronado_city.gdextension" >> "$L"
echo "NATIVE_BUILD linux: $(basename "$OUT") $(($(stat -c %s "$OUT") / 1024)) KB ($n files compiled)"
