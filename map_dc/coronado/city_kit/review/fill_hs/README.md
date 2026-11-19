# High street fill (branch `claude/fill-high-street`) - block 1

Status 19 Nov: block 1 seen by Yasin ("its fine roll out to the entire zone"); **blocks 2 and 3 built**, nothing locked. Blocks 4-6 follow: 4, then the steep 5 and 6.

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

---------------------------------------------------------------------------------------------------------------------

## Block 3: south of 11th St to the ring's Ocean Blvd, C Ave to Amber
A whole block (no pilot inside), 175 x 110 m, with four streets round it: 11th St (rising 2.15 -> 4.15 eastward), Amber
(falling 4.15 -> 2.15 toward the beach), C Ave and Ocean Blvd (both flat at 2.15, the boulevard's edge on a slant). The
ground is ONE surface through those four profiles (`n_hs_b3_site.gd` g = the 11th St rise times Amber's fall): it equals
each street at its edge. Two alley mouths exist (11th St at u -146..-140, C Ave at v 254..260): a service alley runs
south from 11th, the residents' alley east from C Ave to the high street's rear lot.
| piece | what and why |
|---|---|
| `n_hs_b3_amber` | Amber down to the beach, each building on its own level pad: a corner pair on 11th (**Beach Market**, **Shore Cuts** barber), a beach condo with **Swim & Sun** below, **Coronado Surf Co.**, **Beach Break Cafe**, **Ocean Realty** (vacation rentals), **Ocean Burger**; then the block's landmark, **Amber Beach Plaza** with the old **lookout tower** and a beach kiosk: palms in wells, benches facing the ocean, a beach shower, bike racks, a fountain, bollards along Amber, the beach rules. Rear lot off the residents' alley. |
| `n_hs_b3_dingbats` | Along 11th St (the walk to the beach): four 1950s dingbats and a Spanish apartment house, each on its own terrace at the walk height of its middle (11th rises 1.5 m along the row) with steps on the paths, front lawns with fan palms, hedges open at the paths, mailboxes; shared yards behind (washing, grills, benches), tenants' parking nose-in off the alley. |
| `n_hs_b3_cottages` | Six beach cottages facing C Ave (continuing the beach-cottage houses across the street), each lot closed (picket front with the path open, privacy behind), garages on the service alley with ramps, outdoor showers, a kayak rack, deck chairs, washing, a grill. |
| `n_hs_b3_motel` | The **Seabreeze Motel** facing the ocean across its lawn (loungers in pairs under umbrellas, palms, picnic tables, a beach shower, a hedge open at its path), guests parked behind off the alley; a beach condo with **Beach Rentals** below (kayaks, umbrellas, bikes on its forecourt); a public walk from the alley to the beach crossing. |

### Land and seams (block 3)
- With the land as it is now: 760 m2 under the land, none over 30 cm, floating 0. With the DRY trial fit (626 nodes
  lowered, usual 0.05 m, largest 0.29 m; not written): under 0, floating 0. **The shared land was not changed.**
- Seams: every edge against the four streets and between my four pieces: largest 0.8 cm, 0 m over 2 cm (one 15 cm
  step between my own pieces was found and fixed: the first dingbat terrace now ends 0.6 m inside its piece).

### Checks (block 3 area)
| check | result |
|---|---|
| `validate.gd` | 0 on my pieces (11 elsewhere, in locked pieces) |
| `check_life.gd` | 0 on my pieces |
| `audit_trees.gd` | 355 trees, 0 in hard ground |
| `check_rooms.gd --only=g_hs_` | 0 problems, 25 rooms (blocks 1-3) |
| lock test | RESULT PASS |
What they cannot see: as for block 1. Fixed on the way, found by the checks: loungers under the umbrellas, a plant in
front of a French door, bins inside a double garage, the motel's ice chest and soda machine inside its wall, a lamp on
a fence; the cottage fences rebuilt as closed lots (they ended in the open), the dingbat yards made open shared yards.

### Walk-in places, block 3 (built)
| room | kind | name |
|---|---|---|
| g_hs_b3_amber_corner_0 | corner_shop | Beach Market |
| g_hs_b3_amber_corner_1 | salon | Shore Cuts (a key shop was tried first: its pegboard covered the back door) |
| g_hs_b3_amber_condo_0 | clothes | Swim & Sun |
| g_hs_b3_amber_surf_0 | sport | Coronado Surf Co. |
| g_hs_b3_amber_cafe_0 | cafe | Beach Break Cafe |
| g_hs_b3_amber_realty_0 | realty | Ocean Realty (new layout in room_gen_hs.gd: agents' desks, listings in the window) |
| g_hs_b3_amber_burger_1 | fast_food | Ocean Burger (the model's second door: the first gave a 2.6 m room) |
| g_hs_b3_motel_condo_0 | sport | Beach Rentals |
NOT built: the motel (no shop door in its contract: the office would need a room by hand), the lookout tower and the
kiosk (no contract), the homes.

### Pictures (trial land, no shadows, only the block's area loaded; all opened by me)
| file | view | preview draws / primitives |
|---|---|---|
| `b3_top.jpg` | straight down | 536 / 1.87 M |
| `b3_amber_to_beach.jpg` | Amber from 11th down to the beach | 100 / 1.25 M |
| `b3_11th_west.jpg` | 11th St west from Amber | 460 / 2.00 M |
| `b3_steepest_11th_terraces.jpg` | the steepest edge: the dingbat terraces up 11th St | 240 / 1.63 M |
| `b3_c_ave_cottages.jpg` | C Ave south past the cottages | 95 / 1.22 M |
| `b3_ocean_motel.jpg` | Ocean Blvd west past the rentals and the motel | 405 / 1.81 M |
| `b3_beach_plaza.jpg` | the beach plaza and the lookout from the corner | 577 / 2.14 M |
| `b3_rooms_1..4.jpg` | each shop: street front + inside | - |

### NOT done / NOT checked (block 3)
- Not shown to Yasin; nothing locked; not in the shared layout; no bake, no phone.
- The kit's corner model keeps its painted VILLAGE THEATRE / CROWN CAFE boards on its sides in street views that do not
  load the rooms (the shop rooms carry their own signs over the boards they claim).
- Beach Rentals' inside is clothes racks and a bike stand: thin for a rental shop (by eye).

## Block 4: east of Amber, 11th St to the ring's Ocean Blvd, Amber to B Ave
A whole block (no pilot inside), 225 x 120 m, four streets round it: 11th St (rising 4.15 -> 6.15 eastward), Amber
(falling 4.15 -> 2.15 to the beach), B Ave (falling 6.15 -> 4.15) and Ocean Blvd (rising 2.15 -> 4.15 eastward, its edge
on a slant). The ground is ONE surface through those four measured profiles (`n_hs_b4_site.gd`): the ring's and 11th
St's profiles blended by Amber's fall on the west and B Ave's on the east, equal to each street at its edge. Alley
mouths: 11th St at u 190..196 (a service alley south to a turning stub) and B Ave at v 254..260 (the residents' alley
west to the Amber shops' rear lot).
| piece | what and why |
|---|---|
| `n_hs_b4_amber` | The east side of Amber's beach end, facing block 3's shops, each building on its own level pad: a **Spanish arcade** on the 11th St corner (its arches over the walk; **Arcade Books**, **Arches Coffee**, **Shoreline Gallery**), a stucco block with **Ocean Pharmacy** and flats, **The Crown & Anchor** pub, the **Beach Cinema** with its **Cinema Snacks** door, **Sunrise Bakery** by Amber's bus stop. From the bus stop to Ocean Blvd a **corner palm plaza** (palms in beds, benches facing the ocean, a fountain, bike racks, bollards, lamps): the corner where the real town has its great beach hotel, a hero site - this plaza stands there until Yasin decides. Rear lot behind off the residents' alley (back doors kept clear, dumpsters by the food shops). |
| `n_hs_b4_eleventh` | Up 11th St from the shops toward the B Ave houses: two three-storey modern rows, a Spanish revival court, a small row, a white courtyard block and a long garden-apartment block, each on its own terrace at the walk height of its middle (11th rises 1.7 m along the row) with steps on every path, lawns, a palm or flowering tree each, hedges open at the paths, mailboxes; patios behind on the terrace, shared yards (washing, benches, trees), the tenants' parking (51 stalls) nose-in off the alley, bins at its edge; a walk at the east end from 11th St to the alley and the park. |
| `n_hs_b4_cottages` | Seven houses facing B Ave (the residential growth faces them from across the street), each different (craftsman, Victorian, Cape, Spanish, craftsman, beach cottage, a narrow two-storey on the Ocean Blvd corner), each lot a level pad (B Ave falls 2 m: faces up to ~0.25 m at the lot lines, steps where the face crosses the front path), closed all round (picket on the street open at the path, iron for the Spanish house, privacy behind, privacy on the alley meeting the garage), garages on the service alley with ramps, a back-yard life each (showers, surfboards, a kayak rack, a swing set, washing, grills). |
| `n_hs_b4_ocean` | The residents' alley, and **Ocean Park** on the beach side: the **Ocean Park Skate** shop (on a level pad at its front, cut into the slope behind) and its **skate plaza** (quarter pipes facing across the run, a funbox, rails, two bowl sections, benches round it, bike racks, a fountain), a **sand volleyball** court with a beach shower, a **picnic lawn** with palms, tables and grills; park parking off the alley; one main path from the parking to the park's one gate in the boulevard hedge, a cross path linking the three. The plaza, the court and the lawns follow the 1.5 % slope: no wall where a skater or a ball runs. |

### Land and seams (block 4)
- With the land as it is now: 658 m2 under the land, none over 30 cm, floating 0. With the DRY trial fit (560 nodes
  lowered, usual 0.08 m, largest 0.34 m; not written): under 0, floating 0. **The shared land was not changed.**
- Seams: all 19 shared edges (the four streets' walks and junctions, the ring, my four pieces with each other):
  largest 1.1 cm, 0 m over 2 cm. Found and fixed on the way: a 9 cm face 10 cm from the 11th St walk (the band there
  is now 0.7 m+), a 2.0 cm step where the arcade's pad met the rising 11th St walk (its pad now at the mean of its
  two walks, 4.161), a 0.23 m plinth under the 20 m beach condo's facade on Amber's steepest stretch (gone with the
  condo, see below).

### Checks (block 4 area: the 34 pieces round it + mine)
| check | result |
|---|---|
| `validate.gd` | 0 problems on the whole area |
| `check_life.gd` | 0 on my pieces (69 elsewhere, all in the pilot's own pieces: r_n, r_s fences, d_pilot glass, b_* poles) |
| `audit_trees.gd` | 277 trees, 0 in hard ground |
| `sink_check.gd` | 0 props off the ground |
| `check_rooms.gd --only=g_hs_` | 0 problems, 34 rooms (blocks 1-4) |
| lock test | RESULT PASS |
What they cannot see: as for block 1 (no check sees whether a prop makes sense where it is, a face's look, or the
room's taste; validate knows only front doors). Fixed on the way, found by the checks: a bougainvillea in a bird of
paradise, a bike stand and a shower in the hose reels, a condenser inside the arcade, privacy fences into two garages
and then ending in the air (now ending at each garage model's own side, its stats footprint is narrower than the
model). Two door problems were street props of the locked Amber piece (a bin before an arcade shop door, the bus
shelter before the condo's patios): I could not move them, so the arcade moved 0.25 m north and the beach condo gave
way to a smaller bakery; the corner plaza grew to start at the bus stop.

### Walk-in places, block 4 (built)
| room | kind | name |
|---|---|---|
| g_hs_b4_amber_arcade_0 | books | Arcade Books |
| g_hs_b4_amber_arcade_1 | cafe | Arches Coffee |
| g_hs_b4_amber_arcade_2 | gallery | Shoreline Gallery |
| g_hs_b4_amber_stucco_0 | pharmacy | Ocean Pharmacy |
| g_hs_b4_amber_pub_0 | bar | The Crown & Anchor |
| g_hs_b4_amber_cinema_0 | venue | Beach Cinema (its ticket hall) |
| g_hs_b4_amber_cinema_1 | fast_food | Cinema Snacks |
| g_hs_b4_amber_bakery_0 | bakery | Sunrise Bakery |
| g_hs_b4_ocean_skate_0 | sport | Ocean Park Skate |
Two changes in my generator copy `room_gen_hs.gd` (found by `check_rooms`): a shop door with a raised sill (the skate
shed's, 0.2 m) gets the room's floor at the sill (the pilot's own skate-shed room has the same "doorway" report);
the bakery's shelves are stocked models (the kit's bakery shelf ships empty). The rooms of blocks 1-3 were not rebuilt.
NOT built: the homes; no bar or bakery back-of-house beyond what the generator gives.

### Pictures (trial land, no shadows, only the block's area loaded; all opened by me)
| file | view | preview draws / primitives |
|---|---|---|
| `b4_top.jpg` | straight down | 602 / 2.05 M |
| `b4_amber_to_beach.jpg` | Amber from the 11th St corner under the arcade to the beach (cars off) | 74 / 1.17 M |
| `b4_11th_east.jpg` | 11th St east past the apartment terraces (cars off) | 196 / 1.21 M |
| `b4_steepest_b_ave.jpg` | the steepest edge: B Ave falling 2 m past the stepped house lots | 120 / 1.29 M |
| `b4_ocean_park.jpg` | Ocean Blvd west past the park hedge, the skate plaza beyond (cars off) | 267 / 1.23 M |
| `b4_skate_plaza.jpg` | the skate plaza and the shop | 360 / 1.65 M |
| `b4_corner_plaza.jpg` | the corner plaza (the hero hotel's site) from Amber x Ocean Blvd | 449 / 1.94 M |
| `b4_residents_alley.jpg` | the residents' alley west from B Ave | 296 / 1.68 M |
| `b4_rooms_1..5.jpg` | each shop: street front + inside | - |
Preview numbers are not game numbers (whole-island terrain about 1.1 M triangles, unmerged batches, preview cars where on).

### NOT done / NOT checked (block 4)
- Not shown to Yasin; nothing locked; not in the shared layout; no bake, no phone.
- **Ask Yasin:** the hero hotel at Amber x Ocean Blvd. The palm plaza holds the corner (v 289..ring); a hand-made hotel
  would replace it and the bakery.
- By eye, thin: the skate shop's inside (a counter, one shelf, a bike stand in an 11 x 9 m room), the cinema's ticket
  hall (a counter and posters), and the bakery's shelves show grocery goods, not bread (the kit has no stocked bread
  shelf). The gallery's middle is rows of benches. The checker passes all four; it does not judge taste.
- The skate plaza's two bowl sections show their tall backs to the cross path and the boulevard.
- The arcade model shows its own painted boards in street views without rooms (as the corner models in blocks 1-3).
- The street views' bakery front is half hidden by the street piece's pole (`b4_rooms_2.jpg`).

## Blocks 5 and 6: east of Amber on the hill (9th to 11th St, Amber to B Ave), round the pilot's b_se / b_ne, its hill rows r_s / r_n and the residential quarter
Two U-shaped pockets, each about 24,000 m2, wrapped round the pilot's downtown block on Amber, its hill row of houses
and a residential quarter piece. The land climbs 6 - 7 m from Amber's foot (4.15) to the hill top (10 - 11.3). The pilot's
rows and the quarter meet them with STEPPED edges (one level lot per 15 m). Method, both blocks
(`n_hs_b5_site.gd`, `n_hs_b6_site.gd`): every edge measured from the scratch ground dump at 0.25 m; the ground is one
surface made region by region as Coons patches through the measured edge profiles (each region's edges are the same
functions its neighbours use, so my pieces meet exactly); the neighbours' stepped lot lines are met by EDGE STRIPS at
their exact heights (`hs_fill_lib.edge_strip`, new), the strips' faces 2 m inside my pieces. Alley mouths
(`legs_measured.json`): 10th St at u 190..196 (both sides), B Ave at v +-54..60. The residents' alleys run behind the
pilot rows from B Ave to a lane beside b_se / b_ne down to the Amber shops' rear lots.

### Block 5 (south, 10th to 11th St)
| piece | what and why |
|---|---|
| `n_hs_b5_amber` | Amber's shop fronts go on south of b_se: the **Coronado Post Office** behind its steps, **Hillside Bistro**, a corner pair (**Scoops**, **Bay Cleaners**) by a **paseo** to the rear lot, the orange **arcade** centred on Amber's bus stop (**Orange Grove**, **Island Gifts**, **Step Lively**, **Arcade Hair**), a small cafe and a corner plaza on 11th St. Amber is level here: one floor height. |
| `n_hs_b5_eleventh` | **Fire Station 2** on 11th St (its apron straight onto the street, the crews' cars behind), a garden-apartment block and a Spanish court on terraces up the street, stalls off the aisle. |
| `n_hs_b5_hill` | The steepest ground is not built on: **Hillside Park**. The **lookout** terrace at the alley (a ~1 m wall with a railing, benches facing down Amber to the ocean), a path across the slope from the shops' lane, a path down to the **tennis courts** (two courts on a pad) and the parking aisle; lawns with trees, benches, lamps. The residents' alley behind r_s, the lane beside b_se. |
| `n_hs_b5_tenth` | 10th St goes on as the pilot's row: **six houses** on 15 m lots (colonial, contemporary, a narrow cottage, Spanish, Cape, ranch), lawns open to the walk, back yards closed by wood fences, garages on the alley reached by the service lane from 10th St's mouth. |
| `n_hs_b5_school` | **Hilltop Elementary** on B Ave: two wings in an L on one level platform at the main door's walk height (walls 0.5 - 0.9 m with hedges or chain-link), the forecourt on B Ave, the playground between the wings, the school garden on the slope, staff parking off the alley. |

### Block 6 (north, 9th to 10th St; the steepest, 7 m)
| piece | what and why |
|---|---|
| `n_hs_b6_amber` | Amber climbs 2 m to 9th St: each shop on its own pad at its door's height: a brick pair (**Ninth Street Books**), **Hill Savings**, a row (**Silver Tide**, **Hill Shoes**, **Hillcrest Threads**), a corner pair (**Ninth Street Pharmacy**) by a paseo, the trades' building (**Coronado Hardware**, **Plaza Cleaners**), **Hillclimb Coffee**, and a **pocket plaza** where the street meets b_ne. |
| `n_hs_b6_ninth` | The **Hill Rec Center** (its hall a walk-in room), the **Hilltop Market** under three storeys of flats, a modern apartment row; terraces up 9th St (a ~0.9 m wall between them), stalls off the aisle. |
| `n_hs_b6_hill` | **Hillcrest Terraces**: six small apartment houses facing WEST (the view) on three level terraces stepping up the hill (walls 1 - 1.6 m with planted strips), a stair walk across all three, courts with tables, grills and washing; the residents' stalls off the alley behind r_n; the lane and the aisle. |
| `n_hs_b6_tenth` | The north side of 10th St goes on as the pilot's r_n: **six houses** (Tudor, mid-century, a narrow two-storey, Spanish, a ranch, a craftsman), garages on the alley. |
| `n_hs_b6_garden` | **Hilltop Courts**: townhouses with their own garages: the south row's on the residents' alley, the north row's on a private drive (**Hilltop Court**) leaving the alley through the residents' lot; small gardens; a footpath to B Ave. |

### Land and seams (blocks 5 and 6)
| | block 5 | block 6 |
|---|---|---|
| under the current land | 2,276 m2, 161 m2 over 30 cm, deepest 0.66 m (the park's lane edge, the school garden) | 6,701 m2, 1,439 m2 over 30 cm, 19 m2 over 1 m, deepest 1.05 m (the terraces cut into the hill) |
| DRY trial fit (not written) | 538 nodes lowered, usual 0.16 m, largest 0.94 m: under 0, floating 0 | 1,291 nodes lowered, usual 0.18 m, largest 1.20 m: under 0, floating 0 |
| seams with the streets and between my pieces | largest 1.6 cm (3.4 cm at the one corner where B Ave, r_q and the school meet) | largest 1.5 cm |
| seams with the pilot rows and r_q | at their exact lot heights; left: their own steps at their corners (r_s / r_n vs 10th St 0.17 m, r_q vs B Ave 0.12 - 0.28 m, the r_s lot step at u 56 0.10 m) | the same |
**The shared land was not changed.** The land lowering the dry fit needs on block 6 (up to 1.2 m, the terraces) is the
largest of the zone: if the land is written later, those cuts are real.

### Checks (each block's area: the pieces round it + mine)
| check | block 5 | block 6 |
|---|---|---|
| `validate.gd` | 0 problems | 0 on my pieces (4 in the residential quarter: house numbers on mailboxes) |
| `check_life.gd` | 0 on my pieces (68 elsewhere: the pilot's r_n / r_s fences, d_pilot glass, b_* poles) | 0 on my pieces (68 elsewhere, the same) |
| `audit_trees.gd` | 288 trees, 0 in hard ground | 345 trees, 0 in hard ground |
| `sink_check.gd` | 0 props off the ground | 0 |
| `check_rooms.gd --only=g_hs_` | 0 problems, 53 rooms (all six blocks) | |
| lock test | RESULT PASS | RESULT PASS |
What they cannot see: as for block 1. Fixed on the way, found by the checks: Amber's locked street props in front of
doors (a bus shelter at the block 5 arcade, a paper box and a bench at block 6's shops: both rows re-ordered, paseos
added); 10th St yard fences that ended in the air (now from each house's own footprint, shared lot lines drawn once);
garage aprons of 67 % (the lot pads moved to their back's height, aprons 2 m); lot faces next to the walks (bands 1.2 -
2.2 m); r_q's profile at two places (measured again); a railing pair overlapping, a lamp in a hedge, a condenser on a
washing line, mailboxes in a narrow path; a wall mailbox standing on the walk (removed, found by eye).

### Walk-in places (built): 19
Block 5 (8): Coronado Post Office (bank layout: the office layout left 303 m2 bare), Hillside Bistro, Scoops, Bay
Cleaners, Orange Grove, Island Gifts, Step Lively, Arcade Hair. Block 6 (11): Ninth Street Books, Hill Savings, Silver
Tide, Hill Shoes (a key shop's pegboard covered the back door), Hillcrest Threads, Ninth Street Pharmacy, Coronado
Hardware, Plaza Cleaners (gift frames too tall for the trade building's 2.2 m ceiling; a key shop's pegboard covered its
roll-up), Hillclimb Coffee, Hilltop Market, Hill Rec Center (hall layout).
NOT built: the fire station, the school, the corner cafe on 11th St (no contract: shallow model), the homes.

### Pictures (trial land, no shadows, only the block's area loaded, cars off except the tops; all opened by me)
| file | view | preview draws / primitives |
|---|---|---|
| `b5_top.jpg` | straight down | 851 / 2.35 M |
| `b5_amber_south.jpg` | Amber south from b_se past the post office | 87 / 1.16 M |
| `b5_steepest_alley.jpg` | the steepest edge: the alley climbing behind r_s (its lot walls on the left) | 243 / 1.21 M |
| `b5_lookout_view.jpg` | from the lookout west over the park | 155 / 1.19 M |
| `b5_10th_east.jpg` | 10th St east past the new houses | 144 / 1.17 M |
| `b5_b_ave_school.jpg` | B Ave south past the school | 138 / 1.19 M |
| `b5_11th_fire.jpg` | 11th St east past the fire station | 246 / 1.21 M |
| `b5_school_playground.jpg` | the playground and the classroom wing | 207 / 1.19 M |
| `b6_top.jpg` | straight down | 1117 / 2.50 M |
| `b6_amber_climb.jpg` | Amber north from b_ne past the pocket plaza | 156 / 1.19 M |
| `b6_steepest_terraces.jpg` | the steepest: the stair walk up the three terraces | 363 / 1.26 M |
| `b6_terrace_view.jpg` | from the middle terrace west | 165 / 1.19 M |
| `b6_9th_rec.jpg` | 9th St east past the rec center and the market | 363 / 1.25 M |
| `b6_10th_north.jpg` | 10th St east, north side | 221 / 1.20 M |
| `b6_courts_drive.jpg` | Hilltop Court, the private drive | 213 / 1.22 M |
| `b6_b_ave_north.jpg` | B Ave north past the courts | 334 / 1.29 M |
| `b5_rooms_1..4.jpg`, `b6_rooms_1..6.jpg` | each shop: street front + inside | - |

### NOT done / NOT checked (blocks 5 and 6)
- Not shown to Yasin; nothing locked; not in the shared layout; no bake, no phone; the shared land not written (block
  6's terraces need up to 1.2 m of cut if it is).
- By eye: the post office's inside is desks with computers (bank layout), not a post counter; Silver Tide (jewellery)
  shows bottle shelves; the fire station model keeps its painted "FIRE STATION 1" board and the cafe its "CROWN CAFE"
  board in street views without rooms.
- The school's platform shows a 0.5 - 0.7 m wall along B Ave's walk at its ends (2.2 m back from the walk).
- No interiors for the fire station and the school (they would need hand-made rooms); the townhouses' garages are
  closed doors (no garage interiors).
- The cars in the pictures are preview cars (off in the street views).

## Locked (19 Nov, Yasin: "lock them")
All 25 high street pieces (`n_hs_b1_*` .. `n_hs_b6_*`) are locked in `locked.json` (`lock.py lock ... --by=Yasin`); the
lock test says RESULT PASS. A change now needs Yasin's word, `lock.py unlock`, a rebuild, the checks and a relock. The
walk-in rooms (`g_hs_*`) and the room assignment are not part of the piece lock. Still NOT done: the shared layout
(`integrate.py`), the land (only the dry trial), the bake, the phone.
