# Industrial growth: variants and pilot area (18 Nov, branch claude/grow-industrial). LOCKED 19 Nov (Yasin: "lock them
# for now, rest will be handmade adjustments"): the 11 pieces and the 16 rooms.

Six new blocks around the locked industrial sample (`i_*`). Each one is one 100 x 100 m corner piece at a road-kit
junction. There are three VARIANTS, each built twice (two dressings), so no two blocks are the same. Every walk-in
place has its own room. Yasin decides: keep, change or drop each variant before any wider growth.

Pictures: `*_air.jpg` / `*_street.jpg` / `*_gate.jpg` / `*_edge.jpg` here, and the rooms in `rooms/` (`*_street.jpg`
by day, `*_street_night.jpg` in the evening, `*_in.jpg` inside from the door). Cloud preview: no shadows, the
weathered buildings drawn about 40 % too dark, and not taken in the new GTA IV look (the look needs the baked city;
see the job board).

## The pilot area (the cells it covers)
Grid frame (u along 10th St, v along Amber). The area is u -900..-500, v -1600..-1400: the strip between 1st St (the bay
boulevard) and 3rd St, from J Ave to the zone's east edge. Together with the sample, the superblock J Ave / G Ave /
1st St / 3rd St is now built on all four corners. It is the first time an industrial block has built neighbours
on every side.

| Piece | Where (u, v) | Variant |
|---|---|---|
| `i_va_w800_n1600_sw` | -900..-800, -1600..-1500 | A port, 1st dressing |
| `i_vb_w800_n1600_se` | -800..-700, -1600..-1500 | B fleet, 1st |
| `i_vc_w600_n1600_sw` | -700..-600, -1600..-1500 | C cold chain, 1st |
| `i_va_w600_n1600_se` | -600..-500, -1600..-1500 | A port, 2nd (edge to the houses) |
| `i_vb_w600_n1400_nw` | -700..-600, -1500..-1400 | B fleet, 2nd |
| `i_vc_w600_n1400_ne` | -600..-500, -1500..-1400 | C cold chain, 2nd (edge to the houses) |

Why this area: it is flat (pad 2 m everywhere, no slope pieces needed), and it is the zoning map's industrial
extension along the bay. It closes the sample's open north and east sides. The two blocks south of 3rd St at G Ave
would need sloped ground (G Ave rises 2 m there), so they wait. The 36 m strip by Alameda Blvd (west of the sample) is
not built yet either: it needs a curved edge.

## The variants
**A "port"**: Harbor Freight Station (containers stacked beside the yard crane, a devanning shed, a chassis line),
then Bay Boatworks (trailered boats in rows, three boats on the hard, a boat shed, a sail loft). Walk-ins: freight
office, ship chandlery, reefer-repair parts counter, the boatyard's broker office, a marine-engines parts counter.
Unused kit it brings in: **dock crane**, **18 in cones**, **rubber wheel stops**, **stucco wall**,
**bougainvillea wall**, **torrey pine B**, transformer substation (crane feed); also boats, buoys, dock boxes, kayak
rack and life-ring stand on land.

**B "fleet"**: the City Yard (the town's trucks overnight, diesel island, a fleet wash, a row of lock-ups), then 3rd
St Truck Services (a truck wash, tyre store, heavy repair, diesel, drivers' cars along the back wall, a billboard to
3rd St). Walk-ins: public works permits counter, a workwear store, the truck-stop diner, a truck-parts counter.
Unused kit: **car wash** building (as fleet and truck wash), **single garages flat / clay** (lock-ups), **iron
bollards**, **fuel pumps** off the waterfront, **rubber wheel stops**, **stucco wall**, temp-fence screens.

**C "cold chain"**: Pacific Seafood + Bay Ice Plant (fish market and lunch counter on the corner, packing hall, cold
store, plugged-in reefers, ammonia tanks behind barbed wire, the ice plant's water tower), then 3rd St Food Wholesale
(a shift canteen, restaurant cash and carry with a customers' lot and cart corral, a produce hall, a meat packer).
Walk-ins: fish market, seafood sales office, the canteen, the restaurant supply counter, a uniform laundry.
Kit it uses: ice chests, shopping carts + corral, vending machines, **stucco wall**, **bougainvillea wall**,
**torrey pine B**, steel bollards.

## Planner's rules followed
- **Every edge measured.** Each block reads the street pieces around it before laying its ground, so it meets the
  sidewalk flush (14.31 m on 1st and 3rd St, 8.70 m on the truck avenues, 3rd St's taper by J Ave followed). Every truck
  gate sits on one of the street's own aprons. 1st St (the bay boulevard) has no aprons, so it gets no truck gates:
  offices, counters and shops face it.
- **Toward the houses (u -500):** a stucco wall, bougainvillea on the house side, and a grass strip with torrey pines
  and eucalyptus. That is a yard and a planted edge, not a hard jump. These are the two quietest variants
  (boatyard, food wholesale).
- **Fences and the phone (layered see-through):** no chain-link stands behind another chain-link on a sight line.
  - The boulevard frontages are block or stucco walls, which are opaque.
  - Edges shared with the sample use the sample's own fence; nothing is doubled.
  - Edges shared between two new blocks get ONE wall, built by one of them.
  - Chain-link only where seeing through is the point: J Ave at the city yard (security), the boatyard's boulevard
    front (the boats are the shop window), and the avenue frontages between buildings, as in the sample. Behind
    each of these stand opaque sheds, walls or containers.
  - Barbed chain-link is used once, round the ammonia tanks.

## The rooms (14, all new; generator `tools/city/rooms/room_gen_ind.gd`, list `tools/city/rooms/assign_ind.py`)
Industrial character, unlike the high street's rooms: sealed concrete or quarry tile, drop-in ceilings, cool
fluorescent strips, steel shelving, pegboard and workbench behind the parts counters, filing cabinets, vending
machines, and stock on the floor (cones, drums, gas bottles, ice chests). Indoor checker: 0 problems in these 14 rooms (the
last run loaded 219 rooms city-wide; its only 5 problems are in a strip-growth room, g_strip_*, another session's). Each room has 2-6 real lights (the fixtures plus daylight at the window).

What is honestly weak:
- The kit's shelves and gondolas are EMPTY (no goods models), so the stores look bare.
- The fish market has too many dining tables for a fish counter.
- (fixed 18 Nov, Yasin: "something blocking the door", "overlapping props") the diner and the workwear store first stood
  in `ck_grt_row2`, a gritty model whose painted windows overlap its own side door and whose storefront band (room
  library) ran across the shop door. They are now in `ck/mod_fastfood` and `ck/ck_svc_pawn_fast` (real shopfronts,
  the room behind both doors). The diner's bin stands at the corner, 3 m past its door; the paper box is gone.
- (fixed 18 Nov, Yasin: "most shelves are empty") the kit's `wall_shelf` and `gondola_aisle` are empty models; the
  rooms now use only stocked shelving (steel racking with goods, boxed stock), aisles as back-to-back pairs.
- The wear on the floors is light.

These are first drafts for Yasin's word.

## Numbers (cloud, 18 Nov; NOT a phone)
The area was baked twice with the runtime bake (`--area=-700,-1500,320 --nofarground`, same everything else):
without and with the six blocks. Then the same eight views were measured with `rt_shots.gd` (pictures
`baked_base_*.jpg` / `baked_ind_*.jpg` here). Draws and triangles are renderer facts and valid on the cloud. Times
are not.

| View | Draws before -> after | Triangles before -> after |
|---|---|---|
| 1st St at J Ave, looking east | 36 -> 62 | 211k -> 295k |
| 1st St at G Ave, looking east | 34 -> 41 | 166k -> 232k |
| G Ave mid-block, looking at 3rd St | 50 -> 66 | 268k -> 368k |
| 3rd St at G Ave, looking west | 62 -> 70 | 322k -> 387k |
| 3rd St at G Ave, looking east | 33 -> 39 | 174k -> 245k |
| J Ave mid-block, looking at 1st St | 25 -> 38 | 119k -> 238k |
| in the freight yard | 20 -> 28 | 100k -> 186k |
| 30 m up over the seafood block | 48 -> 78 | 275k -> 363k |

Every view stays well inside the phone budget (150 draws, about 500k triangles in view); the worst is 78 draws, 387k
triangles. The sample's own range is 85-120 on the phone with its rooms and lights; these figures are the bake's,
without rooms.

**Download:** the six blocks add **about 5.8 MB** to the baked data. That is +5.0 MB in the three cells they lie in
(cell_-3_-8 1.4 -> 3.2 MB, cell_-4_-8 1.8 -> 3.5 MB, cell_-5_-8 3.3 -> 4.8 MB), +0.6 MB of shared models (lib) and
+0.1 MB of far tier.

**Rooms are NOT in the bake yet** (the bake knows no rooms; `docs/look_patches/rooms_bake.md`). As built, one room is
21-36 draws and has 4-6 real lights. A street view that sees 2-3 of these rooms within 62 m would add 50-100 draws
unmerged, which goes over 150. They need the merge step (`tools/city/rooms/room_merge.gd`, prototype: about a fifth)
and the light budget proposed in rooms_bake.md before they go on the phone.

## Checks (the industrial area, with every neighbour loaded)
Validator **0 problems**, trees **0 in hard ground**, sink **0**, indoor checker **0 problems** (all 176 rooms), lock
test **RESULT PASS**. The city-wide validator also lists problems in the gritty edge growth blocks (g_v*, another
session's work); none of them are in these blocks.

## Polish pass and the new indoor props (18 Nov, Yasin: "did you replace the props? ... run a polish pass on your part,
## lots of props ... think like an interior and exterior designer, customer and city planner")
- **New indoor props:** commit 9fce731 (`claude/kit-indoor-props`, the assets branch's dd8d53a) taken. All 14 rooms
  were rebuilt with them. The kit's wall shelves and aisle gondolas are now stocked, so they are back in the rooms.
- **Rooms:** each kind gets what its staff and customers still lacked, on free wall space. Examples:
  - permits counter: a water fountain, benches, brochure racks, a snack machine
  - parts counters: gas bottles and cones for sale, a display table
  - workwear store: a fitting room, boot bench, mannequin
  - canteen and diner: vending machines, fridges
  - every room: safety and notice boards on walls with nothing in front of them, plants and bins
  Indoor checker 0 in these rooms. Pictures: `rooms/`, retaken.
- **Outdoors:** each block got a polish list, every item with its reason in the script. Each item goes in a zone
  chosen for its purpose, and a careful placer (`ind_grow_lib.place`) sets it only where it clears buildings, doors,
  other props, truck lanes and parked cars.
  - stop signs at every yard exit
  - fire hydrants by the big sheds
  - workers' break spots (picnic table, bench, bin, vending machine)
  - the city yard's stock of new household bins and the signs crew's spare signs
  - mooring buoys waiting for the season, antifouling drums by the boats
  - the canteen's outdoor tables, carts left at the cash-and-carry
  - wash-down hoses at the fish and ice doors
  Pictures: `polish_*.jpg`. Area checks: validator 0, trees 0, sink 0.

## The whole zone (19 Nov, Yasin: "find mistakes ... fix them ... roll out to your whole zone, then do a polish pass on
## the whole zone")
The industrial zone is now built everywhere the city kit reaches it (west of it the naval air station stays as it is):
| Piece | Where (world u, v) | What |
|---|---|---|
| `i_vb_w600_n1400_sw` | -700..-600, -1400..-1300 | Island Movers + self storage (B fleet, 3rd dressing): office on 3rd St (walk-in), storage sheds and lock-ups, van park; on G Ave's slope |
| `i_vc_w600_n1400_se` | -600..-500, -1400..-1300 | Coronado Brewing Co. (C cold chain, 3rd dressing): taproom (walk-in) with a beer garden, four fermenters, brewhouse, keg store; house buffer; on the slope |
| `i_va_w951_n1400_ne` | -951..-900, -1590..-1414 | the freight station's empties depot (A port, 3rd dressing): long container stacks, reached by a new gate in the freight station's wall; wall follows the ring's corner |
| `i_green_w951_n1400_se` | -951..-900, -1386..-1300 | Alameda Green: the district's fenced lunch green (one gate, trees, tables, benches, fountain) |
| `i_life_w800_n1400` | the locked sample | a life overlay (the sample stays untouched): stop signs at the yard exits, hydrants, break spots, bins, bike racks, work clutter, placed only where free |
New library parts: row-measured floors for odd shapes, a Coons-patch drape onto sloping streets with level pads under
the buildings, and a careful placer for polish props.

**Mistakes found and fixed on the way:**
- Back-of-house meters, boxes and AC units on doors and in front of rollups (Yasin's pictures). Services now keep
  off every back door, rollup and window.
- A building on the slope sunk at the back ("shop is sunk"). It now stands on a level pad that eases into the slope.
- Benches standing beside picnic tables ("stray bench"). Gone from every break spot; benches only face a path or green.
- A wall floating off the ground on the slope ("wall bulges off the ground"). Each wall or fence panel now stands
  at the lowest ground along its length.
- Meters on a window ("prop sitting on a window"). Wall items keep 0.9 m off every window, because the painted
  window is wider than its recorded opening.
- A hydrant in the middle of a yard ("fire hydrant in the middle of nowhere"). Hydrants now stand only within 2 m
  of a building wall.
- Dark patch decals reading as shadows of nothing in the yards. Now narrow trench repairs.
- The green's fence clipping the kerb return, walls tight against the gritty block's props, a skip against a wall,
  two overlapping tanks.
- **Seen in the LOCKED sample and NOT changed** (needs Yasin's word to unlock): the same shadow-like dark patches in
  its yards, and possibly the same back-of-house items in front of doors and rollups.

Checks over the whole zone (all neighbours loaded): validator 0 problems (about 8,300 props, 200 buildings), trees 0
in hard ground, sink 0, indoor checker 0 for the 16 industrial rooms, lock test RESULT PASS.
Not re-measured: the baked draws / triangles / download for the new pieces (only the pilot six were baked and measured).
