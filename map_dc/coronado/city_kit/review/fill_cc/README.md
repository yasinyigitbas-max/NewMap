# City-centre fill, block 1 (claude/fill-city-centre, 19 Nov 2026) - DRAFT, NOT SHOWN, NOT LOCKED

Block 1 = the land between 6th St (north), C Ave (west), Amber (east) and 7th St (south), round the locked city-centre
sample (c_nw) and the civic band (v_ne, city hall). Grid frame u = x, v = z. Real outline, measured from the street
pieces' ground vertex by vertex: an L of 20,384 m2, u -190.8..-16, v -790.8..-700, plus the arm u -100..-50 down to the
7th St walk (v -609.2..-609.7).

## Land first
- Land under the block 5.97..6.10 m; every street edge round it (6th, C Ave, Amber, 7th, v_ne, c_nw) 6.15 m: FLAT.
  One pad at walk level 6.15 for all four pieces. No terraces or retaining walls were needed here.
- Ground built and checked BEFORE any building or prop (CCF_STAGE=ground), and again after every rebuild:
  - `ground_check.py` (whole city + these 4 pieces): grow_cc 0 m2 buried, 0 hanging, 0 steps > 20 cm, 0 under another piece.
  - my own 25 cm seam test: 0 empty cells beside the block (the 6th St and 7th St walk edges are not straight - the
    ground follows them vertex by vertex), 0 overlap with any neighbour, worst step against every neighbour 0.0 cm.
  - `lower_land_to_pieces.py --fit --ease-from=<today's grid> --out=<scratch>` (DRY, never --write): with today's land
    24 half-metre cells have the land 4-5 cm under the ground instead of 5 (tree-well soil 1 cm under the land);
    the trial lowers 35 land nodes by up to 6 cm and then nothing of block 1 lies under the land. THE LAND WAS NOT
    WRITTEN: that is for whoever owns the land (terrain_grid.npz is shared).

## What was built (one script per piece, reasons in each header; library copy `pieces/cc_fill_lib.gd`)
| Piece | Area | What |
|---|---|---|
| `n_cc_b1_am` | u -50..-16 | Amber street wall north of c_nw: the 59 m GLASS TOWER on the Amber x 6th corner (key corner; Yasin: "add one very tall building to every block you make, alternative in between them" - blocks alternate the 59 m glass tower and the 50 m condo tower), a 4 m paved pocket in front of Amber's bus shelter, a 4-storey brick bank, a brick row (deli, tailor, phone repair), a brick shop-and-flat with fire escapes (barber), a corner cafe; alley A (c_nw's alley carried on to the 6th St apron that already exists at u -50..-44); the service yard behind (bins, meters, plant, a transformer, a tagged block wall to 6th St) |
| `n_cc_b1_n` | u -140..-50, v -790.8..-740 | 6th St row of shops with flats over them (corner market, walk-up, brick row: hardware / laundromat / watch repair, stucco block with the diner, pharmacy), a walk-up coffee kiosk on the corner of alley A; the residents' garden court behind (lawn, trees, benches, table, grill, washing line, iron fence and a gate); a back row on alley C (flats, a print and sign shop, a bike repair); alley C east |
| `n_cc_b1_west` | u -190.8..-140 | C Ave x 6th corner flats (stucco corner block with a corner bakery, a walk-up, a garden apartment row) round a garden court with a play corner on bark; the downtown church set back behind its square, its churchyard (old graves in rows) and garden; alley B (the civic block's lane carried on to the 6th St apron at u -146..-140), alley C west from the C Ave apron |
| `n_cc_b1_court` | u -140..-50, v -740..-700 + the arm to 7th St | THE COURTHOUSE (the plan's MUST site) on its square on 7th St; the district's 4-level parking garage entered from alley C; a pedestrian walk behind it to the court green; law offices, bail bonds and legal aid facing the green, the District Attorney's offices closing its south side; the courthouse's walled sally port off a secure lane |

**Courthouse: why this block.** The plan says "on the centre square, next to the police". The police station is in
v_se (u -168, v -578, south of 7th St); city hall is in v_ne (u -120, v -627, north of 7th St). Block 1's arm
(u -100..-50) faces 7th St right beside city hall and diagonally across 7th St from the police: the three civic
buildings and the memorial green make one civic heart. None of the other five blocks is next to the police.

Counts: 26 buildings; outdoor props by piece 82 / 155 / 350 / 171 (758) (each with its reason; refused ones printed,
none silently dropped); 4 parked-car stalls (delivery van, deli owner, two in the sally port).

## Walk-in places (rooms built with the block - Yasin, relayed: "use the indoor generator in the pilot and do them both together")
Copies of the pilot's tools, shared files untouched: `tools/city/rooms/room_gen_cc.gd`, `assign_cc.py`,
`gen_shots_cc.gd`, `interiors/room_contracts_cc.gd`; tables `interiors/assignment_cc.json`, `room_contracts_cc.json`,
`cc_buildings.json`; rooms `interiors/rooms/g_cc_b1_*.scn` (22).
| Piece | Building | Room (kind) |
|---|---|---|
| am | glass tower | Sixth & Amber Tower - lobby (lobby) |
| am | brick corner | Amber Savings Bank (bank) |
| am | brick row | Marlowe's Deli (restaurant), Ferris Tailors (clothes), Fix-It Phone Repair (keys) |
| am | brick fire-escape row | Seventh Wave Barbers (salon) |
| am | brick corner | Court Side Coffee (cafe) |
| n | brick corner | Sixth St Market (corner_shop) |
| n | brick row | Island Hardware (store), Sixth St Laundromat (cleaners), Watch & Jewel Repair (jewelry) |
| n | stucco block | Sixth Street Diner (restaurant) |
| n | brick row | Downtown Pharmacy (pharmacy) |
| n | alley workshop | Alley Sign & Print (print) |
| n | alley workshop | Spokes Bike Repair (bike) |
| west | stucco corner block | C Avenue Bakery (bakery) |
| west | church | Sacred Heart Church (church: pews facing the altar) |
| court | courthouse | Coronado County Courthouse - public hall (court) |
| court | brick row | Hale & Ortiz Attorneys (law) |
| court | brick row | Bayview Bail Bonds (bail) |
| court | brick row | Island Legal Aid (office) |
| court | brick row | District Attorney (law) |
Not walk-in (no room): the coffee kiosk (walk-up window), the garage, every flat.

## Checks on the final state (what each can and cannot see)
| Check | Result | Sees / does NOT see |
|---|---|---|
| `ground_check.py` (whole city + 4 pieces) | grow_cc 0 m2 buried, 0 hanging, 0 steps > 20 cm, 0 under | ground against land and neighbours on a 1 m grid; not buildings or props against their ground; slivers under 1 m (my seam test below covers those) |
| own 25 cm seam test (scratch script) | 0 empty cells beside the block, 0 overlaps, worst step 0.0 cm at all 15 neighbours | top surfaces only |
| `lower_land_to_pieces.py` dry trial | 32 half-metre cells have the land 4-5 cm under (not 5); 43 nodes would drop at most 6 cm; NOT written | the land rule only |
| `validate.gd` (area layout, 114 rows) | 13 problems in the area, 0 in these pieces | overlaps, inside buildings, door space, props on roads; not heights or whether a prop makes sense |
| `check_life.gd` | 9 fence ends "lead nowhere": each ends on a real building wall that the checker measures by nominal footprint (looked at on the top view); 0 other faults | poles, paths, glass, fence ends; with whole-area load |
| `audit_trees.gd` | 1,065 trees, 0 in hard ground | trees only |
| `sink_check.gd` | 0 | STREET pieces only: says nothing about these blocks |
| `check_rooms.gd --only=g_cc_` | 22 rooms, 0 problems | the indoor kinds; NOT whether a shop has all a shop of its kind needs, nor how it reads from the street |
| lock test | RESULT PASS (496 locked pieces, 103 files) | that locked files are unchanged; nothing of mine is locked |
Refused props are printed at every build (bins that would stand in front of back doors, pots on the street's furniture,
a second bike rack under a lamp...); none was dropped silently.

## Pictures (all opened and looked at; preview renderer on the cloud's software GPU, no shadows, parked cars off, only the 114 layout rows round block 1 loaded - the streets end at the edge of what was loaded)
`b1_top.jpg` (straight down, land loaded, 200 m), `b1_amber_eye.jpg`, `b1_6th_eye.jpg` (the two main street frontages at eye height),
`b1_court_square.jpg`, `b1_cave_edge.jpg` (C Ave: the block is flat, there is no steep edge; this is its residential edge),
`b1_alleyA.jpg`, `b1_alleyC_workshops.jpg`, `b1_glass_tower.jpg`, `b1_rooms_1..6.jpg` (every room: street front and inside from the door).
`t1_OLD_office_tower...jpg` is the first version's 32 m tower, replaced by the glass tower; `t2`/`t3` show the hotel and condo towers as they stand in the sample.
Draws per view in this preview: top 501, Amber 611, 6th St 276, square 751, C Ave 391, alley A 431, alley C 639, glass tower 398;
triangles 1.2-1.4 million. THESE ARE NOT GAME NUMBERS: the preview draws every loaded piece's batches and every building tier
unmerged (114 pieces); the game's runtime bake merges them per cell. The bake was not run and the phone was not used, so
whether block 1 keeps a view under ~150 draws is NOT known. Rooms add about 30-60 props each (not in the bake).

## NOT done / NOT checked
- Not shown to Yasin as a block yet; nothing locked; the land not written (the dry trial asks 35-43 nodes lowered <= 6 cm).
- Not run: the runtime bake, the phone, the game's streaming, x_wall_feet (not needed: no edge of block 1 stands over the land).
- Not in the shared layout: `integrate.py` was not run; the rows are in `review/grow_cc_blocks.json`.
- Window ACs left out (no way here to put them IN windows); roof plant only where a roof is flat (refused spots printed).
- By eye, open questions: the glass tower's lobby holds eight seating groups to pass the checker's "bare" rule - a real lobby
  would be emptier; the courthouse hall is benches and a clerk's counter only (no courtroom: the kit has no court furniture);
  the 9 fence ends above were judged from the top view, not from eye height one by one.
- Roofs of the stucco block and the apartment row are pitched: no plant there.

## Kit used here that the census lists as unused
`urban/urb_courthouse` (first use anywhere), `prop_headstone_*` again (churchyard), `prop_switch_rack`, `prop_play_structure`
in a flats' court; `ext_parking_garage` a second time. Courthouse: no court furniture exists in the kit (no bench / dock / bar).

---

# Block 2 (claude/fill-city-centre, 19 Nov 2026) - DRAFT, NOT SHOWN, NOT LOCKED

Block 2 = 6th St (north), Amber (west), B Ave (east), 7th St (south), round the locked c_ne sample and the apartment
sample a_nw. Real outline measured from the street pieces vertex by vertex, u 16..240.8, v -790.8..-609.2.

## Land first
- Land 5.95..6.11 m; every street edge and neighbour round it 6.15 m: FLAT, one pad at 6.15 for all five pieces.
- Ground checked before any building or prop and again on the final state: ground_check grow_cc 0 buried / 0 hanging /
  0 steps / 0 under; my 25 cm seam test 0 overlap, worst step 0.0 cm against all 16 neighbours; 3 single empty 25 cm
  cells are at block 3's curved edges, not block 2. Dry land trial (never --write): 289 land nodes lowered by up to
  6 cm, then 0 cells under. THE LAND WAS NOT WRITTEN.

## What was built
| Piece | Area | What |
|---|---|---|
| `n_cc_b2_am` | u 16..50 | Amber x 6th corner: the 50 m CONDO TOWER (blocks alternate glass 59 m / condo 50 m), a brick row (ice cream, jeweller, gallery), a wine bar block, a shoe shop with fire escapes; the condo's garden; alley A2 |
| `n_cc_b2_n` | 6th St east of c_ne | eight shop-and-flat buildings on 6th (corner cafe, Thai restaurant, books / souvenirs / keys, clothes / salon / store, corner store, dentist, corner bar); a residents' play garden behind; back rows on alley C2 (upholstery) |
| `n_cc_b2_e` | u 190..240.8 | the 6th x B Ave corner restaurant block and a beach condo with an ice cream window; walk-ups and Spanish garden flats along B Ave round two fenced gardens; alley B2 (a_nw's lane carried to 6th) |
| `n_cc_b2_s` | alley C2 south side | the block's 4-level GARAGE on alley C2 (no lots: the cars go in it), a garage walk to 7th St, architects' office, flats, two lawn courts and a residents' yard |
| `n_cc_b2_7th` | 7th St north side | the DEPARTMENT STORE facing 7th, an insurance office, a burger block, a brick row (sports, souvenirs, gallery); alley D2 with a tailor-cleaner, a pawn shop, a locksmith, workshops and flats |

Fix on the last pass: the corner restaurant's two dumpsters stood inside the residents' garden by its new fence; now
one dumpster at the restaurant's back corner on the alley B2 pocket.

## Walk-in places: 29 rooms `g_cc_b2_*` (list in `interiors/assignment_cc.json`; sheets `b2_rooms_1..5.jpg`, one
inside and one street picture per shop). The condo's ice cream window got a bakery-kind room (counter, cases) - close,
not exact.

## Checks on the final state (what each can and cannot see)
- validate.gd on the block-2 area layout: 0 lines name n_cc (13 problems in the loaded area are other pieces'). Sees
  props in buildings, before doors, on each other; cannot see whether a prop makes sense.
- check_life: only "fence end leads nowhere" for my fences; each ends on a real wall - the check uses nominal
  footprints, so it cannot see the real wall the fence meets.
- audit_trees: 0 trees in hard ground (sees the ground under the trunk only).
- sink_check: 0 props off the ground (street pieces only - it does not look inside fill pieces).
- check_rooms --only=g_cc_: 0 problems in 51 rooms (cannot judge style).
- lock test: RESULT PASS (496 locked pieces untouched).

## Pictures (opened and looked at; preview on the cloud's software GPU, no shadows, unbaked)
`b2_top.jpg` (draws 703, 1.54 M triangles), `b2_amber_condo.jpg` (517), `b2_6th_eye.jpg` (546), `b2_bave_eye.jpg`
(621), `b2_7th_eye.jpg` (480), `b2_play_garden.jpg` (594), `b2_alleyD2_walk.jpg` (793). Draw counts are the preview's
unbaked numbers with ~120 layout rows loaded; the bake (target ~150) and the phone were not run.

## NOT done / NOT checked
No bake, no phone run, no lock, land not written. Flat block, so no steepest-edge picture (no edge steeper than 0 cm).
