# Handover: run the phone test on Yasin's PC (18 Nov 2026)

From the cloud session that did the audit, the runtime bake and the streamer. The cloud cannot reach Yasin's PC or
phone (his PC lists its folders but does not offer them to a cloud session), so a session ON THE PC takes this over.

## Read first
1. `CLAUDE.md`, then `map_dc/coronado/city_kit/JOB_BOARD.md` (top entries of "WHERE WE ARE").
2. `docs/RUNTIME_BAKE.md` (the bake, the streamer, what was measured, what is open).
3. `tools/city/rig/phone_rig.sh` and `tools/city/rig/rig.gd` (the test itself).

## The job
Get ONE clean run of the phone test on the Redmi and its result pushed to this branch
(`claude/festive-faraday-20ltx2`):

```bash
bash tools/city/rig/phone_rig.sh all run1
```

The script was written in the cloud and has NEVER run on Windows. Yasin ran it twice and "nothing happens". Expect to
fix it. Run it step by step and read the logs it writes in `OUT/`:

| Step | Command | What it needs on the PC | Log |
|---|---|---|---|
| paths | `bash tools/city/rig/phone_rig.sh status` | prints the Godot, exporter and adb paths it will use | - |
| bake | `... phone_rig.sh bake` | python with Pillow (once, texture arrays); Godot 4.7.2 console exe; a first import of ~2,700 kit models (slow) | `OUT/import.log`, `OUT/bake.log` (must end with `BAKE_DONE`) |
| export | `... phone_rig.sh export` | the game project's `android/build` template (copied into `android/` here), JDK 17, the editor that exports | `OUT/export.log`, `OUT/citykit_rig.apk` |
| install | `... phone_rig.sh install` | adb, the phone connected with debugging on | - |
| run | `... phone_rig.sh run run1` | about 4 minutes, phone awake | `map_dc/coronado/city_kit/review/phone/run1.txt`, `OUT/logcat_run1.txt` |

Paths the script assumes (taken from the old game's own scripts; override by environment variable if wrong):
- `GODOT=/c/Users/yasin/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`
- `GAME=/c/coronado_b17int19_hud_onelap_rebake1_treevis1_mobilevk1_actprobe1_src6_source`,
  `GAME_P=$GAME/coronado-actprobe1-source/project` (its `android/build` holds the game's own engine, build `all3`)
- exporter: `$GAME/engine_bins/ed_all3/Godot_v4.7.2-coronado_ed_all3_win64_console.exe` if it exists, else `GODOT`
- `ADB=/c/Users/yasin/AppData/Local/Android/Sdk/platform-tools/adb.exe`, Redmi serial `FEMFRK8PYDMBKBAQ` (`DEV=`)
- `JAVA_HOME=/c/Program Files/Eclipse Adoptium/jdk-17.0.21.9-hotspot`

Likely trouble, in the order I would check:
1. The script printed nothing: run `status` first; check Git Bash is in the clone (`git rev-parse --show-toplevel`) and
   on the branch; check `GODOT` exists.
2. The headless import hangs with many threads on this PC (the old game's notes): if `OUT/import.log` stops growing,
   import single-threaded (`[editor]` + `import/use_multiple_threads=false` in project.godot for the import only,
   do not commit that).
3. The bake needs a real renderer and opens a window; it must print `BAKE_DONE cells=140`.
4. Export: preset `Rig` in `export_presets.cfg` uses the gradle build; the template version must match the editor.
   If the patched editor will not export, use the official one (`GODOT_EXPORT=$GODOT`).
5. On the phone: the first log line names the engine (`coronado_all3` = light grid present). `RIG ERROR no baked
   city` means the runtime folder did not get into the APK (check the preset's filters).
6. Physics on Android is set to Jolt on its own thread by a `.android` override in project.godot; if the app fails
   at start because of it, remove the two lines and say so.

## What the result must answer (report these to Yasin in plain words)
From `review/phone/run1.txt`, per drive (50, 108, 210, 280 km/h by day; 50 km/h at night):
- frame time: median, 99 %, worst; how many frames over 33 / 50 / 100 ms;
- the `RIG slow ...` lines: what the streamer was doing in each slow frame (a cell loading? collision? nothing?);
- late cells (`220m=`, `60m=`), draws and triangles (budget 150 / 300k), memory;
- `boot first_area_ms` and `warm_ms`; the engine line; any `Shader cache miss` or `ERROR`.
The open question is whether creating a cell's meshes hitches on a real phone GPU. In the cloud a few frames of
20-46 ms remain while a cell loads. If the phone shows the same or worse, the next step is cells that arrive in
parts (not built). If it is clean, say so.

Useful second runs (app already installed, about 4 minutes each):
```bash
bash tools/city/rig/phone_rig.sh run nowarm --nowarm
```
```bash
bash tools/city/rig/phone_rig.sh run speed --plan=speed
```
```bash
bash tools/city/rig/phone_rig.sh run load1 --loading=1
```

## Rules
- Locked pieces never change (`tests/city_kit/test_locked_pieces.gd` must say RESULT PASS). The bake output
  (`map_dc/coronado/city_kit/runtime/`, `runtime_tex/`), `android/` and `OUT/` are not in git: keep it so.
- Nothing is copied from the old game's code (Yasin: "try not to copy anything at all"); its PATHS and its Android
  template are used, that is all.
- Commit and push after every step, to `claude/festive-faraday-20ltx2`. No pull request unless Yasin asks.
- Stop the app on the phone when done (`adb shell am force-stop com.yasin.citykit.rig`).
- Write to Yasin short and plain: what ran, the numbers, what did not work, what needs his decision. He is not a
  programmer by trade and asked for honesty.
- Update `JOB_BOARD.md` ("WHERE WE ARE") and `docs/RUNTIME_BAKE.md` ("The phone test") with what was found.

## State when handed over
- Branch `claude/festive-faraday-20ltx2`, everything committed and pushed. Lock test RESULT PASS.
- Cloud: whole city baked (140 cells), drives at 209 / 281 / 360 km/h with no cell late, cell add 0.3-0.5 ms.
- Yasin's facts: top speed target about 280 km/h, no fast travel, first-person camera that can look back.
- Decisions still waiting for Yasin are listed at the end of `docs/RUNTIME_BAKE.md`.
