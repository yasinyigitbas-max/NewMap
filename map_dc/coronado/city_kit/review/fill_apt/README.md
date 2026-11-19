# Apartment band fill (branch claude/fill-apartments, 19 Nov) - the whole zone: blocks 1, 2, 3 (drafts for Yasin)

Yasin, after block 1: "go on populate the entire zone". The apartment band east of the sample, three blocks, eight
pieces, 25 hand-designed sub-blocks, 15 shop rooms. Nothing is locked. Nothing shared was changed (see the end).
Each piece is its own script (`tools/city/pilot/pieces/n_apt_*.gd`, the reasons for everything in its header) with my
copies of the libraries: `apt_fill_lib.gd` (copy of apt_lib + the land on slopes + wall items clear of openings +
shortened fence panels), `apt_fill_b2_land.gd`, `apt_fill_b3_land.gd` (measured street heights, data only).
Rows in `review/grow_apt_blocks.json` (my own table; `integrate.py` takes it later; NOT run into the shared layout).

## The three blocks
| block | where | pieces | land | what it is |
|---|---|---|---|---|
| 1 | B Ave - Adela, 7th - 8th St, the L round the sample's a_ne | n_apt_b1_bw / _be / _7th | flat, level with its streets at 6.15 m | the old courts with a bakery and a barber; 1960s dingbats, sand volleyball, tennis courts, taqueria and nail salon; 7th St's shops (dry cleaner, pharmacy & post, tax office, donuts, coffee window), a boarded walk-up being renovated, carports, a skate pad, the launderette |
| 2 | B Ave - Adela, 7th - 6th St, round the sample's a_se | n_apt_b2_7th / _be / _bw | rises 2.00 m to the B Ave x 6th corner (measured: B Ave +2.00 m, 6th St -2.00 m) | the church with its plaza and lot, the corner market, a community garden behind a picket fence; garage townhouses stepping down the alley, a garden court, the play and picnic lawn, the bike shop; the community room and preschool on the top corner with its play yard on a level pad, walk-ups stepping up B Ave, lock-up garages, a barbecue terrace |
| 3 | B Ave - Adela, 6th St - the residential quarters at z -300 | n_apt_b3_w / _e | the steep end: B Ave +2.00 m, Adela +1.00 m, 6th St -2.00 m, the houses' terraces behind 10.30-7.16 m | Hilltop Books, a Spanish court, a BUNGALOW COURT (six small cottages, each on its own terrace, round a garden walk off B Ave), 6th St walk-ups, the residents' garden; three garage townhouses stepping down against the retaining line, the corner court, Adela walk-ups |

Totals (saved pieces): 6,444 props, 108 buildings, 409 parking stalls (recorded for the parked-car layer), ground
188,712 triangles.

## Land first (Yasin: "CONSIDER THE ELEVATION")
Order for every block: the street heights round it MEASURED on the built pieces (probe of a ground dump, 1-2 m apart),
the ground alone built and checked and committed (b1 e91b1d9a, b2 and b3 their "GROUND ONLY" commits), only then
buildings, props and rooms.
- Block 1: one level floor at the walk height (the land's 25 cm hump goes under it).
- Blocks 2 and 3: one smooth surface that equals every measured street edge exactly (block 2: the product of the B Ave
  and 6th St profiles; block 3: the Coons patch of the four edges); every building on a level pad at the middle of its
  front, eased into the slope over 5 m, never within 3 m of an edge (so the edges stay on the measured heights); the
  play yards, the terrace on their own level pads. Rows step: the B Ave walk-ups, the 6th St row, the townhouses.
- Block 3's back line with the residential quarters: their house terraces step 0.35-0.95 m between lots; this block's
  edge follows them smoothed, exactly at their two alley mouths, and a retaining face stands on the shared line wherever
  the two grounds differ (180 m: up to 0.65 m where their terrace is higher, 0.20 m where this block is), facing the
  side that sees it; a fence on top.

Measured on the finished pieces (all eight, `OUT/apt/seams.py`, every edge every 0.5 m): every street edge and every
seam between my own pieces has its neighbour along its whole length, largest step 0.008 m (the meshes' own triangles on
the slope; the rule is 2 cm). The only larger steps are block 3's retaining faces on the residential line (0.21 m and
0.66 m: the planned faces). Dry land trial (`lower_land_to_pieces.py --fit --ease-from=<today's grid> --out=<scratch>`,
NOT `--write`) with `ground_check.py` against it: 0 m2 of these pieces under the land, 0 hanging edges; the trial lowers
4,669 land nodes (usual 0.13 m, largest 1.19 m where block 3 cuts into the hill), raises none for these pieces.
NOT done: the land in the repo is not changed. Until the land fit is run for real (integration), today's land covers
parts of these floors (block 1's hump up to 25 cm; block 3 more than 30 cm on 10,097 m2). The top views are on the
TRIAL land; `b1_top_todays_land.jpg` shows what today's land does.

## Checks (area layout: the rows within u 0-750, v -1050..-50 + these 8; real renderer)
What each check sees and does not see: the super-builder skill's table. My pieces' lines only:
- `validate.gd`: 21 lines, all "fence_wood_privacy inside <building>" in narrow gaps between buildings: the validator
  sizes every prop from the kit manifest and ignores its scale, so a panel I SHORTENED to fit (the skill: never
  stretched) is tested as 2 m long; the real panels end 0.2 m clear of the walls. Not fixed in the shared validator.
- `check_life.gd`: 9 lines: 8 are the open mouths of the four CMU bin enclosures (open so the truck reaches the bins),
  1 is the tennis courts' gate placed by the shared civ_lib.park. 0 wall items over a window or door (my copy slides
  every meter, light, mailbox, intercom, hose reel clear of the measured openings, shops, flats and houses).
- `audit_trees.gd`: 0 trees in hard ground (1,307 in the area).  `sink_check.gd`: 0 - street pieces only, it says
  nothing about these blocks.
- Lock test: RESULT PASS (496 locked pieces, 103 locked plan files) - only that no locked file changed.

## Walk-in places: 15 rooms, built with their blocks (Yasin, relayed: "use the indoor generator in the pilot and do them both together")
Table `interiors/assignment_apt.json` (`tools/city/rooms/assign_apt.py`, the reason for every shop in it), generator
`tools/city/rooms/room_gen_apt.gd` (a copy of the strip session's copy of the pilot's room_gen.gd; softer colours for
the band, new kinds: bakery, barber, pharmacy & post, donuts, church, community room, bike shop, books; small rule fixes
noted in the file). `check_rooms.gd -- --only=g_apt_`: CHECKS 0 problems in 15 rooms (it cannot see whether a shop has
everything its kind needs: by eye, from the pictures).
| block | room (interiors/rooms/) | shop |
|---|---|---|
| 1 | g_apt_b1_bw__bakery__0, __barber__0 | B Avenue Bakery, Eighth Street Barbers |
| 1 | g_apt_b1_be__taqueria__0, __nail_salon__0 | Taqueria La Esquina, Polished Nail Studio |
| 1 | g_apt_b1_7th__dry_cleaner__0, __corner_shops_7th__0/1/2, __coffee_window__0, __launderette__0 | Seventh Street Cleaners, Adela Pharmacy & Post, Island Tax Service, Sunrise Donuts, The Coffee Window, Adela Wash & Fold |
| 2 | g_apt_b2_7th__church_7th__0, __corner_market__0 | Seventh Street Community Church, Adela Corner Market |
| 2 | g_apt_b2_be__bike_shop__0 | Hill Street Bikes |
| 2 | g_apt_b2_bw__community_room__0 | Glorietta Hill Community Room (and preschool) |
| 3 | g_apt_b3_w__hilltop_books__0 | Hilltop Books (small: 5.9 x 5.2 m, 9 props) |
Rooms are not in the runtime bake (no room is yet), so not in the draw numbers.

## Numbers (cloud, lavapipe - NOT the phone)
One scratch runtime bake of the area with all eight pieces (a copy of bake_runtime.gd reading the shared layout + my
rows, out to OUT/rt_apt, not committed; 16 cells), then rt_shots.gd through the streamer:
| view | draws | triangles |
|---|---|---|
| b1 8th St east, eye height | 64 | 666k |
| b1 7th St west | 133 | 1,285k |
| b1 alley seam with a_ne | 134 | 1,180k |
| b2 7th St east | 103 | 873k |
| b2 B Ave uphill | 74 | 905k |
| b2 townhouse alley | 66 | 542k |
| b3 6th St east | 88 | 731k |
| b3 B Ave uphill | 107 | 796k |
| b3 residents' garden | 97 | 1,136k |
| above the zone, 84 m up | 84 | 945k |
- Draws 64-134 a view: under the ~150 (Yasin's first rule).
- Triangles 0.54-1.28 M: OVER the ~500k mark in every view; not split into mine / the far world / the neighbours.
  Known heavy parts: the ground (189k in the eight pieces: unmerged cells against cracks; block 2's community garden
  beds and block 3's walks cut many cells), wheel stops, the townhouses, the tennis courts. Cheap cuts if wanted: merge
  the ground cells on block 1 (flat), fewer wheel stops. Not done without Yasin's word.

## Pictures (all opened and looked at by me; only the area round the zone is loaded; no shadows in the cloud preview)
- Block 1: `b1_top_trial_land.jpg`, `b1_top_todays_land.jpg`, `b1_eye_8th_st_east.jpg`, `b1_eye_7th_st_west.jpg`,
  `b1_eye_adela_south.jpg`, `b1_edge_alley_seam_a_ne.jpg`, `b1_shops_sheet_0..3.jpg` (the dry cleaner's front in sheet 1
  is a tree trunk: its retake is `b1_shop_dry_cleaner_front.jpg`), `b1_baked_above.jpg`.
- Block 2: `b2_top_trial_land.jpg`, `b2_eye_bave_uphill_steepest_edge.jpg`, `b2_eye_6th_st_east.jpg`,
  `b2_eye_townhouse_alley.jpg`, `b2_shops_sheet.jpg` (church, market, bike shop, community room: front and inside).
- Block 3: `b3_top_trial_land.jpg`, `b3_eye_bave_uphill_steepest_edge.jpg`, `b3_eye_bungalow_court.jpg`,
  `b3_eye_retaining_line.jpg` (from a townhouse yard: the back fence on the retaining line, no gap), `b3_eye_6th_st_east.jpg`,
  `b3_eye_residents_garden.jpg`, `b3_sheet_streets_and_bookshop.jpg` (its first B Ave picture stands against the
  bookshop's wall; the retake is the steepest-edge one).
- `zone_baked_above.jpg`: the whole zone through the streamer (the trees draw black there: the preview's foliage light).
- Every street view that starts at a junction corner shows the junction's kerb ramp with the grass edge over it (the
  fault Yasin pointed at): the road kit's locked junctions, left alone on his word ("no dont touch it"); the dry run of
  a patch tool for it is in `ramp_sides_dry_run.txt` (64 of 74 junction designs).

## NOT done / NOT checked
- The land fit for real (only the dry trial); `x_wall_feet` not rebuilt for these blocks (their edges are flush or
  have their own retaining faces; not run).
- Not checked: the phone; the game; the rooms at night and their draw cost; wires (poles stand on gravel pads, their
  places are in each piece's meta "poles", no `w_` piece drawn); the parked-car layer in the game (stalls recorded).
- The 21 validator lines on shortened panels were reasoned from the rule and a few measured, not each pictured.
- By eye, open questions for Yasin: block 3's residents' garden reads open and plain at eye height; Hilltop Books'
  room is small and light on props; block 3 cuts up to 1.19 m into today's land (the trial land fits it, the real fit
  is an integration step).
- Block 1's ten rooms were rewritten by a later generator run: same prop counts and sizes, file bytes differ; not
  compared prop by prop.
- KIT_USAGE.md not updated (shared). First or rare use here: kit tennis courts, skate pieces, volleyball net, builder's
  screen + roll-off, carports, the single-garage types, the boarded walk-up, boutique row, coffee window, realty unit,
  civ_church again, civ_community_center, com_surf_shop, com_shallow_books, white picket fence with its posts and gate
  (unused before), prop_mailbox_post_metal, prop_house_numbers_tile, houses spanish_small / beach_white / ranch_porch /
  narrow cottages (the bungalow court), prop_ac_condenser_compact.

## Shared files: NOT touched
`zoning/terrain_grid.npz`, `terrain/data_citykit/`, `city_grid_layout.json`, `locked.json`, every existing `.scn`,
`x_wall_feet`, `x_shore_foam`, `wall_feet.json`, `shore_foam.json`, the locked plan files, `assignment_all.json`, every
existing room, the shared libraries and generators. One new shared-folder file: `materials/bw_city_color_95.tres` (the
building wear level of the boarded walk-up, made by kit_lib; new, not a change).
