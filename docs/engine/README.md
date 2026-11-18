# Coronado's own Godot build (Android arm64)

Started 12 Nov 2026 (Yasin) for engine fixes game code cannot reach. The engine source is NOT in this repository:
`build.sh` clones it at the pinned tag (`VERSION`), applies patch files from `patches/` and builds.

## What a build is
The game exports with the Gradle build (`gradle_build/use_gradle_build=true`). The official 4.7.2 Android build
template (`android_source.zip`, installed to `android/build/`) holds the engine in exactly two files:

    android/build/libs/debug/godot-lib.template_debug.aar
    android/build/libs/release/godot-lib.template_release.aar

Each .aar holds `jni/<abi>/libgodot_android.so` + `libc++_shared.so`, `classes.jar` (the Java/Kotlin side) and a few
resources. The official ones carry four ABIs (103 / 113 MB); ours carry arm64-v8a only (25 / 26 MB), which is all the
preset exports. Every other file of the template is identical, so the PC swaps only these two files.

## Build (cloud session, 4 cores: first build ~25 min, a patch variant ~5-12 min)
    bash engine/build.sh base                                   # unmodified 4.7.2-stable
    bash engine/build.sh a_font engine/patches/a_font_atlas_race.patch
Output: `/e/out/<name>/libs/{debug,release}/*.aar`, `SHA256SUMS`, `build_info.txt` (copied to `engine/builds/<name>/`).
Needs ~12 GB under `/e` (source, objects, NDK r29, SDK) and Java 17+.

Options follow the official build (godot-build-scripts `build-android/build.sh`): `production=yes`, Swappy installed,
NDK 29.0.14206865, no LTO (Android's detect.py turns `lto=auto` into none). Differences: `debug_symbols=no` (official
builds with symbols for a separate symbols zip; Gradle strips them from the .aar), arm64 only, and the build name.

## Rules that keep a build usable
- **Patches are applied, never committed, in the engine tree.** `GODOT_VERSION_HASH` (the git commit) and the version
  number are hashed into every shader cache key (`servers/rendering/renderer_rd/shader_rd.cpp`, `setup()`), together
  with that shader's source text. Same commit = shaders baked by the official 4.7.2 editor are accepted. A patch that
  edits a built-in shader's GLSL changes the key of that shader only: its baked cache is skipped and it compiles on
  the phone at first use.
- **Build name**: `BUILD_NAME=coronado_<name>`. The phone log's first line reads
  `Godot Engine v4.7.2.stable.coronado_<name>`: check it in every A/B run. The name is not part of any cache key or of
  the GDExtension compatibility check (that uses major.minor.patch against `compatibility_minimum`).
- **Do not change bound methods, classes or the GDExtension interface** in a patch: `native/` is built against
  godot-cpp 4.5 and resolves 148 interface functions and method hashes at load.
- One patch per build, on the baseline only, unless a note says otherwise (A/B rule).

## Using a build on the PC
Each build is one parentless commit on its own branch `engine-bin/<name>` (pushed by `engine/publish.sh <name>`),
~51 MB. Fetch only the one you need, into a folder outside the project:

    git fetch origin engine-bin/base
    git archive FETCH_HEAD | tar -x -C /c/some/folder/engine_base      # libs/debug, libs/release, SHA256SUMS
    (cd /c/some/folder/engine_base && sha256sum -c SHA256SUMS)

Never merge or check out these branches (they hold nothing but the binaries).
1. Keep a copy of the two official .aar files (or reinstall the build template to get them back).
2. Copy the pair over `android/build/libs/debug/` and `android/build/libs/release/`; check `sha256sum` against
   `engine/builds/<name>/SHA256SUMS`.
3. Export as usual. `android/.build_version` stays `4.7.2.stable`, the editor asks nothing.

## Patches and builds (12 Nov 2026)
Each build is the baseline plus exactly one patch. Checksums in `builds/<name>/`, binaries on branch `engine-bin/<name>`.

| build | patch | what it does | checked here (Linux, lavapipe) |
|---|---|---|---|
| `base` | none | unmodified 4.7.2-stable | same size, imports, strings as the official library |
| `a_font` | `a_font_atlas_race.patch` | glyph atlas upload gets its own Image, the render thread never sees the live one | `tests/font_race`: 146 / 154 errors -> 0 |
| `b1_respv_off` | `b1_respv_off_for_spec_constants.patch` | no re-spirv for shaders with specialization constants | `tests/shader_mem`: -50 MB, pixels differ by <= 3/255 |
| `b2_respv_demand` | `b2_respv_parse_on_demand.patch` | re-spirv parses at pipeline creation instead of keeping a parsed copy | `tests/shader_mem`: -146 MB, identical picture |
| `b3_variant_bytes` | `b3_free_variant_bytes.patch` | shader_rd frees variant bytes after use | -4 MB, identical picture |
| `c_sgsr1` | `c_sgsr1_mobile_upscaler.patch` | `scaling_3d/mode = FSR 1` works in the Mobile renderer and runs SGSR 1 (edge direction) | `tests/upscale`: bilinear path bit-identical to baseline, SGSR pictures in `tests/upscale/results` |
| `all1` | a + b2 + b3 + c (in that order) | the candidate engine once each single patch has passed its lap | all three tests: 0 font errors, same pictures, -140 MB in `tests/shader_mem` |
| `e2_light_grid` | `e_mobile_light_grid.patch` | TEST ONLY. Tile + depth-slice light grid for omni / spot lights in the Mobile renderer (24 x 12 tiles, 64 depth slices, nearest 32 omni + 32 spot). Off unless `rendering/lights_and_shadows/mobile_light_grid` is true (can be set while running). Changes the scene shader source: with the official editor every baked scene shader is skipped and compiles on the phone at first use, grid on or off; export with the `ed_all3` editor to avoid that | `tests/light_grid`: off = bit-identical to baseline; on = same picture up to 8 lights per mesh, all lights beyond that |
| `all3` | a + b2 + b3 + c + e | TEST ONLY: `all1` plus the light grid | all four tests |
| `ed_all3` | a + b2 + b3 + c + e | Windows x86_64 EDITOR built from the same source as `all3` (see "The matching editor") | built; never started (a cloud session cannot run Windows programs) |

Superseded, do not use: `e_light_grid`, `all2`, `ed_all2` (the light grid without depth slices; same pictures, a
little slower, and their shader source differs from `e2_light_grid` / `all3` / `ed_all3`).

`patches/dev/` holds measuring patches that are never shipped. `LIGHTS_DESIGN.md` is the lights design note (no code).
Linux test engine: `scons platform=linuxbsd target=template_debug disable_path_overrides=no` in the engine tree.

## The matching editor (`engine-bin/ed_all3`)
Why: the shader baker of the exporting editor stores each built-in shader under a key made of the engine version,
the git hash and that shader's source text. A patch that edits a built-in shader (c adds one, e changes the Mobile
scene shader) makes the official editor's baked files useless for it; the phone then compiles those shaders itself
at first use. An editor built from the same patched source bakes files the patched engine accepts.

    git fetch origin engine-bin/ed_all3
    git archive FETCH_HEAD | tar -x -C /c/some/folder/ed_all3        # editor.zip, SHA256SUMS, build_info.txt
    (cd /c/some/folder/ed_all3 && sha256sum -c SHA256SUMS && unzip editor.zip)

- Use `Godot_v4.7.2-coronado_ed_all3_win64_console.exe` in place of the official console exe for the APK export
  only, with the `all3` (or `e2_light_grid`, `c_sgsr1`) pair in `android/build/libs/`. It reports version
  `4.7.2.stable`, so `android/.build_version` and the project's `.godot` folder stay valid.
- Built with `production=yes lto=none d3d12=no angle=no` by llvm-mingw: Vulkan only, somewhat slower than the
  official editor. Keep the official editor for everything else.
- It has never been started. The first export with it is itself a test: compare the APK's log against an export
  from the official editor (no "Shader cache miss" lines for scene shaders is the pass mark; run with `--verbose`).
