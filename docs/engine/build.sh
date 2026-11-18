#!/bin/bash
# Coronado's own Godot build for Android arm64 (template_debug + template_release), in the form the game's Gradle
# export uses: android/build/libs/debug/godot-lib.template_debug.aar + libs/release/godot-lib.template_release.aar.
#
# usage: bash engine/build.sh <name> [patch ...]
#   <name>   output name; also the engine build name: the phone log starts with "Godot Engine v4.7.2.stable.coronado_<name>"
#   [patch]  patch files (engine/patches/*.patch) applied on top of the pinned tag, in the order given
# env: ENGINE_WORK (default /e: short path, holds source + SDK, ~12 GB), JOBS (default nproc), TARGETS (default "release debug")
# out: $ENGINE_WORK/out/<name>/libs/{debug,release}/*.aar + SHA256SUMS + build_info.txt
#
# The engine source stays outside the game repository. Patches are applied to the work tree and never committed:
# the git hash compiled into the engine (GODOT_VERSION_HASH) keys the shader cache (shader_rd.cpp), so it must stay
# the tag's commit or every shader baked by the official 4.7.2 editor is rejected.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/VERSION"
NAME=${1:?usage: build.sh <name> [patch ...]}; shift
PATCHES=()
for p in "$@"; do PATCHES+=("$(realpath "$p")"); done
W=${ENGINE_WORK:-/e}
JOBS=${JOBS:-$(nproc)}
TARGETS=${TARGETS:-"release debug"}
SRC=$W/godot
export ANDROID_HOME=$W/sdk
mkdir -p "$W/logs" "$W/out"

# 1. toolchain (idempotent)
command -v scons >/dev/null || pip install -q scons
if [ ! -d "$ANDROID_HOME/ndk/$NDK_VERSION" ]; then
  mkdir -p "$ANDROID_HOME/ndk" && (cd "$ANDROID_HOME" && curl -sSL --retry 5 -C - -o ndk.zip "$NDK_ZIP" && unzip -q ndk.zip \
    && mv android-ndk-r29 "ndk/$NDK_VERSION" && rm ndk.zip)
fi
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  (cd "$ANDROID_HOME" && curl -sSL --retry 5 -o clt.zip "$CMDLINE_TOOLS_ZIP" && unzip -q clt.zip && mv cmdline-tools latest \
    && mkdir cmdline-tools && mv latest cmdline-tools/ && rm clt.zip)
fi
if [ ! -d "$ANDROID_HOME/build-tools/36.1.0" ] || [ ! -d "$ANDROID_HOME/platforms/android-36" ]; then
  # shellcheck disable=SC2086
  yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" $SDK_PACKAGES > "$W/logs/sdkmanager.log" 2>&1 || true
fi

# 2. source at the pinned tag, clean, patches applied (not committed)
[ -d "$SRC/.git" ] || git clone -q --depth 1 -b "$GODOT_TAG" "$GODOT_REPO" "$SRC"
cd "$SRC"
[ "$(git rev-parse HEAD)" = "$GODOT_COMMIT" ] || { echo "engine source is not at $GODOT_COMMIT"; exit 1; }
git checkout -q -- .                       # drop the previous variant's patch (tracked files only; build objects stay)
git clean -qfd -- core drivers main modules platform/android/*.cpp platform/android/*.h scene servers 2>/dev/null || true
[ -f thirdparty/swappy-frame-pacing/arm64-v8a/libswappy_static.a ] || python3 misc/scripts/install_swappy_android.py
for p in "${PATCHES[@]}"; do echo "patch: $p"; git apply --whitespace=nowarn "$p"; done
git diff --stat | tail -1 || true

# 3. native libraries (scons rebuilds only what the patch touched) -> platform/android/java/lib/libs/<type>/arm64-v8a
export BUILD_NAME=coronado_$NAME
for t in $TARGETS; do
  # shellcheck disable=SC2086
  scons -j"$JOBS" $SCONS_OPTIONS target=template_$t > "$W/logs/${NAME}_$t.log" 2>&1 || { tail -30 "$W/logs/${NAME}_$t.log"; exit 1; }
done

# 4. Gradle: the .aar pair (same task the official build runs)
# Maven Central answers 429 (rate limit) on a cold cache: retry, the downloads so far are kept.
ok=0
for try in 1 2 3 4 5 6; do
  if (cd platform/android/java && ./gradlew --no-daemon -q generateGodotTemplates > "$W/logs/${NAME}_gradle.log" 2>&1); then ok=1; break; fi
  grep -q "status code 429\|Too Many Requests\|Connection reset\|timed out" "$W/logs/${NAME}_gradle.log" || break
  echo "gradle: download refused (try $try), waiting"; sleep $((try * 45))
done
[ $ok = 1 ] || { grep -v "^ *>" "$W/logs/${NAME}_gradle.log" | tail -30; exit 1; }

# 5. collect
O=$W/out/$NAME
rm -rf "$O" && mkdir -p "$O/libs/debug" "$O/libs/release"
cp bin/godot-lib.template_debug.aar "$O/libs/debug/"
cp bin/godot-lib.template_release.aar "$O/libs/release/"
{
  echo "name: coronado_$NAME"
  echo "godot: $GODOT_TAG $GODOT_COMMIT"
  echo "patches: ${PATCHES[*]:-none}"
  for p in "${PATCHES[@]}"; do sha256sum "$p"; done
  echo "scons: $SCONS_OPTIONS target=template_{$TARGETS}"
  echo "ndk: $NDK_VERSION"
} > "$O/build_info.txt"
(cd "$O" && sha256sum libs/*/*.aar > SHA256SUMS && ls -la libs/*/*.aar && cat SHA256SUMS)
