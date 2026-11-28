#!/bin/bash
# PHONE TEST of the baked city and its streamer. Run on Yasin's PC in Git Bash, from anywhere inside the NewMap clone:
#   bash tools/city/rig/phone_rig.sh all   [NAME] [rig args]   bake the city, export the rig app, install, run, collect
#   bash tools/city/rig/phone_rig.sh run   [NAME] [rig args]   run again (app already on the phone), e.g. other settings
#   bash tools/city/rig/phone_rig.sh bake | export | install | status
#   bash tools/city/rig/phone_rig.sh shots NAME [rig args]   pictures (rig --plan=shots), pulled to city_kit/review/tiers/NAME/
#        e.g.  shots before   and   shots after --tiers      (the same views, to compare tier settings)
# NAME labels the result (default: run1). Rig args: see tools/city/rig/rig.gd (--plan=default|quick|speed|zones --lead=2 ...).
#   bash tools/city/rig/phone_rig.sh run zones1 --plan=zones        teleports between the populated zones (about 6 minutes)
#   bash tools/city/rig/phone_rig.sh run mine --drive=NAME/ROUTE/KMH/SECONDS/NIGHT ...   drives of your own, no rebuild
# The result (the app's RIG lines, phone model, temperature) is written to
# map_dc/coronado/city_kit/review/phone/NAME.txt and pushed to the branch, so the cloud session can read it.
# PUSH=0 keeps it local. DEV=<serial> picks the phone (default: the Redmi).
# Paths are the ones the game's own scripts use on this PC; override by environment if they moved.
set -u
cd "$(dirname "$0")/../../.." || exit 1
ROOT=$(pwd)
GAME=${GAME:-/c/coronado_b17int19_hud_onelap_rebake1_treevis1_mobilevk1_actprobe1_src6_source}
GAME_P=${GAME_P:-$GAME/coronado-actprobe1-source/project}
GODOT=${GODOT:-/c/Users/yasin/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}
ED_ALL3=$GAME/engine_bins/ed_all3/Godot_v4.7.2-coronado_ed_all3_win64_console.exe
GODOT_EXPORT=${GODOT_EXPORT:-$([ -f "$ED_ALL3" ] && echo "$ED_ALL3" || echo "$GODOT")}
ADB=${ADB:-/c/Users/yasin/AppData/Local/Android/Sdk/platform-tools/adb.exe}
DEV=${DEV:-FEMFRK8PYDMBKBAQ}
PKG=com.yasin.citykit.rig
JAVA_HOME="${JAVA_HOME:-/c/Program Files/Eclipse Adoptium/jdk-17.0.21.9-hotspot}"
# Windows programs (gradle) need C:\... here: with MSYS_NO_PATHCONV=1 Git Bash hands /c/... over unchanged
command -v cygpath >/dev/null && JAVA_HOME=$(cygpath -w "$JAVA_HOME")
export JAVA_HOME
export MSYS_NO_PATHCONV=1
OUT=$ROOT/OUT; mkdir -p "$OUT"
A() { "$ADB" -s "$DEV" "$@"; }
die() { echo "PHONE_RIG STOP: $*"; exit 2; }
need() { [ -e "$1" ] || die "not found: $1 ($2)"; }
winpath() { command -v cygpath >/dev/null && cygpath -w "$1" || echo "$1"; }

do_bake() {
  need "$GODOT" "the Godot 4.7.2 console exe; set GODOT=..."
  if [ ! -f map_dc/coronado/city_kit/runtime_tex/arr_ground.png ]; then
    PY=$(command -v python || command -v python3 || command -v py) || die "python not found (needed once, for the texture arrays)"
    "$PY" -c "import PIL" 2>/dev/null || "$PY" -m pip install --quiet pillow || die "python has no Pillow: run  pip install pillow"
    "$PY" tools/city/bake/make_arrays.py || die "make_arrays.py failed"
  fi
  echo "PHONE_RIG import (first time: several minutes)"; "$GODOT" --headless --path . --import > "$OUT/import.log" 2>&1
  echo "PHONE_RIG bake (about 1-3 minutes, a window opens)"
  # (--render-thread safe: the game runs with a separate render thread since 20 Nov (B28); the PC tools read meshes and
  # make textures, which needs the old mode: the room merge broke without it, "finalize can only be called from the render thread")
  "$GODOT" --path . --render-thread safe --rendering-method mobile --resolution 640x360 -s res://tools/city/bake/bake_runtime.gd -- --all > "$OUT/bake.log" 2>&1
  grep -a "^BAKE_DONE\|^BAKE check\|SCRIPT ERROR" "$OUT/bake.log" | cut -c1-200
  grep -aq "^BAKE_DONE" "$OUT/bake.log" || die "the bake did not finish: see OUT/bake.log"
  echo "PHONE_RIG city light (the sky and far-shadow maps, ~2 minutes)"
  GODOT="$GODOT" bash tools/city/look/city_light.sh > "$OUT/city_light.log" 2>&1 || echo "PHONE_RIG city light FAILED (see OUT/city_light.log): the game runs without it"
  grep -a "^CITYLIGHT" "$OUT/city_light.log" | tail -3
}

do_export() {
  need "$GODOT_EXPORT" "the editor that exports; set GODOT_EXPORT=..."
  [ -f map_dc/coronado/city_kit/runtime/manifest.json ] || die "no baked city: run  phone_rig.sh bake"
  if [ ! -d android/build ]; then      # the Android build template with the game's own engine (all3: light grid) lives in the game project
    need "$GAME_P/android/build" "the game project's Android template; set GAME_P=<game project folder>"
    # Only the template itself: NOT the game's last build (build/, .gradle/, 1.2 GB) and NOT the game's exported files
    # (src/*/assets). Left in, the editor scans them as part of this project and their names end up in the APK.
    echo "PHONE_RIG copying the Android template from the game project"; mkdir -p android/build
    for e in "$GAME_P/android/build"/* "$GAME_P/android/build"/.[!.]*; do
      [ -e "$e" ] || continue
      case $(basename "$e") in build|.gradle) continue ;; esac
      cp -r "$e" android/build/ || die "copy failed"
    done
    rm -rf android/build/src/main/assets android/build/src/instrumented/assets
    [ -f "$GAME_P/android/.build_version" ] && cp "$GAME_P/android/.build_version" android/
  fi
  # the native module (traffic and people in C++, docs/TRAFFIC_PEOPLE_PORT.md) is built here, not kept in git: a
  # few seconds when nothing changed. If it cannot be built the app is exported without it and says so at start.
  if [ -f native/build.sh ]; then bash native/build.sh | grep -a "NATIVE_BUILD" || true; [ -f native/bin/libcoronado_city.android.arm64.so ] || echo "PHONE_RIG the native module did not build: exporting without it"; fi
  # (28 Nov night) a kit texture re-imported with Godot's defaults loses its mipmaps and its compression: bricks seen at a
  # distance turned to streaks on the phone (bld_color.png.import, rewritten by a headless import). No export like that.
  BAD=$(grep -l "^mipmaps/generate=false" assets/coronado_kit/textures/*.png.import assets/coronado_kit/atlases/*.png.import 2>/dev/null)
  [ -z "$BAD" ] || die "kit textures without mipmaps (restore them: git checkout HEAD -- <file>, then --import): $BAD"
  touch android/build/.gdignore      # the editor must not read the template folder as project files (the stock template ships this file)
  # No gradle daemon: on Windows it stays alive after the build, holds the log open, and the export never returns.
  export GRADLE_OPTS="${GRADLE_OPTS:-} -Dorg.gradle.daemon=false"
  echo "PHONE_RIG export with $(basename "$GODOT_EXPORT") (several minutes)"
  rm -f "$OUT/citykit_rig.apk"
  "$GODOT_EXPORT" --headless --path . --export-debug Rig "$(winpath "$OUT/citykit_rig.apk")" > "$OUT/export.log" 2>&1
  [ -f "$OUT/citykit_rig.apk" ] || { tail -15 "$OUT/export.log"; die "no APK: see OUT/export.log"; }
  # (20 Nov: an export whose editor could not load the GDExtension - its Windows DLL copy locked by another Godot - left the
  # Android library out without failing: a grey screen on every phone) no game library in the APK = no APK
  unzip -l "$OUT/citykit_rig.apk" | grep -q "libcoronado_city.android.arm64.so" || { mv "$OUT/citykit_rig.apk" "$OUT/citykit_rig_NO_NATIVE.apk"; grep -a "extension\|dll" "$OUT/export.log" | head -5; die "the APK has no libcoronado_city.android.arm64.so (the editor could not load the extension: close other Godot runs, delete native/bin/~*, export again)"; }
  ls -la "$OUT/citykit_rig.apk" | awk '{print "PHONE_RIG apk", $5/1048576, "MB"}'
}

connected() { "$ADB" devices | grep -q "^$DEV[[:space:]]*device"; }

do_install() {
  need "$ADB" "adb; set ADB=..."; connected || die "phone $DEV not connected: $("$ADB" devices | tail -n +2 | tr '\n' ' ')  (set DEV=<serial>)"
  A install -r "$(winpath "$OUT/citykit_rig.apk")" || die "install failed"
}

do_run() {
  local NAME=$1; shift
  need "$ADB" "adb"; connected || die "phone $DEV not connected (set DEV=<serial>)"
  A shell am force-stop $PKG
  local f; f=$(mktemp); printf '%s\n' "$* --quit" > "$f"
  A push "$(winpath "$f")" /data/local/tmp/rig_args.txt >/dev/null; rm -f "$f"
  A shell "run-as $PKG sh -c 'mkdir -p files; cat /data/local/tmp/rig_args.txt > files/rig_args.txt'"
  local T0; T0=$(A shell dumpsys battery | grep -m1 '^ *temperature:' | tr -dc '0-9')
  A logcat -c; A shell am start -n $PKG/com.godot.game.GodotAppLauncher >/dev/null
  echo "PHONE_RIG running '$NAME' (args: $*). Leave the phone awake and untouched."
  local T=0 MEM=""
  while [ $T -lt 900 ]; do
    timeout 10 tail -f /dev/null; T=$((T+10))
    [ $T -eq 60 ] && MEM=$(A shell dumpsys meminfo $PKG | grep -E "TOTAL PSS|TOTAL:|Graphics:|Native Heap:" | tr -d '\r' | tr '\n' ';')
    A logcat -d -s godot:* | grep -aq "RIG plan_done" && break
    [ -z "$(A shell pidof $PKG | tr -dc '0-9')" ] && [ $T -gt 20 ] && break
  done
  local T1; T1=$(A shell dumpsys battery | grep -m1 '^ *temperature:' | tr -dc '0-9')
  local RES=$ROOT/map_dc/coronado/city_kit/review/phone; mkdir -p "$RES"; touch "$RES/.gdignore"
  { echo "# phone rig run '$NAME'  $(date -u +%Y-%m-%dT%H:%MZ)  args: $*"
    echo "# phone: $(A shell getprop ro.product.model | tr -d '\r') android $(A shell getprop ro.build.version.release | tr -d '\r') serial $DEV | battery temp ${T0} -> ${T1} (0.1 C) | exporter $(basename "$GODOT_EXPORT")"
    echo "# commit $(git rev-parse --short HEAD) | meminfo at 60 s: $MEM"
    A logcat -d -s godot:* | tr -d '\r' | grep -a "Godot Engine v\|RIG \|SCRIPT ERROR\|ERROR:\|Shader cache miss" | sed 's/^.*godot *: //' | head -400
  } > "$RES/$NAME.txt"
  A logcat -d -s godot:* | tr -d '\r' > "$OUT/logcat_$NAME.txt"
  local SHOTS=""
  case " $* " in *" --plan=shots "*) SHOTS=map_dc/coronado/city_kit/review/tiers/$NAME ;; esac
  if [ -n "$SHOTS" ]; then      # the pictures the app saved, as one tar stream (exec-out keeps the bytes as they are)
    rm -rf "$SHOTS"; mkdir -p "$SHOTS"; touch "$ROOT/map_dc/coronado/city_kit/review/tiers/.gdignore"
    A exec-out run-as $PKG sh -c 'cd files/rig/shots && tar cf - *.jpg' | tar xf - -C "$SHOTS" && echo "PHONE_RIG pictures: $(ls "$SHOTS" | wc -l) in $SHOTS"
    A shell "run-as $PKG rm -rf files/rig/shots"
  fi
  A shell am force-stop $PKG; A shell "run-as $PKG rm -f files/rig_args.txt"
  echo "PHONE_RIG result: map_dc/coronado/city_kit/review/phone/$NAME.txt"; grep -a "RIG drive\|RIG boot\|ERROR" "$RES/$NAME.txt" | cut -c1-230
  # the streaming budget: PASS or FAIL with the reasons (tools/city/rig/health.py holds the limits)
  local PYH; [ -z "$SHOTS" ] && PYH=$(command -v python || command -v python3 || command -v py) && "$PYH" tools/city/rig/health.py "map_dc/coronado/city_kit/review/phone/$NAME.txt"
  [ -n "$SHOTS" ] && git add "$SHOTS"
  if [ "${PUSH:-1}" = "1" ]; then
    # a path inside the repo, not $RES: with MSYS_NO_PATHCONV=1 git for Windows gets /c/... unchanged and says "Invalid path '/c'"
    git add map_dc/coronado/city_kit/review/phone && git commit -q -m "Phone rig run '$NAME'" && git push -q origin HEAD && echo "PHONE_RIG pushed to $(git rev-parse --abbrev-ref HEAD)" || echo "PHONE_RIG could not push: send the file by hand"
  fi
}

cmd=${1:-all}; shift || true
case $cmd in
  bake) do_bake ;;
  export) do_export ;;
  install) do_install ;;
  run) NAME=${1:-run1}; shift || true; do_run "$NAME" "$@" ;;
  shots) NAME=${1:-shots1}; shift || true; do_run "$NAME" --plan=shots "$@" ;;
  all) NAME=${1:-run1}; shift || true; do_bake; do_export; do_install; do_run "$NAME" "$@" ;;
  status) echo "godot: $GODOT"; echo "exporter: $GODOT_EXPORT"; echo "adb: $ADB"; "$ADB" devices; ls -la "$OUT" 2>/dev/null | tail -5 ;;
  *) echo "usage: phone_rig.sh all|run|bake|export|install|status [NAME] [rig args]" ;;
esac
