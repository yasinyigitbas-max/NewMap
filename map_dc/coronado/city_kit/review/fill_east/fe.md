# fe fill: the east of the apartment band and the ring strip (20 Nov, branch `claude/fill-high-street`)

Builder "fe" under the coordinator (BUILD_GUIDE.md in this folder). Drafts: NOT committed by me, NOT locked, NOT in
`city_grid_layout.json`. Area layout for the checks: `OUT/fill/fe/area.json` (the shared layout's rows round the area +
my 7 pieces at grid [0, 4.0, 0] `"from": "grow_fe"` + my 7 tree pieces `"from": "trees"`).

## The plan (written before building; land measured first)

What the measuring found (OUT/g_city, `OUT/fill/fe/edges_fe.py`, `edges_hp.py`, `curve_edge.py`; land `terrain_grid.npz`):
- **The brief's ring strip is not what is on the ground.** South of v -800 there is NO u 600 street: every cross street
  runs from the u 500 street straight to the ring, so each empty block is u 509 .. the ring's inner walk (about 130 m
  wide, not 30 - 60 m). I filled the whole width (it is empty land inside the ring, and "the last built block" is the
  apartment band west of the u 500 street). Tell me if part of it was meant for someone else.
- **v -1400 .. -1200 is not empty**: m_gr_ad3se and m_gr_e4n reach the ring's walk; no empty cell there. Nothing built.
  (A 25 m sliver u 375 .. 400, v -1385 .. -1215, between the residential quadrants and the strip, is empty but not in my
  list; not touched.)
- Block "u 200 .. 400, v -1000 .. -800" is, on the ground, the L u 259 .. 491 x v -991 .. -809 minus the residential
  quadrant r_q_250_m1000_se (u 259 .. 375, v -991 .. -900). "Block u 400 .. 600" = u 509 .. ring, v -985.7 .. -809.
- Land: 6.1 at the u 500 street falling to 4.1 at the ring everywhere south of -800 (1.5 - 3 %); at v -390 .. -100 the
  u 500 street's walk climbs to 8.15 and the land falls 4 m to the ring; block 1 falls 1.8 m to its north-east corner.
  Every street walk was measured to be at least 5 cm over the land at its edge.
- Car openings (legs_measured.json, checked on the ground dump): the aprons listed in `n_fe_site.gd`'s header. The ring
  and s_rg_b087 have none.

| Piece | Block | Plan (one line) |
|---|---|---|
| `n_fe_b1w` | u 259..375, v -900..-809 | CROWN HILL GARDENS: 5 garden apartments (3 on the -800 street, 2 on the drive) round a court; residents' stalls on a T of drives from the u 250 street's and the -800 street's aprons; bin pad at the drive's end |
| `n_fe_b1e` | u 375..491, v -991..-809 | CROWN HILL CORNERS: a shop row (laundry, coffee, barber) and a corner market / pharmacy facing the strip across the -1000 street, their lot off its apron; CROWN HILL MEWS: 12 townhouses on two mews from the u 500 street's aprons, a green between; 3 garden apartments on the -800 street |
| `n_fe_b2` | u 509..ring, v -985.7..-809 | RINGSIDE: a two-bay service shop (bikes, dry cleaner) on the u 500 street; 4 garden apartments; the ring park's north end: the OVERLOOK with the OVERLOOK CAFE's terrace to the bay, a sand volleyball court, a picnic grove; one drive between the u 500 street's south apron and the -800 street's apron for residents and park visitors |
| `n_fe_r7` | u 509..ring, v -791..-609 | GLORIETTA MEWS: 12 townhouses on two mews from the u 500 street's aprons, a green; the park's PLAYGROUND (play items deleted by the superchecker pass, see below) with its car park off the -800 street's apron |
| `n_fe_r5` | u 509..ring, v -591..-409 | GLORIETTA REC CENTER (door on the u 500 street, 0.3 m sill with closed steps) and two fenced TENNIS COURTS on a level pad; 2 garden apartments; the park's lookout and picnic grove |
| `n_fe_r3` | u 509..ring, v -391..-209 | GLORIETTA TERRACES: 5 small apartment buildings each on its own terrace; TERRACE LANE apron to apron (u 554..560 at both cross streets, stubs to the u 500 street's aprons); the SKATE SPOT on a level concrete pad, a lookout, a picnic lawn |
| `n_fe_r1` | u 509..ring, v -191..-9 | GLORIETTA POINT: a bakery and a surf shop on the v 0 street (toward the waterfront), their lot off its apron, service lane from the u 500 street; 3 apartments on the hill; the BANDSTAND lawn and a lookout where the ring bends |

The RING PATH (3 m, paved) runs north - south through b2, r7, r5, r3, r1 (u 618..621 / 616..619 / 610..613 / 600..603),
20 - 25 m inside the boulevard, with benches facing the bay on the strip between.

## Ground and land (how)
`n_fe_site.gd`: the ground of every block is 5 cm over the land (`n_fe_land.gd`, exported by `export_land_patch.py`),
and within 12 m of each walk eased onto that walk's measured height (tables in the site file), keeping the land's shape
(target = land(p) + walk(foot) - land(foot)), so it is never under the land and meets each walk at its edge. Buildings,
the courts, the skate pad and the bandstand stand on level pads at the highest ground under them; the field is graded
up to them at 6 % (`hs_fill_lib.graded`) and fades back onto the plain ground within 4 m of a walk (and of the
b1w | b1e seam) so a pad never lifts a seam. The ring edge is slanted: `n_fe_site.paint_rows` cuts rows on the global
grid with a trapezoid to the edge.

## Superchecker pass (Yasin via the coordinator: "be MUCH more prone to delete")
`tools/city/super/sc.py check` on every piece with the area layout (run through `OUT/fill/fe/scx.py`, a scratch wrapper:
the branch's `sc_lib` has no `SC_LAYOUT` switch, so the wrapper sets `sc_lib.LAYOUT` / `load_layout` in its own process
only; no shared file changed). Every finding on an item became a deletion in the piece's literal `const SC` list with
the checker's text as its reason (`OUT/fill/fe/sc2src.py` wrote the lists from the findings files): 90 props out in all
(no_reason 72 - benches, picnic tables, chairs and ALL the play items, since the rule counts them "alone" - bin_open 13,
opening 2, sail_over_nothing 3, park_empty 2); 126 column boxes as measured. No wear mark had a finding. Re-check: only
report-only kinds left (wide_batch, empty_area, edge_step).
CONSEQUENCE: the parks lost most seating and every play item (the b1w tot lot, the b1e play corner, the r7 playground);
what stays is lawns, paths, lookouts, the courts, the skate elements, the volleyball net, the bandstand, a few tables.
That follows the instruction; it is less "life" than planned.
Rooms: the checker's room findings with no plain fix were erased on proven copies (`rooms_and_trees.sh`'s rule),
PROOF RESULT PASS for 7 rooms, installed with `install-room` (rooms were not locked; nothing locked or unlocked).

## Rooms (11, `tools/city/rooms/assign_fe.py` -> `interiors/assignment_fe.json`, room_gen_hp.gd)
b1e: Crown Hill Laundry (cleaners), Hilltop Coffee (cafe), Corner Cuts Barbers (salon), Crown Hill Market (corner_shop),
Hilltop Pharmacy (pharmacy); b2: Ringside Bikes (sport), Ringside Dry Cleaners (cleaners), Overlook Cafe (cafe);
r5: Glorietta Rec Center (sport desk); r1: Point Bakery (bakery), Glorietta Surf Co. (sport). All models have contracts
in room_contracts.json. Not walk-in: apartments, townhouses.

## Trees (hand lists `zoning/trees/fe_*.json`, pieces `t_fe_*`)
17 trees. The plan's in-view limit (12 trees / 8 broadleaf within 60 m of any street point) is already nearly full along
the ring (its palm boulevard) and the strip, so the clumps of 3 - 5 the park rule asks for did not fit: 2 - 4 trees per
piece, placed where the limit leaves room (measured with the scratch `OUT/fill/fe/tview.py`). `sc.py trees` ok for all 7.

## Checks (area layout, real renderer) - numbers in OUT/fill/fe/final_*.txt
See the coordinator report for the final numbers; what each cannot see:
- validate.gd: overlaps, props in buildings, door space, props on lanes. NOT heights, land, sense.
- check_life.gd: poles on asphalt, items on paths, wall items over openings, fence ends. Nothing else.
- audit_trees.gd: trees in hard ground only.
- check_rooms.gd --only=g_fe_: the indoor kinds; NOT whether a shop has what it needs.
- seams.py / buried.py / grade.py (scratch, on OUT/fill/fe/g): heights at 0.25 m / 1 m cells; NOT faces, looks.
- superchecker: findings by rule; it cannot see whether a place reads well.
NOT DONE / NOT LOOKED AT: no picture was taken or opened; nobody has seen these pieces. Not baked, no phone run.
Junction corners: 2.5 - 5.6 cm steps over 2 - 7 m at each junction corner (seams.py); 5 cm outside my edge the junction
walk is exactly my height (sampled), the step is in the junction's own corner cells; not fixed. The residential quadrant
r_q_250_m1000_se's edge has a 6 - 8 cm step of its own (u 294 .. 296, and at its corner v -990.6); my edge follows a
linear table there, 6 cm off over ~1 m. The exact-collider patch was applied to the saved pieces IN PLACE: rebuilding a
piece from its script drops it (run exact_colliders.gd again after any rebuild).

## Final numbers (20 Nov, after trees and exact colliders; area layout)
- validate.gd: 0 on fe pieces (22 problems in the area, all in n_apt_* / r_q_* pieces, the same before my pieces).
- check_life.gd: 0 lines naming an fe piece.
- audit_trees.gd: 82 trees checked in the area, 0 in hard ground.
- check_rooms.gd --only=g_fe_: 0 problems, 11 rooms.
- buried.py: 0 of 147,647 1 m cells with the land over my ground (closest 4.8 cm under it).
- grade.py: median 1.5 %, 99 % under 6.0 %, 0.33 % over 8 % (pad faces, steps, the courts' and skate pad's faces).
- seams.py: every street walk edge within 2 cm except the junction corners (above) and the r_q quadrant's own step.
- exact colliders: colexact_verify largest gap 0.1 mm on all 14 files.
- superchecker after the exact colliders: it reports `no_collision` / `column_no_collision` again on every piece (44 -
  210 per piece). The same happens on the locked n_hp_west (68 + 10) whose colliders were made the same way: the
  checker's reader does not see exact_colliders.gd's shapes (colexact_verify does, corner for corner). A checker blind
  spot for the coordinator, not changed. Before the colliders step: only report-only kinds were left.
- Room findings still listed by the superchecker (report-only for it): sign_wrong, shop_lacks, staff_door_off,
  thin_wall, window_empty, no_counter (rec center). Not fixed by hand.
