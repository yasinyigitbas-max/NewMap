# University campus (claude/sharp-ride-16u9ik, 19 Nov 2026) - DRAFT, NOT SHOWN, NOT LOCKED

The campus (ZONING.md MUST site: "west of the stadium, which it shares; students live in the gritty edge") is the
superblock u/v -790.8..-409.2 (381.6 m square, STREETS.md "2 x 2 cells with its own campus roads"). No street enters it;
every side has 6 m driveway aprons at the same four places. Built one quarter at a time; own table
`review/grow_un_campus.json` (layout row (-600, 6.0, -600), local x = u + 600, z = v + 600), own room tools
(`room_contracts_un.gd`, `assign_un.py`, `room_gen_un.gd` with two new kinds: lecture hall, university foyer).

## The land (read first)
North-east quarter 6.13..6.30 (a low crown); north-west and south-east flat (6.0..6.3); the SOUTH-WEST quarter falls to
4.0 m at its corner, with the south and west streets' walks falling 6.15 -> 4.15 along it.

## Plan (to be built quarter by quarter)
- NE (built): the campus FRONT - the BUS STATION (one-way loop through 6th St's two aprons round a platform island with
  four shelters, timetable cases, bike racks and a coffee kiosk), the UNIVERSITY HALL (pub_university, first use of the
  kit model) across a plaza, the MAIN QUAD, library, lecture wing, science wing, the students' gate café and bookstore,
  the faculty lot off the east street's aprons.
- NW: student union, museum, a second quad (next).
- SE: rec centre ("the gym"), sports fields, the campus garage near the stadium side.
- SW (the slope): dorms on terraces stepping down to 4 m, the dorm green.
- The two campus malls (u -600, v -600) meet at a central plaza.

## Ground (NE)
The ground follows the land 8 cm over it (ground exactly on the land flickered in the preview) and eases over 8 m to
walk level 6.15 at both streets and every apron; every building on a level pad at the highest ground under it (a short
plinth face where the ground falls away). Ground check: no step against any street, no gap, no overlap; the only empty
cells beside it are the campus quarters not built yet. Dry land trial: at most 0.13 m (land not written).

## Checks (NE, campus area layout, 124 rows)
validate.gd 0 lines naming n_un (12 problems are other pieces'); check_life nothing; audit_trees 0 in hard ground;
check_rooms 0 problems in 7 rooms; lock test PASS. What they cannot see: see the super-builder skill's table.

## Pictures (opened): un_ne_top.jpg, un_ne_plaza.jpg; un_ne_bus_OLD_before_ground_fix.jpg is the OLD state (land showing
through before the ground followed the land). Preview renderer, no shadows, parked cars off.
