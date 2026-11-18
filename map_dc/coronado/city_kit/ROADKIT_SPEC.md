# Road kit, groups 2-5: the brief every builder and reviewer works from (17 Nov)

Yasin, 17 Nov: "go on and good luck. ultracode is on, read the rules and my messages from start to finish and make sure
the subagents do the same, act like an architect, city planner and exterior designer, no jagged edges".

## 0. Read first, start to finish, before writing anything
1. Yasin's messages, all of them: `/tmp/claude-0/-home-user-coronado-source/eb746224-af68-52a3-91df-ef414b5ad74a/scratchpad/yasin_messages.md`.
2. The rules and the queue: `map_dc/coronado/city_kit/JOB_BOARD.md`.
3. The method, the traps and the lessons: `.claude/skills/coronado-city-kit/SKILL.md`.
4. The plans:
   - `CITY_PLAN.md`
   - `ZONING.md` (locked)
   - `STREETS.md` (locked skeleton and grading plan)
   - `PILOT_DESIGN.md`
5. The audit of the existing zones: `/tmp/claude-0/-home-user-coronado-source/eb746224-af68-52a3-91df-ef414b5ad74a/scratchpad/audit/audit.txt`. Fix #1 (signals on the asphalt) was a sign error at a kerb return: never repeat it.
6. The road kit so far: `tools/city/pilot/pieces/road_lib.gd`, the pattern every new piece follows. Group 1 is locked: `j_res`, `s_res_a/b/c`, `s_res_up/dn*`.
7. The pieces your family connects to:
   - `j_apt`, `s_apt`, `s_civ`, `s_grt`, `s_wfd` (road_lib.apt_street)
   - `j_strip`, `s_strip_art`, `s_strip_side` (strip_lib)
   - `j_ind`, `s_ind` (ind_lib)
   - `j_amber_10th`, `s_amber_n/s`, `s_10th_w/e` (amber_seg, tenth_seg, site.gd)
   - `j_cc`, `s_cc_amber_n/s`, `s_cc_10th` (s_cc_amber.gd, s_cc_10th.gd)

## 1. Who you are
**An architect, a city planner (road planner) and an exterior designer at once.**
- Every kerb, sign, lamp, tree, mark and stain exists for a reason: who uses it, when, why there. Write that reason in a comment next to it.
- Lots of props, lively, lived-in, never brand new. Wear goes where the thing that makes it happens.
- **Variety:** no two legs or junctions dressed the same. Use leg variants (a/b/c) and the RES_MIX tree mix.
- **No jagged edges:**
  - exact polygons; kerb returns are smooth arcs (12+ segments)
  - paint is cut into the asphalt (`K.painted_rect`, one plane, nothing lifted)
  - smooth arrows (`S.arrow2` + `K.fill_arrow`)
  - no stair-steps, no gaps, no overlaps where two pieces meet

## 2. The frame and the conventions (measure, never assume)
- **Grid frame (skeleton):**
  - u: along 10th St toward ESE; v: along Amber toward SSW; origin Amber x 10th
  - lattice pitch 200 m. East of Amber the u lines are 0, 250, 500, so those blocks are 250 m long.
- **Pieces are authored in a local frame:** the junction centre is the origin, and a leg runs along +z from the junction tile to 100 m.
  - Place a piece with yaw (Godot: yaw 90 turns +z to +x).
  - A layout row: `{"piece", "pos": [x, y, z], "yaw"}`; y = the junction's pad height.
- **Where the existing legs start** (the junction tile edge). Measure these with an AABB script before relying on them:

  | Legs | Start |
  |---|---|
  | residential / standard (`s_res*`, `s_apt`, `s_civ/grt/wfd`) | 20 |
  | strip arterial (`s_strip_art`) | 22, along the strip frame's x |
  | strip side street (`s_strip_side`) | 26 |
  | truck street (`s_ind`) | 22 |
  | pilot Amber (`s_amber_*`) | 17.5 to 97.5 |
  | pilot 10th (`s_10th_*`) | 23.5 |
  | centre Amber / centre 10th | measure |

- **Cross-sections (half widths, metres):**

  | Street | Lanes | Parking / bike | Kerb | Parkway | Property line | Kerb return R |
  |---|---|---|---|---|---|---|
  | residential / standard (apt_lib) | 3.3 | parking to 5.7 | 5.7 | grass 5.7-7.2 | sidewalk to 9.2 | 6 |
  | strip arterial (strip_lib) | turn lane 1.8, lanes 5.3 / 8.8 | bike lane to 10.3 | 10.3 | palms to 12.3 | sidewalk to 14.3 | 8 |
  | strip side (strip_lib) | 3.3 | parking to 5.7 | 5.7 | — | sidewalk to 8.7 | |
  | truck (ind_lib) | 4.2 | shoulder to 6.7 | 6.7 | — | sidewalk to 8.7 | 12 |
  | pilot Amber (site.gd) | median 2.5, lanes 9.1 | parking to 11.5 | 11.5 | — | building line 16 | 6 |
  | centre Amber (site.gd) | median 2.5, lanes 9.1 | — | kerb on the lane edge | — | building line 16 | 6 |

- **Ownership:** `map_dc/coronado/city_kit/review/sites.json` lists every junction and block of the locked skeleton with its legs, sections, pad height, rise and OWNER family. Build exactly what your family owns. Write down any site you cannot serve and why.
- **Heights:**
  - Junction pads are level at the grading plan's height (sites.json "pad").
  - A 200 m block rises H with road_lib's smoothstep across the 160 m between the junction tiles. The up-leg carries `seg_y(H, z)`; the down-leg is the same with -H, seen from the upper junction.
  - Other block lengths: the profile spans the block's own length between its tiles. Use the same smoothstep family, generalised in YOUR lib.
  - Max grade 8 %.
  - On a slope, use the z-slope helpers (`road_lib.strip_z`, `red_kerb_z`, `lane_wear_y`, decals <= 4 m). site.gd's `sidewalk_strip` / `red_kerb` / `walk_y` only follow the pilot's x-hill.
  - Stalls on slopes: `[x, z, yaw, y, grade]`.
- **3rd / 4th St are two-way arterials on the strip cross-section (`s_strip_art`), not a one-way pair.** The locked strip sample sits on 4th St with its arterial along 4th, so every 3rd/4th piece must match it.
- **Junction control:**
  - residential / standard: all-way stop
  - any arterial or Amber crossing: signals (mast arms over the major street, posts for the minor, street names)
  - T into the ring: the stem stops; the ring has signals where an arterial or Amber meets it
- **Corner furniture** stands at r - 1 from the kerb return's centre (the centre lies inside the block): on the walk, never on the asphalt fillet.
- **Bus stops:** far side, both directions, on bus routes (arterials, Amber, the ring, std collector streets). The boarding pad goes through any grass parkway at the doors, the sign at its front end, nothing within 2.5 m of the sign. Residential legs get none.
- **Trees:**
  - in grass parkways or round wells, never in concrete; never within 0.9 m of a fence
  - mixed species (road_lib RES_MIX), young to mature (`Props.add` scale)
  - none in the sight triangle of a stop or signal (about 25 m from the junction centre on the approach)

## 3. Files: what you may and may not touch
- **May create** (your family prefix only):
  - `tools/city/pilot/pieces/road_<family>.gd` (your library)
  - piece scripts `tools/city/pilot/pieces/<prefix>*.gd` and their `.scn`
  - preview-only review grounds `zz_<family>_*`
  - `map_dc/coronado/city_kit/review/<family>.json` (review layout rows) and `review/<family>_sites.json` (site -> piece, yaw, y: the integration table)
  - shots in `/tmp/claude-0/-home-user-coronado-source/eb746224-af68-52a3-91df-ef414b5ad74a/scratchpad/shots_<family>/`
- **Prefixes:**

  | Family | Prefixes |
  |---|---|
  | resstd | `j_rs_`, `s_rs_` |
  | amber | `j_am_`, `s_am_` |
  | art | `j_ar_`, `s_ar_` |
  | ring | `j_rg_`, `s_rg_` |
  | review grounds | `zz_<family>_` |

- **NEVER edit:**
  - shared helpers: road_lib.gd, kit_lib.gd, site.gd, wear_lib.gd, apt_lib, strip_lib, ind_lib, amber_seg, tenth_seg, cc_lib, civ_lib, grt_lib
  - tools: validate.gd, shots.gd, split_props.gd, audit_trees.gd, lock.py
  - data and docs: city_layout.json, locked.json, any `zoning/*` file, JOB_BOARD.md, SKILL.md
  - any locked piece or its script (`python3 -I tools/city/pilot/lock.py status`)
  - another family's files
- **If you need a shared helper changed,** copy what you need into your own lib and say so in your report.
- **No git commands that change anything:** no commit, push, checkout, reset, stash, rm. The coordinator commits.

## 4. Build, check, look (the loop)
- **Build:** `bash /tmp/claude-0/-home-user-coronado-source/eb746224-af68-52a3-91df-ef414b5ad74a/scratchpad/build.sh <piece> [...]`
  - real renderer
  - splits prop batches
  - refuses locked pieces
  - parse-check new scripts first: `godot --headless --path PV --check-only -s res://<script>`; a parse error hangs a build until its timeout
- **Preview project:** `PV=/tmp/claude-0/-home-user-coronado-source/eb746224-af68-52a3-91df-ef414b5ad74a/scratchpad/pv`. Its `tools/city/pilot` and `map_dc/coronado/city_kit` are symlinks to the repo. Another agent may be building at the same time: if a run dies on an odd import or lock error, wait a minute and retry once.
- **Review layout:** put your pieces in `review/<family>.json` in your review area, with preview-only grass under raised parts (see road_lib.review_ground_chain):

  | Family | Review origin |
  |---|---|
  | resstd | (0, 0, -3000) |
  | amber | (1600, 0, -3000) |
  | art | (3200, 0, -3000) |
  | ring | its pieces in grid coordinates with pos [0, 0, -8000] (the ring is per-site), plus its generic pieces at (4800, 0, -3000) |

- **Checks** (all with the real renderer: `xvfb-run -a -s "-screen 0 640x360x24" godot --path $PV --rendering-method mobile --rendering-driver vulkan -s ...`). All must pass before you report done:
  - your area alone: `CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=res://map_dc/coronado/city_kit/review/<family>.json` with `res://tools/city/pilot/validate.gd` -> `CHECKS 0 problems`. The `street` check flags any ground prop on a street piece's asphalt.
  - the same env with `res://tools/city/pilot/audit_trees.gd` -> `0 in hard ground`
  - the whole city plus your area: `CITYKIT_LAYOUT_EXTRA=...` only -> `CHECKS 0 problems`
  - `res://tests/city_kit/test_locked_pieces.gd` -> `RESULT PASS`
- **Shots:** `NOSHADOW=1 CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=... xvfb-run -a -s "-screen 0 1600x900x24" godot --path $PV --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/preview/shots.gd -- --out=DIR "--cams=name:x,y,z:tx,ty,tz;..."`
  - eye level 1.7-1.8 m over a lane, plus one high oblique per junction type
  - LOOK at every shot with the Read tool
  - check kerbs, joints between pieces (no gaps, steps or z-fighting), corner furniture on the walk, paint, trees, wear
  - say which shots you did not open
- **Diff an existing piece:** `tools/city/pilot/diff_piece.gd -- <old.scn> <new.scn>`.

## 5. Report (your final answer)
- the pieces built (name, purpose)
- the sites served (count by type) and any not served
- check outputs (the CHECKS / TREES / RESULT lines)
- the shots you looked at, and what you saw
- the files you created
- open issues, and decisions for Yasin

## 6. Added 17 Nov ~17:00 (coordinator): blocks next to a LOCKED sample
- **A locked sample's own legs are FLAT at its pad.** The one exception is the pilot's 10th St east leg (`s_10th_e`), which climbs the pilot's built hill (+5.9 m by x 150).
- **So on a block that touches a sample, the new leg from the other junction takes the WHOLE rise.** It runs a smoothstep from its own junction tile to the end of the sample's leg (100 m from the sample's junction; 150 m for the pilot's 10th St east).
- **Grade:** max 1.5 H / 80 for a 200 m block, so every such block in the grading plan stays <= 8 %.
- **The blocks** (sites.json ids):

  | Block | Street | Rise | Sample | Owner |
  |---|---|---|---|---|
  | b012 | G Ave | +2 | G | resstd |
  | b043 | Amber | -2 | P | amber |
  | b051 | B Ave | +2 | A | resstd |
  | b057 | Adela | +2 | M | art |
  | b078 | 4th St, 250 m | -4 | M | art |
  | b081 | 5th St | +2 | G | resstd |
  | b121 | 10th St, 250 m | +6 | P (its 5.9 m is already in s_10th_e) | resstd |
  | b130 | 11th St | -4 | W | ring |
  | b136 | W leg | +2 | W | ring |
  | b161 | Ocean Blvd | -2 | W | ring |

- **Reviewers:** check that these halves really meet: height and grade at the joint.
- **Added 17 Nov ~17:15: the waterfront sample W's pad is 1.35 m, not the grading plan's 2.0 m.**
  - Why: W's walk must be 1.5 m above the game's sea at y 0, or its marina floats and boats hover above the water.
  - review/sites.json now carries pad 1.35 for W's node, and the rises of W's three blocks (b130, b136, b161) are adjusted so their far ends keep their pads.
  - Ring builders: use 1.35 at W.

## 7. Yasin approved, 17 Nov ~17:15 ("okay they can go ahead"). Treat these as rules, not open questions:
- **Ring at the waterfront:** the ring leaves the skeleton line by up to ~20 m. Smooth biarc transitions join the waterfront's straight s_wfd legs.
- **Coast-side promenade:** 6 m (4 m walk + 2 m planting with bench bays facing the water), only where the ring faces water. The golf and base-fence sides keep the plain 2 m walk.
- **Ring bus stops:** far side both directions at every signalised T, plus enough stop-controlled T's that stops are never more than ~330 m apart.
- **Truck streets** meet the ring with stop control.
- **High-street side streets** (9th, 10th, 11th off Amber): the downtown section runs from Amber to the first alley, then residential. The pilot's double yellow carries on to the next junction.
- **Centre side streets:** std with parking up to the first alley, then a smooth 12 m build-out into the centre's no-parking, 6.4 m-walk section.
- **Civic and campus avenues:** one species per street (planted at one time); each tree still varies in model, turn and size. Residential streets keep the RES_MIX mix.

## 8. Known issues for the reviewers (coordinator, 17 Nov ~18:20; Yasin: "lamps look like they sunk in ... keep an eye on them")
- **The "sunk lamps" in Amber's residential parkway are pop-up lawn sprinklers** (`prop_sprinkler_popup`, 11 in s_am_b037_a's parkway strip). At street level they read as black stubs or sunk lamp bases, and that many reads as debris.
  - Rule: at most 1-2 per lot frontage, only in lawns with no other detail, never in a row along the walk; or none in street parkways at all (they belong to front yards).
  - Every family: check your pieces for the same.
- **Measured: no lamp or other ground prop on any street piece is sunk.** One exception floats: a speed sign 0.12 m above the ground in s_ar_b078_a at (-10.7, 86.0), on a slope.
  - Rule: on slopes, a prop's base y = the surface height at its own position, not at the piece's origin or the kerb line.
- **Reviewers:** run a sink/float check (prop base vs. the piece's ground surface under it, tolerance +-4 cm; trees in wells -12 cm). The script is `/tmp/claude-0/-home-user-coronado-source/eb746224-af68-52a3-91df-ef414b5ad74a/scratchpad/pv/zz_sink.gd` (real renderer, prints `SINK ...` lines and `SINK_DONE n`).
- **Also seen in the builders' shots** (check and fix):
  - oversized street-name signs on some mast arms
  - a bus shelter rendering black (check the material, not just the preview lighting)
  - dark rectangular patch decals in arterial lanes that read as shadows
