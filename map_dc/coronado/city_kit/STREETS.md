# Street skeleton (APPROVED and LOCKED 17 Nov, Yasin: "all 3 are okay")

- **Picture:** `zoning/streets_map.png`.
- **Scripts:** `tools/city/pilot/zoning/streets.py` lays out the grid and checks it; `render_streets.py` draws the picture.
- **Basis:** the approved, locked zoning map (`ZONING.md`). These scripts only read it.

## Why a 200 m grid
- The kit's street pieces run 100 m from a junction, and a sample's quadrants reach the same 100 m. Samples therefore tile on a 200 m junction lattice.
- **Coronado's real streets:**
  - Numbered streets are 176 m apart. Nine fit at 200 m: 2nd St is dropped, and every other name keeps its order.
  - The lettered avenues are 85 m apart. Every second or third one is kept.
- **The lattice:**
  - turned 26 deg to Amber's bearing
  - origin: Amber x 10th
  - streets (u): J, G, E, C Ave, Amber, B Ave (250 m east, because the pilot's hill rows reach x 146), Adela Ave (500)
  - streets (v): 1st, 3rd, 4th, 5th, 6th, 7th, 8th, 9th, 10th, 11th St

## Samples on their junctions (each moved 115 m or less from the zoning map)

| Sample | Junction (u, v) | Streets |
|---|---|---|
| Pilot | Amber x 10th (0, 0) | high street |
| City centre | Amber x 7th (0, -600) | |
| Apartments | B Ave x 7th (250, -600) | |
| Civic + stadium | C Ave x 7th (-200, -600) | the stadium closes 8th St between E Ave and Amber |
| Gritty edge | G Ave x 5th (-600, -1000) | |
| Industrial | J Ave x 3rd (-800, -1400) | truck streets to 1st St |
| Strip | Adela x 4th (500, -1200) | on the bridge couplet |
| Waterfront | (570, 200), yaw 90 | its streets are part of the ring; the pier leg points into Glorietta Bay |

## The island ring
A boulevard runs right round the island:
- Alameda Blvd along the base fence
- Ocean Blvd about 75 m behind the top of the beach
- Glorietta Blvd along the golf course and the bay
- 1st St along the bay front

It has straight sides and 45 m rounded corners. Its curves need NEW curved street pieces.

The bridge lands between 3rd and 4th St. The Y split is a hero junction, made by hand.

## Superblocks (no through street)
- the stadium
- the university campus (2 x 2 cells, with its own campus roads)
- the hospital campus (1st-3rd St, east)

## Checks (`python3 streets.py`)
- **Every sample has its junction and its legs.** Each neighbour junction leaves room for the sample's own street pieces.
- **No street runs through a locked sample,** and no junction sits inside one.
- **Size:** 93 junctions (51 crossroads, 41 T, the bridge end) and 33.7 km of street.
- **Grades:** steepest street 8.0 %. That is the pilot's own built rise, which 9th, 10th and 11th St share, because the hill is a ridge.
  - The real ground under the town is eased (Gaussian 500 m) and levelled to each sample's pad.
  - The hills are the approved ones, with their flat margins at the new sample positions.

## Yasin's decisions (17 Nov: "all 3 are okay")
- Crown Hill main roads stay as they are (Amber up to 7 %, 4th St 7.5 %): the postcard drive.
- The diagonals (Palm, Olive) are dropped.
- 2nd St is dropped.

## Locked files
`tools/city/pilot/zoning/streets.py` and `map_dc/coronado/city_kit/zoning/streets_map.png` (locked.json "files").

## Questions that were asked (answered above)
1. **Main roads over Crown Hill:** Amber is 6-7 % and 4th St is 7.5 %.
   - Option A: keep them; it is a postcard drive over the hill.
   - Option B: widen Crown Hill so the main roads stay at 6 % or less. That changes the locked zoning hill, so it needs his word.
2. **The diagonals** (Palm Ave NW, Olive Ave SW) are dropped. They would need odd-angle junction pieces.
3. **2nd St** is dropped, so that nine streets fit at 200 m.

## Junction pieces this grid needs
About 30 combinations, which reduce to these families. Existing junctions: j_apt, j_cc, j_ind, j_strip, j_amber_10th.
- **NEW crossroads:**
  - residential x residential
  - residential x standard
  - high street x residential
  - centre x standard / residential
  - the 3rd/4th one-way couplet crossing residential / standard / industrial / strip (about 14 junctions)
- **NEW T-junctions:**
  - onto the ring: residential 17, standard 6, couplet 4, truck 2, high street, strip
  - inside the grid: standard, residential, centre, high street
- **NEW ring pieces:** straight and curved.
- **Hero junctions:** the bridge Y, and the ferry landing.

## Grading plan (17 Nov, road kit step 2): `tools/city/pilot/zoning/grading.py` -> `zoning/grading.json`
- **Pads:** junction pads are level, so each block's whole rise happens between two pads.
  - Every pad is snapped to a 2 m step, so blocks rise 0, 2, 4, 6 or 8 m.
  - Pads are then nudged until every block is 8 % or less with the kit's smoothstep profile (max grade 1.5 H / 160).
  - Locked samples keep their pads.
- **Result:**
  - steepest block 7.5 %
  - pads sit on average 0.7 m from the planned ground, at most 2.8 m (the Country Club ridge's edge toward Ocean Blvd comes down a little)
- **What 200 m residential blocks need:**

  | Rise | Blocks |
  |---|---|
  | flat | 11 |
  | 2 m | 15 |
  | 4 m | 9 |
  | 6 m | 7 |
  | 8 m | 1 |

  Built:
  - `s_res_up/dn2_a/b`
  - `s_res_up/dn4_a/b`
  - `s_res_up/dn6`
  - (8 m) `s_res_up8/dn8`
- **Still to build:** blocks that are not 200 m long (the 250 m pitch east of Amber, and the stubs to the ring) and the other street families on slopes (standard, couplet, high street, centre, ring) belong to groups 2-5.

## Integration plan (17 Nov): `tools/city/pilot/zoning/integrate.py` -> `city_grid_layout.json`
- **What it assembles:** the whole city in the grid frame (x = u, z = v, y = datum metres).
  - The locked samples move to their skeleton junctions at the grading pads. The waterfront turns 90 deg about its origin. Wires and overlays move with their sample.
  - The road kit rows come from the fleet's `review/*_sites.json` tables.
  - Coverage lists every junction and block not yet served.
- **Before the road kit:** 84 sample rows; 83 junctions and 138 blocks to serve.
- **For the terrain step:** the waterfront's pad must be **1.35 m** (its walk 1.5 m above the game's sea at y 0), not the grading plan's 2 m step. Its land-side ground eases from there.
- **Still to do:** the game placement (Amber's 26 deg bearing, world offset) and the terrain under the pads.
