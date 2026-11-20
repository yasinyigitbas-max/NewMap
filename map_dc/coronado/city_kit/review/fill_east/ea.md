# ea: the east shore north of v -1100, beyond the ring (20 Nov)

Builder "ea" for the east shore (SHORE_GUIDE.md + BUILD_GUIDE.md). Yasin: "FILL THAT RED AREA WITH GRASS > SAND AND
BEYOND IT SHOULD BE THE SEA, PUT LOTS OF RELEVANT PROPS IN THAT AREA, MAKE THE SEA SAND CONNECTION SEAMLESS AND BUBBLY
LIKE THE WATERFRONT AND AROUND THE ISLAND". Drafts: NOT committed by me, NOT locked, NOT in `city_grid_layout.json`.
Nobody has looked at a picture of any of it: no shots were taken.

## The area (measured, read-only: OUT/fill/ea/area_poly.py, split.py, site_data.py, edges.py)
All land with no piece between the ring's outer walk and the sea, v -1700 .. -1100, out to 25 m past the 0 m line (the
sand goes on under the water to there; depth there -2.0 m). West end: u 516 = the east edge of the u 500 ring junction
(north of the ring the shore runs on west: not mine). The bridge roads (s_br_ramp_1..5 from the v -1400 ring junction,
s_br_appr_1..4 from the v -1200 junction: never touched) cut it into four pieces. 169,400 m2 in all.
No street here has an apron (legs_measured.json: none on the ring north of -1100 nor on the bridge roads), so no car can
come in: NO car parks (the guide's "a small car park or two" was impossible without a new driveway); people come on foot
and by bike from the two ring junctions' corners and along the ring walk (bike racks at the entries).
Land: 2.0 - 2.1 m along the ring north of -1400, falling to the sea over 60 - 200 m; 2 - 5 m in the lens and the south
strip; the shore piece rises to a 5 m crest by the bridge (u 925 - 945, v -1200 .. -1100). Every street walk round the
area is 4.9 cm or more over the land at its edge.

## Pieces (all at grid pos [0, 0, 0], yaw 0: x = u, z = v, y = world height; scripts in tools/city/pilot/pieces/)
| Piece | Where | Plan in one line |
|---|---|---|
| `n_ea_cape` | v -1700 .. -1460, ring bend to the sea | NORTH BEACH: the Commons forecourt at the u 500 corner with NORTH BEACH RENTALS (kayaks, boards; racks on the sand) and NORTH BEACH CAFE (terrace); the promenade along the dune (lamps, bench pairs); 4 boardwalk accesses with showers; picnic tables + grills on the grass band; on the wide sand 2 volleyball courts, 3 lifeguard towers with life rings, rip signs, umbrella groups |
| `n_ea_shore` | v -1460 .. -1100, seaward of the ramp | BRIDGE BEACH: the entry at the v -1400 junction's NE corner (bike racks, water, rules); the promenade on along the ramp to -1100; BRIDGE POINT SCOOPS (ice cream, forecourt tables); the CREST LOOKOUT (level deck, rails, benches) on the high ground; picnic tables + grills; 4 accesses (3 boardwalks, 1 paved path) with showers; 2 volleyball courts on the wide north sand, 3 towers, umbrellas, the fenced DOG BEACH at the south end (gate, dog rules, water, bin) |
| `n_ea_lens` | between the ramp and the approach | BRIDGE MEADOW: the meadow walk joining the two junction corners (lamps, bench pairs), a fenced playground (sand pad, 3 play items together, parents' benches, bin at the gate), a picnic grove, the bandstand on its pad with benches facing it, open lawn |
| `n_ea_south` | south of the approach to v -1100 | APPROACH GREEN: the green walk from the v -1200 junction's SE corner toward eb's land, lamps, bench pairs, two picnic tables (one under a sail), lawn |

Shared file `n_ea_site.gd`: the outlines, the walk edges with their measured heights, the 0 m line, the dune line, the
promenade, and `g(u, v)`; land table `n_ea_land.gd` (export_land_patch.py). Ground tris: cape 25.7k, shore 36.9k, lens
22.3k, south 7.8k (2 m global grid cut to the outline and to every path / pad polygon). Props (with decks, fences):
110 / 241 / 125 / 18; buildings 2 / 1 / 0 / 0.

## Ground: grass > sand > sea, seamless (how)
- `g`: the land + 5 cm; the 5 cm eases to 0 within 10 m of the 0 m line (distance to shore_foam.json's own line) and is
  0 where the land is under 0, so the ground's 0 m contour IS the land's; within 12 m of a street walk eased onto the
  walk's measured height keeping the land's shape. The sand runs on under the water to 25 m past the line.
- Grass > sand: the hand-drawn dune line `n_ea_site.DUNE`. North of v -1400 the land is only 2 m at the ring, so the
  guide's "grass above ~2.5 m" would leave no grass: there the line keeps a 30 - 50 m park band (about the 1.4 m
  contour) and the beach is wide (60 - 160 m); south of -1380 it follows the 2.0 - 2.6 m contour. The cells are cut
  exactly on the curved line (no 2 m staircase), iceplant and agave along it. NOT a 3 - 6 m blend: the kit has no blend
  material and the superchecker removes grime / sand-tint marks on grass or sand (TILE_OK), so no blend decals.
- Buildings, the lookout, the playground and the bandstand on level pads at the highest ground under them, the field
  graded up to them at 6 %; skirts under the free edges (v -1700, u 516, v -1100).

## Seam with eb at v -1100 (my edge heights, world m; my ground stops exactly at v -1100)
The edge is `g` = land + 0.05 except within 12 m of a street (eased to the walk) and 0 lift within 10 m of the water:
u 675 4.175 | 700 4.330 | 740 4.403 | 780 4.471 | 820 4.723 | 860 4.955 | 880 5.104 (approach walk) | 930 5.314 (ramp walk)
| 960 4.461 | 1000 3.172 | 1040 1.631 | 1060 0.753 | 1080 -0.599 (= land, under water) | 1095 -1.733. The promenade
(3 m, plaza, centre u 960.9 at v -1100) and the green walk (3 m, centre ~u 849.6) reach the edge; the dune line crosses
it at u 1003; sand from there to the edge of the water and 25 m on. Formula, land table and lines are in n_ea_site.gd.

## Superchecker (`FW_AREA=OUT/fill/ea/area.json python3 -I OUT/fill/fw/sc_fw.py check <piece>`; the branch's sc_lib has no SC_LAYOUT)
First pass found little: bin_open 2 (cafe bins 1.4 m from its wall: moved to 0.6 m, one plainly safe spot), no_reason 3
(the three play items 6 m apart: drawn 4.2 - 4.5 m apart so they read as one play area), column_no_collision 3 (boxes as
measured, `const SC`). Nothing was deleted outdoors: no item had a finding left. Rooms (`OUT/fill/ea/rooms_ea.sh` =
rooms_and_trees.sh through the wrapper): every open "choose" line erased, PROOF RESULT PASS, install-room for the three:
5 items deleted (cafe: kitchen line in front of the side door, drinks fridge behind a window; rentals: 2 wall shelves
in front of the back door; scoops: drinks fridge behind a window). Final check: only report-only kinds (wide_batch,
empty_area, edge_step, ground_low = sand under 1.35 m beside the sea, by design) and room report-only kinds (shop_lacks,
sign_wrong of the kit's painted signs, staff_door_off). After exact_colliders.gd the checker would report no_collision
again (its known blind spot); colexact_verify is the proof below.

## Checks (area layout OUT/fill/ea/area.json: 49 shared rows round the area + 4 pieces "grow_ea" + 4 tree pieces "trees")
| Check | Result | Cannot see |
|---|---|---|
| validate.gd | 0 problems (whole area) | heights, land, whether a prop makes sense |
| check_life.gd | 0 on ea pieces (51 in the area, all in m_ne / m_nw / m_se / m_sw); LIFE_INFO lens play items 3 | everything but its kinds |
| audit_trees.gd | 76 trees in the area, 0 in hard ground | - |
| check_rooms.gd --only=g_ea_ | 0 problems, 3 rooms, every floor cell reachable | whether a shop has what it needs |
| 0 m contour vs shore_foam.json (OUT/fill/ea/foamseam.py) | 792 m of contour; both ways median 0.007 m, p95 0.03, max 0.139 m (at u 894, v -1466): 100 % within 0.3 m | the foam's look; the sea mesh itself (8 m texels) |
| seams (OUT/py/seams.py, 0.25 m) | every walk of the ramp, approach and junctions within 1.1 cm; ring bend (s_rg_nw_b163_1..3) +3.3 .. +3.8 cm over 2 - 4 m per piece (mine higher, at the curve); lens wedge tip at s_br_ramp_1 (u 916.6, v -1104.4) -8.8 cm over 1.2 m; cape / shore seam 1.6 cm | faces, looks |
| land over my ground (OUT/py/buried.py, 1 m) | 0 cells over 3 mm (10,659 cells within 3 mm: the water band where the lift is 0 by design) | - |
| grade (OUT/py/grade.py) | median 1.7 %, p99 7.8 %, 0.10 % over 8 % (pad faces, the ease onto the bridge walks) | - |
| ground overlap (OUT/py/overlap_new.py, 1 m cells) | 1 - 4 cells with each of 7 street pieces along shared edges (the outline's 2 - 3 cm simplification) | - |
| sc.py trees | 4 lists ok after thinning for the in-view limit (17 -> 12 at the ring bend: hp_main's and the ring's own lists fill it) | - |
| exact colliders + colexact_verify | 8 files, largest gap 0.1 mm, 0 colliders without a prop; without by design: sprinklers, iceplant | - |

## Trees (hand lists `zoning/trees/ea_{cape,shore,lens,south}.json`, pieces `t_ea_*` at [0, 0, 0])
29 trees: cape 4 (the Commons' canary palm, a coral at the picnic tables, a palm and a torrey pine at the north end),
shore 13 (8 promenade palms, a clump of 3 at the picnic grass, 2 queen palms at the ice cream forecourt), lens 8
(playground clump 3, picnic grove 3, bandstand 2), south 4. None on the sand below the dune line. The cape lost 8 of
its 12 (promenade palms) to the in-view limit at the ring bend.

## Files (all ea)
`tools/city/pilot/pieces/n_ea_{site,land,cape,shore,lens,south}.gd`; `pieces/n_ea_*.scn`, `t_ea_*.scn`;
`tools/city/rooms/assign_ea.py` -> `interiors/assignment_ea.json`, `rooms_ea_report.json`, rooms `g_ea_cape_rent_0`
(North Beach Rentals, sport), `g_ea_cape_cafe_0` (North Beach Cafe, cafe), `g_ea_shore_scoops_0` (Bridge Point Scoops,
ice_cream); the room fixes' logs install-room wrote in `review/superchecker/g_ea_*`; scratch in `OUT/fill/ea/`.

## Not done / for the coordinator
- No picture taken or opened: nothing here has been looked at. Not committed by me (the coordinator's WIP commit
  912ddf09 caught earlier copies of the .scn files; the files now on disk are the final ones, exact colliders patched
  in place: a rebuild from a script drops them). Not locked, not in the shared layout, no bake, no phone.
- No car park (no apron anywhere round the area). No fire rings (no kit prop). No towels and no worn footpaths on the
  sand: as marks they would be on sand, which the superchecker removes. No buoys offshore (they would stand off my ground).
- The grass > sand edge is an exact curve with dune plants, not a 3 - 6 m blend.
- West end at u 516 and the v -1700 line are my choice of edge (land goes on north and west there); skirts close them.
- The lens wedge tip by s_br_ramp_1 (u 911 - 917, v -1104 .. -1100) is a 0 - 6 m sliver of lawn; 8.8 cm step there.
- The volleyball courts are nets on plain sand (no court lines).
