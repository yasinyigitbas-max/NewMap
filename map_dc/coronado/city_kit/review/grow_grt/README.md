# Gritty edge growth: variants + pilot area (18 Nov, branch `claude/grow-gritty`) - FOR YASIN, NOTHING LOCKED

The gritty sample (`g_ne g_nw g_se g_sw`, `s_grt`, `w_grt`) was locked by Yasin on 17 Nov, so this round grows FROM it.
Pictures: `shots/` (cloud preview: no shadows; the weathered buildings render about 40 % too dark here; real phone
pictures come from the PC session).

## The three variants (recipes in `tools/city/pilot/pieces/grt_grow_recipes.gd`)
| Variant | Where it goes | What it is |
|---|---|---|
| **v1 yard edge** | the side that backs onto the industrial sample | a one-storey trade corner on 4th St (check cashing + tyres / used parts, bars over the counter), the dead filling station next door, a hand car wash OR a tyre shop, the street's last narrow old cottages behind weathered board fences with their garages on the lane, a contractor's shed / parts depot with its yard inside the block |
| **v2 trade street** | the middle, round the sample | a brick corner block with a shop under the flats, a row of small businesses (pawn, liquor, diner, takeout, laundromat, check cashing, thrift, barber, tattoo, dive bar) with dead fronts between them, brick walk-ups with fire escapes on the Ave, the service yard, and inside the block a pay lot (attendant's kiosk), a fenced vacant lot, or a back-street body shop |
| **v3 walk-up homes** | toward the Crown Hill apartments (east) and the campus (south) | one corner shop + a laundromat (or check cashing + a botanica, or a campus grill), then homes: apartment rows behind small yards, a dingbat on the lane, narrow houses / walk-ups / student rentals on the Ave, and a shared court with a walled community garden |

No two blocks are dressed the same: each site's seed picks the buildings, the businesses, the Ave houses and the inside
of the block (the two v1 blocks: car wash + contractor's shed vs tyre shop + parts depot; the three v2: pay lot / body
shop / vacant lot; the three v3: three different Ave sides). Zones change by transition: v1 next to industry, v2 in the
middle, v3 toward the homes.

## The pilot area (`review/grow_grt_blocks.json`, written by `tools/city/pilot/zoning/grt_sites.py`)
Grid frame u -800..-500, v -1300..-900: the 3 x 4 run of 100 m quadrants between the locked INDUSTRIAL sample (J Ave x
3rd St) and the locked GRITTY sample (G Ave x 5th St). The sample holds 4 of them; the 8 new blocks fill the rest:
| Piece | Quadrant | Recipe |
|---|---|---|
| g_v1_j4ne | J Ave x 4th St, NE (u -800..-700, v -1300..-1200) | v1, backs onto the industrial sample's i_se |
| g_v2_g4nw | G Ave x 4th St, NW (u -700..-600, v -1300..-1200) | v2 |
| g_v1_g4ne | G Ave x 4th St, NE (u -600..-500, v -1300..-1200) | v1 |
| g_v2_j4se | J Ave x 4th St, SE (u -800..-700, v -1200..-1100) | v2 (same city block as the sample's g_nw) |
| g_v3_g4sw | G Ave x 4th St, SW (u -700..-600, v -1200..-1100) | v3 |
| g_v3_g4se | G Ave x 4th St, SE (u -600..-500, v -1200..-1100) | v3 (faces E Ave / the apartments) |
| g_v2_j5ne | J Ave x 5th St, NE (u -800..-700, v -1100..-1000) | v2 |
| g_v3_j5se | J Ave x 5th St, SE (u -800..-700, v -1000..-900) | v3 (toward the campus) |
Why here: it is the one stretch where the zone gets filled neighbours on every side at once: industry to the north,
the sample to the south-east, 4th St (the arterial, bus stops both ways) and 5th St through it, and one whole city block
(J-G x 4th-5th) complete. Baked cells: `cell_-4_-7`, `-3_-7`, `-4_-6`, `-3_-6`, `-4_-5`, `-3_-5` (200 m cells).

## What was hard and how it is solved (`tools/city/pilot/pieces/grt_grow_lib.gd`)
- The streets round the sample are not the sample's: 4th St is the strip arterial (property line 14.3 m, driveways
  where road_art put them) and the Aves climb 2 m a block up to the sample's 6 m pad. Each block is laid out flat, then
  DRAPED: its ground follows both sidewalks exactly (measured from the built street pieces) and meets the sample's flat
  edge; every building stands on its own level terrace (height of the middle of its front), the yard eases back to the
  slope round it. The service lanes line up with the sample's and the streets' alley aprons, so alleys run through.
- The validator's rules are applied while building (no prop in a building, no overlaps, no tree on paving), and wall
  props never hang over a window or door (slid along the wall, dropped only when no wall is free).

## Fencing and the phone (the gritty edge cost 40 % more GPU at a tier fade: layered see-through things)
- Chain-link only round yards and lots INSIDE the blocks (contractor's yard: on the two lane sides only, the inner
  edges open toward the neighbour; vacant lot: one ring, one gate), never along a street, never a second fence in front
  of it, no tree within 0.9 m.
- Street side: no front fences at all; short weathered board fences only BETWEEN front yards, across the sight line.
- The community gardens are walled in solid stucco (opaque: cheap to draw) with one wooden gate.

## Rooms (every open shop; `interiors/assignment_grt.json`, `tools/city/rooms/room_gen_grt.gd`)
25 rooms. Shut on purpose (boarded / dead fronts, no room): the old filling stations, the dead bays of the brick and
row buildings (ck_grt_row2 paints its windows boarded: only dead fronts go in it), the shut second bay of the
laundromat building in g_v3_g4sw. The car wash and the contractor's / parts depots
are work yards, not shops.
Built with the NEW kit indoor set (assets branch dd8d53a, same files as `claude/kit-indoor-props` 9fce731: the shelves
come stocked). Inside, from the customer's side: the counter in view from the door, the first 1.5 m clear, queue and staff space;
gritty: steel bars over the counter where cash or bottles change hands, stock crammed on every shelf (with gaps where
something sold out), chairs that never matched, fluorescent tubes (warm light only in the bar and the diners), walls
that were white once, floors worn grey where people stand, notices on the walls (never over a window, never into the
ceiling, never over each other), hand-painted plates outside in faded colours; the pawn shop and the thrift store take
in everything (pawned bikes, gym benches, surfboards), laundromats have folding tables down the middle, the owner's
stool at the staff end of the counter.

## Numbers (GRT_NUMBERS; cloud measurements, NOT the phone)
Measured on the BAKED area (`bake_runtime.gd --area=-650,-1100,120 --nofarground`: the six cells of the pilot area, no
far ground, no rooms in the bake yet: docs/look_patches/rooms_bake.md), `rt_shots.gd` from the same 24 viewpoints (each
block from above, along its numbered street and along its Ave), before (samples + streets only) -> after:
- **Draws per view: 44-106 after (23-66 before).** Inside the phone's ~150 in every view.
- **Triangles per view: 386k-874k after (97k-236k before).** Over the ~500k mark in 16 of 24 views; worst along G Ave
  (874k, both sides filled). Per block the new pieces are no heavier than the sample's own (near buildings 14-27k
  triangles a block, sample 7-38k; near props ~75k a block, sample ~88k): the view total rises because every view now
  looks over filled blocks instead of empty ones. Yasin's rule: draws first, triangles are fine - but say it.
- **Download: the six baked cells grow from 15.1 to 28.0 MB (+12.8 MB, about 1.6 MB a block; a sample block with its
  streets bakes to ~2.5 MB), shared models (lib) +1.6 MB** (the car wash, the narrow houses, the garages ...). The
  blocks' ground is split only where the slope bends (3-6k triangles a block; 18k at a fixed 2 m grid).
- **Rooms** (25): as built 26-36 draws each; MERGED (tools/city/rooms/room_merge.gd, runtime/rooms, not in git) 7-9
  draws each (706 -> 221 for all 25, a room 28.2 -> 8.8); 4-5 real lights each (3 fixtures, the back room, daylight at
  the window), 9k-41k triangles. Still not in the streamed city (the bake knows no rooms yet).
- Yasin 18 Nov, "whats that thing flying there?": the counter bars were sized to the planned counter row and hung in
  the air; now a cashier's cage on the counter really placed, counter top to ceiling, posts to the floor, a pass-through
  slot at the till (shots/rooms_counter_cages.jpg).
- Validator CHECKS 0 problems (area 8,156 props; whole city 25,992+), trees 0 in hard ground, sink 0, indoor checker 0
  problems in the gritty rooms, lock test RESULT PASS. Nothing locked.
