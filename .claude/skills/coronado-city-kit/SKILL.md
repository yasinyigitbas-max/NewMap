---
name: coronado-city-kit
description: Build Coronado's city by hand-made block-kit pieces (map_dc/coronado/city_kit) instead of generators - junctions, street pieces, downtown blocks, residential rows on the hill, power lines - each piece authored once by its own script, validated, shown to Yasin, then LOCKED so nothing can change it again. Covers the cloud preview project, the authoring library (tools/city/pilot), the validator, wear / lived-in rules, budgets, Yasin's design rules and the traps that cost hours. Use for any work on city_kit pieces, the Amber Ave district, adding blocks or streets, "make the city denser", "grow the block", or when a piece looks wrong.
---

# Coronado city kit (block kit, started 16 Nov 2026)

**Read `map_dc/coronado/city_kit/JOB_BOARD.md` first**: the standing queue, Yasin's rules from the whole conversation
and his 17 Nov standing instruction (hourly asset check, lock what is done, never break what is done). A project
hook (`.claude/settings.json`, SessionStart "compact") prints it after every context compression.

Why: whole-city generators failed several times. Every fix to one kerb changed every kerb, and good spots broke
while others were fixed (about 20% of a month's usage lost). The rule now: **a fix in one place can never change
another place.**

## How it works
- **One piece = one frozen scene:** `map_dc/coronado/city_kit/pieces/<name>.scn`.
  - Kinds: junction `j_`, street `s_`, downtown block `b_`, residential row `r_`, wires `w_`.
  - Written ONCE by its own script `tools/city/pilot/pieces/<name>.gd`. The builder files (amber_seg, tenth_seg, block_lib, res_block, wear_lib, kit_lib, site) are only helpers.
- **Lock after Yasin approves:** `python -I tools/city/pilot/lock.py lock <piece> --by=Yasin`.
  - `tests/city_kit/test_locked_pieces.gd` fails if a locked file changes by a byte.
  - Never re-run a locked piece's script. A change needs Yasin's word plus `lock.py unlock`.
- **Layout:** `map_dc/coronado/city_kit/city_layout.json` places piece instances (piece, position, yaw). A prefab may be used many times, so fixing a prefab fixes all its uses on purpose.
- **Frame:**
  - origin = the Amber x 10th junction centre; X east along the streets, -Z north along Amber.
  - `site.gd hill(x)`: level to x 40, smoothstep to +5.9 m at x 150, max 8% (only depends on x).
  - World placement (not done yet): rotate by Amber's bearing 26 deg, offset to about (-1752, 7.2, 3297).
- **Design rules** are in `map_dc/coronado/city_kit/PILOT_DESIGN.md` (cross-sections, junction, furniture logic).

## The repo IS the preview project (18 Nov: the new map moved to its own repo, NewMap)
The repo root is a standalone Godot 4.7.2 project (project.godot: mobile renderer; override.cfg: 16 worker threads). It
carries only the new map plus the few files it borrows from the game (road / terrain textures, the shop-room textures,
today's terrain data and road graph the zoning tools read, fonts, the preview cars). First time in a session:
```bash
apt-get update && apt-get install -y mesa-vulkan-drivers xvfb
```
```bash
godot --headless --path . --import
```
| Job | Command (repo root) |
|---|---|
| build pieces (refuses locked ones) | `tools/city/run/build.sh <piece> ...` |
| every check (validator, trees, sink, rooms, lock test) | `tools/city/run/checks.sh` |
| terrain after ground changes | `tools/city/run/terrain.sh` |
| shots | `xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/preview/shots.gd -- --out=DIR "--cams=name:x,y,z:tx,ty,tz;..."` (env NOSHADOW=1, CITYKIT_LAYOUT_ONLY / CITYKIT_LAYOUT_EXTRA, TERRAIN=res://terrain_grid.json) |

## Traps (each cost real time)
- **Build pieces with the real renderer (xvfb + vulkan), never `--headless`:** MultiMesh instance data lives in the renderer and saves EMPTY under the dummy renderer (props vanish).
- **A script with a parse error hangs Godot instead of quitting:** run `--check-only -s` first. GDScript treats Variant inference as an error: type loop variables (`for xs: float in [...]`) and values from `Callable.call()`.
- **The kit's `assets/coronado_kit/shaders/prop_wear.gdshader` does not compile in 4.7** (`INSTANCE_CUSTOM` in fragment): props turn white. Use `city_kit/shaders/prop_wear_fix.gdshader`.
  - Vertex colours carry BOTH colour variants (containers, bins) and baked AO (bandstand). Multiplying them raw turns
    light parts black; ignoring them turns containers white. The fix shaders use a hue-preserving tint:
    `tint = COLOR.rgb / max channel * mix(1, max channel, 0.5)`. Changing a shared shader changes the LOOK of locked
    pieces (their files stay identical): tell Yasin.
- **Kit fences, gates and pickets are double-sided** (cull off). A wear material must keep that (`prop_wear_fix_2s`), or panels vanish from one side.
- **Cloud preview (lavapipe) limits:**
  - Sky-based ambient renders alpha-cut foliage BLACK: use colour ambient.
  - Shadows break: NOSHADOW=1. Shots have no shadows; say so.
- **Camera height:** on the hill, cameras must add `hill(x)`, or the shot is from underground.
- **Kit model orientation:**
  - Kit models face +Z. Yaw 90 = facing +X.
  - Mast arm extends -X. Kerb inlet grate is on +Z.
  - Utility pole cross-arm is along model X: it must CROSS the line (alley along z: yaw 0).
  - Cobra lamp arm is +Z.
- **Wear decals were INVISIBLE for a whole pass (16 Nov)**: the flat quads were wound back-facing and culled. Only the
  red kerb faces showed. Any new mark type gets a test render (all tiles at alpha 1 on asphalt and concrete) before use.
- **Main's wear atlas tiles:**
  - 0 crack (tint dark for sealed); 1 near invisible: don't use
  - 2/3 dark asphalt patches; 4/5 pale concrete patches
  - 6/7 oil, 8 tyre streaks, 9-12 covers, 13 paint, 14 grime
  - 15 = tyre SKID ARCS, never foot wear; foot wear = grime 14 at low alpha
- **Wear and clutter scale with the cluster:** the city centre gets more than the high street.
  - every building's back wall: meter bank, gas meter, AC units, bin carts if people live there
  - courts and alleys: delivery-truck oil, many cracks, patches, grime along the walls
  - tagged block walls by the bins
  - Buildings use weathering 0.65 with rain streaks.
- **Big or fixed buildings the kit lacks:** `tools/city/pilot/modular/merge_modular.gd` merges kit modular pieces
  from a layout json (same 0.5 m grid) into `map_dc/coronado/city_kit/buildings/<name>/` (one mesh per tier, far =
  a grid of an existing example's far hull). Use as folder `"ck/<name>"`. The kit's Python merge tools are NOT in
  this repo. Kit `mod_stg_row` has NO roof pieces (open-topped): use `ck/mod_stg_row_roofed`.
- **"concrete" ground paint renders near white** in yards and courts, and dark decals on it read as floating
  shadows. Yards are asphalt. Pale patch tiles 4/5 must be tinted grey (~0.5) or they read as white squares.
- **Validator also checks building vs building overlap** (`bldg`).
- **Tree wells:** never draw a full sidewalk and a well on top (the slab hides the well's soil: "trees grow out of the
  cement"). Use `S.sidewalk_with_wells` (tenth_seg does). Amber's `amber_sidewalk` already leaves the holes.
- **Bike racks (2.5 m long, model X) stand PARALLEL to the kerb or the shopfront**, never across a sidewalk (17 Nov:
  racks blocked the walk). Shops on a narrow sidewalk get a forecourt for their tables / bench / racks.
- **Bus stops (Yasin 17 Nov): every area has a stop in BOTH directions**, far side of a junction, in the parking lane
  or shoulder with a red kerb and no stalls; a bench at the back of the sidewalk facing the street (shelters only where
  the sidewalk is wide enough to keep a clear path).
- **Shared yards are placed by use, not by free space** (apt_lib.fill_open): kids' corners in courts between two rows
  (bench facing the play), sitting spots just behind buildings, garden patches along side walls, nothing near alleys.
- **Every batch ends with three checks:** validator `CHECKS 0 problems`, `audit_trees.gd` `0 in hard ground`, lock test
  `RESULT PASS`. A build list must never name a locked piece (17 Nov: w_ind rebuilt while locked; restored from git
  with `git show <approved commit>:<path>` - the lock file stores the approved sha256).
- **A sample's quadrant library pattern** (ind_lib / strip_lib / apt_lib): constants for the cross-section, `q()` /
  `rect()` in quadrant coordinates (u = |x|, v = |z|), placement helpers that face buildings to the street, `dress()`
  per building (walks, door pots/lights, mailbox, hedges, AC, dish, back of house, patio), a finish() that saves
  "stalls" / "poles" meta for the parked cars and the wires piece. New samples copy this pattern.
- **painted_rect: the FIRST matching paint wins**: put details (stall lines, gutters, holes "-") before the area paint.
- **Door steps are props-free**: anything placed by a rule (pots, trees, benches, yard clusters) is checked against
  every ground-floor door (kit stats doors_front, incl. patio doors) - and each item of a cluster on its own.
- **Validator skips wall / roof mounted props** (manifest "mount" != ground, or lifted > 1.2 m): AC units, dishes,
  door lights, meters are not "inside" or "blocking" anything.
- **Merged buildings:** `merge_modular.gd` takes kit examples_map layouts too (`ck/ck_apt3_row2`, `ck_apt3_row3`,
  `ck_brk3_row2`, `ck_brk3_corner2`) and derives ground-floor doors from the pieces' openings.
- **Preview ground plane is 4000 m now** (17 Nov): at 1200 m the stadium site ran past its edge and "half the stadium
  floated" in Yasin's view. A site that looks like it hangs over a void: check the preview plane first.
- **Tree audit:** `tools/city/pilot/audit_trees.gd` checks every tree / palm's trunk against the ground under it
  (grass, mulch, gravel = fine; concrete, paving, asphalt = a tree in cement). Run it after any piece with trees.
- **Fences:** a post at EVERY panel joint, panels never stretched apart (`ind_lib.lot_fence`, `_iron_run`): posts only
  at run ends left floating panels. Panel lengths: chain-link 2.0, wrought iron 1.98, CMU 2.03.
- **Validator stats:** `K.building` stores meta "kit" (folder); labelled buildings in older pieces are matched by mesh
  shape. Before this, labelled buildings were silently NOT checked (found 16 Nov: 6 blocked doors in industrial).
- **Parked cars:** lots record meta "stalls" [x, z, yaw]; the preview draws the game's parked models on ~3 in 4
  (CARS=0 turns them off). Preview draws per shot are inflated by those cars (one draw each in the preview only).
- **A parse error in a helper hangs every piece build until its timeout** (strip_lib, 16 Nov): `--check-only` all
  changed scripts before a build batch.
- **Wire pieces (`w_*`) are built in WORLD coordinates: their layout row stays at pos [0,0,0].** w_ind was once placed
  at the site offset too and every wire hung 400 m away, unseen for two rounds. Look for the wires in a shot.
- **Wires use `city_kit/shaders/wire.gdshader`** (w_ind): ribbon edges on the centre line, opened toward the camera with
  a minimum ~1.3 px width. A fixed 4 cm ribbon breaks into dashes past ~25 m. Same triangles. (w_power is locked and
  still uses the fixed ribbon.)
- Service drops land on the wall facing the pole, never the building centre (the wire would go through the roof).
- **Paint is cut into the asphalt** (`kit_lib.painted_rect`, same plane, no lifted layers). Wear marks are decals at 1 cm lift that fade out by 90 m.

## Clusters (Yasin 16 Nov): read map_dc/coronado/city_kit/CITY_PLAN.md
The city is grown from approved cluster samples placed by a zoning map:
- **Residential:** the pilot's hill rows.
- **High street:** the pilot's Amber blocks. They read as a small-town main street, NOT a dense centre.
- **City centre:** the `c_*` sample, on its OWN street pieces `j_cc`, `s_cc_amber_n/_s`, `s_cc_10th` (Yasin 16 Nov:
  "widen the sidewalks in the city center"): no parking lane, kerb on the lane edge (`S.A_KERB = S.A_LANE`,
  `S.T_KERB = S.T_LANE`, set at the top of the piece script; A_KERB/T_KERB are static vars for this), sidewalks
  6.9 m (Amber) / 6.4 m (10th). Building lines unchanged, so the locked blocks did not move. The pilot street
  pieces keep the parking-lane section (high street).
- **Commercial strip:** `j_strip`, `s_strip_art` (x2), `s_strip_side` (x2), `m_*`, `w_strip` at (-400,0,0): car-oriented
  arterial (turn lane, bike lanes, palm parkway), lots in front of set-back buildings, pads on the corners.
- **Industrial:** density pass (Yasin: "definitely very very empty"). Each 100 m quadrant is a PERIMETER BLOCK:
  buildings shoulder to shoulder on both frontages (`ind_lib.put`, fronts 0.5 m behind the property line), open
  driveways only at the standard aprons, a back row facing the yard (`put_back`), the working yard in the middle.
  One quadrant may be one big building (NW = 72 x 48 m distribution centre). Every frontage business gets its own
  sidewalk furniture (`walk_prop`), every building gets back-of-house services, grime at its feet and oil/tyre marks
  at its rollups (`bld_wear`); yards get `yard_wear` (density ~1 mark per 35 m2). Facade wear 0.85.
- (earlier notes) the `i_*` sample at (0,0,-400) with `j_ind` / `s_ind` / `w_ind` (`ind_lib.gd`): 4-lane truck street,
  no parking lane, wide kerb radius (12 m), standard 10 m aprons with 6 m rolling gates at s=40 and 75 on every
  frontage, chain-link lot fences, gravel yards. A CMU wall + eucalyptus buffer faces any residential neighbour.
  Cobra lamps and lot lights are checked by the validator as posts only.

Agents may fill zones in parallel only after a sample is locked. They write only their own piece scripts; the shared
helpers stay with one session.

## Reuse rule (learned 16 Nov)
Street pieces (`s_`, `j_`) carry ONLY street furniture: meters, lamps, trees, bins, signs, shelters. Anything tied to
a particular building front (a bench by a cafe door, a bike rack for a bookshop) belongs to the BLOCK piece. Otherwise
reusing a street piece puts that bench in front of somebody else's door (the validator caught it).

## Yasin's rules (his words, 16 Nov)
- **Act as exterior designer, architect and city planner at once.** Believable, lots of props, each with a reason.
- **"Denser than Coronado":**
  - The high street sample was too thin: 1-2 storeys, empty rear lots, 15 m lots.
  - City centre = continuous 4-6 storey walls, towers on key corners, the alley side built up too.
  - Parking in garages or on the street, not open lots.
- **Purpose:** every feature exists for a reason, in the right place, at the right time, like an architect / planner would decide.
- **Lived in, never brand new:**
  - oil where cars park, braking marks at stop bars, cracks and patches, gutter grime
  - red kerbs at bus zones and hydrants
  - dirt at building feet, worn grass where people cut corners
  - bins beside garages (not collection day)
- **Banned:** NO grass tufts (`plant_lawn_patch`): "looks terrible". No square dry mats.
- **Park enclosures:** a closed hedge with ONE apparent entrance.
- **Budgets:** cables ~700 tris total in one draw ("3100 for cables, really?"). Buildings 1.5-5k tris near tier (kit SPEC.md).
- **Shots:** look at every shot yourself before sending; say which ones you did not open. Never claim "zero problems" beyond what the validator covers.
- Not measured on the Redmi yet: say so in reports.

## Lessons 17 Nov (batch-2 fixes, stadium gates, top view)
- Run validate.gd / audit_trees.gd / the lock test with the REAL renderer (xvfb + vulkan), never `--headless`:
  headless MultiMesh transforms read as (0,0) and the validator reports millions of fake overlaps.
- A kit model's tiers can differ in shape: the stadium's MID tier cuts a 9.5 m gate opening, the near tier 6.5 m, the
  far tier none. Measure openings on every tier (raycast each MeshInstance3D of the BUILT scene), size fillers for the
  widest and hide them inside the wall thickness.
- Long props are lines: reserve their full length in fill_open (clothesline 5.2 m, fences, dingbat stairs). Check the
  manifest `footprint_w`, not a guess.
- Keep the foot of every outdoor stair (in-model stairs too) 2.5 m clear; vending / ice chests go at the far end of a
  wall, never at a stair or door.
- No wheel stops under a dingbat (cars nose up to the stair wall); no tree within 0.9 m of a fence panel.
- Whole-city plan: `TOPVIEW=<metres across>` + `LABELS=<json file>` in shots.gd = orthographic, near tiers only, no
  distance culling. Camera straight down with target z 1 m north of the camera for north-up. Wires look thick in it.
- Gritty edge (17 Nov): `grt_lib.gd` on top of civ_lib (same sub-blocks A/B/C/D): `shop` (property line + 2.5 m
  forecourt, furniture slid clear of doors and DROPPED when no clear spot - a door always wins), `home` (chain-link
  front fence with gaps at the walks; "+v"/"+u" faces = rear rows facing the lane parking), `dingbat`, `lot`
  (vacant / scrap / site, ONE gate, billboard in the corner clear of the gate track), `bins`.
- A shade sail goes OVER the table it shades (4.6 x 3.8 m), never between two tables (Yasin 17 Nov, garden photo).
- civ_lib.lot's planted end islands close the aisle: next to a lane use `A.pad` (nose-in off the lane) instead.
- Kit parks with partial hedges (star circle) get chain-link round them with ONE gate.
- Close-up cameras at 3-6 m land in parkway trees: put cameras over lanes / junctions or at 12+ m.
- merge layouts: a helper with a positional default arg (D) swallowed "stg" -> missing walls. Name the arguments.
- Shader "conditions" for kit props that only ship one look (kit_lib Props.build, new material files only, so locked
  pieces never change): "iron" (prop_iron.gdshader: white metalwork -> black iron; balconies on brick) and "net"
  (prop_net.gdshader: tennis nets two-sided, see-through mesh, white tape). ind_lib.add passes them through.
- Apartment rows (ck_apt3_*) have walkway fronts with rails and doors: never add the balcony prop to them.
- **Every built piece must be split** (17 Nov, fixed with Yasin's go): a prop type's instances share ONE MultiMesh
  and Godot measures visibility range to its AABB centre, so small props far from the centre of a big piece never
  drew (stadium picnic tables) and bigger ones showed their mid tier up close. `tools/city/pilot/split_props.gd --
  <pieces>` re-packs a SAVED piece (no script re-run): batches whose props can be > 45 m (near) / 90 m (mid) from
  the centre go into 64 m / 128 m cells under `Props/cell_<tier>_<x>_<z>/` keeping the batch name (tools find
  batches by "*_near"); far tiers stay whole; it refuses to save unless every instance transform is identical.
  The scratch build.sh runs it after every build. Cost measured: +0..10 draws per view.
- **Life overlays (d_pilot, d_cc, 17 Nov):** to add props to locked samples without touching them, an overlay piece
  (`life_lib.gd`) loads the sample's layout rows (with yaws), reads buildings (kit stats, roof by raycast: only flat
  roofs, normal.y > 0.97, 2.6 m above ground), ground (height raycast, cached) and every existing prop (4 m grid), and
  adds only clear, logical items. Older pieces' buildings without meta "kit" have inexact footprints: no door props
  on them. Wall items still check free space at their foot. A while-loop step outside its loop once ate all memory.
- **Every building records meta "kit" now** (17 Nov, Yasin: "all the zones should have the same standards"):
  `tools/city/pilot/record_kit.gd -- <pieces>` added it to the 10 oldest pieces (58 buildings, by name or near-mesh
  shape) without changing anything else (refuses to save on any transform / prop difference). New pieces get it from
  K.building. Door props keep 1.55 m from EVERY building's doors (a neighbour's too) and 0.75 m off the facade.

## Lessons 17 Nov (audit fixes, road kit start)
- **Kerb returns: the arc's centre c lies INSIDE the block**; the corner sidewalk is between c and the arc. Furniture on
  the corner goes at r - 1 (behind the kerb); r + 1 is on the asphalt fillet (j_amber_10th / j_cc signals stood in the
  road for a day). Corner props must be checked from the street, not only by the validator.
- **Validator `street` check** (validate.gd): any ground prop on the road surface (asphalt / paint surfaces of the
  ground mesh) of ANY j_* / s_* piece in the layout. It found exactly the audit's 12 poles and nothing else.
- **New road pieces live in `pieces/road_lib.gd`**; never change apt_lib / ind_lib / amber_seg for new work (locked
  pieces were built with them). `road_lib.apt_street(name, dress)`: s_apt cross-section with zone dress apt / civ / grt
  / wfd: identical stalls, aprons, hydrant, bus zone, so a variant swaps in a layout row without touching blocks.
- **Bus stops on parkway streets get a concrete boarding pad** through the parkway at the doors, no tree on it, the
  sign at its front end, the lamp at the back of the zone, the speed sign 25 m on (audit #15: four posts in 2.5 m).
- **Pale patches: `W.pale_patch()`** (tiles 4/5 always ~0.5 grey). Dark tiles (2/3) alone on a road read as shadows of
  nothing: only long narrow trench strips or patches round a manhole.
- **`tools/city/pilot/diff_piece.gd -- <old.scn> <new.scn>`**: what a rebuild changed (props added / removed / moved,
  ground surfaces). Run it before asking Yasin to relock: a rebuild with today's helpers may change more than the fix.
- Kit jacaranda crowns start at 2.3-2.9 m (measured): too low over parking and sign bands; scaling would need x1.9.
  On Amber they alternate with queen palms (crown 7.3 m) until a street-pruned jacaranda exists.
- **Residential road kit (road_lib)**: s_apt cross-section with residential dress (no centre line, unmarked parking,
  garages on alleys so no driveway cuts, lamp per junction corner + one mid-block, hydrant ~100 m alternate sides).
  Slopes: a block rises H across the 160 m between junction tiles (smoothstep); the up-leg carries H, the down-leg
  -H from the upper junction, so the halves meet with equal height and grade; max grade 1.5 H / 160. site.gd's
  sidewalk_strip / red_kerb / S.walk_y only follow the pilot's x-hill: on z-slopes use road_lib strip_z / red_kerb_z /
  lane_wear_y (decals <= 4 m on curved slopes). Stalls on slopes: [x, z, yaw, y, grade]; shots.gd tilts the cars.
- **Kit tree crowns (measured)**: broadleaf yard trees hang to 1.6-2.5 m (coral, magnolia, ficus, jacaranda); street
  trees need ~2.5 m over the walk: torrey pine 4.8+, queen palm 4.2+, fan palm 7.4+.
- **Street trees (Yasin 17 Nov): variety over rules.** One species per street read as copy-paste; low crowns over
  the road are acceptable ("from fps view they'll be visible anyway"). road_lib RES_MIX: weighted species, runs of
  the same species (owner / builder plantings), scale 0.75-1.15 (Props.add `scale`; colliders stay unscaled),
  11-14 m rhythm, ~8 % gaps; several leg variants (s_res_a/b/c) so neighbouring legs differ.

## Lessons 17 Nov (terrain, game bake, shore foam, 1st St raise, merges)
- **Terrain pipeline (re-run in this order after any piece's ground changes):**
  1. `tools/city/pilot/zoning/piece_ground.gd` in the preview (CITYKIT_LAYOUT_ONLY=1 + EXTRA city_grid_layout.json,
     real renderer) -> pack to `zoning/piece_ground.npz` (the command is in its header)
  2. `terrain.py` (fits the ground to the pieces AS BUILT: nodes touching a piece sit 5 cm under its lowest ground,
     `fit_edges` raises the neighbours flush; beach from the smooth coast polylines; box +300 m on the land sides
     pinned to today's ground) -> `zoning/terrain_grid.npz`
  3. `coast.py` only if the box changes (its box must cover terrain.py's box, or the beach in the margin has no
     smooth line and stair-steps)
  4. `shore_foam.py` + build piece `x_shore_foam` (foam strip along every beach; whole-city piece at [0,0,0])
  5. `bake_game_terrain.py` -> `map_dc/coronado/terrain/data_citykit/` (game reads it with the user arg
     `--citykit`, `CoronadoTerrain.data_dir()`; terrain/data and the live game untouched)
  6. checks: `terrain_check.gd` (shows-through must be 0), the water line's bend per 1 m (contour of H at 0)
- **The game's sea is ONE flat plane at y = 0.** Any piece ground at 0 z-fights / floods (1st St was graded at 0:
  the grading blur pulled the bay-side pads down). Pads near water must be >= 2 m; the waterfront walk is 1.5 m over
  the sea (pad 1.35).
- **Jagged water lines come from masks.** Heights near the coast must come from the true distance to the smooth
  coast polylines (shapely), never from a 4 m / 2.5 m mask's EDT. Piece ground under water (a ramp's toe) must not
  constrain the beach (it digs pits that bend the water line); but only near the sea, or 1st St at 0 lost its
  constraint and the ground poked through it.
- **Beach into the sea (Yasin: "eases into the sea with bubbles"):** sea floor = max(beach 8 % slope, min(old,
  -0.5 - 2 % * d)): no flat shelf, no step down to the old depth.
- **Preview terrain:** shots.gd `TERRAIN=res://terrain_grid.json` (export .f32 / .u8 / .json from the npz). Vertex
  colours need pow(c, 2.2) in a ShaderMaterial or the ground renders white (Yasin saw it). The 1 m contour lines are
  preview only: say so in captions.
- **Regenerating review/sites.json (roadkit_sites.py) drops hand edits** (the waterfront node at 1.35 and its 3
  blocks): diff it and restore them.
- **zz_ring_nw_write.gd needs the full piece list as args** (scratchpad nw_all.txt); without it it writes an almost
  empty table. Same for the other family writers: check the row count against git before committing.
- **diff_piece.gd must run with the real renderer** (headless reads MultiMesh as empty: positions 0, fake adds /
  removes). It does not show ground height changes: compare the ground mesh's y range separately.
- **Merging a branch that touches locked.json:** take ours, add only THEIR new entries; never re-add an entry we
  unlocked (an old grading.json hash came back and failed the lock test). Run the lock test after every merge.
- **Interiors (merged 17 Nov, claude/city-kit-interiors):** rooms in city_kit/interiors/rooms, checker
  `rooms/check_rooms.gd` (0 problems required). The preview project needs links to map_dc/coronado/shops/interior
  and ui/fonts, then an import, or the checker dies on missing textures.
- **Seawalls / promenades follow the shoreline** (Yasin on the ferry plan): offset the smoothed water line inland,
  never a straight quay across a curving coast.
- **Godot writes .uid files on import:** commit them (the stop hook asks).

## Lessons 18 Nov (audit, runtime bake): read docs/AUDIT_PERF_LIFE_18NOV.md and docs/RUNTIME_BAKE.md
- **Measure, then change:** `tools/city/audit/` (census.gd per piece, probe.gd street views with each group hidden in
  turn, load_times.gd) and `tools/city/bake/rt_shots.gd --probe --detail` for the baked city. Counts are valid on the
  cloud GPU, times are not a phone's.
- **Runtime bake** (`tools/city/bake/bake_runtime.gd`): derived data in `city_kit/runtime/` (not in git), pieces are
  never written. First `make_arrays.py`, then `--import`, then the bake. `--check` lists stale cells.
- **Yasin: draw calls as low as possible, triangles second.** Big batches (near per 64 m, mid and ground per cell, far
  world in 1 km chunks). Merging the near tier per piece batch instead costs +45 draws.
- **The cloud preview renders `bldg_wear` buildings about 40 % too dark** (Mobile renderer on lavapipe; OpenGL and
  Forward+ agree with each other). Do not tune building colours from cloud shots; a shader with one more uniform
  renders the brighter, matching result.
- **Packed arrays through a Variant cast are copies:** `(x as PackedFloat32Array).append(..)` appends to nothing, and a
  packed array stored in a Dictionary is copied on access. Use typed locals, or a SurfaceTool per bucket.
- **Instance uniforms:** write every one on every instance; `texture_debug_usage` is not exposed to scripts.
- **Kit textures are VRAM compressed with mipmaps since 18 Nov** (Yasin's yes). New kit atlases must get the same
  import settings, or they load at 4x the memory and sparkle.
- `prop_wear_mat` names materials by the colour atlas only, so most near props run without normal / ORM maps (the
  first creator was a mid tier). Known, kept, Yasin's call.

