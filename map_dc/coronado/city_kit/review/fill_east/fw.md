# fw: the north-west column (u -400..-200, v -1600..-800), 20 Nov

Builder "fw" for the fill (BUILD_GUIDE.md). Four empty blocks on Crown Hill's west slope, filled outdoors and indoors,
superchecked, hand trees, exact colliders. NOT committed, NOT locked, NOT in the shared layout (the coordinator does
that). Nobody has looked at a picture of it: no shots were taken.

## Plan (written before building; survey numbers from OUT/g_city, legs_measured.json, terrain_grid.npz)
Edges (OUT/fill/fw/edges.py): u -390.8 / -209.2; A v -1585.7..-1414.3, B -1385.7..-1214.3, C -1185.7..-1009.2,
D -990.8..-809.2. Walk heights every 4 m in `n_fw_site.gd` (OUT/fill/fw/walkh.py). The streets climb the hill: 2.15 at
the bay corners, 10.15 at (-200, -1200), 8.15 at (-200, -1000), 6.15 in the SW. Land 1.95..10.10; B falls 8 m SE->NW
(up to 6 %), C 6 m NE->W, A and D gentle. Aprons (the only car openings): A W/E v -1460..-1454; B W/E -1346..-1340 and
-1260..-1254; C W/E -1146..-1140, -1060..-1054, S u -346..-340, -260..-254; D on all four sides. Ring and arterials: none.

| Block / piece | Plan in one line |
|---|---|
| A `n_fw_bay` | Bay front: 4 garden apartments + a beach condo (BAYFRONT CAFE on the ground floor) facing the bay walk; their 2 parking courts and the Bay Court behind; CROWN MEWS joins the two aprons with 6 + 6 townhouses (garages on the mews, closed back gardens); Mews Green with a tot lot pad; Mews Corner at the arterial junction |
| B `n_fw_slope` | Hillside Terrace and Summit Terrace join the aprons; HILLTOP MARKET + SUDS LAUNDROMAT (com_orange_corner) on the low NW corner with a lot; 4 walk-ups on the lower arterial; CROWN HILL COFFEE on the NE corner; 3 apartment courts (2 x apt_court_white each) stepping up the slope; 3 walk-ups on the upper arterial; CROWN HILL LOOKOUT deck (rails, view NW to the bay) and a fenced playground terrace on the high SE corner |
| C `n_fw_crest` | Crest Lane and Garden Way join the aprons, 2 lanes up from the v -1000 street; CREST BAKERY + CREST CUTS salon on the crest corner (NE, highest); 3 garden apartments on the arterial; Crest Steps pocket garden; Hillcrest Gardens (2 courts of 2 garden apartments) with Hillcrest Green between; 7 dingbats on the v -1000 street |
| D `n_fw_court` | Park Lane and East Lane cross N-S apron to apron; 4 + 6 walk-ups facing the side streets; CROWN HILL COMMUNITY CENTER (SW, its lot) and CROWN HILL PHARMACY (SE) facing the civic band; Crown Court (4 garden apartments round a garden); CROWN HILL PARK (playground terrace, sails, benches, entry plaza) |

All pieces at grid [0, 0, 0], yaw 0 (x = u, y = world height, z = v). Ground: 5 cm over the land (`n_fw_land.gd`),
eased onto each walk within 12 m, never under the land; each building on a level pad at the highest ground under it;
the field graded up to the pads at 6 % for 6 m, then a 33 % grass bank (`n_fw_site.graded`: with plain 6 % grading a
high pad's apron rose 0.95 m over the next lower pad's front on the hill); the lookout deck and playgrounds are level
terraces with retaining faces; a 0.2 m face under every separately painted patch edge.

## Files (all with the fw prefix)
- pieces (scripts `tools/city/pilot/pieces/`, saved `map_dc/coronado/city_kit/pieces/`): `n_fw_bay`, `n_fw_slope`,
  `n_fw_crest`, `n_fw_court`; site `n_fw_site.gd`; land `n_fw_land.gd`
- trees: `zoning/trees/fw_bay.json` (6), `fw_slope.json` (6), `fw_crest.json` (4), `fw_court.json` (6); pieces
  `t_fw_bay`, `t_fw_slope`, `t_fw_crest`, `t_fw_court` (pos [0,0,0])
- rooms: `tools/city/rooms/assign_fw.py` -> `interiors/assignment_fw.json`, `rooms_fw_report.json`; 8 rooms
  `g_fw_bay_condo_0` (Bayfront Cafe), `g_fw_slope_market_0` (Hilltop Market), `g_fw_slope_market_1` (Suds Laundromat),
  `g_fw_slope_coffee_0`, `g_fw_crest_bakery_0`, `g_fw_crest_salon_0`, `g_fw_court_community_0`, `g_fw_court_pharmacy_0`
- area layout for the checks: `OUT/fill/fw/area.json` (the street / neighbour rows round the column + the 8 fw pieces,
  "from": "grow_fw" / "trees"); scratch tools in `OUT/fill/fw/`
- ground tris: bay 42.9k (over the ~40k aim by 7 %), slope 35.2k, crest 36.5k, court 36.6k. Props: 925 / 320 / 246 / 206.

## Superchecker (Yasin, 20 Nov: "MUCH more prone to delete")
This checkout's `sc_lib` has no SC_LAYOUT switch, so it was run through `OUT/fill/fw/sc_fw.py` (only replaces which
layout file it reads). Every finding written into each script's literal `const SC` (`OUT/fill/fw/sc_list.py` turns the
findings into the list; each line keeps its reason): 108 props out (16 / 29 / 25 / 38: no_reason seats and tables -
including the bay tot lot's three play items and both Bay Court tables, bins in the open, the sails left over nothing,
two arbors narrowing the Green's walk), 29 marks out (oil with no car / oil on grass), 123 column boxes. Re-check:
only report-only kinds left (wide_batch, empty_area; ground_step on slope 17 m / crest 23 m at <= 11 cm, inside door
strips). Rooms: 17 items deleted with room_drop_prop (unreachable fridge, 4 frames into the ceiling, then every
door_blocked / window_blocked / queue_blocked item); left: report-only (staff_door_off, sign_wrong / sign_blank of the
kit's painted signs, thin_wall between market and laundromat, shop_lacks till / counter, window_empty).
NOTE: after the exact-collider step the checker reports `no_collision` / `column_no_collision` again on every piece
(841 / 50 on bay ...). The locked hospital piece n_hp_west shows the same after the same step: the checker does not
read the true-size collider layout. The verifier says every prop has its collider (below).

## Checks (area layout OUT/fill/fw/area.json, real renderer fell back to GL on this box)
| Check | Result | Cannot see |
|---|---|---|
| validate.gd | 0 on fw pieces (6 in the area, all in other pieces: a signal mast in r_q_m200_m1400_se's fence, a house number on a mailbox) | heights, land, whether a prop makes sense |
| check_life.gd | 0 | everything but its kinds |
| audit_trees.gd | 22 trees, 0 in hard ground | - |
| check_rooms.gd --only=g_fw_ | 0 problems, 8 rooms | whether a shop has what it needs |
| seams (OUT/py/seams.py, 0.25 m) | 44 shared edges, 0 m over 2 cm, largest 1.8 cm (crest / s_ar_b075_a) | faces, looks |
| land over my ground (OUT/py/buried.py, 1 m) | 0 cells on all four | - |
| grades (OUT/py/grade.py) | bay p99 6 %, court 6.5 %; slope p99 23.7 % and crest 21.3 %: 4 % of their cells over 8 % = the 33 % grass banks between pads and the terrace faces (deck up to 1.9 m, with rails / fence) | - |
| sc.py trees | all four lists ok; the in-view limit (12 trees of any kind from any street point, counting all lists) cut the lists from 39 to 22 | - |
| exact colliders + colexact_verify | 8 pieces, largest gap 0.1 mm, no collider without a prop; without collider by design: sprinklers, iceplant | - |

## Not done / for the coordinator
- No pictures looked at (by eye: none). Not committed, not locked, not in `city_grid_layout.json`, no bake, no phone.
- `n_fw_bay` ground is 42.9k triangles (aim ~40k).
- The bay tot lot's bark pad is empty (its play items were deleted by the "no_reason" rule); the park clumps in D are
  single trees after the in-view limit.
- The front of some buildings on the slope stands on a 33 % grass bank beside the next pad: not looked at.
- The validator found 0 door-space problems, but no low eye-height look was taken at any door.
- No model needed a new room contract.
