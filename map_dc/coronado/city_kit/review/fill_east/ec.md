# ec: the east shore beyond the ring, south part (v -500 .. 0), 20 Nov

Builder "ec" for the east-shore fill (SHORE_GUIDE.md, BUILD_GUIDE.md). All land between the ring road's east walk and
the sea for v -500 .. 0, filled GRASS > SAND > SEA, superchecked outdoors and indoors, hand trees, exact colliders.
NOT committed, NOT locked, NOT in `city_grid_layout.json` (the coordinator does that). Nobody has looked at a picture
of it: no shots were taken.

## The area as measured (read-only; OUT/g_city, terrain_grid.npz, shore_foam.json)
- West: the ring's outer (east) walk edge, 4.150 all along: u 667.7 (v -504) .. 659.3 (bend at v -121) .. 645.05 (v 0,
  j_rg_se_e627_s0). The ring pieces and its T junctions here have NO apron on this side (legs_measured.json) and there is
  no road beyond the ring: no car park was built (people walk in at the junction corners v -400, v -200, v 0).
- South: v 0. **Open land goes on south of v 0** (the land is still 0.4 - 3.7 m there, nothing built east of the
  junction): stopped at v 0 as asked; a face under the open edge.
- North: v -500, builder eb's area. East: the sea; the land's 0 m line runs u 1401.8 (v -500), 1354.7 (v -390),
  1454.6 (v -10).
- Land: 4.1 at the ring, a hill to 11.1 m at u 900, v -340; east of u 1100 a low flat 0.5 - 1.5 m, then 1 : 8 into the sea.

## Pieces (all at grid pos [0, 0, 0], yaw 0: x = u, z = v, y = world; scripts `tools/city/pilot/pieces/`)
| Piece | Area | Plan in one line | Props | Ground tris |
|---|---|---|---|---|
| `n_ec_hill_n` | ring .. u 932, v -500 .. -250 | SHORE HILL PARK: beach walk A400 from the v -400 junction over the hill, the summit LOOKOUT terrace (benches, fountain, lamps), picnic grove with grills under the ring | 37 | 9.9k |
| `n_ec_hill_s` | ring .. u 932, v -250 .. 0 | beach walks A200 and A0 from the v -200 / v 0 junctions, the SOUTH LOOKOUT, picnic lawn, PLAYGROUND (3 play items on a bark pad, parents' benches), picnic spot by A0 | 46 | 11.1k |
| `n_ec_dune_n` | u 932 .. 1200, v -500 .. -250 | the lawn, the PROMENADE along the dune line (pier lamps, bench pairs facing the sea), the GRASS > SAND line with iceplant and agaves, SHORELINE SNACK BAR at A400 (terrace, bike rack), the beach access (shower, rules / rip signs), 2 volleyball courts, umbrellas | 71 | 10.4k |
| `n_ec_dune_s` | u 932 .. 1200, v -250 .. 0 | the same promenade and dune edge; DUNE CAFE at A200 (terrace); SOUTH BEACH RENTALS at A0 (kayak racks, umbrellas for hire, bins, bike rack); 2 accesses with showers and signs; 4 volleyball courts; picnic tables, beach chairs | 85 | 12.2k |
| `n_ec_beach_n` | u 1200 .. 0 m line + 25 m, v -500 .. -250 | the sand to the water and on under it: 2 lifeguard towers facing the water (life ring stand, rip sign each), umbrella groups, a kayak rack | 28 | 25.2k (2 m grid) |
| `n_ec_beach_s` | u 1200 .. 0 m line + 25 m, v -250 .. 0 | 2 lifeguard towers, the rental shop's 2 launching racks, umbrella groups, the DOG BEACH (picket-fenced run, gate, dog sign, bin, 2 benches) | 141 (108 fence parts) | 31.5k (2 m grid) |

Shared: `n_ec_site.gd` (edges, the dune / promenade / 0 m lines, the ground rule, the band painter), `n_ec_land.gd`
(the land table, export_land_patch.py). Scratch: `OUT/fill/ec/` (edges.py, shore.py, geo.py, mk_area.py, trees_ec.py,
shore_seam.py, rooms_fix.sh, the check outputs). Area layout for the checks: `OUT/fill/ec/area.json` (the shared
layout's rows round the area + my 6 pieces "from": "grow_ec" + 4 tree pieces "from": "trees").

## Ground, the dune line, the shore
- THE GROUND RULE (`n_ec_site.g`, the same as eb's `n_eb_site.g`): land + 5 cm, the 5 cm eased to 0 (smoothstep) over the
  last 10 m before the land's 0 m line, the land itself beyond it and under the water to 25 m past the 0 m line; within
  12 m of the ring's walk eased onto 4.150 keeping the land's shape. Buildings, lookouts and the playground on level
  pads at the highest ground under them, the field graded up to them at 6 %.
- **Edge heights at v -500 (for eb; sampled on my ground dump)**: 4.150 at the ring's walk (u 667.6), 4.15 at u 700,
  then the land + 5 cm: 5.15 (u 800), 6.92 (u 900), 6.77 (u 940), 5.45 (u 1000), 2.56 at the dune line (u 1124.9), 1.54
  (u 1250), 0.55 (u 1380), the lift easing to 0 by the 0 m line at u 1401.8, then the land (-1.93 at u 1426, the sea edge
  u 1426.8). Measured against eb's built n_eb_sw / n_eb_se: 264 + 28 +
  240 + 227 m of shared edge, largest step 0.9 cm. The dune line takes eb's DUNE value there (1124.94) and the promenade
  meets eb's (eased 0.79 m over v -500 .. -470); materials continue across the seam (plaza 1116.5 .. 1119.5, sand from
  ~1125).
- Dune line (grass > sand): hand-drawn, Catmull-Rom: the land's 2.5 m contour from v -500 to -260 (u 1110 - 1125, small
  bays and points), bending west with the hill's foot, then held at u 1003 - 1010 on the low south flat (land 1.1 - 1.5
  there: following 2.5 m strictly would have left a 40 m lawn and a 650 m beach). The beach is 280 m wide in the north,
  450 m in the south. The line is a shared vertex line of the ground (no stair-steps): `n_ec_site.rows` cuts every row
  into bands between curved boundaries (ring edge, promenade, dune line, sea edge).

## Superchecker (BUILD_GUIDE: "much more prone to delete")
Run as `FW_AREA=OUT/fill/ec/area.json python3 -I OUT/fill/fw/sc_fw.py check <piece>` (no SC_LAYOUT on this branch).
Before the exact colliders: all six pieces only report-only kinds (wide_batch, empty_area; dune_s one ground_step:
6 m at 6 cm at the cafe pad's corner). Deleted:
- props (in each script's `const SC`, with the checker's reason): both terrace shade sails (sail_over_nothing), the 4
  terrace bins of the snack bar and the cafe (bin_open: the wall is 1.8 m inside the model's bbox); 3 column boxes added.
- banned: all 24 dry lawn patches I used as dune grass ("grass tufts are banned (16 Nov)"): out of the ALONG lists.
- wear: EVERY mark on grass or sand had a finding (1,596 marks: 328 dune_n, 379 dune_s, 409 beach_n, 480 beach_s): the
  sand blown onto the grass along the dune line, the footpaths across the sand from each access to the water, the wet
  sand along the water and under the showers, the towels' patches, the dog run's trodden sand. Out at the source
  (`_wear`). Only the three queue marks at the shop doors (on paving) remain. CONSEQUENCE: no footpaths and no wet-sand
  band; the dune edge is only the material line plus iceplant / agaves.
- one bench in the dog run left out before the check (it would have stood alone).
- rooms: 6 items erased on proven copies (the snack bar's and the cafe's kitchen line, the cafe's drinks fridge, the
  rental shop's 2 wall shelves and a clothes rack: door_blocked / window_blocked), PROOF RESULT PASS each, installed with
  `install-room` (not locked).
After the exact colliders the checker reports `no_collision` again (30 / 39 / 41 / 53 / 23 / 135): its known blind spot
(it reads only Props/PropCol); colexact_verify sees every collider (below).

## Rooms (3; `tools/city/rooms/assign_ec.py` -> `interiors/assignment_ec.json`, room_gen_hp.gd)
`g_ec_dune_n_snackbar_0` Shoreline Snack Bar (fast_food), `g_ec_dune_s_cafe_0` Dune Cafe (cafe),
`g_ec_dune_s_rentals_0` South Beach Rentals (sport). All models have contracts. Left (report-only): the snack bar has
no kitchen line any more (shop_lacks), the cafe no indoor bin; sign_wrong: the models' painted signs say CROWN CAFE /
SILVER STRAND SURF; staff_door_off in all three.

## Trees (hand lists `zoning/trees/ec_{hill_n,hill_s,dune_n,dune_s}.json`, pieces `t_ec_*`, 8 each, 32)
Palms (canary date, Mexican fan, queen) and 3 Torrey pines at the lookouts, in clumps round the picnic grove, the
lookouts, the playground, the shops and the seating; none on the sand. `sc.py trees` ok for all four (in view of the
ring: 12 of any kind, the limit, near the hill pieces' west edge; 2 broadleaf).

## Checks (area layout OUT/fill/ec/area.json; outputs OUT/fill/ec/final_*.txt)
| Check | Result | Cannot see |
|---|---|---|
| validate.gd | 0 problems (1,416 props, 9 buildings) | heights, land, whether a prop makes sense |
| check_life.gd | 0 on ec pieces (4 in the area: n_wf_b2e's fence ends, not mine) | everything but its kinds |
| audit_trees.gd | 32 trees, 0 in hard ground | - |
| check_rooms.gd --only=g_ec_ | 0 problems, 3 rooms, every floor cell reachable | whether a shop has what it needs |
| land over my ground (1 m cells) | 0 of 363,653 cells more than 10 m inland; within 10 m of the 0 m line 27 of 5,000 by <= 3.4 mm; under the water 6,499 of 12,501 by <= 2.3 mm (triangles vs the bilinear land where the lift is 0) | faces, looks |
| seams (OUT/py/seams.py, 0.25 m) | every edge with the ring, its junctions and between my pieces: largest 1.0 cm; with eb at v -500: 0.9 cm | faces, looks |
| grades (OUT/py/grade.py) | hill_n p99 5.0 %, dune_s p99 5.6 %; beach p99 8.2 % (all over 8 % under the water, the land's 1 : 8) | - |
| sand's 0 m contour vs the land's 0 m line | median 0.01 m, p95 0.02, max 0.07 (500 points, 1 per m) | - |
| **sand's 0 m contour vs shore_foam.json's centre line** | **median 1.13 m, p95 1.17, max 1.55: NOT within 0.3 m** | - |
| the foam strip's own waterline (where its rows cross 0 m) vs my contour | median 0.02 m, p95 0.03, max 0.67 | - |
| exact colliders + colexact_verify | 10 files, largest gap 0.1 mm, no collider without a prop; without collider by design: sprinklers, iceplant | - |

THE FOAM SEAM, honestly: the foam strip's centre line (shore_foam.json, row 3) stands on land 0.084 - 0.095 m high
(median 0.090) along this WHOLE shore, i.e. 1.1 m inland of the land's own 0 m line; its 13 rows are drawn at the land
height + 2 cm, so the strip itself meets the sea on the land's 0 m line. My sand follows the land exactly there (the rule
the guide asks), so the sea cuts it where the foam strip's own surface meets the water (0.02 m median), inside the
strip, 1.1 m seaward of its centre (shader UV ~0.55 where the still-water line is 0.4). Getting within 0.3 m of the
centre line would need the sand 9 cm UNDER the land along the water (or a regenerated foam file, locked). Not done.
eb follows the same rule, so the same 1.1 m holds there.

## Not done / for the coordinator
- No picture looked at (no shots), no bake, no phone run. Not committed, not locked, not in the shared layout.
- South of v 0 the open land is not filled (as asked). No car park (no apron, no road beyond the ring).
- No fire rings (no kit model); no boardwalk over the dune (the access is paving).
- The wet-sand band, footpaths and the sand blown onto the grass were all deleted by the superchecker rule: the beach is
  plain sand; the 400 - 450 m of sand in the south is mostly empty (empty_area, report-only).
- The terrain itself coincides with my sand where the lift is 0 (the last 10 m and under the water): z-fighting is
  possible there until the land is lowered under the pieces at integration (lower_land_to_pieces.py; not run, no land
  writes).
- The exact colliders are patched into the saved files: rebuilding any piece from its script drops them (run
  exact_colliders.gd again after any rebuild).
- Tool side effects outside my prefix (written by the shared tools, not by hand): sc.py appended to
  `review/superchecker/log.jsonl` and wrote `review/superchecker/g_ec_*.fixes.json / .proof.txt`; Godot created
  `.gd.uid` files next to scripts it ran.
