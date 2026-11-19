# Holes in the city's collision on roads and pavements: fix report (19 Nov 2026, cloud session)

Yasin: "fix all of them"; then "fill those too with collisions, dont change the appereance".

## Before and after

| Sweep (`tools/city/audit/collision_holes.gd`) | points | before | after |
|---|---|---|---|
| centre lines (`--centre`, the first scan) | 161,360 | 89 listed (95 miss points) | **0** |
| full width, 1 m along, 0.5 m across (the default now) | 977,333 | 108 places (first run after the bake fix: 36) | **0** |
| full width, fine: 0.5 m along, 0.25 m across | 3,791,010 | 42 places (after the bake fix and j_cc) | **0** |

Files: `before/` (the first scan, its cause table `before/why.json`), `after/holes_centre|wide|fine.txt/json`.
Each run re-baked first (`bake_runtime.gd --all`, 140 cells).

The full-width sweep also lists apart 73 (1 m) / 78 (fine) **edge points**: misses where ground lies within 5 cm on one
side only. The sweep's row there lies exactly on the outer edge of a pavement, where the land begins (a ray exactly on
a surface's outer boundary hits or misses by rounding). They are not holes and were not filled. A miss with ground on
two opposite sides within 5 cm (a crack) counts as a hole. A miss with no ground within 5 cm counts as a hole too.

## The holes by cause, and what changed

### 1. The bake cut hairline cracks into the ground collision: 70 of the first 89 (all 63 on roads)
- **Seen:** on a 0.1 m probe grid these were zero-width lines, for example exactly x = 480.000 or exactly z = -400.000.
  Raw locked pieces placed in an empty world (`tools/city/audit/hole_why.gd`) were whole at the same points.
- **Cause:** `bake_runtime.gd` cut each piece's ground trimesh into chunks of up to 400 triangles. It stored each chunk
  around its own off-grid centre, in the piece's frame, rotated by the piece's yaw. Float32 rounding then put a shared
  corner a few hundredths of a millimetre apart in two neighbouring chunks. A ray straight down onto the seam went
  between them. Lane centre lines and 200 m cell borders sit on round coordinates, so they hit those seams.
- **Change (bake):** the ground goes to `_split_concave` in world space, and each chunk's centre is a whole metre. That
  makes "corner - centre" and "centre + that" exact, so a shared corner is the same float in both chunks.
  - Cost: copies of a piece within one cell no longer share ground chunks.
  - Side effect: cell -6_-6 held only 5 collision chunks and no drawing; those now fall in its neighbours (141 → 140
    cells).
  - Building colliders are unchanged.

### 2. Two bugs in the scan's own grouping (not holes, but they made the old list wrong)
The union-find's parent list was a packed array, which the lambda received as a copy. On top of that, a one-line
`if ...: a; b` put the append inside the `if`. So no two points were ever joined: the "89 holes" were 89 single points,
and the same spot was listed twice. Both are fixed.

### 3. Corners of the city-centre junction `j_cc` with neither ground nor collision: 18 of the first 89
- **Seen:** at each of the 4 corners there is a 6 m quarter circle, centred on (±15.1, ±9.3) and bounded by the kerb's top
  edge. The piece's own pavement rings it. The crowd walks over it and the signal poles stand in it. This is the
  downtown hole the traffic session reported (x -14..-10, z -608..-604) and its three mirror images, 70 sweep points
  each. In the bird's-eye view the corners are empty (`j_cc_corners_before.png`).
- **Change (piece):** collision only, at kerb-top height, using the kerb's own 13 top-edge vertices plus the circle's
  centre. PROOF RESULT PASS: 48 new collision triangles; the other 13,204 ground and collision triangles are identical.
- **Not changed: the corners still look empty.** Nothing is drawn there, and in the game the land shows through.
  Whether to pave them is Yasin's call.

### 4. The crowd's walking band passes beyond the pavement onto unbuilt ground: 34 places, 23 pieces
- **Where:** at the back corners of junctions, and in gaps of up to 0.9 m between two pieces (f_sw / j_apt,
  j_ar_g3 / i_vb, i_vc, s_ar_b074_a / _b / g_v1_g4ne).
- **What was measured:** the band (the crowd's `hw` in streets.bin) runs 0.06–1.1 m past the pavement's back edge. The
  pavement and its collision were whole. At every one of these places the drawn ground ends exactly where the collision
  ends (hole_why measures both).
- **Change (piece):** collision only. Each fill is the band's misses plus 0.35 m, at the pavement's own height, which is
  read from the piece's drawn ground plane at each corner (slopes included).
  - The repeated junctions j_rs_t_lll_a and j_rs_t_lll_b showed the same corners at each place they stand, so one
    polygon covers every copy.
  - Gaps between two pieces went to the piece that stands only once (f_sw, not j_apt, which stands 7 times).

### 5. A lane's centre line runs exactly along a seam between two road pieces: 3 seams, plus 1 exact triangle corner
- **Where:**
  - x = 375.000, between s_rs_b094_a and s_rs_b094_b
  - z = 100.000, between s_am_b044_b and s_am_fill_hs
  - x = 400.000, between s_ar_b078_a and s_strip_art
  - one exact triangle corner inside s_rg_b159_2
- **Cause:** a ray straight down onto the shared edge misses at single points. Godot's ray–triangle test is strict at
  edges, so rounding decides. Some of these points miss in the raw pieces too, not only in the bake.
- **Change (piece):** a 0.3 m collision strip over each seam at the road's own height, stopping short of the median
  kerb on s_am_b044_b. A 0.7 m square at the s_rg_b159_2 corner. Nothing is drawn.

## How the piece changes were made
- **New superchecker op `add_ground_col` (`tools/city/super/sc_fix.gd`):**
  - It adds one listed convex polygon to the piece's ground **collision** only. Each corner is listed as `[x, z]` or
    `[x, z, y]`, and the new faces face the same way as the ground already there.
  - The proof requires exactly (corners - 2) new collision triangles, each made only of the listed corners, and
    nothing else different.
- **Run per piece:** `sc.py fix <piece> --fixes=...` produced PROOF RESULT PASS and no fault count changed on the
  re-check. Then `sc.py install <piece> --by=Yasin --record=collision`, which relocks the piece.
- **Records:** each fix is recorded as `review/superchecker/<piece>.collision.fixes.json` and `.proof.txt`, beside the
  street sessions' own `<piece>.fixes.json`, which is untouched. Each record line carries its cause.
  `--record=` is new in `sc.py install`.
- **Claims:** no piece claimed without a `.fixes.json` was touched.
- **When an upstream change came in:** s_rg_b159_2 changed upstream between the proof and the install. The install
  refused, so I re-proved it on the new version and installed it.
- **Pieces changed (31):**
  - j_cc
  - f_sw
  - i_vb_w600_n1400_nw
  - i_vc_w600_n1400_ne, i_vc_w600_n1600_sw
  - j_am_3rd, j_am_9th
  - j_ar_g3
  - j_rg_e660_n1000
  - j_rg_nw_e0_n1600, j_rg_nw_e660_n1200, j_rg_nw_e660_n1400, j_rg_nw_w200_n1600, j_rg_nw_w952_n1200,
    j_rg_nw_w994_n1000
  - j_rg_se_e627_s0, j_rg_se_w200_s328, j_rg_se_w400_s315, j_rg_se_w600_s302
  - j_rg_w800_s289
  - j_rs_t_lll_a, j_rs_t_lll_b, j_rs_t_lrl_a, j_rs_t_rrr_a
  - s_am_b044_b
  - s_ar_b074_b, s_ar_b078_a
  - s_rg_b159_2
  - s_rg_nw_b144_2
  - s_rg_se_b161_w
  - s_rs_b094_a
- The lock test said RESULT PASS before every commit.

## The scan, extended
- **Full width:** `collision_holes.gd` sweeps every pavement and crossing over the whole width people may use, stopping
  0.1 m short of each edge. It also sweeps every lane 1.4 m each side of its centre line.
  - It uses two new read-only audit methods in the C++: `CityCrowd.walk_points_across` and
    `CityTraffic.lane_points_across`.
  - `--centre` gives the old centre-line scan.
- **Cells with no file:** points in a cell the bake has no file for are now checked. Before, they were skipped.
- **Misses are classified** as hole, crack or edge point (see above).
- **holes.json** now lists each hole's own points.
- **Diagnosis tools (read-only):**
  - `hole_why.gd`: raw pieces, collision and drawn ground at each hole.
  - `ground_vs_col.gd`: ground drawn without collision, per piece. It found none in the pieces it was run on.

## What the scan cannot see
- **Anything off the sweep lines:**
  - Ground beyond the walking band and beyond 1.4 m either side of a lane: parking stalls, driveways, plazas, lots,
    yards, parks, the beach. Only the ways traffic and the crowd use are swept.
  - Holes smaller than the sweep spacing (0.5 m along by 0.25 m across in the finest run) can pass between rows.
- **Prop colliders:** rays hit any collision on layer 1, so a prop collider standing over a hole would hide it. It also
  does not check whether props block a way.
- **Height:** each ray runs from 1.5 m above to 1.5 m below the way's own height. Ground present but more than 1.5 m
  off, or a step or slope in the ground, is not measured.
- **Fills on unbuilt ground:** the fills in cause 4 lie where nothing is drawn. In the game the terrain is there; its
  height against the fill was not checked.
- **The game itself:** the scan uses the bake and the streamer in a headless run. The game's terrain collision and the
  traffic session's 3 cm safety floor are not part of it.
- **The phone was not run.** Collision triangle counts went up slightly (shapes 22,526 → 25,465 in the bake report,
  mostly from the world-space chunking). Cost on the Redmi was not measured: re-run the zones / stream gate.
- **Native build:** the C++ was built and run here on Linux only (godot-cpp 4.5 @ 27d9dd2, built with scons). The
  Windows dll and the Android .so were not rebuilt; the two new methods are audit-only.

## To reproduce in a cloud session
1. Godot 4.7.2 Linux, plus `mesa-vulkan-drivers` and `xvfb`.
2. Build godot-cpp (`scons platform=linux target=template_debug`).
3. Compile `native/src/*.cpp` into `native/bin/libcoronado_city.linux.x86_64.so`, and add `linux.*` lines to a copy of
   the `.gdextension`.
4. `godot --headless --path . --import`
5. `xvfb-run -a godot --rendering-driver vulkan --path . --rendering-method mobile -s res://tools/city/bake/bake_runtime.gd -- --all`
6. `godot --headless --path . -s res://tools/city/audit/collision_holes.gd [-- --centre | --step=0.5 --across=0.25]`
