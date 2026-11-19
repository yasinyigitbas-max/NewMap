# High street fill (branch `claude/fill-high-street`) - block 1

Status 19 Nov: block 1 seen by Yasin ("its fine roll out to the entire zone"); **block 2 built**, nothing locked. Blocks 3-6 follow in this order: 3, 4, then the steep 5 and 6.

## Block 1: west of Amber, 10th to 11th St (around the pilot's pocket-park block `b_sw`)
Its real outline, measured from the street pieces' ground (scratch dump, 0.25 m raster): an L round `b_sw` -
u -100 .. -16, v 9.2 .. 190.8, less `b_sw` and its alley (u -50 .. -16, v 9.7 .. 97.5). Neighbours: Amber (walk 4.15),
10th St (4.15), 11th St (falls 4.15 -> 3.19 to the west), the residential growth quadrants on the west (their edge
4.15 -> 3.18, with their own retaining faces), `b_sw` (4.15). The two rear alleys of the residential quadrants
(v 54-60 and 140-146) dead-ended on this edge: both are carried through to the pilot's service alley.

Three pieces, each its own script (layout row [0, 4.0, 0], yaw 0, the pilot's frame; table `review/grow_hs_blocks.json`):
| piece | what and why |
|---|---|
| `n_hs_b1_amber` | Amber from the hotel to 11th: a 3-storey brick row (shops + flats), a paseo from the garage to Amber, **the town library** (landmark) set back 6 m behind a plaza with two jacarandas in wells, benches, bike rack, fountain; an Orange-style shop row, a coffee house, a 4-storey brick corner on 11th. Behind: rear lot with stalls off the alley, the library's staff / service strip, the corner yard (one aisle, two stall rows, loading door kept clear), block wall + coral trees to 11th. |
| `n_hs_b1_tenth` | "Tenth Street Court": a 3-storey market building on the alley corner, a Spanish-revival apartment house behind front gardens, a shared court (kids' corner on bark, table under its sail, barbecue, washing line, two trees, lamps) closed by a second row of garden apartments; the residents' alley carried through; a 40-stall residents' car park (open to both alleys) and a community garden on the bank, picket fence with one gate. |
| `n_hs_b1_eleventh` | The town's **parking garage** (entrance on the service alley, people walk out by the paseo), screened from the houses by a bank of eucalyptus, privet and a lot-line fence; the second alley carried through; two apartment houses on 11th St on their own level terraces, parking off the alley behind, gardens. |

Helpers: `n_hs_b1_site.gd` (this block's shared heights only: one line of heights where the three pieces meet; places
nothing), `hs_fill_lib.gd` (drawing helpers: grid-snapped ground, faces, skirts, fences that end exactly at their ends
with a post at every joint, hedges). Every building and prop is its own line in its piece script with its reason.
Pilot libraries used unchanged: `kit_lib`, `site` (walk height, tree wells), `wear_lib` (oil, cracks, lane wear).

## Land first (how the ground was made, and checked before any building)
- Everything level at the high street height 4.15 (as the pilot); the west part comes down to the residential edge over
  a 17 m smooth bank (<= 8 %); the court's west edge in 2 m (<= 11 cm); the cross alley falls 1.7 %; the 11th St
  houses on terraces at the walk height of their middle (3.41 / 3.83 m) with retaining faces at the front (steps on
  the paths), between the lots and along the alley parking. A 0.5-1 m band follows each neighbour exactly at every
  edge; the faces stand inside the piece. A skirt under every outer edge.
- Checked on ground only, then again on the finished pieces (same numbers):
  - `ground_check.py` with the land as it is now: block 1 ground under the land 366 m2, all 5-30 cm (none over 30 cm),
    floating 0. With the DRY trial land (`lower_land_to_pieces.py --fit --ease-from=<current grid> --out=<scratch>`,
    NOT written): under the land 0, floating 0; it would lower 120 land nodes (usual 0.09 m, largest 0.28 m), raise
    none near the block. **The shared land was not changed**: until someone runs the land fit, those 366 m2 lie
    up to 30 cm under the land.
  - Seams (my scratch probe: every 0.25 m edge cell of my pieces against the cell across): against Amber, 10th,
    11th, `b_sw` and between my three pieces the largest step is 0.8 cm (0 m over 2 cm).
    Against the residential quadrants: `r_q_m200_0_se` 7 m over 2 cm (up to 11 cm, v 46-54);
    `r_q_m200_200_ne` 65 m over 2 cm, up to 0.50 m. That is their OWN retaining face at their edge: my edge sits on
    the face's top line; where they have no face (v 154-163) my skirt closes it. `ground_check.py` counts these as
    37 m of step.
- What these do NOT see: buildings and props against their own ground (by eye only, in the pictures).

## Checks on the block 1 area (layout = the 39 pieces round the block + mine; real renderer)
| check | result | what it cannot see |
|---|---|---|
| `validate.gd` | 0 on my pieces (6 in the locked residential quadrants, not mine) | heights, land, whether a prop makes sense; doors only from the kit's FRONT doors - I moved bins off the back doors by hand from the contracts |
| `check_life.gd` | 2 on my pieces: the community garden's gate leaf stands open (it reads as a fence end), and the bank's fence ends on the privet hedge | everything else; it measures fence ends against the kits' FOOTPRINTS, so I ran fence ends 0.2-1.1 m into walls |
| `audit_trees.gd` | 316 trees, 0 in hard ground | - |
| `sink_check.gd` | 0 | street pieces only: none of mine |
| `check_rooms.gd --only=g_hs_` | 0 problems, 10 rooms | whether the shop has what that shop needs (by eye, pictures below) |
| lock test | RESULT PASS (496 locked pieces, 103 plan files) | - |

## Walk-in places (built WITH the block, Yasin 19 Nov via the start session: "use the indoor generator in the pilot and do them both together")
`tools/city/rooms/assign_hs.py` -> `interiors/assignment_hs.json`; `tools/city/rooms/room_gen_hs.gd` (a copy of the
pilot's `room_gen.gd`: reads my assignment; caps repeats at the checker's limits; at most 2 frames a wall / 4 a room,
none over a window; a library layout) -> `interiors/rooms/g_hs_*.scn`. No existing room touched.
| room | kind | name |
|---|---|---|
| g_hs_b1_amber_brick_row_0 | pharmacy | Amber Drug |
| g_hs_b1_amber_brick_row_1 | restaurant | Amber Deli |
| g_hs_b1_amber_brick_row_2 | shoes | Sole Coronado |
| g_hs_b1_amber_library_0 | library | Coronado Public Library (painted sign kept) |
| g_hs_b1_amber_orange_row_0 | souvenir | Ferry Landing Gifts |
| g_hs_b1_amber_orange_row_1 | clothes | Tide Threads |
| g_hs_b1_amber_orange_row_2 | jewelry | Coral & Pearl |
| g_hs_b1_amber_cafe_0 | cafe | Library Grounds Coffee |
| g_hs_b1_amber_corner_0 | sport (surf) | South Beach Surf |
| g_hs_b1_tenth_market_0 | corner_shop | Tenth Street Market |
Not walk-in: the parking garage, the six apartment buildings.

## Pictures (preview, NO shadows (lavapipe), cloud GPU; the land is the DRY TRIAL land, not the shared land)
All opened by me. Only the block's area is loaded: roads end at its edge, they have not sunk.
| file | view | preview draws / primitives |
|---|---|---|
| `b1_top.jpg` | straight down, 200 m, land loaded | 852 / 1.98 M (top view: every near model, no culling) |
| `b1_amber_south.jpg` | Amber, eye height, looking south along the new frontage | 167 / 1.56 M |
| `b1_11th_west.jpg` | 11th St, eye height, west from the corner | 417 / 1.85 M |
| `b1_10th_west.jpg` | 10th St, eye height, west past the market | 428 / 1.81 M |
| `b1_steepest_cross_alley.jpg` | the steepest edge: the cross alley falling to the houses, the retaining wall and fence over it, the parking below the gardens | 358 / 1.68 M |
| `b1_library_plaza.jpg` | the library and its plaza from Amber's parking lane | 375 / 1.79 M |
| `b1_court.jpg` | the court through the passage from 10th | 298 / 1.77 M |
| `b1_rooms_1..5.jpg` | each shop: street front + inside from the door | - |
Draw counts here are NOT the game's: the preview draws every prop batch of every loaded piece unmerged, 159 preview
cars (one draw each) and the whole island's land (about 1.1 M of the primitives). The runtime bake was not run, so
the game's draws for this block are NOT measured (target about 150 a view).

## NOT done / NOT checked
- Yasin has not seen it. Nothing locked. Blocks 2-6 not started.
- The shared land is not fitted (366 m2 up to 30 cm under it until the land fit runs; the dry trial says 0).
- Not in `city_grid_layout.json` (integrate.py not run, as instructed); `x_wall_feet` not rebuilt for these pieces.
- No runtime bake, no phone, no game draw count, no `checks.sh` on the whole city (area only).
- No new wires: the pilot's alley poles stop at v 86; the alley extension has no poles (service underground).
- By eye, still to look at closer: Coral & Pearl's cases are the kit's `glass_display_case`, which read like shelves
  of bottles; the coffee house model has a side door facing the corner building's wall (the kit model, 5 cm gap);
  dark boxes on two building walls in the court passage are in the kit models, not props.
- check_life's 2 fence ends (above).

---------------------------------------------------------------------------------------------------------------------

## Block 2: west of Amber, 9th to 10th St (around the pilot's block `b_nw`)
The mirror of block 1, but on the rise: Amber and the residential edge climb 2 m from 10th (4.15) to 9th (6.15);
Amber's steepest stretch is 3.5 % (v -155..-143). Outline: u -100..-16, v -190.8..-9.2, less `b_nw` and its alley.
The houses' two rear alleys (v -60..-54, -146..-140) again dead-ended here: both carried through to the pilot's alley.
Four pieces (`n_hs_b2_site.gd` holds the shared heights):
| piece | what and why |
|---|---|
| `n_hs_b2_amber` | Amber from `b_nw` up to 9th, each building on its own level pad at its door's walk height (a 0.6 m band follows the walk, low retaining plinths behind): a stucco block with **Rosa's Taqueria**, the **Crownado Savings** bank, the block's landmark **St. Anne's church** (red spire) set back behind a level forecourt so the spire closes the view up Amber, the **church walk** from Amber to its hall, an Orange-style pair (ice cream, gallery), a brick row with fire escapes (**hardware**, propane exchange by its door), a brick corner on 9th (**bookshop**). Rear lot off the alley; a staff / delivery yard north of the church walk. |
| `n_hs_b2_park` | **Tenth Street Park**: iron fence with ONE gate on 10th, privacy fence to the gardens next door, a level bark play pad (swings, slide, climbing frame) with benches watching it, two picnic tables each under its own sail with a grill, a plaza with benches and a fountain, beds, five trees, lamps; the residents' alley on through. |
| `n_hs_b2_mews` | **Amber Mews**: six townhouse rows (two kit models alternating) facing a private lane, a garage per unit with a short ramp from the lane, each row on its own level pad at the lane's height (the mews rises 1.2 m north), gardens behind with side fences and gates, bins beside the end garages, lamps, a hydrant, no parking in the lane; the cross alley. |
| `n_hs_b2_ninth` | The church's **community center** on 9th St (pad at the walk), a memorial garden toward the houses (obelisk, benches facing it, trees), its lot off the cross alley, its service side (bins, condensers) on the east, a path from the church walk to 9th. |

### Land and seams (block 2)
- With the land as it is now: 2,131 m2 of block 2 under the land, 84 m2 of it more than 30 cm (deepest 0.41 m, the
  mews), floating 0. With the DRY trial land fit (not written; it would lower 444 nodes, usual 0.12 m, largest
  0.58 m): under 0, floating 0. **The shared land was not changed.**
- Seams (0.25 m probe): streets, `b_nw` and my own pieces: largest 0.9 cm. Against the residential quadrants:
  `r_q_m200_0_ne` up to 0.31 m (mews, 28 m) and 0.11 m (park), `r_q_m200_m200_se` up to 0.50 m at v -154 (6.5 m):
  their own faces at their edge, my edge on their top line.

### Checks (block 2 area: the 38 pieces round it + mine)
| check | result | what it cannot see |
|---|---|---|
| `validate.gd` | 0 on my pieces (10 in the locked residential quadrants) | as for block 1 |
| `check_life.gd` | 4 on my pieces: the park gate's two leaves stand open (they read as fence ends); the hall's lot-line fence ends at the 9th St hedge and at the alley | it measures against kit footprints |
| `audit_trees.gd` | 313 trees, 0 in hard ground | - |
| `check_rooms.gd --only=g_hs_` | 0 problems, 17 rooms (blocks 1 + 2) | whether a shop has what it needs (by eye) |
| lock test | RESULT PASS | - |
Generator copy changed for block 2 (`room_gen_hs.gd`): a bank layout (teller counter, officers' desks each with a
customer chair) and a hall layout (meeting tables, kitchen behind); the bin at a counter end only where it meets a
wall. Block 1's rooms were NOT rebuilt with it.

### Walk-in places, block 2 (built)
| room | kind | name |
|---|---|---|
| g_hs_b2_amber_stucco_0 | fast_food | Rosa's Taqueria (a salon was tried first: the wide shallow room stayed bare) |
| g_hs_b2_amber_bank_0 | bank | Crownado Savings (painted sign kept) |
| g_hs_b2_amber_shops_0 | ice_cream | Hilltop Scoops |
| g_hs_b2_amber_shops_1 | gallery | Amber Art Co |
| g_hs_b2_amber_hardware_0 | store | Amber Hardware |
| g_hs_b2_amber_corner_0 | books | Ninth Street Books |
| g_hs_b2_ninth_hall_0 | hall | Christ Church Community Center (painted sign kept) |
NOT built: the church's interior (no church layout in the generator; it is walk-in in reality), the townhouses
(homes).

### Pictures (trial land, no shadows, only the block's area loaded; all opened by me)
| file | view | preview draws / primitives |
|---|---|---|
| `b2_top.jpg` | straight down, 200 m | 853 / 2.01 M |
| `b2_amber_north.jpg` | up Amber from `b_nw` | 192 / 1.54 M |
| `b2_9th_west.jpg` | 9th St west from Amber | 421 / 1.77 M |
| `b2_10th_park_gate.jpg` | into the park through its gate | 366 / 1.79 M |
| `b2_steepest_mews_lane.jpg` | the mews lane, up the rise | 241 / 1.55 M |
| `b2_church.jpg` | the church and its forecourt from Amber | 454 / 1.81 M |
| `b2_hall_9th.jpg` | the community center from 9th | 482 / 1.87 M |
| `b2_rooms_1..4.jpg` | each shop: street front + inside | - |
Sheets 1, 2 and 4 were re-rendered after the taqueria change with the same rooms; I opened them before that run, and
sheet 3 (the taqueria) after it. The same note on draw counts as block 1: preview numbers, not the game's.

### NOT done / NOT checked (block 2)
- Not shown to Yasin yet; nothing locked; not in the shared layout; `x_wall_feet` not rebuilt; no bake, no phone.
- The hardware's shelves are the kit's general shelves (bottles), the gallery is benches and frames: thin, by eye.
- The church interior (above).
