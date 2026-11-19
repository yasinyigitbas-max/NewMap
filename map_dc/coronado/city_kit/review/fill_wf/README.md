# Waterfront fill, block 1 (branch claude/fill-waterfront, 19 Nov 2026) - DRAFT, not locked, waiting for Yasin

Yasin 19 Nov: "two blocks next to water front will be waterfront area, not residental"; on the proposal
(`proposal_plan.png`): "hotel is good, there arent any landmarks there", "CONSIDER THE ELEVATION". Relayed by the
session that started this one: "use the indoor generator in the pilot and do them both together" (rooms built with the
block; that message came from another session, not typed here by Yasin).

## What block 1 is (grid u 259-561, v 209-331; three pieces, one script each)
Measured outline (from the neighbours' own ground meshes, `tools/city/pilot/zoning/wf_fill_ground.py`): between Pier St
(the street from town down to the pier, walk 6.15 -> 1.50 m), B Ave (6.15 -> 4.15), the ring (4.15 -> 1.50) and the
locked sample quadrant f_nw (flat 1.50), plus the strip south of f_nw down to the ring's corner. 26,577 m2.

| Piece | Grid u | What stands there and why |
|---|---|---|
| `n_wf_b1w` | 259-331 | Pier St's quiet top: Casa del Mar inn on the B Ave corner (garden over the lot), Harbour Bakery & Coffee, Bay Bikes (rental bikes in racks), the Shoreline Grill with a raised dining deck; the visitor lot's upper level (in from the two driveway openings the streets already have); two blocks of holiday flats on the Beach Walk; five cottages on the ring |
| `n_wf_b1m` | 331-404 | the busy middle: Scoops ice cream / Sandbar swimwear / Seashell gifts, the Pier Steps (a public ramp from Pier St down to the lot and the Beach Walk), the Tide Bar with its deck, Deep Blue Dive / Sun & Sand sandals / Board Room surf rentals; the lot's ramps and middle level; three flat blocks; holiday flats and four cottages on the ring |
| `n_wf_b1e` | 404-561 | the bottom of Pier St, 50 m from the pier plaza: the Fish House (deck) with Pier Poke & Tacos, Pier Bait & Tackle, Salt Water Surf, the Bay Paddle kayak hire kiosk; the lot's lowest level with steps down to the beach side; a playground with picnic tables for beach families; three cottages; BEACH LANE (palms, verges, benches, bike racks, a shower, a fountain, the beach rules sign) to the corner across from the beach |

## The ground (land first)
Level pads at each building's front walk height, a retaining face on every step (generated where two cells differ),
steps (risers <= 17 cm) and ramps (walk <= 8.3 %, lot aisles 8.1 %) between them; a 2 m band along every street
follows the measured walk exactly; seams between my three pieces follow the same base field.
Pier St front: 6.15 / 6.02 / 5.86 / drive 5.73 -> 4.90 / 5.47 | 4.67 / Pier Steps 4.30 -> 3.60 / 3.88 / 3.17 |
2.25 / 1.67 / 1.54 / 1.50. Lot 4.90 / 3.60 / 2.30. Flats 4.60 / 3.45 / 2.25. Beach Walk 4.41 -> 1.50.
Cottages 4.15 ... 1.55 (each at its ring walk height). Railings (iron, at the pad) or privet hedges on every drop
over about 0.6 m; every railing ends at a wall or the next railing.

## Numbers (what each check sees and does NOT see)
| Check | Result | Sees / does not see |
|---|---|---|
| `ground_check.py` against the TRIAL land (`lower_land_to_pieces.py <dump> --fit --ease-from=<current grid> --out=<scratch>`, never `--write`) | grow_wf: buried 0, hanging 0, steps > 20 cm 0, under another piece 0 | piece ground vs land and vs neighbours; not props, not buildings |
| same against TODAY's land | 3,138 m2 under it (1,080 m2 > 30 cm, n_wf_b1w 947 m2, deepest 1.08 m) | the lot is cut into the slope: true until the land fit runs at integration (750 land nodes, usual -0.14 m, largest -1.21 m; 6 spots where the lowered land meets untouched land with a step over 1 m, all beside a piece) |
| my seam measure (`OUT` scratch tool: every 0.5 m of every edge, my ground 5 cm in vs the neighbour 5 cm out) | 0 m over 2 cm on 1,302 m of edge; largest 1.7 cm (Pier St) | heights at the edge only |
| props vs their own ground (scratch tool, ray down under every ground prop's origin) | 648 props, 0 more than 5 cm off | fences left out on purpose (they stand at the lowest ground of their run, 0.1-0.46 m under the higher side) |
| `validate.gd` (area layout) | 0 for n_wf_*; 6 in the neighbouring residential pieces (mailbox x house numbers, not mine) | overlaps, doors, lanes; not heights, not sense |
| `check_life.gd` | 0 for n_wf_*; 95 in the locked sample and neighbours (poles on asphalt, wall items on windows: not mine, not touched) | poles, paths, wall items over openings, fence ends |
| `audit_trees.gd` | 0 of 612 trees in hard ground | - |
| `sink_check.gd` | 0 | STREET pieces only: says nothing about these blocks |
| `check_rooms.gd -- --only=g_wfa_` | 0 problems, 16 rooms | whether the shop has what that shop needs (by eye, pictures `rooms/`) |
| lock test | RESULT PASS (496 locked pieces, 103 plan files) | that locked files did not change |

Draws (cloud preview, raw pieces, NOT the runtime bake, NOT the phone; whole neighbourhood loaded, preview cars off):
views 309-535 draws in all, of which my three pieces add 50-125 at eye height (Pier St +110, ring +100, lot +124,
steep edge +51, Beach Lane +15) and 263 in the straight-down view (near tier of everything). Triangles: my pieces add
80-190k a view. Ground: 19.7k / 18.3k / 11.7k triangles (every painted stall line cuts the whole floor: costly).
Props 723 / 621 / 510; buildings 12 / 11 / 9; stalls 64 / 58 / 40.

## Walk-in places (16 rooms, `interiors/assignment_wf.json`, rooms `interiors/rooms/g_wfa_*.scn`)
Casa del Mar Inn (reception), Harbour Bakery & Coffee, Bay Bikes, Shoreline Grill, Scoops Ice Cream, Sandbar
Swimwear, Seashell Gifts, The Tide Bar, Deep Blue Dive, Sun & Sand Sandals, Board Room Surf Rentals, The Fish House,
Pier Poke & Tacos, Pier Bait & Tackle, Salt Water Surf, Bay Paddle (kiosk). Built by `tools/city/rooms/room_gen_wf.gd`
(a copy of the pilot's room_gen.gd: four waterfront kinds, frames 2 a wall and clear of windows, bins against a wall,
every front door of a bay kept clear, a fill pass for small rooms). Room draws not measured (unmerged rooms cost about
37-41 draws each in the earlier measure).

## NOT done / NOT checked
- Block 2 (waits for Yasin's word on block 1).
- Not seen in the game, not baked (`bake_runtime.gd`), not on the phone; draws above are the raw preview.
- The land is NOT changed: the trial land is a scratch file. Integration must run `lower_land_to_pieces.py --fit
  --ease-from` with these pieces (and `integrate.py` must pick up `review/grow_wf_blocks.json`); `x_wall_feet` was not
  rebuilt for them (their edges all meet streets / f_nw flush, so it should need no faces here: not measured).
- No wires piece: the cottages' and shops' power drops are not drawn.
- Wear decals checked by surface rule only (asphalt / paving), not each by eye. Tyre marks: the two drive mouths only.
- The view "down the slope toward the water" does not show the water: block 1 falls only 4.6 m and the sample's
  buildings stand between it and the bay. Block 2 (8.6 m) is the one with the views.
- Rooms: one inside and one street picture each (opened); not from behind the counter; signs on side boards not looked at.
- Pictures: preview renderer (no shadows, NOSHADOW=1), the land is the TRIAL land, only this area is loaded.

## Pictures (all opened)
`b1_top.jpg` (straight down, trial land), `b1_pierst.jpg` (eye height down Pier St), `b1_ring.jpg` (eye height on
the ring's walk past the cottages), `b1_down_to_water.jpg` (from the lot's top level east), `b1_steep_edge.jpg` (the
lot's 1.3 m step: aisle ramps, walled beds, bollards), `b1_beach_lane.jpg`; `rooms/rooms_sheet_*.jpg` (each shop:
street front and inside).
