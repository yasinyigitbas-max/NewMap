# eb fill: the middle of the east shore beyond the ring (v -1100 .. -500), 20 Nov

Builder "eb" under the coordinator (BUILD_GUIDE.md and SHORE_GUIDE.md in this folder). Yasin: "FILL THAT RED AREA WITH
GRASS > SAND AND BEYOND IT SHOULD BE THE SEA, PUT LOTS OF RELEVANT PROPS IN THAT AREA, MAKE THE SEA SAND CONNECTION
SEAMLESS AND BUBBLY LIKE THE WATERFRONT AND AROUND THE ISLAND". These are drafts. I did not commit them, did not lock
them and did not add them to `city_grid_layout.json`. Nobody has looked at them from eye height: the only picture
is a top view by material (`OUT/fill/eb/top.png`).

## What the measuring found (read-only; `OUT/fill/eb/edges_eb.py`, `site_data.py`, from OUT/g_city, terrain_grid.npz)
- The ring's east walk edge runs from u 674.3 (v -1104 .. -999.5) to u 667.6 (v -497.6). Its height is 4.150 all
  along, 5.2 - 10 cm over the land. That side of the ring has no apron, no leg and no driveway, and the bridge
  approach has none either (legs_measured.json). So **no car park could be made**: no existing apron or road
  reaches this land. People come on foot or by bike, across the ring's junctions at v -1000, -800 and -600.
- **The bridge approach** (s_br_appr_3 .. 6, off-ramp s_br_ramp_1) crosses the north of the area from u 872, v -1112
  and ends at u 1180, v -922 .. -893. No deck is built beyond that end. Its edges stand 5 - 21 cm over the land.
  East of u 1180, between v -930 and -885 (where a deck would carry on), only the promenade passes and no prop stands.
- The land falls from 4 - 7 m to the sea. On the bluff (u 1150 - 1240, v -960 .. -860) it falls by up to 15 %.
  Elsewhere it falls by 1 - 8 %.

## Pieces (all at grid [0, 0, 0], yaw 0: x = u, z = v, y = world height; `"from": "grow_eb"`)
| Piece | Area | Plan (one line) |
|---|---|---|
| `n_eb_nw` | ring .. u 960, v -1100 .. -800, less the bridge and the land north-east of it | RINGSIDE MEADOW: the Ring Gate loop from the -1000 junction and the Meadow Walk from the -800 junction, two picnic groves with grills, benches in pairs, lamps, a fountain, bike racks |
| `n_eb_sw` | ring .. u 960, v -800 .. -500 | GLORIETTA MEADOW: the Glorietta Walk from the -600 junction, the Meadow path, a BANDSTAND with benches, two picnic groves, the KNOLL LOOKOUT (level railed terrace on the 6 m knoll, benches to the sea) |
| `n_eb_ne` | u 960 .. the sea (+ the land north-east of the bridge), v -1100 .. -800 | BRIDGE BEACH north of the approach: a fenced DOG BEACH with a gate, the BRIDGE BEACH SNACK SHACK (com_kiosk) and its tables, a beach access with a shower, the north lifeguard tower, a life ring, a rip sign, umbrellas and a volleyball net. THE BLUFF south of the approach: a path to the BLUFF OVERLOOK (railed terrace), a beach access with two fenced dune plots and bins, the second tower, umbrellas |
| `n_eb_me` | u 960 .. the sea, v -800 .. -650 | MIDDLE BEACH: the BAYSHORE BEACH CAFE (com_cafe_seaside) with a terrace under sails, a beach access with dune plots and bins, two volleyball courts, the third tower, umbrellas and loungers, lawn groves |
| `n_eb_se` | u 960 .. the sea, v -650 .. -500 | SOUTH BEACH: the Glorietta Walk reaches the promenade at the south access, BAYSHORE PADDLE HIRE (com_surf_shop) with kayak and board racks out front, three volleyball courts, the fourth tower, umbrellas and loungers, lawn groves |

All four beach pieces share the PROMENADE: 3 m of paving, 8 m in from the dune line on the grass, with lamps on its
land side. Scripts are `tools/city/pilot/pieces/n_eb_*.gd`. The shared site file is `n_eb_site.gd`: edges, lines,
the ground rule, the painter that cuts every cell exactly to the edges, the dune line and the paths, and closed
fences with one post at each joint. The land table is `n_eb_land.gd`. Ground triangles per piece: nw 11.8k,
sw 11.6k, ne 13.2k, me 8.6k, se 9.8k. Props per piece after the checks: 37 / 105 / 358 / 125 / 147, counting fence
panels and posts.

## Ground: grass > sand > sea, and the seam with the water
- The ground is the land + 5 cm. The 5 cm eases to 0 (smoothstep) over the last 10 m before the 0 m line (`ZERO`,
  read from the foam line). On the water side it is the land itself, and it runs on under the sea to `SEA_LIM`,
  40 m along u past the 0 m line (at least 25 m along the shore's normal). Within 12 m of the ring's walk or the
  bridge's edge it is eased onto that edge's height while keeping the land's shape, as in n_fe_site.
- Every whole 4 m cell is split along the diagonal whose corners stand higher together. That keeps the flat
  triangles from dipping under the land's own bilinear surface where the ground equals the land (at the water).
- **Grass > sand**: the `DUNE` line is the land's 2.5 m line, read scanning in from the water, smoothed over 36 m and
  given a gentle hand wave of +-2.5 m. Cells crossed by it are cut exactly along it, so the edge has no staircase.
  There is no texture blend: the kit has no blend material and no wear decal is allowed on grass or sand. Ice
  plant patches and agaves sit on the dune edge instead. The sand is 26 m wide under the bluff and up to 278 m in
  the south.
- **Edge heights for the neighbours**: same rule. At v -1100 the ground is 4.150 at the ring (u 674.3), 4.62 at
  u 800, 3.17 at u 1000, 0.007 at the waterline (u 1072) and -2.68 at its end (u 1112.5). At v -500 it is 4.152 at
  the ring (u 667.7), 6.75 at u 880 (the knoll), 2.56 at u 1125 (the dune), -0.014 at u 1402 and -2.68 at its end
  (u 1441.5). The promenade crosses v -1100 at about u 1011 and v -500 at about u 1118.
- **Seams with ea and ec** (both their pieces dumped beside mine, `OUT/fill/eb/seam_nb.json`): n_ea_shore 173 m and
  n_ea_south 208 m largest 1.0 cm; n_ec_beach_n / dune_n / hill_n 227 / 268 / 264 m largest 0.9 cm. No ground
  overlap.

## Checks (area layout `OUT/fill/eb/area.json`: the shared rows round the area + 5 pieces "grow_eb" + 5 tree pieces "trees")
| Check | Result | Cannot see |
|---|---|---|
| validate.gd | 0 problems (1,866 props, 17 buildings in the area) | heights, land, sense |
| check_life.gd | 0 lines on eb pieces (10 in the area, all m_se / s_ / j_) | everything but its kinds |
| audit_trees.gd | 77 trees, 0 in hard ground | - |
| check_rooms.gd --only=g_eb_ | 0 problems, 3 rooms | whether a shop has what it needs |
| seams (OUT/py/seams.py, 0.25 m) | every shared edge within 1.0 cm (ring walks, junctions, bridge sides, eb\|eb, ea, ec). The exception is the approach's end at u 1180: 1.0 m "kerb-like" 15 cm, its verge \| road kerb | faces, looks |
| land over my ground (`buried_eb.py`, 1 m, > 1 mm) | above water: 0 cells in all five. Under the sea: ne 353, me 70, se 10 cells, at most 3.8 cm, in the cut cells at the sea limit 20 - 40 m out | under-water looks |
| sand's 0 m contour vs zoning/shore_foam.json (`waterline.py`) | 725 foam points: p50 3.7 cm, p95 11.7 cm, **max 21.1 cm** (u 1234, v -970); 0 over 0.3 m | the foam shader's look |
| grades (OUT/py/grade.py) | p99: nw 2.4 %, sw 3.8 %, me 7.5 %, se 8.0 %, ne 12.4 % (the bluff's land itself, 6 % of its cells over 8 %) | - |
| ground overlap (OUT/py/overlap_new.py) | 0 m2 | - |
| superchecker outdoors | only report-only kinds left: wide_batch, empty_area, ground_step (sw 4 m at the lookout's corner, ne 30 m on the bluff by the promenade, both <= 7 cm. Not looked at; probably a T-joint between my cells on a steep slope, since the checker reads heights 0.6 m apart), edge_gap (nw 1 m at u 881, v -1100: the bridge corner on the north seam) | whether a place reads well |
| sc.py trees | eb_nw 10, eb_sw 10, eb_ne 12, eb_me 10, eb_se 10: all ok, in-view at most 11 of 12 | - |
| exact colliders + colexact_verify | 10 files, largest gap 0.2 mm, no collider without a prop. Sprinklers and ice plant have none, by design | - |
After exact_colliders.gd the superchecker reports no_collision / column_no_collision again, because it does not
read PropColExact (the known blind spot). The numbers above were taken before that step. colexact_verify is the
proof.

## What was deleted or changed by the checks
- Superchecker: the snack shack's 2 bins (trash, recycling) stood in front of its window ("opening"). They were
  deleted in the script's `SC` list. One column box each was added to the cafe and the paddle hire.
- check_life ("fence end leads nowhere", 30 ends): every open fence run went.
  - The ring-gate rails went (nw 3, sw 2), and with them their 6 bins: a bin in the open is a fault. The gates
    keep their racks and lamps.
  - The dune fences and dog-beach fences became closed shapes: two fenced dune plots at each access, with ice
    plant inside and the bins against them, and the dog beach fenced all round with a 3 m gate.
  - The lookout rails now go all round their terraces, with an opening where the path arrives.
- The lint pass (`OUT/fill/eb/lint.py`) moved 4 plants, a bike rack and a table with its sail off the promenade before the first build.
  One ice plant patch was deleted because it stood on the dog-beach fence line.

## Rooms (`tools/city/rooms/assign_eb.py` -> `interiors/assignment_eb.json`, room_gen_hp.gd)
`g_eb_ne_kiosk_0` Bridge Beach Snack Shack (cafe), `g_eb_me_cafe_0` Bayshore Beach Cafe (cafe), `g_eb_se_hire_0`
Bayshore Paddle Hire (sport). check_rooms: 0 problems.
- **Not installed:** the superchecker's proven room copies are in `OUT/super/work/g_eb_*.scn` (PROOF RESULT PASS
  for all 3). They each delete the items the checker could not place, 6 in all:
  - the kiosk's drinks fridge behind its window;
  - the cafe's kitchen line in front of its back door, and its drinks fridge behind a window;
  - the hire shop's two wall shelves in front of its back door, and a surfboard rack behind a window.

  I did not run `sc.py install-room ... --by=Yasin`: that is Yasin's word, not mine. The coordinator can install
  them. The room files in `interiors/rooms/` are still the generated ones.
- Report-only room findings: the kiosk has a house-type door (shop_house_door), plus shop_lacks 3, sign_wrong,
  window_empty. The cafe and the hire shop have staff_door_off, and the hire shop has sign_wrong 4.
- The kiosk's contract door is "residential", so assign_all.bays() finds no shop door in it. assign_eb.py uses the
  whole floor as the room, as the waterfront's and campus kiosks do.

## Not done / not seen
- No picture from eye height and no bake. Nobody has looked at the umbrellas, towers and nets on the slope, the
  promenade's curve, the dune edge, or the bridge's dead end.
- No car park: there is no apron (above). No restroom building: the kit has no restroom model.
- Footpaths worn across the sand (SHORE_GUIDE) were not made: the superchecker deletes any wear mark on sand or
  grass.
- The grass meets the sand at a hard material line with no texture blend: a cut curve plus ice plant.
- The parks are wide and open (empty_area is reported on every piece). There are 52 trees in all, kept down by
  the plan's in-view limit near the ring and the bridge.
- The exact colliders are patched into the saved files. Rebuilding any piece from its script drops them: run
  exact_colliders.gd again.
- Superchecker numbers in `OUT/fill/eb/sc3_*.txt`, check outputs in `OUT/fill/eb/final_*.txt`.
