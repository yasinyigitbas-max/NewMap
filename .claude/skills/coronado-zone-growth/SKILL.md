---
name: coronado-zone-growth
description: Grow a whole zone of Coronado's city kit from its locked sample, outdoors and indoors together (variants, a pilot area, then the rest of the zone, a polish pass, rooms behind every walk-in door, checks, bake numbers, lock). Learned on the industrial zone, 18-19 Nov 2026 (branch claude/grow-industrial), with every mistake made there and Yasin's correction for it. Use for "grow the X zone", "make variants", "roll out to the whole zone", "polish pass", "fill the rest of the zone", for rooms in growth blocks, or when a growth block looks wrong. Read coronado-city-kit (pieces, locking, validator) and coronado-city-interiors (rooms) first; this skill sits on top of them.
---

# Growing a zone (industrial, 18-19 Nov 2026)

What came out of the industrial session, as a worked example:
- 10 blocks and a life overlay for the locked sample.
- 16 rooms.
- Every check at 0, then everything locked by Yasin.

Read:
- `map_dc/coronado/city_kit/review/grow_ind/README.md`: what was built, why, the numbers.
- `tools/city/pilot/pieces/ind_grow_lib.gd`: the library. Each function header gives its reason.

## Yasin's words that shaped it (keep them)
- "work like an exterior designer and city planners for outdoors and look from the perspective of interior designer
  and the customers when you design indoors"
- "you are not limited to unused buildings or props only, but when you are done make sure that youve used every prop
  and buildings that makes sense in your part"
- "do out and indoors together ... i want the shops to look different" (each zone's rooms have their own character)
- "run a polish pass on your part, lots of props"; "find mistakes if you find them, fix them, if not, roll out to
  your whole zone, then do a polish pass on the whole zone"; "lock them for now, rest will be handmade adjustments"
- He checks the PICTURES closely and finds what checkers miss. Look at every picture yourself before sending.
  Write to him short and plain.

## The method that worked
1. **Read first:** the job board, the city-kit skill, CITY_PLAN / ZONING / STREETS / KIT_USAGE, integrate.py, and the
   sample's builders (`i_*.gd`, `ind_lib.gd`).
2. **Measure, never assume, the streets around a site.** The road kit's sections differ:
   - 1st St / ring inland: property line 14.31 m.
   - 3rd St arterial: 14.31 m, tapering to 8.7 by J Ave.
   - Truck avenues: 8.70 m.
   - Residential street: about 9.2 m, with alley mouths.
   - Kerb returns differ too.
   How the library uses this:
   - `G.measure()` loads the street pieces and raycasts the sidewalk edge (2 cm). The floor polygon starts exactly
     there: no gap, no overlap.
   - `G.measure_rows()` does the same row by row for odd shapes (a strip ending in the ring's rounded corner),
     reading EVERY neighbouring piece, not only streets.
3. **Gates sit on the street's own aprons.** Read them from the road builders: art legs' `apr`, stub aprons every
   35 m from z0+18 (no-parking signs mark them).
   - A boulevard with no aprons (1st St, Alameda) gets no truck gate: offices and counters face it.
   - A residential street has no driveways, only alley mouths: use the alley mouth as the yard gate.
4. **Variants:** 3 design ideas, each dressed 2-3 times on different sites (A port, B fleet, C cold chain). Each piece
   is its own builder script with a header that gives the planner's reasons.
5. **Placement table** in the shared form `review/grow_<zone>_blocks.json` `{"rows": [{piece, pos, yaw}]}`. integrate.py
   reads every `grow_*_blocks.json`. Never patch integrate.py for your zone (the gritty session's hook is the shared
   one). Regenerate `city_grid_layout.json` after every table change.
6. **Slopes:** `G.measure_rows` + `G.floor_rows` + `G.drape` (a Coons patch from the heights measured all round the
   edge), plus `G.pad` (a level pad under each building, eased into the slope over 5 m).
   - Read each edge height just OUTSIDE the free area (on the walk), never on the road.
   - An edge with nothing beside it takes the line between its neighbours' ends, or the corner gets a step.
7. **Polish:** `G.place` / `G.spot` put each prop in a zone chosen for its PURPOSE. It goes only where it clears
   buildings (by their real mesh), doors (1.6 m), other props, truck lanes (keep rects) and parked cars, and is
   left out otherwise.
   - Every item has a reason in a comment: stop signs at yard exits, hydrants by buildings, a workers' break spot,
     the city yard's stock of new bins.
   - A locked sample gets a LIFE OVERLAY piece (`i_life_w800_n1400`, like d_pilot). It reads the sample read-only
     (`G.obstacles_scene`) and is never an edit to the sample.
8. **Rooms:**
   - `tools/city/rooms/list_buildings_ind.gd` -> `assign_ind.py` (place, kind, name, reason; bays from
     assign_all.bays(), boards claimed) -> `room_gen_ind.gd`. That is a COPY of room_gen.gd with the zone's own kinds;
     never edit the shared one.
   - Then run `check_rooms.gd -- --only=g_ind_` until it reports 0.
   - Pictures: `gen_shots_ind.gd` (street by day, evening, inside).
9. **Checks** on the zone with every neighbour loaded: put an area layout (rows within the zone's box) in `.godot/`,
   then validator 0, trees 0, sink 0, rooms 0, lock test PASS. The city-wide run is slow and mixes in other
   sessions' problems.
10. **Numbers:**
    - Bake the area twice, without and with your table: `bake_runtime.gd -- --area=X,Z,R --nofarground
      --out=res://.godot/rt_x/`. The TRAILING SLASH matters: without it the folders are glued to the name and the
      scenes point nowhere (draws=1).
    - Measure the same views with `rt_shots.gd --runtime=...`, and compare cell sizes for the download.
11. **Commit and push after every step.**

## Mistakes made here and Yasin's corrections (do not repeat)
| What went wrong | Yasin | The rule now |
|---|---|---|
| ext_marina_office has a 20 m wooden jetty in its model; on 1st St it lay across the road | "what are those wooden pieces on the road" | Place buildings by their REAL near-mesh outline (`G.overhang`), not the stats footprint. Check a new model's mesh AABB. Car wash +5 m canopy, harbour office +4 m porch, warehouse/factory +3.5 m. |
| A bin and a paper box by the diner door; then the room library's storefront BULKHEAD ran across the door of ck_grt_row2 | "something blocking the door", "a thick seam like object" | Keep sidewalk furniture well away from doors (the validator's 1.55 m is not enough to read clear). Do not use ck_grt_row2 for walk-in places (painted windows overlap its own side door, and room_lib's bulkhead crosses its shop door): use ck/mod_fastfood, ck/ck_svc_pawn_fast. The indoor checker's `doorway` rule catches room geometry in a door. |
| Painted windows overlapping a door in a kit model | "here we have more overlapping props" | That model is a kit flaw: avoid it for rooms; look at every room's street picture. |
| Kit wall_shelf / gondola_aisle shipped empty | "most shelves are empty", "cant you fill the shelves with props?" | Since the indoor props of dd8d53a they are stocked; check a manifest's goods trims (tg_*). The indoor checker's `bare` rule flags empty shelf models. |
| Too many of one thing, bins in the open, boards over windows | (combined checker) | room_gen_ind caps repeats (vending 1, brochure 2, fridges 4), puts bins at walls, allows 2 boards a wall and 5 a room, never over a window at any height, and places boards AFTER furniture and floor stock. |
| Back-of-house meters, boxes and AC units on doors, in front of rollups, over windows | "prop overlaps on the wall", "props overlap on the gate", "prop sitting on a window" | `G.G_services`: services from cc_lib filtered against the model's back openings (contract, both signs of along; 0.35 m off doors and rollups, 0.9 m off windows). Use `G.put` / `G.put_back`, never `I.put` with services. |
| A building set at the lowest ground under it on a slope: the back steps sank | "shop is sunk" | Level pad under every building on a slope (`G.pad`), at its street-front level, easing into the slope. |
| A bench placed beside a picnic table | "picnic table sits next to a stray bench" | A picnic table has its seats; a bench only faces a path, a green or a view. |
| Wall panels on a slope at their centre height: the downhill end floated | "wall bulges off the ground" | In `G.drape` a fence or wall panel stands at the LOWEST ground along its length (-3 cm). |
| A hydrant placed anywhere free in a yard | "fire hydrant in the middle of nowhere" | Hydrants (and hose reels) only within 2 m of a building wall (`NEAR_WALL` in `G.place`). |
| ind_lib.yard_wear's dark patch squares | (seen in the pictures) | Dark tiles alone read as shadows of nothing: `G.yard_wear` makes them narrow trench repairs. The LOCKED sample still has them (needs Yasin's word). |
| prop_tank_vertical is 9 m across: k-rails stood inside tanks | | Read `footprint_w/d` of every big prop before placing (dock crane 39 x 4 m pedestal jib crane, not a gantry; water tower 11 m; billboard 14.6 m). |
| The validator counted the crane's 39 m footprint across the stacks | | Lay a long prop's footprint along a lane, not over other props. |
| Inline comment placed before a closing `)` | (parse error, build hung) | `--check-only` every changed script before a build; put comments at the line's end. |
| list_buildings hung on a piece with no Buildings node | (job never finished) | `get_node_or_null`; a GDScript error hangs Godot instead of quitting. Long jobs: run in the background and watch for "Terminated". |
| Room files built from an out-of-date buildings list | | After any building moves (pads, swaps): list_buildings -> assign -> room_gen -> check, in that order. |
| Polish benches/bins by the corner sign, fences on the kerb return, walls touching a neighbour's props | (validator) | Fences at corners cut across on the diagonal past the junction's furniture; own-edge walls 0.7 m in from a boundary the neighbour leaves open. |

## Working beside other sessions
- Name everything with the zone prefix: `i_*` pieces, `g_ind_*` rooms, `*_ind.*` tools. Keep your own tables.
- Add lines to the job board and KIT_USAGE; never rewrite others' lines.
- Merge the working branch often (the PC session merges everything pushed). On a job-board conflict, keep both sides.
- Godot import stubs (`.uid` / `.import`) of OTHER sessions' files appear after merges. Delete them locally rather than
  committing them: random ids collide at the next merge.
- The PC session ("Hello") is reached with `mcp__claude-code-remote__send_message`. It needs Yasin's one-time
  approval card (`confirm_repository_trust`). Peers cannot read replies unless they say so.
- A private repo you cannot reach: do not route around a refused add_repo. Ask for the files to be pushed into this
  repo (that is how the indoor props came: branch claude/kit-indoor-props, commit 9fce731).

## Budgets measured (cloud, not a phone)
- Pilot six blocks: worst street view 78 draws / 387k triangles; download +5.8 MB.
- Rooms are NOT in the bake: 21-36 draws and 4-6 lights each, unmerged. Two or three in view would pass 150.
- Layered see-through fences cost the phone: boulevard fronts and shared edges are opaque walls; chain-link only where
  seeing through is the point, never behind another.
