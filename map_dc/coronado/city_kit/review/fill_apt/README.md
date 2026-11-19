# Apartment band fill (branch claude/fill-apartments, 19 Nov) - BLOCK 1 of 3, a draft for Yasin

Block 1 = the block between B Ave and Adela Ave, 7th and 8th St (grid u 259-491, v -791..-609), the L-shaped land
round the locked apartment sample quadrant `a_ne`. Blocks 2 and 3 are NOT started (waiting for Yasin's word on this one).
Nothing is locked. Nothing shared was changed (see the end).

## What was built and why
Three pieces, each its own script (`tools/city/pilot/pieces/n_apt_b1_*.gd`, the reasons are in each script's header),
all at layout pos [250, 6, -600], yaw 0 (the sample's junction frame, so the seams with `a_ne` line up exactly). Rows in
`review/grow_apt_blocks.json` (my own table; `integrate.py` picks it up later, NOT run into the shared layout).

The block is not one lot: the streets round it have alley mouths at 54-60 m from every junction, so it is cut by four
alleys: two continue the sample's own alleys (u 304-310, v -654..-660), two come off the Adela / 8th St aprons.

| piece | where | what it is, and why there |
|---|---|---|
| `n_apt_b1_bw` | B Ave x 8th St, u 259-350, v -791..-700 | **the old courts**: the band's oldest corner (1920s-30s Spanish and white courts, 1950s walk-ups). The **bakery** on the corner (8th St is the walk into the centre), a **barber** under a flat beside it, the shared courtyard behind (picnic table under a jacaranda, clothesline, bed), the shops' bins in a CMU enclosure the truck reaches from the alley; a play corner (swings, slide, bark, the parent's bench) behind the B Ave walk-ups; the courts' citrus and herb garden; a row of 7 lock-up garages the courts rent (old buildings have no parking); a garden wing whose windows look over `a_ne`'s playground |
| `n_apt_b1_be` | 8th St x Adela, u 350-491, v -791..-700 | **the 1960s end** toward the golf course: stucco blocks and a condo on 8th, three **dingbats over their carports** on the alley, the dingbat tenants' **sand volleyball** court (sailors, nurses), the complex's **two tennis courts** (kit park, fence rebuilt with posts, one gate) and their lawn (benches facing the courts, tables under sails, grill, fountain, arbor); the **taqueria** and a **nail salon** on the corner of 8th and Adela (tables on the forecourt), walk-ups on Adela |
| `n_apt_b1_7th` | 7th St x Adela, u 350-491, v -700..-609 | **the working street**: 7th St is the bus street to the centre. A brick walk-up with a **dry cleaner**, a garden apartment, a **boarded walk-up** (roll-off and builder's screen: renovation starting), a stucco block; the corner of 7th and Adela: **pharmacy & post, tax office, donut shop** and a **coffee window**; carports for the 7th St flats, the block's **skate pad** for the teenagers (the small ones have `a_ne`'s playground next door), the old residents' shade benches facing it; the **launderette** under the flats on Adela |

Counts (saved pieces): 2,421 props, 49 buildings, 152 parking stalls (recorded for the parked-car layer), ground 58,336
triangles (cells unmerged, no T-joints).

## Land first (Yasin: "CONSIDER THE ELEVATION")
- Land under block 1 (`zoning/terrain_grid.npz`): 5.95-6.40 m, a 25 cm hump in the middle of the east half. The four
  streets are built at pad 6.0, walk 6.15 m; `a_ne` is level at 6.15. So the block is ONE level floor at the walk
  height (it meets every street and `a_ne` without a slope down to the kerb); the hump goes under it.
- Built ground-only first (alleys + floor), checked, committed (e91b1d9a), only then buildings and props.
- Seams, measured every 0.5 m along all 12 edges of the 3 pieces (`OUT/apt/seams.py`, scratch): every edge has a
  neighbour along its whole length (8th St, Adela, 7th St, B Ave walks and their junctions, `a_ne`, each other);
  largest step 0.000 m.
- Dry land trial (`lower_land_to_pieces.py <dump> --fit --ease-from=<today's grid> --out=<scratch>`, NOT `--write`):
  the land goes 5 cm under these pieces by lowering 1,882 land nodes (usual 0.10 m, largest 0.31 m), none raised by
  them. Then `ground_check.py` against the trial land: these pieces 0 m2 under the land, 0 hanging edge cells, 0 m of
  seam stepping over 20 cm. (The trial also moved land for the residential pieces in the same area file - their
  floating edges, not mine; it is a scratch file and was not written.)
- The land is NOT changed in the repo: when integrated, the land fit has to be run for real (Yasin's / the integration
  session's step). Until then today's land covers up to 25 cm of this block's floor in the middle: the top view
  `b1_top_todays_land.jpg` shows exactly that (the green blob); `b1_top_trial_land.jpg` is on the trial land.

## Checks (area layout: the 118 rows within u 0-750, v -1050..-50 + these 3; real renderer)
What each check sees and does not see is in the super-builder skill's table; in short:
- `validate.gd`: 26 problems in the area, 7 of them in my pieces, all "fence_wood_privacy inside <building>": the
  validator sizes every prop from the kit manifest and ignores its scale, so a fence panel I SHORTENED to fit a gap
  (1.25-1.9 m, the skill's rule: never stretched, a short run gets shorter panels) is tested as 2 m long. The real
  panels end 0.2 m clear of the walls. (Not fixed in the shared validator: not mine to change.) The other 19 are the
  neighbours' (overlaps in the sample / residential pieces). Does NOT see heights, the land, yards, or sense.
- `check_life.gd`: 7 lines in my pieces: 6 are the open mouths of the three CMU bin enclosures (open on purpose: the
  truck reaches the bins), 1 is the tennis courts' gate, placed by the shared `civ_lib.park` as in the civic sample.
  0 wall items over a window or door (my copy of the dressing slides every meter, light, mailbox, intercom and hose
  reel clear of the measured openings, or leaves it out); for comparison the locked sample `a_ne`..`a_sw` has 46-62
  such lines each from the shared rules. Does NOT see play items on asphalt, wear on the wrong surface, sense.
- `audit_trees.gd`: 0 trees in hard ground (1,240 checked in the area).
- `sink_check.gd`: 0 - it only checks STREET pieces, so it says nothing about these blocks.
- `ground_check.py` + the trial land: above.
- Lock test: see "Numbers" below.

## Walk-in places (rooms built WITH the block, Yasin relayed: "use the indoor generator in the pilot and do them both together")
10 rooms, `interiors/rooms/g_apt_*.scn`, from my table `interiors/assignment_apt.json` (`tools/city/rooms/assign_apt.py`,
the reason for every shop is in it) and my generator `tools/city/rooms/room_gen_apt.gd` - a copy of the strip
session's copy of the pilot's `room_gen.gd` (the shared generators untouched), softer wall colours for the band, plus
bakery / barber / pharmacy-and-post / donut kinds; three rule fixes in the copy (the nail technician's chair 0.25 m
further from the wall, the menu board clear of a back door, the taqueria's fridge reachable).
| room | shop | kind |
|---|---|---|
| `g_apt_b1_bw__bakery__0` | B Avenue Bakery | bakery (bread shelves, cases, kitchen behind a partition, two-tops) |
| `g_apt_b1_bw__barber__0` | Eighth Street Barbers | barber (mirror stations both sides, waiting bench in the window) |
| `g_apt_b1_be__taqueria__0` | Taqueria La Esquina | taqueria (booths, two-tops, salsa bar, counter) |
| `g_apt_b1_be__nail_salon__0` | Polished Nail Studio | nails (nail tables with both chairs, product shelves) |
| `g_apt_b1_7th__dry_cleaner__0` | Seventh Street Cleaners | dry cleaner (counter, garment rails) |
| `g_apt_b1_7th__corner_shops_7th__0` | Adela Pharmacy & Post | pharmacy (stocked shelves, post box inside) |
| `g_apt_b1_7th__corner_shops_7th__1` | Island Tax Service | tax office (desks, filing) |
| `g_apt_b1_7th__corner_shops_7th__2` | Sunrise Donuts | donuts |
| `g_apt_b1_7th__coffee_window__0` | The Coffee Window | coffee |
| `g_apt_b1_7th__launderette__0` | Adela Wash & Fold | laundromat (washers / dryers on the walls, soap machine, waiting seats) |
`check_rooms.gd -- --only=g_apt_`: CHECKS 0 problems (after three rounds: 19 -> 11 -> 2 -> 0). It does NOT see whether
a shop has everything its kind needs: that is by eye, from the pictures. Rooms are not in the runtime bake yet (no room
is), so they are not in the draw numbers below.

## Pictures (all opened and looked at by me)
- `b1_top_trial_land.jpg` - straight down, on the TRIAL land (preview contour lines; parked cars are the preview's).
- `b1_top_todays_land.jpg` - the same on today's land: the hump drawn over the floor (what the land fit removes).
- `b1_eye_8th_st_east.jpg`, `b1_eye_7th_st_west.jpg`, `b1_eye_adela_south.jpg` - eye height (1.7 m) along the streets,
  rooms open. Flat preview plane, no land (the land does not show at street level here).
- `b1_edge_alley_seam_a_ne.jpg` - the block has no slope; this is its seam with the locked `a_ne` along the alley, on
  the trial land.
- `b1_shops_sheet_0..3.jpg` - every shop: front from across the pavement and inside from the door. The dry cleaner's
  front picture in sheet 1 is a tree trunk (the camera landed in a parkway tree): its retake is
  `b1_shop_dry_cleaner_front.jpg`.
- Only part of the city is loaded in every picture (the area file): the roads end where the loaded area ends.
- No shadows in any picture (the cloud preview's renderer).

## Numbers
DRAWS_PLACEHOLDER

## NOT done / NOT checked
- Blocks 2 and 3 (waiting for Yasin's word on block 1).
- The land is not fitted in the repo (only the dry trial); `x_wall_feet` not rebuilt for these blocks (not needed on
  a flat block whose edges are all flush, but not run).
- Not checked: the phone; the game itself; the rooms from the street at night; the rooms' cost in draws (they are not
  in the bake); the wires (no `w_` piece for these alleys: the poles stand and their places are recorded as the piece's
  meta "poles", the wires are not drawn); the parked-car layer in the game (stalls recorded).
- Eye-height pictures are with a flat plane, not the land; the top view with the land is the trial land.
- The 7 validator lines on shortened fence panels were reasoned, not proven in a picture one by one.
- KIT_USAGE.md not updated (shared file). Used here that were rare or unused before: kit tennis courts, skate pieces
  (funbox, quarter pipes, rail, bowl), volleyball net away from the beach, builder's screen + roll-off, 18 in cones,
  carports, the four single-garage types, the boarded walk-up, boutique row, coffee window, realty unit (nail salon).

## Shared files: NOT touched
`zoning/terrain_grid.npz`, `terrain/data_citykit/`, `city_grid_layout.json`, `locked.json`, every existing `.scn`,
`x_wall_feet`, `x_shore_foam`, `wall_feet.json`, `shore_foam.json`, the locked plan files, `assignment_all.json`, every
existing room, the shared libraries and generators (`apt_lib`, `civ_lib`, `room_gen*.gd`, `validate.gd` ...).
New files only: the three piece scripts + scenes, `apt_fill_lib.gd`, `review/grow_apt_blocks.json`, this folder,
`interiors/apt_buildings.json`, `assignment_apt.json`, `rooms_apt_report.json`, `rooms/g_apt_*.scn`,
`tools/city/rooms/{list_buildings_apt.gd, assign_apt.py, room_gen_apt.gd, gen_shots_apt.gd}`.
