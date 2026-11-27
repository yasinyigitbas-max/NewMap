#!/bin/bash
# Builds the traversal system's C++ library (native/traversal/src) for the traversal lab.
#   bash native/traversal/build.sh linux      the library the cloud runs the tests with
#   bash native/traversal/build.sh windows    the library for the exe Yasin play-tests (needs a mingw cross compiler
#                                             and godot-cpp's Windows library)
# Needs godot-cpp, branch 4.5 at 27d9dd2 (the commit native/build.sh uses), built by scons, in $GODOT_CPP
# (default OUT/native_tools/godot-cpp, not in git). The library and the .gdextension file Godot reads go into
# traversal_lab/bin and traversal_lab/traversal.gdextension; neither is in git, so a checkout that has not built
# the library runs the script version and nothing else.
set -u
cd "$(dirname "$0")" || exit 1
HERE=$(pwd)
REPO=$(cd ../.. && pwd)
GODOT_CPP=${GODOT_CPP:-$REPO/OUT/native_tools/godot-cpp}
LAB=$REPO/traversal_lab
JOBS=${JOBS:-4}
TARGET=${1:-linux}
INC="-I$GODOT_CPP/gdextension -I$GODOT_CPP/include -I$GODOT_CPP/gen/include -I$HERE/src"
WARN="-Wall -Wno-unused-parameter -Wno-unused-variable"
case $TARGET in
  linux)
    CXX=${CXX:-g++}
    CFLAGS="-std=c++17 -fno-exceptions -fPIC -fvisibility=hidden -O2 -DLINUX_ENABLED -DUNIX_ENABLED -DTHREADS_ENABLED -DDEBUG_ENABLED -DNDEBUG -DGDEXTENSION"
    LFLAGS="-shared -fvisibility=hidden -Wl,--no-undefined -static-libgcc -static-libstdc++"
    GCLIB=$GODOT_CPP/bin/libgodot-cpp.linux.template_debug.x86_64.a
    OUT=$LAB/bin/libtraversal.linux.x86_64.so ;;
  windows)
    CXX=${CXX:-x86_64-w64-mingw32-g++}      # (the compiler scons built godot-cpp with: the two must use the same thread model)
    CFLAGS="-std=c++17 -fno-exceptions -fvisibility=hidden -O2 -DWINDOWS_ENABLED -DTHREADS_ENABLED -DDEBUG_ENABLED -DNDEBUG -DGDEXTENSION"
    LFLAGS="-shared -fvisibility=hidden -Wl,--no-undefined -static -static-libgcc -static-libstdc++ -s"
    GCLIB=$GODOT_CPP/bin/libgodot-cpp.windows.template_debug.x86_64.a
    OUT=$LAB/bin/traversal.windows.x86_64.dll ;;
  *) echo "usage: build.sh linux|windows"; exit 2 ;;
esac
[ -f "$GCLIB" ] || { echo "TRAVERSAL_BUILD STOP: no $GCLIB (build godot-cpp with scons first)"; exit 2; }
OBJDIR=$REPO/OUT/native_tools/traversal_obj/$TARGET
mkdir -p "$OBJDIR" "$LAB/bin"
fail=0
objs=""
for f in "$HERE"/src/*.cpp; do
  o=$OBJDIR/$(basename "$f" .cpp).o
  objs="$objs $o"
  if [ ! -f "$o" ] || [ "$f" -nt "$o" ] || [ -n "$(find "$HERE/src" -name '*.h' -newer "$o" | head -1)" ]; then
    ( $CXX $CFLAGS $WARN $INC -c "$f" -o "$o" || echo "FAILED $f" ) &
    while [ "$(jobs -r | wc -l)" -ge "$JOBS" ]; do sleep 0.2; done
  fi
done
wait
for o in $objs; do [ -f "$o" ] || fail=1; done
[ $fail = 0 ] || { echo "TRAVERSAL_BUILD STOP: a file did not compile"; exit 1; }
$CXX $LFLAGS $objs "$GCLIB" -o "$OUT" || { echo "TRAVERSAL_BUILD STOP: link"; exit 1; }
cat > "$LAB/traversal.gdextension" <<EOT
[configuration]
entry_symbol = "traversal_init"
compatibility_minimum = "4.5"
reloadable = false

[libraries]
linux.debug.x86_64 = "res://bin/libtraversal.linux.x86_64.so"
linux.release.x86_64 = "res://bin/libtraversal.linux.x86_64.so"
windows.debug.x86_64 = "res://bin/traversal.windows.x86_64.dll"
windows.release.x86_64 = "res://bin/traversal.windows.x86_64.dll"
EOT
echo "TRAVERSAL_BUILD OK: $OUT"
