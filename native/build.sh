#!/bin/bash
# Builds the new map's native module (native/src -> native/bin) on Yasin's PC, in Git Bash:
#   bash native/build.sh            the Windows dll (debug checks on) + the Android arm64 .so
#   bash native/build.sh windows | android | clean | status
# It compiles native/src/*.cpp with the SAME flags godot-cpp's own scons uses (read from `scons -n verbose=yes` on
# 19 Nov 2026) and links against godot-cpp's static library. No scons run per build: a full build of the module
# takes seconds, and no checkout rebuilds godot-cpp. Objects go to native/build/, libraries to native/bin/, and the
# file Godot reads (native/coronado_city.gdextension) is copied from its template. None of the three is in git
# (docs/TRAFFIC_PEOPLE_PORT.md "The BUILD": a checkout that has not built the module never loads it).
#
# Needs (all on this PC; override by environment):
#   NATIVE_TOOLS  a folder outside git for godot-cpp (default: the main checkout's OUT/native_tools)
#   GODOT_CPP     godot-cpp, branch 4.5 at 27d9dd2 + one line (#include <cstdlib> in src/godot.cpp). Made here when
#                 missing: cloned; its two static libraries are taken from the old game's tools folder when they
#                 are there (same commit), else built once by scons (about an hour each on this PC)
#   MINGW         llvm-mingw's bin folder (the Windows compiler)
#   ANDROID_HOME  the Android SDK with the NDK NDK_VERSION
# A dll that a running Godot has loaded cannot be overwritten on Windows: close Godot (and the editor) first.
set -u
cd "$(dirname "$0")" || exit 1
NATIVE=$(pwd)
GAME=${GAME:-/c/coronado_b17int19_hud_onelap_rebake1_treevis1_mobilevk1_actprobe1_src6_source}
NATIVE_TOOLS=${NATIVE_TOOLS:-/c/Users/yasin/NewMap/OUT/native_tools}
GODOT_CPP=${GODOT_CPP:-$NATIVE_TOOLS/godot-cpp}
GODOT_CPP_COMMIT=27d9dd2
# (28 Nov: the game folder and its copy were deleted; the same release, mstorsjo/llvm-mingw 20261104, downloaded again
# with Yasin's OK to C:/Users/yasin/tools_native)
MINGW_HOME=/c/Users/yasin/tools_native/llvm-mingw-20261104-ucrt-x86_64/bin
[ -d "$MINGW_HOME" ] || MINGW_HOME=$GAME/tools_native/llvm-mingw-20261104-ucrt-x86_64/bin
MINGW=${MINGW:-$MINGW_HOME}
ANDROID_HOME=${ANDROID_HOME:-/c/Users/yasin/AppData/Local/Android/Sdk}
NDK_VERSION=${NDK_VERSION:-29.0.14206865}
# Windows programs (the compilers) get C:/... paths from here on: phone_rig.sh runs with MSYS_NO_PATHCONV=1, under
# which Git Bash hands /c/... over unchanged and the compiler finds nothing
if command -v cygpath >/dev/null; then
  NATIVE=$(cygpath -m "$NATIVE"); GODOT_CPP=$(cygpath -m "$GODOT_CPP"); MINGW=$(cygpath -m "$MINGW"); ANDROID_HOME=$(cygpath -m "$ANDROID_HOME"); NATIVE_TOOLS=$(cygpath -m "$NATIVE_TOOLS"); GAME=$(cygpath -m "$GAME")
fi
NDK_BIN=$ANDROID_HOME/ndk/$NDK_VERSION/toolchains/llvm/prebuilt/windows-x86_64/bin
NAME=coronado_city
JOBS=${JOBS:-4}
die() { echo "NATIVE_BUILD STOP: $*"; exit 2; }
PY=$(command -v python || command -v python3 || command -v py) || PY=""

INC="-I$GODOT_CPP/gdextension -I$GODOT_CPP/include -I$GODOT_CPP/gen/include -I$NATIVE/src"
WARN="-Wall -Wno-unused-parameter -Wno-unused-variable -ftrivial-auto-var-init=zero"   # (unused-variable: godot-cpp's own GDCLASS macro trips it in every class)
# target -> compiler, compile flags, link flags, godot-cpp library, output
setup() {
  case $1 in
    windows)
      CXX="$MINGW/g++"; OBJ=o
      CFLAGS="-std=c++17 -fno-exceptions -Wwrite-strings -fvisibility=hidden -O2 -DWINDOWS_ENABLED -DTHREADS_ENABLED -DHOT_RELOAD_ENABLED -DDEBUG_ENABLED -DNDEBUG -DGDEXTENSION"
      LFLAGS="-Wl,--no-undefined -static -static-libgcc -static-libstdc++ -fvisibility=hidden -s -shared"
      GCLIB=$GODOT_CPP/bin/libgodot-cpp.windows.template_debug.x86_64.a
      OUT=$NATIVE/bin/$NAME.windows.x86_64.dll
      SCONS_ARGS="platform=windows use_mingw=yes use_llvm=yes arch=x86_64 target=template_debug" ;;
    android)
      # ONE Android library, built like godot-cpp's template_release (no debug checks), used by debug AND release
      # exports: the extension interface is plain C, so a release module loads in a debug engine. (godot-cpp's
      # Android debug library is a 60-minute build on this 4-thread PC, and the old game's release APK crashed at
      # start when its release library was missing: one library cannot go missing.)
      CXX="$NDK_BIN/clang++"; OBJ=os
      CFLAGS="-std=c++17 -fno-exceptions --target=aarch64-linux-android24 -march=armv8-a -fPIC -fvisibility=hidden -O3 -DANDROID_ENABLED -DUNIX_ENABLED -DTHREADS_ENABLED -DNDEBUG -DGDEXTENSION"
      # -static-libstdc++: the APK ships no libc++_shared.so for extensions (the old game's rule)
      LFLAGS="--target=aarch64-linux-android24 -march=armv8-a -fvisibility=hidden -s -shared -static-libstdc++ -Wl,--exclude-libs,ALL"   # (exclude-libs: the static C++ runtime's symbols are not exported, so they cannot meet the engine's own)
      GCLIB=$GODOT_CPP/bin/libgodot-cpp.android.template_release.arm64.a
      OUT=$NATIVE/bin/lib$NAME.android.arm64.so
      SCONS_ARGS="platform=android arch=arm64 target=template_release ndk_version=$NDK_VERSION" ;;
    linux)
      # a cloud session (Linux, no Windows tools): the system g++, godot-cpp's linux template_debug library. For tests
      # in the cloud only (docs/damage/STATUS.md): GODOT_CPP=/path/to/godot-cpp bash native/build.sh linux
      CXX=${LINUX_CXX:-$(command -v g++)}; OBJ=lo
      CFLAGS="-std=c++17 -fno-exceptions -fPIC -fvisibility=hidden -O2 -DLINUXBSD_ENABLED -DUNIX_ENABLED -DTHREADS_ENABLED -DHOT_RELOAD_ENABLED -DDEBUG_ENABLED -DNDEBUG -DGDEXTENSION"
      LFLAGS="-shared -fvisibility=hidden -static-libgcc -static-libstdc++ -s"
      GCLIB=$GODOT_CPP/bin/libgodot-cpp.linux.template_debug.x86_64.a
      OUT=$NATIVE/bin/lib$NAME.linux.x86_64.so
      SCONS_ARGS="platform=linux arch=x86_64 target=template_debug" ;;
    *) die "unknown target $1" ;;
  esac
}

# godot-cpp: the checkout, then its static library for the target (scons, once)
need_godot_cpp() {
  if [ ! -d "$GODOT_CPP" ]; then
    mkdir -p "$(dirname "$GODOT_CPP")"
    if [ -d "$GAME/tools_native/godot-cpp/.git" ]; then git clone -q "$GAME/tools_native/godot-cpp" "$GODOT_CPP" || die "godot-cpp: clone failed"
    else git clone -q -b 4.5 https://github.com/godotengine/godot-cpp "$GODOT_CPP" || die "godot-cpp: clone failed"; fi
    (cd "$GODOT_CPP" && git checkout -q $GODOT_CPP_COMMIT) || die "godot-cpp: commit $GODOT_CPP_COMMIT not found"
  fi
  grep -q "include <cstdlib>" "$GODOT_CPP/src/godot.cpp" || sed -i 's|^#include <godot_cpp/godot.hpp>|#include <cstdlib>   // newer llvm-mingw libc++ does not pull realloc / free in\n#include <godot_cpp/godot.hpp>|' "$GODOT_CPP/src/godot.cpp"
  # the old game's tools folder has the same godot-cpp (same commit, same line) already built: take its library
  local OLD=$GAME/tools_native/godot-cpp
  if [ ! -f "$GCLIB" ] && [ -f "$OLD/bin/$(basename "$GCLIB")" ] && [ "$(cd "$OLD" && git rev-parse --short HEAD)" = "$(cd "$GODOT_CPP" && git rev-parse --short HEAD)" ]; then
    mkdir -p "$GODOT_CPP/bin"; cp "$OLD/bin/$(basename "$GCLIB")" "$GCLIB"; [ -d "$GODOT_CPP/gen/include" ] || cp -r "$OLD/gen" "$GODOT_CPP/gen"
  fi
  if [ ! -f "$GCLIB" ]; then
    [ -n "$PY" ] || die "python not found (scons builds godot-cpp once)"
    echo "NATIVE_BUILD godot-cpp for '$1' is not built yet: building it with scons (about an hour on 4 threads, once)"
    # one scons at a time on a godot-cpp checkout: two regenerate gen/ and break each other
    (cd "$GODOT_CPP" && PATH="$MINGW:$PATH" ANDROID_HOME="$ANDROID_HOME" "$PY" -m SCons $SCONS_ARGS -j"$JOBS" > "$NATIVE_TOOLS/godot_cpp_$1.log" 2>&1) || die "godot-cpp build failed: see $NATIVE_TOOLS/godot_cpp_$1.log"
    [ -f "$GCLIB" ] || die "godot-cpp built but $GCLIB is missing"
  fi
}

build() {
  setup "$1"; need_godot_cpp "$1"
  [ -x "$CXX" ] || [ -x "$CXX.exe" ] || die "compiler not found: $CXX"
  local B=$NATIVE/build/$1; mkdir -p "$B" "$NATIVE/bin"
  # an object is rebuilt when ANY file of src/ is newer than it (headers included): simple, and the module is small
  # (the traversal system's sources, native/traversal/src, are compiled into this module too: TRAV_IN_GAME)
  local newest; newest=$(ls -t "$NATIVE"/src/*.cpp "$NATIVE"/src/*.h "$NATIVE"/traversal/src/*.cpp "$NATIVE"/traversal/src/*.h "$NATIVE"/traversal/src/*.inc "$NATIVE/build.sh" | head -1)
  local objs="" n=0 pids="" f o
  for f in "$NATIVE"/src/*.cpp "$NATIVE"/traversal/src/*.cpp; do
    o=$B/$(basename "${f%.cpp}").$OBJ; objs="$objs $o"
    if [ ! -f "$o" ] || [ "$newest" -nt "$o" ]; then
      ( "$CXX" -o "$o" -c $CFLAGS -DTRAV_IN_GAME $WARN $INC -I"$NATIVE/traversal/src" "$f" 2> "$o.log" || { cat "$o.log"; rm -f "$o"; exit 1; }; [ -s "$o.log" ] && cat "$o.log"; exit 0 ) &
      pids="$pids $!"; n=$((n + 1))
      if [ $((n % JOBS)) -eq 0 ]; then for p in $pids; do wait "$p" || FAIL=1; done; pids=""; fi
    fi
  done
  for p in $pids; do wait "$p" || FAIL=1; done
  [ "${FAIL:-0}" = "0" ] || die "compile errors ($1)"
  for o in $objs; do [ -f "$o" ] || die "compile errors ($1)"; done
  if [ $n -gt 0 ] || [ ! -f "$OUT" ]; then
    "$CXX" $LFLAGS -o "$OUT.new" $objs "$GCLIB" || die "link failed ($1)"
    mv -f "$OUT.new" "$OUT" 2>/dev/null || die "cannot replace $OUT: a running Godot has it loaded; close it and run again"
  fi
  echo "NATIVE_BUILD $1: $(basename "$OUT") $(($(stat -c %s "$OUT") / 1024)) KB ($n files compiled)"
}

finish() {
  # the file Godot reads, and the list it loads extensions from (written by the editor's scan; added here so a plain
  # run right after a build finds the module without opening the editor)
  cp -f "$NATIVE/$NAME.gdextension.in" "$NATIVE/$NAME.gdextension"
  local L=$NATIVE/../.godot/extension_list.cfg
  if [ -d "$NATIVE/../.godot" ] && ! grep -qs "native/$NAME.gdextension" "$L"; then echo "res://native/$NAME.gdextension" >> "$L"; fi
}

case ${1:-all} in
  all) build windows; build android; finish ;;
  windows|android|linux) build "$1"; finish ;;
  clean) rm -rf "$NATIVE/build" "$NATIVE/bin" "$NATIVE/$NAME.gdextension" "$NATIVE/$NAME.gdextension.uid"; echo "NATIVE_BUILD cleaned" ;;
  status) echo "godot-cpp: $GODOT_CPP ($(cd "$GODOT_CPP" 2>/dev/null && git rev-parse --short HEAD))"; ls -la "$GODOT_CPP/bin" "$NATIVE/bin" 2>/dev/null; echo "mingw: $MINGW"; echo "ndk: $NDK_BIN" ;;
  *) echo "usage: build.sh [all|windows|android|linux|clean|status]" ;;
esac
