# West fill (University session, 20 Nov) - BUILT, SUPERCHECKED, LOCKED

Yasin (relayed by the coordinator, then in this session): populate the University share of the empty map (23 blocks,
review/fill_assignment_20nov.json "university", plus three spots he marked), as architect, planner, interior and exterior
designer, to the land, plenty of props and life; then the superchecker (indoors and outdoors) over everything, fix (be
prone to delete), lock. Plan: PLAN.md. Map of the share: university_blocks_yellow.png.

## What is built (48 pieces, own table review/grow_uw_blocks.json for integrate.py)
- Industrial east halves: n_w_i1 marine trades (boatworks, marine engines, marine supply, fenced storage yard), n_w_i2
  builders' yard, building supply, RV and boat storage, tire & brake, liquor & deli.
- Gritty edge: n_w_g1 the Anchor bar, walk-ups, coin laundry, thrift row, townhouses, corner market, lots, vacant lot.
- North of the campus (students): n_w_s1 student apartments and the gate strip (pizza, cycles, pub, housing office),
  n_w_s2a Campus Market and apartments with a sand volleyball court, n_w_s2b student strip and pub, n_w_s2c pocket park.
- Civic and stadium band: n_w_c1 fire station, post office, church; c2 civic park (playground, dog run); c3 staff
  townhouses and senior center; c6 faculty apartments and child care; c7 tennis and volleyball park; c8 team store, sports
  bar, diner, tailgate lot; c9 and c5 Amber Avenue shop rows; c4 stadium promenade; c10 / c11 fan plazas with kiosks;
  h1-h4 the stadium lot's four 40 m holes (tennis x2, playground, picnic grove); p1 memorial green, p2 succulent garden,
  q2-q4 small gardens and a playground in the civic heart's holes.
- West strip (Country Club Ridge): n_w_w3-w6 house blocks (pocket park, Ridgeview Elementary, cottage court, Ridge
  Community Church), n_w_w7 Ridge Park with its overlook, n_w_w2a apartments, w2b community garden and playground,
  w1 nursery, w0a green buffer, w0b allotments (Yasin's north spot); n_w_x1 lane houses.
- South-west edge: n_w_e1-e4 beach-side houses, a surf shop and a beach café, e1b a beach pocket.
- Yasin's spots: w0a/w0b (north), q1 (the square in the 51 % block), p2 (east of the 18 % block).
- Trees: t_w_north / civic / strip / edge, 209 hand-placed by docs/TREE_PLAN.md's rules (OUT/trees_w.py).
- Rooms: 43 (shops, civic, schools, churches); homes, kiosks and the fire station (its model has only bay doors) not
  entered.

## Elevation
Every piece's ground follows the land 8 cm over it and eases over 8 m to the measured height of whatever borders each
side (walks, other blocks; measured every 2 m); buildings on level pads at the highest ground under them. The land is
written ONLY inside these pieces (27,876 nodes, -0.18..+0.50 m); the 38,875 nodes the fit also wanted elsewhere were not
written. Game land baked.

## Superchecker (four rounds, indoors and outdoors; final round)
- Indoors: check_rooms 0 problems in 43 rooms.
- Ground: ground_check 0 buried, 0 hanging, 0 steps, 0 under for the 44 ground pieces (against the land and every
  neighbour).
- Outdoors: validator 0 lines naming the west pieces; check_life 0; audit_trees 0 in hard ground; sink_check 0; own audit
  (every prop against its own ground, seats and play on asphalt, bins more than 1.5 m from any wall or fence) 0.
- Deleted rather than risked: the ring road's sound walls (their ends met nothing), meters and AC on houses (fences,
  windows), 19 bins and dumpsters in the open, a bench on asphalt, carts, the gritty half's board fences and wall, the
  pocket park's wall, lamp and rack (clashed with the gritty lot), the succulent garden's path and furniture (the civic
  heart's own trees and bench stand in that hole), trees near neighbours. Fixed in the helper: fence panels flush with
  the run's ends.
- Lock test: RESULT PASS (604 locked pieces).

## What the checks cannot see / not done
- Tree crowns against walls and fences (trunks only); the builder tests a prop's centre against walls.
- Rooms: whether each has everything its kind needs (by eye); no pictures were made in this pass (Yasin: fill fast).
- Not filled: two irregular slivers along the ring road's curve in the block u -1000..-800, v -1200..-1000
  (about 3,800 + 2,900 m2), and a few strips under 20 m wide; the land outside the ring (south of v ~300) was not in the
  assignment.
- Not integrated into city_grid_layout.json (the coordinator merges grow_uw_blocks.json).
