# University campus (claude/sharp-ride-16u9ik, 19 Nov 2026) - LOCKED 19 Nov (Yasin: "run a polish pass then lock")

The campus (ZONING.md MUST site: "west of the stadium, which it shares; students live in the gritty edge") is the
superblock u/v -790.8..-409.2 (381.6 m square, STREETS.md "2 x 2 cells with its own campus roads"). No street enters it;
every side has 6 m driveway aprons at the same four places. Built one quarter at a time; own table
`review/grow_un_campus.json` (layout row (-600, 6.0, -600), local x = u + 600, z = v + 600), own room tools
(`room_contracts_un.gd`, `assign_un.py`, `room_gen_un.gd` with two new kinds: lecture hall, university foyer).

## The land (read first)
North-east quarter 6.13..6.30 (a low crown); north-west and south-east flat (6.0..6.3); the SOUTH-WEST quarter falls to
4.0 m at its corner, with the south and west streets' walks falling 6.15 -> 4.15 along it.

## Polish pass and lock (19 Nov late)
Polish (Yasin: "plenty of life and relevant props"): hydrants within reach of every building, storm drains and manholes
on the drives and lots, maintenance carts, more lawn chairs, tables, flower beds and sprinklers on the quads and the dorm
green, bikes between the dorms, patio sets, sideline and tennis benches, fountains, vending by the game-day kiosk,
papers; the gate café and bookstore set 1 m back (the 6 cm lip at the 6th St walk is gone). After it: ground check 0
everywhere, no step against any street, validator 0 lines naming n_un, life 0, trees 0 in hard ground, sink 0, rooms 0
problems in 22, lock test PASS (500 locked pieces). LOCKED: n_un_ne, n_un_nw, n_un_se, n_un_sw (lock.py --by=Yasin).
Still not in: garage interior, dorm floors above the lobbies, roof plant on the pitched civic roofs, goals on the field.

## All four quarters built (19 Nov evening): n_un_ne, n_un_nw, n_un_se, n_un_sw
- NE (built): the campus FRONT - the BUS STATION (one-way loop through 6th St's two aprons round a platform island with
  four shelters, timetable cases, bike racks and a coffee kiosk), the UNIVERSITY HALL (pub_university, first use of the
  kit model) across a plaza, the MAIN QUAD, library, lecture wing, science wing, the students' gate café and bookstore,
  the faculty lot off the east street's aprons.
- NW (built): the students' side - the STUDENT UNION at the gate (across the north mall from the gate café; plaza with
  tables, ficus in wells, bikes, the events case, mailbox), a one-way CAMPUS DRIVE inside 6th St between its two aprons
  with a drop-off lane, the university ART MUSEUM facing the street over its forecourt, the SCULPTURE GARDEN (monument,
  agave and bougainvillea beds, benches facing the monument), the CHAPEL, the WEST QUAD (bandstand, lawn chairs facing
  it, magnolia and jacaranda paths, tables), humanities and fine-arts wings, the union's loading yard, visitors' lot off
  the west street.
- SE (built): sport and the stadium side - REC CENTRE (new room kind: gym) and kinesiology wing on the east mall, the
  INTRAMURAL FIELD (floodlights, running loop, sideline benches; the kit has no goals, so it reads as a playing lawn),
  four TENNIS COURTS in a chain-link cage (post at every joint, gate on the north side), the CAMPUS GARAGE (in from the
  east street, out down the campus drive to the south or east street), the STADIUM WALK (game-day kiosk, shuttle
  shelter, benches, bins), corner grove.
- SW (built, the slope): six RESIDENCE HALLS round the DORM GREEN (two barbecue terraces, tables, lawn chairs, shade
  trees), each on its own level pad stepping down the land; the DINING COMMONS on the west mall; residents' lot off the
  west street; a one-way MOVE-IN LOOP through the south street's aprons with short-stay bays; the DORM STOP (shelter,
  bench, timetable) on the south street; the RAIN GARDEN in the low corner (gravel creek, boulders, agaves on mulch);
  a barbecue grove.
- The malls meet at the campus centre (u -600, v -600) as a 12 m cross of paving lined with date palms in wells.

## Ground (NE)
The ground follows the land 8 cm over it (ground exactly on the land flickered in the preview) and eases over 8 m to
walk level 6.15 at both streets and every apron; every building on a level pad at the highest ground under it (a short
plinth face where the ground falls away). Ground check: no step against any street, no gap, no overlap; the only empty
cells beside it are the campus quarters not built yet. Dry land trial: at most 0.13 m (land not written).

## Ground and checks, all four quarters (campus area layout, 127 rows)
- The SW quarter's ground eases to the west and south streets' walks as measured every 2 m (they fall 6.15 -> 4.15);
  every building on a pad at the highest ground under it. ground_check: buried 0, hanging 0, steps 0, under 0.
- Steps against neighbours (stepmap, 25 cm cells): one before the polish, in NE (a 6 cm lip at the gate café and
  bookstore); fixed in the polish pass.
- Dry land trial: 259 land nodes lowered, largest 0.09 m (land NOT written).
- validate.gd 0 lines naming n_un (the area's 12 problems are other pieces'); check_life 0 (after moving two racks off
  the humanities' path); audit_trees 0 of 1289 in hard ground; sink_check 0; check_rooms 0 problems in 22 rooms; lock
  test PASS. The builder refuses props on props, in walls and in doorways: 12 refused in SW (bike racks on dorm patio
  doors, bin carts at back doors, two meters), so those are absent; roof plant skipped on the pitched civic roofs.
- What these cannot see: overlaps of props with fences or foliage canopies, whether a view reads well, the inside of
  the garage (no rooms in the kit model), the dorm floors above the lobbies (homes not entered).

## Pictures (all four): un_top.jpg (straight down, SOUTH AT THE TOP), un_union.jpg (from 6th St), un_dorms.jpg,
un_sport.jpg (the courts' terrace). Preview renderer, no shadows, parked cars off.

## Checks (NE alone, earlier, campus area layout, 124 rows)
validate.gd 0 lines naming n_un (12 problems are other pieces'); check_life nothing; audit_trees 0 in hard ground;
check_rooms 0 problems in 7 rooms; lock test PASS. What they cannot see: see the super-builder skill's table.

## Pictures (opened): un_ne_top.jpg, un_ne_plaza.jpg; un_ne_bus_OLD_before_ground_fix.jpg is the OLD state (land showing
through before the ground followed the land). Preview renderer, no shadows, parked cars off.
