---
name: coronado-rules
description: House rules and system map for the Coronado Godot game (City Game - Dense Core). Load before writing or editing any code, bake data, translation or build file in this project, and when starting a new session here. Covers line endings, preload vs class_name, where each game system lives, how new systems hook in, i18n, settings, perf budgets, content packs, commit style and how to talk to Yasin.
---

# Coronado house rules

Godot 4.7.2 GDScript game: an English-learning life sim on Coronado Island (San Diego), Android first
(Redmi Note class = the 30 fps target, S23 = flagship). Owner: Yasin (Turkish speaker, writes short English).

## Start of a session
1. Read `../../HANDOFF.md` (repo is `.../coronado-actprobe1-source/project`; HANDOFF.md sits two levels up in
   `C:\coronado_b17int19_hud_onelap_rebake1_treevis1_mobilevk1_actprobe1_src6_source`), then `PLANS_ESTIMATES.md` next to it.
2. Follow Yasin's newest word over any file. "Things that need my go are a go" (2026-11-08) still holds unless he stops something.
3. At the end of a block: update HANDOFF.md (state, release, queue) and the memory notes.

## Hard rules (each one broke something before)
- **LF line endings.** The repo is LF. Python on Windows writes CRLF in text mode: read and write with
  `open(p, encoding='utf-8', newline='')`, or bytes. Before committing, `git diff --stat` must show only real lines.
- **preload, not new `class_name`.** New scripts are loaded with `const X := preload("res://...")` or
  `preload(...).new()` (house rule: no new global class_names; they change the global class cache that the
  packs and APK must agree on). Existing class_names (`CoronadoTerrain`, `CellPkg`, ...) are fine to use.
- **Untyped cross-script calls** go through `call(&"name", ...)` / `get(&"x")` / `has_method` when the target may be
  missing (autoloads are often absent in tests and probes). Look at debug/goto_shots.gd for the pattern.
- **Check that it parses** before any run that pops a window or takes minutes: `coronado-check` skill
  (`--check-only`). A parse error in an autoload or debug script silently kills a whole probe or build.
- **Probes and test runs must quit by themselves** and never wait for a click (Yasin's screen gets the window).
- **Bake only what changed** (`coronado-bake`): `--only=<cells|parts>`, fingerprints in bake_fp.gd.
- **Baked data reaches the phone only through content packs** (the APK holds code only). After a bake, a phone
  test needs a new pack export + push, see `coronado-build` / `coronado-phone`.
- **Grass stays** except where a road / crosswalk / driveway crosses it. No broad paving passes.
- **No dogs** (dropped). Voice lines: Kokoro clips, rendered in the cloud (coronado-voice).
- **PC = tests + the Redmi + merges + phone builds only** (Yasin 10 Nov). Bakes, city passes, voice rendering and any
  long compute run in cloud sessions (coronado-team).
- **Never `git commit -am` / `git add -A` on the PC**: ~350 unrelated local changes sit in that checkout. Add named paths (coronado-merge).
- **Clean imports** before bakes and builds (coronado-clean-import): a `valid=false` import silently drops a texture or clip.
- Never ask for or type secrets. Textures may be downloaded freely (CC0, own folder); other downloads need an OK.

## Where things live (autoloads in project.godot)
| Area | Files |
|---|---|
| Boot, packs, loading | core/boot/ (boot.tscn = main scene, pack_boot.gd, pack_manifest.json), core/packs.gd, core/pack_progress.gd |
| Game state / save / settings | core/game_state.gd (hour, clock_running, day), core/save_game.gd (slots), core/game_settings.gd, core/profiles.gd |
| Menus | core/main_menu.gd, core/pause_menu.gd, core/char_creator.gd, ui/ (hud, phone, wardrobe, npc talk, theme) |
| Story / voice / language | core/story.gd (StoryDirector), voice/ (voice, captions, dialogue, narrator), lessons/, core/i18n.gd |
| Player | player/ (health, needs, interact, fp_cam, seats), PlayerHit ragdoll under Traffic |
| World | map_dc/coronado/<area>/ (buildings, roads, furniture, npc, shops, public, home, perf/cell_pkg.gd), world 100 m cells `x_z` |
| City life / fx | world_fx/ (sun_sky, weather, night_lights, ambience, breakables, honks, pixel_look, wind/wet/wear) |
| Traffic / vehicles | traffic/traffic.gd (+ Honks child), vehicles/ (fuel), cityride/, rides/ |
| Jobs / economy / minigames | jobs/, delivery/, economy/, minigames/ |
| Debug | debug/perf_probe.gd (all `--flags`), goto_shots.gd, culprit_panel.gd, perf_route.gd, perf_grid.gd, phys_stress.gd |
| Tools | tools/gray_bake (cell bakes), tools/roads (road post-passes, NOT idempotent), tools/pack (split/publish), tools/lint/gdscan.py |
| Tests | tests/<area>/test_*.gd (SceneTree scripts, PASS/FAIL lines, `quit(1 if fails else 0)`) |

Map frame: origin 32.7157,-117.1611, x = east metres, z = south metres; terrain height `CoronadoTerrain.height_at(x, z)`.

## How new pieces hook in
- A sub-system under an existing autoload: `var n: Node = preload("res://world_fx/x.gd").new(); n.name = "X"; parent.add_child(n)`
  (see traffic/traffic.gd line ~44 for Honks). Add a new autoload only when it is truly global.
- Debug switches: parse in debug/perf_probe.gd `_ready` (args = cmdline + user args + `user://perf_args.txt`, so the
  same flag works on PC and phone). Keep debug UI off screen unless `--perfbuttons`.
- Settings: `GameSettings.get_value(&"key")` / `set_value`; add defaults to DEFAULTS. Per-phone values (render scale,
  colours) go in DEVICE_KEYS -> user://device_settings.json, not the save slot.
- Text shown to players: key in i18n/strings.csv (`keys,en,tr`, UTF-8, LF) and `I18n.en("key")` / `I18n.dual("key")`.
  Godot re-imports the .translation files on the next editor/headless import; commit both .translation files.
  A strings.csv change re-downloads the 9 MB core pack, so batch text changes.

## Perf budget
- Target (Yasin 10 Nov): locked 60 fps on his Samsung S23 in battery saving mode; the Redmi is the proxy. Perf fixes
  that change the look are suggestions only. The game still ships `run/max_fps=30`: judge laps against 16.7 ms
  (p50, p99, share > 16.7 ms and > 33 ms). Anything that adds frames over 16.7 ms is a regression.
- Redmi heats up; do not wait for cooldown (COOL=999). For A/B run A B B A and trust GPU ms / prims over frame ms.
- CPU (main thread) is the usual bottleneck, not GPU. Avoid per-frame scans of big node trees, GPU readbacks
  (`surface_get_arrays`), and sync loads during play; spread work over frames.

## Commits
- Message style: `<block><n>: what changed, in plain words` (e.g. `life3: traffic drivers honk when held up`).
  End with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Commit the build: `build_id.txt` + `core/boot/pack_manifest.json` (+ .translation files if they changed).
- Commit a new script's `*.gd.uid` together with the script (Godot writes it on the first import).

## Talking to Yasin
Short, plain answers. Push a phone notification (PushNotification) when he must act: a build to drive, a choice,
a phone to plug in, a blocking failure. For "what draws this" visual bugs, give him the culprit panel early
(`coronado-probe`) instead of long elimination runs.
