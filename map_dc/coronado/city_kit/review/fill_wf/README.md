# Waterfront fill, blocks 1 and 2 (branch claude/fill-waterfront, 19 Nov 2026) - LOCKED on Yasin's word ("just lock them if you are done with placements"): the six pieces n_wf_b1w/m/e, n_wf_b2w/m/e and the 35 rooms g_wfa_*; lock test RESULT PASS (502 pieces, 138 files)

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


---------------------------------------------------------------------------------------------------------------------

# Block 2 (Yasin: "start it"; the inn is the LOW inn, "i meant the low inn")

Measured outline: u 259-470 between the residential street (walk 10.15 -> 4.15), B Ave (10.15 -> 6.15) and Pier St
(6.15 -> 1.50), plus the corner north of the locked quadrant f_ne (flat 1.50) out to the ring's curve (4.15 -> 1.50).
48,244 m2. The land: a shelf 8-10 m in the west, a steep bank (8 -> 2 m between u 305 and 405), flat at the foot.

| Piece | Grid u | What stands there and why |
|---|---|---|
| `n_wf_b2w` | 259-335 | the top shelf: the Bayview Inn (low, two storeys, 16 rooms, office at its east end) and its guests' parking (in from the street's driveway opening at u 304-310); its garden lawn a level down with chairs turned to the bay; Vista Park below it (level with B Ave at its gate) where THE STEPS start; Pier St: the Salty Dog pub, Shores Holiday Rentals, Sea Breeze Juice, the Blue Pelican bistro, the park's stairs, Cove Deli and Cove Wine & Cheese; the first column of holiday flats |
| `n_wf_b2m` | 335-400 | the bank: two more columns of holiday flats on terraces, each with its sea-view deck, stairs between the levels, the Steps down the whole bank with a landing and a bench on every terrace; Pier St: the Pier Street Arcade (Surfside Cafe, Tidewater Swim & Sandals, Harbour Light Gifts & Prints), Tide Pool Books, the Sunset Arcade (candy and fudge, beach outfitters, sunglasses, espresso) |
| `n_wf_b2e` | 400-605 | the foot, where the town works the boats: two townhouse rows with garages on a yard off the street (driveway u 440-446), the public lot at the bottom of the Steps, Glorietta Marine Supply (chandlery and boat storage) and its yard (driveway u 554-560), the boatyard below it with boats on trailers and the Harbour Boatworks repair shed (next to the sample's boat storage yard); Pier St: Bay Boat & Bike Hire, the Harbour Tours kiosk, a pocket plaza |

## The ground (Yasin: "CONSIDER THE ELEVATION")
Top shelf: inn + parking 9.60, garden 8.60, Vista Park 7.00 (B Ave gate at walk level). The bank, three columns
stepping down twice each north to south: C (u 318-352) 8.40 / 6.80 / 5.80, D (352-386) 7.00 / 5.20 / 4.20,
E (386-412) 5.80 / 3.80 / 3.00. Foot yard 4.00, lot 2.00; marine supply yard 3.90, boatyard 2.00. Pier St pads
6.15 ... 1.56 stepping with the street. Walls up to 2.0 m (E1 -> E2, the foot yard -> the lot), every one with an
iron guard railing on its high side; railings along both streets on the walk's side where the land drops away.
The Steps: B Ave 7.9 -> park 7.0 (ramp 7.6 %), then flights of 2 / 10 / 9 / 11 risers (<= 17 cm) down to the lot.
Drives: 10 % (foot yard -> lot), 10.6 % (marine yard -> boatyard), under the 12 % limit.

## Numbers (block 2; what each check sees as in the table above)
- ground_check vs the TRIAL land (lower_land_to_pieces --fit --ease-from, --out scratch): grow_wf (both blocks)
  buried 0, hanging 0, steps over 20 cm 0, under another piece 0. Against TODAY's land block 2 lies under it on
  7,382 m2 (n_wf_b2w 4,523, b2e 1,747, b2m 1,112; deepest 1.42 m): the terraces are cut into the hill until the land
  fit runs. The trial land changes 2,333 nodes for both blocks (usual -0.24 m, largest -1.64 m); 90 spots where the
  lowered land meets untouched land with a step over 1 m, all beside a piece (none beside empty land).
- seams (every 0.5 m of every edge): 0 m over 2 cm; largest 1.8 cm (Pier St).
- props vs their own ground: 417 ground props in block 2, 0 off by more than 5 cm (fences and railings left out:
  they stand at the lowest ground or on the high side on purpose).
- validate.gd 0 / check_life 0 / audit_trees 0 for all six n_wf pieces (6 and 95 in the neighbours and the locked
  sample, not mine); sink_check 0 (street pieces only).
- check_rooms.gd -- --only=g_wfa_: 0 problems in 35 rooms (16 block 1 + 19 block 2).
- Ground triangles 14.6k / 9.5k / 23.1k (the public lot's stall lines again); props 848 / 720 / 877;
  buildings 9 / 10 / 6; stalls 35 / 0 / 151.
- Draws (raw cloud preview, not the bake, not the phone, preview cars off, measured before the street railings went in): views 280-516 draws in all, of which block 2 adds 40-175 at eye height (Pier St +174, north street +83, down to the water +92, steep edge +40, the Steps +68) and 231 straight down.

## Walk-in places, block 2 (19 rooms g_wfa_b2*)
Bayview Inn (office), The Salty Dog, Shores Holiday Rentals, Sea Breeze Juice, Blue Pelican Bistro, Cove Deli, Cove
Wine & Cheese, Surfside Cafe, Tidewater Swim & Sandals, Harbour Light Gifts & Prints, Tide Pool Books, Sunset Candy &
Fudge, Beach Outfitters, Shades & Sunglasses, Sunset Espresso, Bay Boat & Bike Hire, Harbour Tours (kiosk), Glorietta
Marine Supply, Harbour Boatworks (service desk). Four room kinds added to room_gen_wf.gd for them (boat repairs,
wine shop, and fill passes for the small office and bookshop).

## NOT done / NOT checked (block 2)
- FIXED in the polish pass (unlocked, rebuilt, relocked on Yasin's word): the stairs inside the terraces (block 1: the flats' steps to the Beach Walk; block 2: the inn garden stairs, the stairs between the flats' terraces, the street gates) have GRASS treads with concrete risers: their concrete paint comes after the terrace's grass paint and the first paint wins. The Steps' flights are on paving and are right. Fix = put those stair paints first in the scripts and rebuild: needs Yasin's word (locked).
- b2_down_to_water, b2_steps and b2_boatyard were shot before the street railings replaced the walls (nothing in those views changed).
- The outdoor pictures show the kit's old painted names on some buildings (e.g. "THE ANCHOR BAR" on the Salty
  Dog): the new signs live in the room scenes, which the outdoor preview does not load (the room pictures show them).
- The kit's stucco / brick / CMU walls render near black on north faces in this preview, so the street boundaries
  are iron railings, not garden walls (a choice for the picture as much as for the place; say if walls are wanted).
- All boats in the boatyard are the kit's one trailer model (the same green skiff).
- Same as block 1: not baked, not on the phone, land not written, no wires piece, rooms seen from the door only.

## Pictures (all opened)
`b2_top.jpg`, `b2_pierst.jpg` (Pier St, eye height), `b2_north_street.jpg` (the residential street, eye height),
`b2_down_to_water.jpg` (from Vista Park over the terraces to the bay), `b2_steep_edge.jpg` (the D1 -> D2 1.8 m wall
and its stairs), `b2_steps.jpg` (down the Steps from the C2 landing), `b2_boatyard.jpg`; `rooms/b2_rooms_sheet_*.jpg`.


---------------------------------------------------------------------------------------------------------------------

# Polish pass (Yasin 19 Nov: "run a polish pass in all your quarters, both indoors and outdoors, fill in the empty
# stores a bit", "plenty of props", "and life", "most shops look like copy pasted lines of props in interiors, have
# variety"; no pictures this time - NONE TAKEN, nothing below was looked at, only measured)
- Unlocked the six pieces and 35 rooms on his word, rebuilt, re-checked, relocked (lock test RESULT PASS).
- Outdoors: each piece got a polish(b) list of hand-chosen spots with their reasons (forecourt plants, papers and bins,
  gas bottles and hose carts behind the kitchens, drains and turning arcs in the lots, planting in the strips and on
  the verges, deck chairs / umbrellas / coolers / showers in the gardens and on the flats' decks, more benches on the
  Beach Walk, Vista Park and the Steps, the boatyard's work clutter, sand drift). A guard (wf_fill_lib.try_add) refuses
  a spot that is taken and counts it: placed 204, refused 112. Props now 754 / 657 / 540 / 892 / 761 / 916.
- Stairs inside the terraces: concrete treads now (the paint order fault).
- Indoors: room_gen_wf.gd gives each room its own draw (seeded by its name): wall goods start at a different point and
  take extra kinds of goods, runs of one thing break after 2-3 with a plant / mannequin / display, the middle of the
  floor is dressed from a per-kind mix (some pieces turned, some gaps), cafes and restaurants mix two- and four-tops,
  thin shops get more wall goods. 35 rooms regenerated.
- Checks after: validate.gd 0 / check_life 0 / audit_trees 0 (637 trees) for the n_wf pieces (6 and 95 in others),
  sink_check 0 (street pieces only), props vs own ground 1,301 measured / 0 off, seams 0 m over 2 cm, ground_check vs
  the trial land 0 buried / 0 hanging / 0 steps, check_rooms 0 problems in 35 rooms, lock test RESULT PASS.
- NOT checked: how it looks (no pictures), draws after the added props, the rooms from behind the counter.
