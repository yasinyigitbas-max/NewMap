---
name: coronado-phone-runtime
description: The baked city on the phone - the runtime bake (tools/city/bake/bake_runtime.gd), the streamer (city_stream.gd) with its collision rules, the detail tiers and far world (shaders/rt, far ground), the phone test rig (tools/city/rig: rig.gd, phone_rig.sh, health.py) and how to measure performance on the Redmi honestly (GPU clock, heat, the drawing census). Lessons of the 18-19 Nov tier / census / collision session. Use for "run it on the phone", "is it hitching", "why is X slow", streaming, teleports, collision timing, tier pops, far roads, the census, perf budgets, new trees' cost, or before changing the bake, the streamer or an rt shader.
---

# Coronado on the phone: bake, streamer, tiers, measurement (19 Nov 2026)

Read with: `docs/RUNTIME_BAKE.md` (sections "The streamer", "The streamer on the phone", "Collision per place",
"The tiers"), `docs/DRAW_CENSUS.md`, `docs/HANDOVER_PHONE_TEST.md`, `docs/TREE_ARTIST_BRIEF.md`. The job board's
WHERE WE ARE has the latest state. Yasin's standing rules hold: locked pieces never change (lock test RESULT PASS),
every change switchable, Yasin sees samples before roll-out, commit and push after every step, no merge unless asked,
write to him short and plain and say what was NOT checked.

## 1. The phone test loop (Yasin's PC, Git Bash, in the clone)
```
bash tools/city/rig/phone_rig.sh bake        # BAKE_DONE cells=141; ~3 min warm, 13 min with a first import
bash tools/city/rig/phone_rig.sh export      # ~4 min; OUT/citykit_rig.apk
bash tools/city/rig/phone_rig.sh install
bash tools/city/rig/phone_rig.sh run NAME --plan=stream --probe     # the streaming gate (prints STREAM HEALTH PASS/FAIL)
bash tools/city/rig/phone_rig.sh run NAME --plan=zones --probe      # teleports between the populated zones
bash tools/city/rig/phone_rig.sh shots NAME [args]                   # pictures -> review/tiers/NAME/
bash tools/city/rig/phone_rig.sh run NAME --plan=census --census=day --scale=1.5   # the drawing census
```
- Rig options need NO rebuild (`--drive=`, `--tiers`, `--colrange=`, `--boost=`, `--nowarmnight`, `--scale=`,
  `--look=`, ...). Anything in a .gd, a shader or the bake needs export + install (+ bake if the bake changed).
- Result files go to `map_dc/coronado/city_kit/review/phone/NAME.txt` and are committed and pushed by the script.
  `PUSH=0` keeps a scratch run local (then add it by hand if the docs cite it).
- `health.py` is the gate: no cell late, no frame over 50 ms, <= 0.2 % over 33 ms, teleport ready in 3 s with no frame
  over 50 ms meanwhile, a body in the world within 3 s, no ERROR line. Do not loosen it to make a run pass.
- The phone is SHARED between sessions: one run at a time, only through phone_rig.sh, check
  `adb shell pidof com.yasin.citykit.rig` is empty, tell other sessions (SendMessage) when you take or free it,
  force-stop the app when done. Another session may install its own APK: re-install yours before your next run.
- NEVER run two exports at once (also not a debug and a release): both use `android/build` and gradle's clean kills
  the other. A failed export leaves an OLD APK on the phone that then runs the wrong plan silently: check the
  `RIG start` line (plan, options) of every result before reading its numbers.
- Yasin decides release builds ("dont make the release build yet"). Do not sign with any key on your own.
- Heat: the battery goes 30 -> 36 C over an evening; the phone's numbers drift with it. Give it minutes between long
  runs; print the temperature (phone_rig.sh does, per run).

## 2. Measuring honestly on the Redmi
- **720p frame time sits on the 60 fps vsync step** (16.7 ms); vsync cannot be turned off. Small costs do not show in
  frame times. The rig prints `gpu_ms` on each drive's `map` line for that reason.
- **But the GPU time at 720p does not show costs either: the phone lowers its GPU clock to just make 60 fps.** Half the
  pixels saved 0.0-0.3 ms. To measure a cost the GPU must be saturated: `--scale=1.5` (no view makes 60 fps there).
  Pixel costs there are ~4.5x their 720p size; vertex / CPU costs are not.
- Read only viewpoints whose baseline is the same at the start and the end of the run; differences under ~0.5 ms are
  noise; one run is one run (two identical zones runs differed by 7 frames over 33 ms).
- A slow frame's marks (`RIG slow ...`) say where the time went: `streamer` (main thread in the streamer), `draw` (the
  render side; with GPU ~13 ms a long `draw` is a stall, not drawing), `to_physics` (waiting for the physics thread),
  `physics_wait` / `render_wait` with `--probe`.
- Census findings to start from (`docs/DRAW_CENSUS.md`): plants are the biggest cost (up to 27 %, cut-out leaves ~40 %
  of it), then near buildings, sun shadows, sky reflection, FXAA, near props, wear decals. Mid/far tiers, far ground,
  the look's shader parts are cheap. Apartments is the heaviest zone, then civic, centre, waterfront (whose cost is
  not city objects: sea / sky, unmeasured). Merging trees does not cut GPU cost (they are merged already).

## 3. Streamer rules that were paid for (city_stream.gd)
- Collision: bodies within `col_range` (100 m) of the player, the lead and prepared places are made FIRST; the rest
  are made in the background, only in frames when no cell is loading (`col_background`). Leaving far collision unmade
  (the first try) gave a reproducible 63-414 ms draw stall while the growth's heavy cell loaded; cause not understood,
  the background work is the measured cure. "A body waited" counts from coming into range.
- A teleport (`prepare(p)`): the destination's collision first (distance to prepared places counts), budgets x
  `prepare_boost` (4). `update_focus(p, true)` (the loading screen) attaches the in-range collision at once.
- Budget per place: 1,200 collision units a frame while driving; ~216k units within 100 m of the road ahead is the
  3 s limit. Growth adds collision: re-run the zones gate after every growth step.
- The night is drawn once in the warm-up (rig default, `--nowarmnight` to compare): the first dusk of a session built
  the look's night shaders mid-drive (41 ms frames at 720p, 120 ms at 1.5x). The game must do the same.
- Toggling `env.reflected_light_source` off and back on left the GPU ~28 ms slower until a teleport: do not toggle
  environment settings at runtime without measuring.

## 4. Tiers and the far world
- Every tier shader includes `shaders/rt/rt_tier.gdshaderinc`: exact windows (near 0-60, mid 60-220, far from 220),
  node ranges BAND_MAX/2 wider. `CK_TIERS` (fades + the arrival sweep) is a compile switch made at runtime by
  `city_stream.shader_variant()`; OFF by default because it cost 0.1-0.4 ms GPU and 4 ms in the gritty edge (discard).
  `CK_CHEAP` / `CK_OPAQUE` exist only for the census. Never bake a variant in.
- Far ground: the bake renders the island's ground top-down (1.25 m a texel, ETC2) and draws it as one 20k-triangle
  mesh in the far world; a cell's patch collapses when the cell is in. Free on the phone. 100 of 141 cells have ground.
- Look-pack shaders (rt_bldg etc.) are edited by other sessions too: keep your changes small and inside #ifdef blocks.

## 5. Godot / tool traps met here
- The Bash tool here mangles `\n` and `\"` inside heredocs: write Python edit scripts with the Write tool into the
  scratchpad, then run them. Assert each replacement matches exactly once.
- `ShaderMaterial.get_shader_parameter()` returns null for a value equal to the shader default (it is not stored).
- `RenderingServer.global_shader_parameter_get()` is editor-only (logs an ERROR, which fails health.py).
- `ProjectSettings.get_setting_with_override()` takes one argument; `get_setting(name, default)` has the default.
- `var f := untyped_node.method()` fails to parse on the phone ("Cannot infer the type"): type it explicitly.
- `PortableCompressedTexture2D` saved outside the editor keeps no data (221-byte file): save an ImageTexture of the
  compressed Image instead (a PC without ETC2 converts it on load; the phone uses it as is).
- A worktree checked out before `.gitattributes` existed has CRLF plan files and the lock test fails on 5 of them:
  restore just those files from git (`rm` + `git checkout HEAD -- <files>`); never a blanket reset.
- Godot's import rewrites hundreds of `.import` files on the PC: leave them uncommitted.
- Kill only your own processes (check the command line with wmic); other sessions bake on the same PC.
