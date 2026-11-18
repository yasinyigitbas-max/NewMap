# Plan C handover (14 Nov 2026, from the Fable session to whoever continues)

Read `tools/roads/PLAN_C.md` first for the idea. This file is the state, the commands, Yasin's rules and what is open.

## State
- **A 2D plan of the whole island exists and passes every check.** It is NOT in the game, not on a phone, not baked.
  Yasin has seen the full-size drawing and said "looks good". He has not yet given a go for a rollout.
- 225 blocks (1,950 houses, 796 apartment buildings, 534 shop bays), open land (parks, beach, golf, base), all 28 hero
  buildings on their real outlines, the bridge on its real line, 3,000 parked cars.
- A 3D preview of test areas exists as a separate Godot project (`tools/city/preview/`). Its buildings, lamps and
  meters are code-built placeholders; trees and cars are today's game models.
- The cut-down models are on branch `origin/s/cloud-kit/models` (52 models x 3 tiers, report
  `reports/kit_models_14nov.md`, placement notes `assets/kit/README.md`). Not merged, not used anywhere yet.
  34 of them are CC-BY (Sketchfab): they must be credited in the game.

## The tools (stdlib Python, run with `python -I` from the project folder; numpy only for `--outer`)
| File | Does |
|---|---|
| `tools/city/blocks_from_graph.py` | Blocks from the street graph: merges junction nodes closer than 30 m, straightens streets once for everyone, removes outside faces, sets aside blocks that lie over another, exports every street line and the bridge (motorway edges of `lane_graph.json`) |
| `tools/city/kept_from_game.py` | Hero buildings with real outline + door from game data -> `tools/city/kept.json` (28). Outline = fill from behind the door, wall gaps closed |
| `tools/city/plan_block.py` | The generator and its checks. Blocks: kerb, pavement, verge, lots, houses / apartments / shop rows by street type, alleys in regular blocks, campus mode for huge blocks, hero parcels, parks, props, paint, wear, cars. `--outer`: everything outside the blocks (coast, dead-end streets, golf, base) with exact shapes. Writes `plan.json` + `plan.png` (4 px / m). Exit 1 on any failed check |
| `tools/roads/city_audit.py`, `city_audit_ground.py` | Counts of the OLD map's bugs (the reason for all this) |

Whole town (about 15 minutes, 1.5 GB of memory; run it in the background):
```bash
python -I tools/city/blocks_from_graph.py --centre=-1400,3100 --radius=2600 --out=OUT/blocks.json
python -I tools/city/plan_block.py --blocks=OUT/blocks.json --out=OUT --all --outer
```
Test areas (seconds to 2 minutes): home `--centre=-1700,2860 --radius=330` (no `--outer`), Hotel Bel
`--centre=-1550,3800 --radius=420` with `--outer`. Run both after ANY change to the generator, then the town.
The last town output is in `perf_shots/planc/city/` (not in git: `city_plan_full.png`, `city_plan.json`,
`city_plan_checks.txt`); the block list is `tools/city/data/blocks_city.json`.

3D preview (opens a window, quits by itself; check the shared-checkout rules before opening windows):
```bash
godot --path tools/city/preview -- --plan=OUT/plan.json --out=OUT/shots [--junctions]
godot --path tools/city/preview -- --hotel=tools/city/preview/hotel_bel.json --out=OUT/bel
```
`preview.gd` has absolute paths to the texture downloads (`claude_scripts/kit_dl/acg`) and the game folder at its top.

## Yasin's rules for this work (his words are in the memory note plan-c-city)
1. The plan covers the WHOLE city. No old map left anywhere.
2. Never report "done, but x is not covered / n mistakes". Work until coverage is complete and the checks are at zero.
3. When something proves extra problematic: remove it if it is a regular building, car or prop. NEVER drop a hero
   building. Heroes may look imperfect for now; they must be on the map.
4. At most 3,000 parked cars in the whole city, thinned evenly (`MAX_PARKED`, `CAR_FILL` in plan_block.py). Moving
   traffic is set in the game's traffic system, not here; he wants about 4,000 cars felt in total.
5. Wear: "well maintained but lived in", never ruined.
6. Tree wells are round with the trunk in the middle. Parks have paths and benches.
7. Show him before anything goes to the Redmi. Show the big 2D plan and wait for his go before a rollout.
8. He inspects pictures closely and finds what checks miss. LOOK AT EVERY SHOT YOURSELF before sending it, and say
   which ones you did not look at. Never say "zero problems" about something the checks do not cover.
9. No paint-over mock-ups. Real engine shots or the generated plan only.
10. The plan must be data the game can build from, never a painted picture (the open land was a painted 1 m grid for a
    while; he caught it. It is exported as shapes now: `open_land` in plan.json).

## What the checks cover (plan_block.py `check`, `decorate`, `outer_land`)
Building on building / pavement / verge / kerb / road; prop on a wrong surface; whole tree trunk clear (not just its
centre); two props closer than their footprints; prop or pavement cut by a fence; anything but road outside a kerb
line; every house, apartment, hero and kept building has a paved way to a pavement; crossings do not overlap and
reach a kerb at both ends; paint only on the road; cars fully on road or car park, clear of driveways, hydrants and
crossings; every hero present and not cut. NOT covered: looks, building faces, elevation, anything in 3D.

## Open, in the order I would take them
1. **Models into the preview.** Map plan slots to the 52 models. The model houses have their own footprints and door
   positions: lots, door paths and porches must follow the real models (HOUSES table, PORCH, SETBACK), then re-run
   all checks. Use near / mid / far by distance. Credit the CC-BY ones.
2. **Elevation.** The plan is flat. Ground must follow `CoronadoTerrain.height_at`, each lot levelled, kerbs and
   pavements draped. Not started. (Design work: worth the stronger model.)
3. **The base.** The models session records Yasin's decision "naval base stays as it is; only its gate is seen in
   this release". The plan currently lays out the whole base (212 ha). Confirm with him, then drop it or keep it.
4. **Into the game:** ground mesh per block from plan.json, kit buildings, props; old roads / buildings / props off
   in the same places. Then the systems that read the map: traffic lane graph, bus stops, crowd graph, parked cars,
   minimap, perf route, shop and room doors, story spots (9 hard-coded positions).
5. **Hand-made pieces:** the bridge landing; the two blocks with a loop street inside (`aside` in blocks.json; they
   are covered by open land for now, with their real buildings kept).
6. **Hotel Bel model.** A one-off code-built draft is in the preview (`--hotel`). Yasin: "keep it like this for now,
   it is still bad". Known faults: washed-out colours, a dark patch inside the Ballroom roof ring, verandas only on
   one end, dim night look, about 170,000 triangles. The game's own model has faults too (shots in
   `perf_shots/hotel_bel/`).
7. Small: a few unpainted single cells at the north-east shore in the drawing; forecourts of heroes are plain
   rectangles; parks beside heroes often have no path; 5 crossings and 6 parking lanes are left out by rule.

## Shared checkout
Other sessions use this folder. Named paths only in commits, never `git add -A`. `project.godot` has someone else's
uncommitted change: leave it. Bakes run in the cloud, one final bake at the end.
