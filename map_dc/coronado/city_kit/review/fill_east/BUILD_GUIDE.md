# Filling the Hospital session's empty land (20 Nov): how every builder works

Yasin, relayed by the coordinator: "populate them. act like architects and city planners, build indoors and outdoors,
take the elevation of the map into consideration, then run superchecker on everything you built to bugfix and lock;
plenty of props, plenty of life". His words to this session: "DONT FORGET TO TAKE THE LAND INTO CONSIDERATION, build
according to it"; "dont fill what is beyond the last highway, just keep the rest as sea and shoreline".

Read first: `.claude/skills/coronado-super-builder/SKILL.md` (whole), `map_dc/coronado/city_kit/JOB_BOARD.md` (top),
`map_dc/coronado/city_kit/YASIN_MESSAGES.md`, and `review/fill_hp/README.md` (how the hospital zone and campus were
built: this guide is that method). The reference scripts: `tools/city/pilot/pieces/n_hp_site.gd` (land-following ground),
`n_hp_main.gd`, `n_hp_transit.gd`, `n_hp_west.gd`, `n_un_site.gd`, `n_un_north.gd` (stall lines painted as their own
patches), `n_un_south.gd` (sloped dorms), and `hs_fill_lib.gd` (the helpers).

## Rules (all of them Yasin's or the skill's)
- ONLY empty land in YOUR area. Never move, rebuild, unlock or touch an existing piece (locked or not), a street, a
  junction, the shared layout `city_grid_layout.json`, `locked.json`, `terrain_grid.npz`. Nothing beyond the ring road.
- Do NOT run `git commit`, `git push`, `lock.py`, `integrate.py`, `--write` on any land tool. The coordinator (the
  Hospital session) commits, locks and integrates. Write only files with YOUR prefix (below) plus your area's
  `OUT/fill/<you>/` scratch.
- One script per piece, every building and prop a line with its reason (no loops that decide places by a rule, no
  seeds). Short literal lists (`for x in [..]`) with hand-chosen numbers are fine.
- Planner first: who comes here, from where, when; what this block is next to (zoning map `ZONING.md`,
  `tools/city/pilot/zoning/zones.py`, the built neighbours); write that reason in the script header.
- LAND: the ground follows the land (5 cm over it, from a land table exported for your area by
  `python3 -I tools/city/pilot/zoning/export_land_patch.py <u0> <v0> <u1> <v1> tools/city/pilot/pieces/<prefix>_land.gd "<name>"`)
  and is eased onto every street walk's height within 12 m (see `n_hp_site.g`). Measure every walk edge and its height
  from the city's ground dump (`OUT/g_city`, see Measuring). Every building on a level pad at the highest ground under
  it (`H.pad_height`), the field graded up to the pads at 6 % (`H.graded`, `H.pad_entry`, `H.pad_at`), raised door sills
  get closed steps (`H.steps_z2` / `H.steps_x2`). Steep land: terraces with retaining faces (`H.level_pad`,
  `H.step_face`); never a building sunk into the land or floating.
- Cars only in at the streets' existing aprons (`zoning/legs_measured.json`: apron at 54-60 m from a node, per side).
  No new driveways into street pieces.
- Plenty of props, plenty of life, each with its reason: benches facing something, bins against walls, bike racks by
  doors, lamps, planters, mailboxes, AC units, dumpsters at service sides, wear (oil only where cars stand, tyre marks
  only on asphalt where cars brake or turn). Plants get collision (Yasin: "all of them should have collision"); only
  sprinklers and ground-cover patches stay without.
- NO trees in the piece scripts. Trees come only as hand lists `zoning/trees/<area>.json` after `docs/TREE_PLAN.md`
  (its zone rule), built by `sc.py trees <area>` into `t_<area>` pieces (see Trees).
- Phone budget: paint stall lines / court lines as their own patches (`n_un_north` REGIONS) so a piece's ground stays
  under ~40k triangles.
- Indoors: every building with a shop / civic door gets its room, the kind fitting the place (see Rooms).

## Your prefix and files
- pieces `n_<px>_<name>.gd` in `tools/city/pilot/pieces/`, saved by `H.finish` to `map_dc/coronado/city_kit/pieces/`
- a site file `n_<px>_site.gd` (edges, walk heights, `g(u, v)`), a land table `n_<px>_land.gd`
- rooms: `tools/city/rooms/assign_<px>.py` (copy of `assign_hp.py`; its SHOPS list; writes
  `interiors/assignment_<px>.json`); build with
  `xvfb-run -a -s "-screen 0 640x360x24" godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/rooms/room_gen_hp.gd -- --assign=assignment_<px>.json --report=rooms_<px>_report.json`
  (room ids come out `g_<px>_<piece>_<label>_<i>`). Models must have a contract in `interiors/room_contracts.json` or
  `room_contracts_hp.json`; if you need another model measured, say so in your report (do not edit those files).
- your area layout `OUT/fill/<px>/area.json` (the shared layout's rows near your area + your pieces at their pos) for
  the checks; never the shared layout.
- tree lists `map_dc/coronado/city_kit/zoning/trees/<px>_<name>.json`; tree pieces `t_<px>_<name>.scn`.
- a README `map_dc/coronado/city_kit/review/fill_east/<px>.md`: what is built and why, the checks with their numbers and
  what each cannot see, what is not done.

## Measuring (read-only)
- The city's ground dump is `OUT/g_city` (all 1006 rows). Maps: `python3 -I OUT/py/area_map.py OUT/g_city <u0> <v0> <u1> <v1> OUT/fill/<px>/map 0.5`
  (PNG + piece extents), walk edges: `OUT/py/edges_hp.py`, `OUT/py/curve_edge.py`, `OUT/py/bedge.py` (read their heads).
- Land over your ground: `OUT/py/buried.py`, grades: `OUT/py/grade.py`, seams: `OUT/py/seams.py` (on your own ground
  dump: `godot --headless --path . -s res://OUT/ground_dump_area.gd -- --out=OUT/fill/<px>/g --layout=res://OUT/fill/<px>/area.json`).
- Build a piece: `xvfb-run -a godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/pilot/pieces/<piece>.gd`

## Checks before you report (area layout; real renderer)
`export CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=res://OUT/fill/<px>/area.json` then
`xvfb-run -a -s "-screen 0 640x360x24" godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/validate.gd`
(and `check_life.gd`, `audit_trees.gd`); rooms: `... -s res://map_dc/coronado/city_kit/interiors/rooms/check_rooms.gd -- --only=g_<px>_`.
All must be 0 on your pieces. Seams with streets and neighbours under 2 cm; land over your ground 0.

## Superchecker (then the coordinator locks)
`export SC_GODOT=$PWD/OUT/godot-x SC_PY=python3 SC_GODOT_HEADLESS="godot --headless" SC_LAYOUT=$PWD/OUT/fill/<px>/area.json`
(your area layout's own rows need `"from": "grow_<px>"`), then `python3 -I tools/city/super/sc.py check <piece>` for every
piece. Your pieces are unlocked drafts: fix AT THE SOURCE as the hospital pieces did (a literal `const SC` list per piece,
`H.sc_apply`): be very prone to delete (Yasin: "be very prone to delete something instead of taking risky decisions about
props and wear"): every finding with no plainly safe place is a deletion with its reason; lamps turned back over their
road; oil where no car stands out; column boxes as the checker gives them. Rebuild, check again until only report-only
kinds remain (wide_batch, empty_area). Rooms: `bash tools/city/super/run/rooms_and_trees.sh <piece>` then
`sc.py install-room <room> --by=Yasin` for the proven copies.

## Trees
After the superchecker: `zoning/trees/<px>_<name>.json` per piece (format: `hp_main.json`), each tree a hand line with its
why, by `docs/TREE_PLAN.md`'s rule for the zone (apartments: one per court; residential yards: one per two or three
houses; civic / parks: clumps of 3-5 at the edges and round the seating; commercial: few). `python3 -I tools/city/super/sc.py trees <px>_<name>`
must say ok; copy `OUT/super/work/t_<px>_<name>.scn` into `map_dc/coronado/city_kit/pieces/` and add the row
`{"piece": "t_<px>_<name>", "pos": [0,0,0], "yaw": 0, "from": "trees"}` to your area layout. Then rerun the checks.

## Colliders true to size
Last: `godot --headless --path . -s res://tools/city/pilot/exact_colliders.gd -- <piece> --save` for every piece and
tree piece (each prop's collider rebuilt from its own drawn mesh), verify with
`godot --headless --path . -s res://OUT/colexact_verify.gd -- <pieces...>` (largest gap must be under 1 mm).
