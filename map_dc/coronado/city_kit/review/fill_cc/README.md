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
| `n_cc_b1_am` | u -50..-16 | Amber street wall north of c_nw: 32 m office tower on the Amber x 6th corner (key corner), a 4-storey brick bank, a brick row (deli, tailor, phone repair), two 3-storey brick shop-and-flat buildings (barber, books), a corner cafe; alley A (c_nw's alley carried on to the 6th St apron that already exists at u -50..-44); the service yard behind (bins, meters, plant, a transformer, a tagged block wall to 6th St) |
| `n_cc_b1_n` | u -140..-50, v -790.8..-740 | 6th St row of shops with flats over them (corner market, walk-up, brick row: hardware / laundromat / watch repair, stucco block with the diner, pharmacy), a walk-up coffee kiosk on the corner of alley A; the residents' garden court behind (lawn, trees, benches, table, grill, washing line, iron fence and a gate); a back row on alley C (flats, a print and sign shop, a bike repair); alley C east |
| `n_cc_b1_west` | u -190.8..-140 | C Ave x 6th corner flats (stucco corner block with a corner bakery, a walk-up, a garden apartment row) round a garden court with a play corner on bark; the downtown church set back behind its square, its churchyard (old graves in rows) and garden; alley B (the civic block's lane carried on to the 6th St apron at u -146..-140), alley C west from the C Ave apron |
| `n_cc_b1_court` | u -140..-50, v -740..-700 + the arm to 7th St | THE COURTHOUSE (the plan's MUST site) on its square on 7th St; the district's 4-level parking garage entered from alley C; a pedestrian walk behind it to the court green; law offices, bail bonds and legal aid facing the green; the courthouse's walled sally port off a secure lane |

**Courthouse: why this block.** The plan says "on the centre square, next to the police". The police station is in
v_se (u -168, v -578, south of 7th St); city hall is in v_ne (u -120, v -627, north of 7th St). Block 1's arm
(u -100..-50) faces 7th St right beside city hall and diagonally across 7th St from the police: the three civic
buildings and the memorial green make one civic heart. None of the other five blocks is next to the police.

Counts: 26 buildings; outdoor props by piece about 96 / 155 / 350 / 156 (each with its reason; refused ones printed,
none silently dropped); 4 parked-car stalls (delivery van, deli owner, two in the sally port).

## Walk-in places (rooms built with the block - Yasin, relayed: "use the indoor generator in the pilot and do them both together")
Copies of the pilot's tools, shared files untouched: `tools/city/rooms/room_gen_cc.gd`, `assign_cc.py`,
`gen_shots_cc.gd`, `interiors/room_contracts_cc.gd`; tables `interiors/assignment_cc.json`, `room_contracts_cc.json`,
`cc_buildings.json`; rooms `interiors/rooms/g_cc_b1_*.scn` (22).
| Piece | Building | Room (kind) |
|---|---|---|
| am | office tower | Sixth & Amber Building - lobby (lobby) |
| am | brick corner | Amber Savings Bank (bank) |
| am | brick row | Marlowe's Deli (restaurant), Ferris Tailors (clothes), Fix-It Phone Repair (keys) |
| am | brick fire-escape row | Seventh Wave Barbers (salon) |
| am | brick row | Amber Books (books) |
| am | brick corner | Court Side Coffee (cafe) |
| n | brick corner | Sixth St Market (corner_shop) |
| n | brick row | Island Hardware (store), Sixth St Laundromat (cleaners), Watch & Jewel Repair (jewelry) |
| n | stucco block | Sixth Street Diner (restaurant) |
| n | brick row | Downtown Pharmacy (pharmacy) |
| n | alley workshop | Alley Sign & Print (keys) |
| n | alley workshop | Spokes Bike Repair (sport) |
| west | stucco corner block | C Avenue Bakery (bakery) |
| west | church | Sacred Heart Church (church: pews facing the altar) |
| court | courthouse | Coronado County Courthouse - public hall (court) |
| court | brick row | Hale & Ortiz Attorneys (law) |
| court | brick row | Bayview Bail Bonds (bail) |
| court | brick row | Island Legal Aid (office) |
Not walk-in (no room): the coffee kiosk (walk-up window), the garage, every flat.

## Checks (what each can and cannot see)
FILLED IN BELOW FROM THE FINAL ROUND.
