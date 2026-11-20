# fill_east, prefix fn: the north end, the Crown Hill strip (20 Nov)

## Plan (written before building; what was built follows it)
Survey (OUT/g_city, read-only): the north end is THREE blocks, not the four the brief guessed. There is no street at
u 200: block 2 runs from Amber (u 16) to B Ave (u 240.8). Edges measured on the street meshes: 1st St walk v -1585.7
(2.15), 3rd St walk v -1414.3 (4.15 at u -190.8, 8.15 at Amber, 2.15 at B Ave), the u -200 street u -190.8, Amber
u -16 / +16 (32 m wide; 2.15 at the bay to 8.15 at 3rd St), B Ave u 240.8 / 259.2 (flat 2.15), n_hp_west at u 400.
Every corner square. Car openings (legs_measured + the street meshes): only the u -200 street's east apron and B Ave's
two aprons, all at v -1461 .. -1453; Amber, 1st St and 3rd St have none. The ferry gap (u 328 - 372) is a gap in the
whole 1st St piece (no walk, no road). Land: Crown Hill's north foot, 2.0 at the bay up to 8.0 at Amber x 3rd; block 3
flat.

| Block / piece | Plan in one line |
|---|---|
| 1 `n_fn_west` (u -190.8..-16) | Bay row of four apartment buildings facing the water; CROWN LANE from the west apron up the slope with townhouses (garages on the lane) both sides; the bay row's car park on a connector; a deli + florist on the hilltop corner Amber x 3rd; AMBER GREEN pocket lawn at Amber x 1st. |
| 2 `n_fn_mid` (u 16..240.8) | AMBER CORNER (cafe + ice cream on a plaza at the foot of Amber); AMBER STEPS hillside park along Amber (walk down, a level terrace); three beach condos + three garden apartments facing the bay; BAYVIEW LANE from the B Ave apron with townhouses both sides; the condos' car park. |
| 3 `n_fn_east` (u 259.2..400) | THE FERRY QUARTER: Ferry Plaza on the gap (bollards, benches to the bay), ferry ticket office, kayak & bike rental, Pier Fish House; Ferry Landing Inn on the bay; FERRY DRIVE from the B Ave apron with the park and ride and the inn's lot; FERRY WALK from 3rd St to the bay; Ferry Green; a 3rd St shop row (market, cleaners, 3 boutiques, bakery, 3 shops, pub, realtor, coffee) meeting the hospital's bistro. |
| strip `n_fn_strip` (u 375..400, v -1385.7..-1214.3 and -1185.7..-1009.2) | CROWN HILL GREENWAY: no street opening, but the house blocks' four rear alleys end on its west line, so: one path down the middle, entry plazas at the three streets, a pocket car park on each alley's own line (10 stalls each), two community gardens, lawns. |
| pocket (u 353..393, v -740..-700) | NOT BUILT: it is not empty. It is n_apt_b1_be's tennis courts (a `Parks/park_tennis_courts` prefab whose ground is not a "ground" mesh, so the ground dump shows a hole). Checked in the saved piece. |

## Files
Pieces `tools/city/pilot/pieces/n_fn_{west,mid,east,strip}.gd` -> `pieces/n_fn_*.scn`; site `n_fn_site.gd`; land tables
`n_fn_land.gd` (north end), `n_fn_sland.gd` (strip); tree lists `zoning/trees/fn_{west,mid,east,strip}.json` ->
`pieces/t_fn_*.scn`; rooms `tools/city/rooms/assign_fn.py` -> `interiors/assignment_fn.json`, `rooms_fn_report.json`,
`interiors/rooms/g_fn_*.scn` (19). Area layout: `OUT/fill/fn/area.json` (my 8 pieces with "from": "grow_fn" / "trees"
+ 100 neighbouring rows). Scratch: `OUT/fill/fn/` (measuring scripts, `sc_run.py`: runs sc.py with the area layout,
because this branch's `sc_lib.py` has no SC_LAYOUT switch; it changes no tool).

## Land
Ground = land + 5 cm, eased onto each walk within 12 m (side after side, corners agree), never under land + 2 cm;
graded up to the pads at 6 %, the grading eased back onto the plain ground within 4 m of each edge. Every building on a
level pad at the highest ground under it; the condo and civic doors 0.3 m up get closed steps. Strip: a sheet from the
house side's (smoothed) height to the shop side's, a 1 m edge strip at each neighbour's own measured heights with
retaining faces.

## Superchecker (Yasin via the coordinator: "be MUCH more prone to delete")
Every prop with a finding deleted at the source (`const SC` per piece, `hs_fill_lib.sc_apply`): 67 props (25 benches,
13 picnic tables, 11 bins / carts in the open, 2 hose reels, 2 kettles, a shade sail, and ALL play equipment: 3 play
structures, 3 swings, 2 slides, so the three playgrounds are gone; their sand was turned back to lawn). 117 column
collision boxes from the checker. Every oil mark and lane-wear stripe taken out of the scripts (oil was found on a
drive's centre line). Rooms: 35 items with a finding taken out one by one (`room_drop_prop.gd`; 22 shelves / kitchen
lines in front of back doors, 11 tall things behind windows, 1 plant in a queue, 1 extra card spinner, 1 waiting bench
with no leg room). Re-check: outdoors only report-only kinds left (wide_batch, empty_area; the strip's edge_step).

## Checks (area layout OUT/fill/fn/area.json, real renderer)
| Check | Result on my pieces | Cannot see |
|---|---|---|
| `validate.gd` | 0 (30 lines, all in other pieces) | heights, land, whether a prop makes sense |
| `check_life.gd` | 0 (51 lines, all in other pieces) | as in the skill |
| `audit_trees.gd` | 68 trees in the area, 0 in hard ground | - |
| `check_rooms.gd --only=g_fn_` | 0 problems, 19 rooms | whether a shop has what it needs |
| land over my ground (`OUT/py/buried.py`, 1 m) | 0 cells (blocks: closest 1.9 cm over; strip 0) | faces, looks |
| seams (`OUT/py/seams.py`, 0.25 m) | every street / neighbour edge under 2 cm, EXCEPT: Amber's east walk 26 m at up to 2.3 cm (block 2, v -1530 .. -1500, the 2 cm floor over the land); the strip's ends at the v -1200 arterial (0.39 m over 1 m) and the v -1000 street (7.7 cm over 1 m): there the house block's own edge stands that much above the street walk and my 1 m edge strip carries the house side's height to the walk | faces, looks |
| grades (`OUT/py/grade.py`, blocks) | median 1.2 %, 99 % under 7.3 %, 0.8 % over 8 % (pad faces, steps, terrace faces) | - |
| `sc.py trees` | 4 lists ok (21 trees), after thinning to the in-view limit (the 1st St street trees already stand at 10 of 12) | - |
| exact colliders (`colexact_verify.gd`) | 8 pieces, largest gap 0.1 mm; sprinklers and iceplant without (by design) | - |
Ground triangles: west 31.5k, mid 37.3k, east 31.1k, strip 35.7k (all under 40k).

## Not done / for the coordinator
- Nothing committed, locked, installed or put in the shared layout (rows: the 8 in `OUT/fill/fn/area.json` with "grow_fn" / "trees").
- No pictures taken; nobody has looked at it. Props that sit oddly can only be found by eye.
- No rooms behind: the inn's office door (its contract opens the whole 324 m2 ground floor: "sparse"; needs an office-bay contract), the three beach condos' lobby doors (superchecker no_room).
- The playgrounds the plan wanted were all deleted by the superchecker pass (no_reason); the parks are lawns and walks now.
- The strip's pocket car parks meet the alleys over the 1 m edge strip, which is drawn as grass (not asphalt).
- Rooms were not run through `rooms_and_trees.sh` / `install-room`: those install and lock, which is the coordinator's.
- `sc_lib.py` on this branch ignores SC_LAYOUT (scratch wrapper used); another builder's tree list was mid-write once (one transient JSON error, re-run fine).
