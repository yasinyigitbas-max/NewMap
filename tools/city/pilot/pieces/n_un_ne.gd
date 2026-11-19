extends SceneTree
## Piece n_un_ne (UNIVERSITY CAMPUS, north-east quarter; claude/sharp-ride-16u9ik 19 Nov). Layout row (-600, 6.0, -600),
## local x = u + 600, z = v + 600. Covers u -600..-409.2, v -790.8..-600: the campus quarter on 6th St (north) and the
## east street (toward the stadium it shares, ZONING.md "University campus (MUST): west of the stadium").
## SITE (read first, 19 Nov dump + zoning/terrain_grid.npz): the campus is the 381.6 m superblock u/v -790.8..-409.2
## (STREETS.md: "the university campus, 2 x 2 cells, with its own campus roads"); no street enters it, every side has
## 6 m driveway aprons at the same four places. This quarter: land 6.13..6.30 (a low crown in the middle), 6th St's and
## the east street's walks 6.15 all along, aprons on 6th at u -546.6..-539.4 and -460.6..-453.4, on the east street at
## v -746.6..-739.4 and -660.6..-653.4.
## PLANNER: the students live in the gritty edge north of 6th St (ZONING.md) and come in on foot and by bus, so this
## corner is the campus FRONT: the BUS STATION is a one-way loop through 6th St's two aprons (in at u -546, out at u
## -460) round a platform island with shelters and the ticket kiosk; the UNIVERSITY HALL faces it across a paved plaza;
## the MAIN QUAD lies behind the hall, framed by a lecture wing (west), the library (east) and the campus malls (west
## and south, the axes to the central plaza at u -600, v -600). Faculty and visitors park in the lot off the east
## street's two aprons; the science wing faces the south mall; the students' café and bookstore stand at the gate
## corner where 6th St meets the north mall.
## GROUND (elevation): this quarter is flat: everything paved at walk level 6.15 (flush with every walk and apron); the
## quad is lawn that follows the land's low crown (up to 6.30) eased smoothly to 6.15 at its paths and edges.
## EXTERIOR: shelters, benches, timetable cases, bike racks, bollards, lamps on the platform; the plaza (lamps, trees in
## wells, benches facing the hall, planters, a fountain); the quad (paths lined one species each, benches facing the
## lawn, tables, lamps); the café terrace; the lot (stalls, light poles, meters, oil, tyre marks at the aprons).
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(-600.0, 6.0, -600.0)
const LAND := {"x0": -4.0, "z0": -196.0, "step": 4.0, "nx": 51, "nz": 51, "h": [-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.11,0.11,0.10,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.13,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.12,0.11,0.12,0.11,0.11,0.10,0.10,-0.05,-0.05,0.15,0.16,0.16,0.15,0.15,0.15,0.16,0.16,0.16,0.16,0.16,0.16,0.15,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.15,0.15,0.15,0.15,0.15,0.15,0.14,0.14,0.14,0.13,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.10,-0.05,-0.05,0.17,0.17,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.18,0.17,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.17,0.18,0.17,0.18,0.17,0.18,0.17,0.17,0.16,0.16,0.16,0.15,0.16,0.15,0.15,0.15,0.15,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.13,0.13,0.13,0.11,0.11,0.10,-0.05,-0.05,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.19,0.19,0.19,0.18,0.18,0.18,0.18,0.17,0.17,0.17,0.16,0.16,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.14,0.13,0.13,0.12,0.12,0.10,-0.05,-0.05,0.20,0.20,0.20,0.20,0.21,0.21,0.21,0.21,0.21,0.21,0.21,0.21,0.21,0.22,0.22,0.21,0.22,0.22,0.22,0.21,0.21,0.21,0.21,0.21,0.21,0.21,0.20,0.20,0.19,0.19,0.18,0.19,0.18,0.17,0.17,0.17,0.17,0.17,0.16,0.16,0.16,0.16,0.15,0.15,0.15,0.14,0.13,0.12,0.10,-0.05,-0.05,0.22,0.22,0.22,0.22,0.22,0.22,0.22,0.23,0.23,0.23,0.23,0.24,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.24,0.23,0.23,0.23,0.22,0.22,0.21,0.21,0.21,0.21,0.20,0.20,0.20,0.19,0.18,0.18,0.18,0.18,0.18,0.17,0.17,0.17,0.17,0.16,0.15,0.15,0.13,0.12,0.10,-0.05,-0.05,0.24,0.23,0.23,0.23,0.23,0.24,0.24,0.25,0.24,0.25,0.24,0.24,0.25,0.24,0.25,0.25,0.25,0.25,0.25,0.25,0.24,0.24,0.24,0.24,0.24,0.24,0.23,0.23,0.23,0.21,0.21,0.21,0.21,0.20,0.20,0.19,0.20,0.19,0.19,0.18,0.18,0.18,0.17,0.17,0.16,0.15,0.14,0.12,0.10,-0.05,-0.05,0.24,0.25,0.24,0.25,0.25,0.26,0.25,0.26,0.26,0.25,0.26,0.26,0.26,0.26,0.27,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.25,0.24,0.24,0.24,0.23,0.23,0.22,0.22,0.22,0.22,0.20,0.20,0.20,0.19,0.20,0.19,0.19,0.18,0.18,0.16,0.15,0.14,0.12,0.10,-0.05,-0.05,0.25,0.26,0.25,0.26,0.26,0.27,0.27,0.27,0.27,0.27,0.28,0.27,0.27,0.27,0.28,0.28,0.27,0.28,0.28,0.28,0.28,0.27,0.27,0.27,0.26,0.26,0.26,0.25,0.25,0.25,0.24,0.23,0.23,0.22,0.22,0.22,0.21,0.21,0.21,0.21,0.20,0.20,0.19,0.18,0.17,0.16,0.15,0.12,0.10,-0.05,-0.05,0.26,0.27,0.27,0.27,0.27,0.27,0.28,0.27,0.28,0.28,0.28,0.28,0.29,0.29,0.29,0.29,0.29,0.28,0.28,0.29,0.28,0.29,0.28,0.28,0.28,0.27,0.27,0.26,0.26,0.25,0.25,0.24,0.24,0.23,0.23,0.23,0.22,0.22,0.21,0.21,0.21,0.20,0.20,0.18,0.18,0.16,0.14,0.12,0.10,-0.05,-0.05,0.27,0.28,0.28,0.27,0.28,0.28,0.28,0.28,0.29,0.29,0.30,0.30,0.29,0.29,0.29,0.30,0.29,0.30,0.29,0.30,0.29,0.29,0.29,0.28,0.28,0.28,0.28,0.27,0.27,0.26,0.26,0.25,0.24,0.24,0.23,0.23,0.22,0.23,0.22,0.21,0.21,0.20,0.19,0.18,0.18,0.16,0.15,0.12,0.10,-0.05,-0.05,0.27,0.27,0.28,0.28,0.29,0.29,0.29,0.29,0.29,0.29,0.29,0.30,0.30,0.30,0.30,0.31,0.30,0.31,0.30,0.29,0.30,0.29,0.30,0.29,0.29,0.29,0.29,0.27,0.27,0.26,0.26,0.26,0.25,0.25,0.24,0.24,0.23,0.22,0.22,0.21,0.21,0.20,0.20,0.18,0.18,0.16,0.14,0.12,0.10,-0.05,-0.05,0.28,0.28,0.29,0.29,0.29,0.29,0.29,0.29,0.29,0.30,0.30,0.31,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.29,0.29,0.29,0.28,0.28,0.27,0.27,0.26,0.26,0.24,0.24,0.23,0.23,0.23,0.22,0.22,0.21,0.21,0.20,0.19,0.18,0.16,0.15,0.13,0.12,0.10,-0.05,-0.05,0.28,0.28,0.29,0.29,0.29,0.29,0.29,0.30,0.30,0.30,0.30,0.30,0.30,0.31,0.30,0.30,0.31,0.30,0.31,0.30,0.30,0.30,0.30,0.29,0.29,0.29,0.28,0.28,0.27,0.27,0.26,0.26,0.25,0.24,0.24,0.23,0.23,0.22,0.21,0.20,0.20,0.19,0.18,0.17,0.16,0.15,0.14,0.12,0.10,-0.05,-0.05,0.28,0.28,0.29,0.29,0.29,0.29,0.29,0.29,0.29,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.29,0.29,0.28,0.28,0.28,0.27,0.27,0.27,0.26,0.25,0.25,0.24,0.23,0.22,0.22,0.21,0.21,0.20,0.19,0.19,0.18,0.17,0.15,0.14,0.13,0.12,0.10,-0.05,-0.05,0.28,0.27,0.27,0.28,0.28,0.29,0.29,0.29,0.29,0.30,0.29,0.29,0.29,0.29,0.30,0.29,0.30,0.30,0.30,0.30,0.28,0.29,0.28,0.28,0.28,0.28,0.27,0.27,0.26,0.25,0.25,0.24,0.23,0.22,0.22,0.21,0.21,0.21,0.21,0.19,0.18,0.18,0.17,0.16,0.15,0.14,0.13,0.12,0.10,-0.05,-0.05,0.27,0.27,0.27,0.28,0.28,0.28,0.28,0.28,0.28,0.29,0.29,0.28,0.29,0.29,0.29,0.28,0.29,0.28,0.29,0.28,0.28,0.28,0.28,0.28,0.27,0.27,0.26,0.26,0.25,0.24,0.24,0.23,0.23,0.22,0.22,0.20,0.20,0.20,0.19,0.19,0.18,0.18,0.17,0.16,0.15,0.14,0.13,0.11,0.10,-0.05,-0.05,0.26,0.27,0.26,0.27,0.27,0.27,0.27,0.28,0.28,0.28,0.28,0.27,0.28,0.28,0.28,0.28,0.28,0.28,0.28,0.28,0.28,0.27,0.26,0.27,0.26,0.26,0.25,0.25,0.25,0.24,0.23,0.22,0.21,0.21,0.21,0.20,0.19,0.19,0.19,0.18,0.17,0.17,0.16,0.16,0.15,0.14,0.13,0.11,0.10,-0.05,-0.05,0.25,0.26,0.26,0.26,0.26,0.27,0.27,0.26,0.27,0.27,0.27,0.27,0.27,0.27,0.28,0.28,0.27,0.27,0.26,0.27,0.26,0.27,0.26,0.26,0.26,0.25,0.24,0.23,0.23,0.23,0.22,0.21,0.21,0.20,0.20,0.20,0.18,0.18,0.18,0.18,0.17,0.17,0.16,0.15,0.15,0.13,0.12,0.11,0.10,-0.05,-0.05,0.25,0.26,0.26,0.25,0.25,0.25,0.26,0.26,0.26,0.26,0.27,0.27,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.25,0.24,0.24,0.24,0.24,0.23,0.23,0.22,0.22,0.20,0.19,0.19,0.18,0.18,0.18,0.18,0.17,0.17,0.17,0.15,0.15,0.14,0.14,0.13,0.12,0.11,0.10,-0.05,-0.05,0.24,0.24,0.25,0.25,0.25,0.25,0.26,0.26,0.25,0.25,0.26,0.26,0.25,0.26,0.26,0.26,0.26,0.26,0.25,0.25,0.25,0.24,0.24,0.24,0.24,0.23,0.23,0.22,0.22,0.21,0.20,0.20,0.19,0.19,0.18,0.18,0.18,0.17,0.16,0.16,0.16,0.15,0.15,0.14,0.14,0.13,0.12,0.11,0.10,-0.05,-0.05,0.24,0.24,0.24,0.24,0.24,0.24,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.24,0.24,0.24,0.24,0.23,0.23,0.22,0.22,0.22,0.21,0.21,0.20,0.20,0.18,0.18,0.17,0.17,0.17,0.16,0.16,0.16,0.16,0.15,0.14,0.14,0.13,0.13,0.12,0.11,0.10,-0.05,-0.05,0.23,0.23,0.23,0.23,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.25,0.24,0.24,0.24,0.23,0.23,0.23,0.23,0.22,0.23,0.22,0.21,0.21,0.20,0.19,0.19,0.18,0.18,0.17,0.17,0.16,0.16,0.16,0.15,0.15,0.15,0.14,0.14,0.14,0.13,0.13,0.12,0.11,0.10,-0.05,-0.05,0.22,0.22,0.23,0.23,0.24,0.23,0.23,0.23,0.23,0.24,0.24,0.24,0.24,0.24,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.22,0.21,0.21,0.20,0.20,0.19,0.19,0.18,0.18,0.17,0.17,0.16,0.15,0.15,0.15,0.15,0.15,0.15,0.14,0.14,0.13,0.13,0.12,0.12,0.11,0.10,-0.05,-0.05,0.22,0.21,0.22,0.22,0.22,0.22,0.22,0.23,0.23,0.23,0.22,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.22,0.21,0.21,0.21,0.21,0.21,0.20,0.20,0.19,0.18,0.17,0.17,0.16,0.16,0.16,0.15,0.15,0.15,0.15,0.14,0.14,0.14,0.13,0.13,0.13,0.12,0.12,0.11,0.10,-0.05,-0.05,0.21,0.21,0.21,0.22,0.22,0.22,0.21,0.22,0.22,0.22,0.22,0.22,0.22,0.22,0.23,0.22,0.22,0.22,0.22,0.21,0.21,0.21,0.21,0.21,0.20,0.19,0.19,0.19,0.18,0.17,0.17,0.16,0.16,0.16,0.16,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.13,0.13,0.12,0.12,0.11,0.11,0.10,-0.05,-0.05,0.20,0.21,0.20,0.21,0.21,0.21,0.21,0.22,0.22,0.22,0.22,0.21,0.21,0.21,0.21,0.21,0.22,0.21,0.21,0.21,0.21,0.20,0.20,0.20,0.19,0.19,0.19,0.18,0.18,0.17,0.16,0.15,0.15,0.15,0.15,0.14,0.14,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.12,0.12,0.11,0.11,0.10,-0.05,-0.05,0.19,0.20,0.20,0.20,0.20,0.21,0.21,0.20,0.20,0.20,0.21,0.21,0.21,0.21,0.21,0.21,0.21,0.20,0.20,0.20,0.20,0.20,0.19,0.20,0.19,0.19,0.18,0.17,0.17,0.16,0.16,0.15,0.15,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.11,0.11,0.10,0.10,-0.05,-0.05,0.19,0.20,0.20,0.19,0.19,0.19,0.20,0.20,0.20,0.20,0.21,0.21,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.18,0.18,0.18,0.17,0.17,0.17,0.17,0.16,0.16,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.10,-0.05,-0.05,0.18,0.18,0.19,0.19,0.19,0.19,0.20,0.20,0.19,0.19,0.19,0.19,0.19,0.20,0.20,0.20,0.20,0.20,0.19,0.19,0.18,0.18,0.18,0.18,0.18,0.17,0.17,0.16,0.16,0.15,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.10,0.10,-0.05,-0.05,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.18,0.19,0.18,0.19,0.18,0.18,0.18,0.18,0.18,0.17,0.17,0.16,0.16,0.16,0.15,0.15,0.14,0.14,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.12,0.11,0.11,0.11,0.10,-0.05,-0.05,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.19,0.18,0.18,0.18,0.17,0.17,0.17,0.17,0.17,0.17,0.16,0.16,0.16,0.14,0.14,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.11,0.11,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.16,0.16,0.17,0.17,0.18,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.18,0.18,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.16,0.15,0.15,0.15,0.14,0.14,0.13,0.13,0.13,0.13,0.11,0.11,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.11,0.11,0.10,-0.05,-0.05,0.16,0.15,0.16,0.16,0.16,0.17,0.17,0.17,0.17,0.17,0.16,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.16,0.16,0.16,0.15,0.15,0.15,0.15,0.15,0.14,0.13,0.12,0.12,0.12,0.11,0.11,0.11,0.11,0.11,0.12,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,-0.05,-0.05,0.15,0.15,0.16,0.16,0.16,0.16,0.15,0.16,0.16,0.16,0.16,0.17,0.17,0.17,0.17,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.15,0.15,0.15,0.14,0.14,0.14,0.13,0.13,0.12,0.12,0.12,0.11,0.11,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.15,0.15,0.14,0.15,0.15,0.15,0.15,0.16,0.16,0.16,0.16,0.15,0.16,0.15,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.15,0.14,0.14,0.14,0.14,0.14,0.14,0.13,0.13,0.11,0.11,0.11,0.10,0.11,0.10,0.11,0.11,0.11,0.11,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.13,0.14,0.14,0.14,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.16,0.16,0.16,0.15,0.15,0.15,0.14,0.15,0.14,0.14,0.14,0.14,0.13,0.12,0.12,0.12,0.11,0.11,0.11,0.10,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.10,-0.05,-0.05,0.13,0.14,0.14,0.13,0.13,0.14,0.14,0.14,0.15,0.15,0.15,0.15,0.14,0.14,0.15,0.14,0.14,0.15,0.14,0.15,0.14,0.15,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.10,0.10,0.10,0.09,0.10,0.10,0.10,0.10,0.11,0.11,0.10,0.10,0.10,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.12,0.12,0.13,0.13,0.13,0.13,0.14,0.14,0.13,0.13,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.15,0.13,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.10,0.10,0.10,-0.05,-0.05,0.12,0.12,0.12,0.13,0.12,0.12,0.13,0.13,0.13,0.13,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.14,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.10,0.11,0.11,0.11,0.12,0.12,0.13,0.13,0.13,0.12,0.12,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.10,0.11,0.11,0.11,0.12,0.11,0.11,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.09,0.08,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.10,0.09,0.10,0.10,0.11,0.11,0.11,0.11,0.12,0.12,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.10,0.09,0.09,0.08,0.08,0.08,0.08,0.08,0.09,0.09,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.11,0.10,-0.05,-0.05,0.09,0.09,0.10,0.10,0.10,0.11,0.10,0.10,0.11,0.11,0.11,0.11,0.12,0.12,0.12,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.09,0.09,0.09,0.08,0.08,0.08,0.08,0.07,0.08,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.09,0.09,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.11,0.11,0.10,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.08,0.07,0.07,0.07,0.07,0.08,0.08,0.08,0.08,0.09,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.09,0.09,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.08,0.08,0.08,0.08,0.08,0.08,0.07,0.08,0.08,0.07,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.07,0.08,0.08,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.08,0.08,0.07,0.07,0.07,0.07,0.07,0.07,0.08,0.08,0.08,0.09,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_un_ne")
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z)
	var flat := func(_x: float, _z: float) -> float: return 0.15
	var quad := L.eased(land, [[Vector2(6.0, -125.0), Vector2(118.0, -125.0), flat], [Vector2(6.0, -6.0), Vector2(118.0, -6.0), flat],
		[Vector2(6.0, -125.0), Vector2(6.0, -6.0), flat], [Vector2(118.0, -125.0), Vector2(118.0, -6.0), flat]], 12.0)
	c.terrain([[0.0, -190.8, 190.8, -125.0, flat], [6.0, -125.0, 118.0, -6.0, quad], [0.0, -125.0, 6.0, -6.0, flat],
		[118.0, -125.0, 190.8, -6.0, flat], [0.0, -6.0, 190.8, 0.0, flat]])
	# ---- surfaces (first paint wins)
	c.paint("plaza", 0.0, -190.8, 6.0, 0.0)                    # the north mall (west half of it)
	c.paint("plaza", 0.0, -6.0, 190.8, 0.0)                    # the east mall (north half of it)
	c.paint("asphalt", 54.0, -190.8, 60.0, -166.0)             # bus lane in (from 6th St's apron at u -546)
	c.paint("asphalt", 54.0, -172.0, 146.0, -166.0)            # bus lane along the platform
	c.paint("asphalt", 140.0, -190.8, 146.0, -166.0)           # bus lane out (to the apron at u -460)
	c.paint("concrete", 60.0, -190.8, 140.0, -172.0)           # the platform island
	c.paint("plaza", 54.0, -166.0, 146.0, -150.0)              # University Plaza in front of the hall
	c.paint("plaza", 54.0, -150.0, 146.0, -128.0)              # terraces beside and behind the hall
	c.paint("plaza", 6.0, -190.8, 54.0, -168.0)                # the gate corner: café terrace and bikes
	c.paint("grass", 6.0, -168.0, 54.0, -137.5)                # the lawn by the lecture wing
	c.paint("concrete", 6.0, -137.5, 54.0, -125.0)             # the lecture wing's front walk
	for qp: Array in [[6.0, -66.0, 118.0, -64.0], [61.0, -125.0, 63.0, -6.0], [6.0, -125.0, 118.0, -123.0], [6.0, -8.0, 118.0, -6.0], [6.0, -125.0, 8.0, -6.0], [116.0, -125.0, 118.0, -6.0]]:
		c.paint("concrete", float(qp[0]), float(qp[1]), float(qp[2]), float(qp[3]))      # the quad's paths
	c.paint("grass", 8.0, -123.0, 116.0, -8.0)                 # the quad lawn
	c.paint("concrete", 118.0, -125.0, 146.0, -6.0)            # the library's walk and forecourt
	c.paint("asphalt", 146.0, -146.0, 190.8, -140.0)           # lot lane from the east street (apron v -746)
	c.paint("asphalt", 146.0, -60.0, 190.8, -54.0)             # lot lane to the east street (apron v -660)
	c.paint("asphalt", 146.0, -146.0, 177.0, -54.0)            # the faculty lot (lane, two stall rows, aisle)
	c.paint("grass", 177.0, -140.0, 190.8, -60.0)              # planted buffer to the east street
	c.paint("grass", 146.0, -190.8, 190.8, -146.0)             # the corner lawn
	c.paint("grass", 146.0, -54.0, 190.8, -20.0)               # the lawn behind the science wing
	c.paint("concrete", 146.0, -20.0, 190.8, -6.0)             # the science wing's walk
	for wp: Array in [[64.0, -158.0], [136.0, -158.0], [3.0, -170.0], [3.0, -110.0], [3.0, -50.0], [40.0, -3.0], [100.0, -3.0], [160.0, -3.0]]:
		c.well(float(wp[0]), float(wp[1]))
	c.build_floor(L.rect_edges(0.0, -190.8, 190.8, 0.0))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b090_a", Vector3(-600, 6, -800), 90.0], ["s_rs_b090_b", Vector3(-400, 6, -800), -90.0], ["s_rs_b022_a", Vector3(-400, 6, -800), 0.0], ["s_rs_b022_b", Vector3(-400, 6, -600), -180.0],
		["j_apt", Vector3(-400, 6, -800), 0.0], ["j_rs_t_lll_a", Vector3(-600, 6, -800), 180.0], ["j_rs_t_lll_b", Vector3(-400, 6, -600), 90.0]], O)
	var y := 0.15
	# ---- buildings (each by its real front, at walk level)
	var H := c.bld("public/pub_university", Vector2(100.0, -150.0), "n", false, "uni_hall")
	var LW := c.bld("civic/civ_school_wing", Vector2(30.0, -125.0), "s", false, "uni_lecture_west")
	var LB := c.bld("civic/civ_library", Vector2(120.0, -66.0), "w", false, "uni_library")
	var SW := c.bld("civic/civ_school_wing", Vector2(166.0, -6.4), "s", false, "uni_science")
	var CF := c.bld("commercial/com_shallow_cafe", Vector2(14.5, -190.5), "n", false, "uni_gate_cafe")
	var BK := c.bld("commercial/com_shallow_books", Vector2(23.0, -190.5), "n", false, "uni_gate_books")
	var KI := c.bld("commercial/com_kiosk", Vector2(100.0, -172.6), "s", false, "uni_bus_kiosk")
	# ---- the bus station: shelters face the bus lane, benches and timetables, bikes on the island's street side
	for sx: float in [70.0, 84.0, 116.0, 130.0]:
		c.put("prop_bus_shelter", "worn", Vector3(sx, y, -173.6), 0.0, "bus station: a shelter on the platform edge, facing the buses")
	c.put("prop_bus_stop_sign", "worn", Vector3(62.0, y, -172.6), 0.0, "bus station: stop sign where the buses pull in")
	c.put("prop_bus_stop_sign", "worn", Vector3(138.0, y, -172.6), 0.0, "bus station: stop sign for the second bay")
	for px: float in [77.0, 123.0]: c.put("prop_poster_case", "worn", Vector3(px, y, -174.0), 0.0, "bus station: timetable and campus map case between the shelters")
	for tx: float in [92.0, 108.0]: c.put("prop_trash_receptacle", "worn", Vector3(tx, y, -173.2), 0.0, "bus station: a bin by the kiosk")
	for bx: float in [66.0, 74.0, 82.0, 118.0, 126.0, 134.0]: c.put("prop_bike_rack", "worn", Vector3(bx, y, -188.6), 0.0, "bus station: bikes along the island's street side, parallel to the walk")
	for bo: float in [-189.0, -185.0, -181.0, -177.0]:
		c.put("prop_bollard_steel", "worn", Vector3(60.6, y, bo), 0.0, "bus station: bollards keep cars off the island")
		c.put("prop_bollard_steel", "worn", Vector3(139.4, y, bo), 0.0, "bus station: bollards keep cars off the island")
	c.put("prop_sign_no_parking", "worn", Vector3(53.4, y, -189.6), 90.0, "bus lane: buses only, no stopping")
	c.put("prop_sign_no_parking", "worn", Vector3(146.6, y, -189.6), -90.0, "bus lane: buses only, no stopping")
	for lx: float in [64.0, 100.0, 136.0]: c.put("prop_lamp_cobra", "worn", Vector3(lx, y, -183.0), 0.0, "bus station: the platform lit at night")
	for bz: Array in [[70.0], [84.0], [116.0], [130.0]]: c.put("prop_bench_bus_stop", "worn", Vector3(float(bz[0]), y, -165.4), 180.0, "bus station: seats on the campus side of the lane, facing the bays")
	c.put("prop_vending_soda", "worn", Vector3(93.0, y, -178.6), 0.0, "bus station: drinks beside the kiosk's back")
	c.put("prop_vending_snack", "worn", Vector3(107.0, y, -178.6), 0.0, "bus station: snacks beside the kiosk's back")
	for tm: Array in [[57.0, -175.0, 45.0], [143.0, -175.0, -45.0], [80.0, -169.0, 90.0], [124.0, -169.0, 90.0]]: c.tyre(Vector2(float(tm[0]), float(tm[1])), float(tm[2]), 6.0, 0.45)
	c.oil(Vector2(78.0, -169.0), 90.0); c.oil(Vector2(122.0, -169.0), 90.0)
	# ---- University Plaza
	for lp: float in [70.0, 86.0, 114.0, 130.0]: c.put("prop_lamp_victorian", "worn", Vector3(lp, y, -153.0), 0.0, "plaza: lamps along the hall's front")
	for wx: float in [64.0, 136.0]: c.put("tree_magnolia_a", "normal", Vector3(wx, y, -158.0), c.rr.randf_range(0, 360), "plaza: magnolias in wells framing the hall", true, 0.9)
	for bn: float in [70.0, 78.0, 122.0, 130.0]: c.put("prop_park_bench", "worn", Vector3(bn, y, -160.6), 0.0, "plaza: benches facing the hall")
	c.put("prop_obelisk_monument", "worn", Vector3(100.0, y, -159.0), 0.0, "plaza: the founders' monument on the axis of the hall's door")
	for pl: float in [91.0, 109.0]: c.put("plant_potted_leafy", "normal", Vector3(pl, y, -151.0), 0.0, "plaza: planters either side of the hall's steps")
	c.put("prop_drinking_fountain", "worn", Vector3(140.0, y, -152.0), 0.0, "plaza: water for people off the buses")
	# ---- the gate corner: café terrace, bookstore, bikes (students from the gritty edge come in here)
	for ct: Array in [[10.0, -177.0], [16.0, -177.0], [22.0, -177.0], [10.0, -171.5], [16.0, -171.5], [22.0, -171.5]]:
		c.put("prop_cafe_table", "worn", Vector3(float(ct[0]), y, float(ct[1])), 0.0, "café terrace: tables in the sun by the gate")
		c.put("prop_cafe_chair", "worn", Vector3(float(ct[0]) - 0.8, y, float(ct[1])), 90.0, "café terrace: a chair at its table", false)
		c.put("prop_cafe_chair", "worn", Vector3(float(ct[0]) + 0.8, y, float(ct[1])), -90.0, "café terrace: a chair at its table", false)
	c.put("prop_menu_board", "worn", Vector3(9.0, y, -186.0), 0.0, "café: the day's menu at the terrace entrance")
	for br: float in [32.0, 36.0, 40.0, 44.0, 48.0]: c.put("prop_bike_rack", "worn", Vector3(br, y, -186.0), 90.0, "gate corner: students' bikes in rows off the walk")
	c.put("prop_newspaper_box_red", "worn", Vector3(7.5, y, -190.0), 180.0, "gate corner: the student paper at the gate")
	c.put("prop_newspaper_box_blue", "worn", Vector3(8.3, y, -190.0), 180.0, "gate corner: papers at the gate")
	c.put("prop_recycling_receptacle", "worn", Vector3(27.0, y, -184.0), 0.0, "café terrace: recycling for cups")
	# ---- the lecture wing's lawn
	for t: Array in [[14.0, -150.0, "tree_jacaranda_a", 0.85], [44.0, -158.0, "tree_jacaranda_b", 0.85]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), y, float(t[1])), c.rr.randf_range(0, 360), "lecture lawn: shade trees in the grass", true, float(t[3]))
	c.put("prop_picnic_table", "worn", Vector3(30.0, y, -152.0), 0.0, "lecture lawn: a table between classes")
	# ---- the main quad: paths lined one species each, benches facing the lawn, tables, lamps
	for qz: float in [-115.0, -95.0, -75.0, -55.0, -35.0, -15.0]:
		for side: float in [-3.0, 3.0]:
			c.put("tree_magnolia_b", "normal", Vector3(62.0 + side, c.yf(62.0 + side, qz), qz), c.rr.randf_range(0, 360), "quad: magnolias line the north-south path", true, 0.8)
	for qx: float in [16.0, 36.0, 88.0, 108.0]:
		for side2: float in [-3.0, 3.0]:
			c.put("tree_jacaranda_a", "normal", Vector3(qx, c.yf(qx, -65.0 + side2), -65.0 + side2), c.rr.randf_range(0, 360), "quad: jacarandas line the cross path", true, 0.8)
	for bq: Array in [[26.0, -67.4, 180.0], [46.0, -62.6, 0.0], [78.0, -67.4, 180.0], [98.0, -62.6, 0.0], [59.6, -100.0, 90.0], [64.4, -30.0, -90.0], [59.6, -40.0, 90.0], [64.4, -90.0, -90.0]]:
		c.put("prop_park_bench", "worn", Vector3(float(bq[0]), c.yf(float(bq[0]), float(bq[1])), float(bq[1])), float(bq[2]), "quad: a bench on the path facing the lawn")
	for pt: Array in [[30.0, -100.0], [94.0, -40.0], [30.0, -30.0]]:
		c.put("prop_picnic_table", "worn", Vector3(float(pt[0]), c.yf(float(pt[0]), float(pt[1])), float(pt[1])), 0.0, "quad: a table on the lawn for lunch outdoors")
	for ql: Array in [[62.0, -124.0], [62.0, -65.0], [62.0, -7.0], [7.0, -65.0], [117.0, -65.0]]:
		c.put("prop_lamp_victorian", "worn", Vector3(float(ql[0]) + 1.6, y, float(ql[1])), 0.0, "quad: the paths lit at night")
	c.put("prop_drinking_fountain", "worn", Vector3(64.6, c.yf(64.6, -67.0), -67.0), 0.0, "quad: water where the paths cross")
	# ---- the malls (half of each in this piece): palms in wells, lamps, benches facing the quad
	for mz: float in [-170.0, -110.0, -50.0]: c.put("palm_canary_date_a", "normal", Vector3(3.0, y, mz), c.rr.randf_range(0, 360), "north mall: date palms in wells, the campus axis", true, 0.9)
	for mx: float in [40.0, 100.0, 160.0]: c.put("palm_canary_date_b", "normal", Vector3(mx, y, -3.0), c.rr.randf_range(0, 360), "east mall: date palms in wells, the campus axis", true, 0.9)
	for ml: float in [-140.0, -80.0, -20.0]: c.put("prop_lamp_victorian", "worn", Vector3(4.6, y, ml), 0.0, "north mall: lamps")
	for ml2: float in [70.0, 130.0, 186.0]: c.put("prop_lamp_victorian", "worn", Vector3(ml2, y, -4.6), 0.0, "east mall: lamps")
	# ---- the library's forecourt
	c.put("prop_bike_rack", "worn", Vector3(124.0, y, -84.0), 90.0, "library: bikes beside the entrance, parallel to the wall")
	c.put("prop_bike_rack", "worn", Vector3(124.0, y, -48.0), 90.0, "library: bikes beside the entrance, parallel to the wall")
	c.put("prop_park_bench", "worn", Vector3(118.8, y, -100.0), -90.0, "library: a bench looking over the quad")
	c.put("prop_trash_receptacle", "worn", Vector3(119.0, y, -76.0), 0.0, "library: a bin by the door")
	# ---- the faculty lot: two stall rows each side of an aisle, lights, meter, signs
	for k in 28:
		var sz := -137.0 + k * 2.7
		if sz > -63.0: break
		c.stalls.append([154.5, sz, -90.0, y]); c.stalls.append([159.5, sz, 90.0, y]); c.stalls.append([170.5, sz, -90.0, y])
		if k % 4 == 1: c.oil(Vector2(159.5, sz), 90.0)
	for lp2: float in [-125.0, -100.0, -75.0]: c.put("prop_lot_light_pole", "worn", Vector3(157.0, y, lp2), 0.0, "lot: light poles on the line between the back-to-back rows")
	c.put("prop_parking_meter", "worn", Vector3(176.4, y, -138.0), 0.0, "lot: the pay station by the entrance lane")
	c.put("prop_sign_no_parking", "worn", Vector3(152.6, y, -147.0), 0.0, "lot: keep the lane clear")
	c.tyre(Vector2(187.0, -143.0), -80.0, 6.0, 0.4); c.tyre(Vector2(187.0, -57.0), 80.0, 6.0, 0.4); c.tyre(Vector2(149.0, -143.0), 30.0, 5.0, 0.35); c.tyre(Vector2(165.0, -57.0), -30.0, 5.0, 0.35)
	c.cracks(146.0, -146.0, 177.0, -54.0, 14, 0.4)
	for t2: Array in [[180.0, -130.0, "tree_eucalyptus_a"], [186.0, -110.0, "tree_eucalyptus_b"], [180.0, -90.0, "tree_eucalyptus_a"], [186.0, -70.0, "tree_eucalyptus_b"], [160.0, -175.0, "tree_torrey_pine_a"], [178.0, -160.0, "tree_coral_a"], [165.0, -40.0, "tree_ficus_a"], [182.0, -32.0, "tree_magnolia_a"]]:
		c.put(String(t2[2]), "normal", Vector3(float(t2[0]), y, float(t2[1])), c.rr.randf_range(0, 360), "lawns: trees in the grass (eucalyptus screen the lot from the street)", true, 0.85)
	c.put("prop_transformer_substation", "worn", Vector3(150.0, y, -186.0), 0.0, "the campus quarter's transformer, in the corner lawn off the bus lane")
	# ---- service sides, bins
	for r: Dictionary in [H, LW, LB, SW, CF, BK]: c.services(r, 2.0, 1, false)
	c.put("prop_dumpster_3yd_green", "worn", Vector3(126.0, y, -131.0), 90.0, "hall: waste, collected from the lot lane")
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(126.0, y, -134.0), 90.0, "hall and library: paper recycling")
	c.put("prop_dumpster_3yd_green", "worn", Vector3(50.0, y, -170.0), 0.0, "café and bookstore: waste by the bus lane")
	# ---- roofs and doors
	c.roof_plant(H, [[-10.0, -4.0, "prop_ac_condenser"], [10.0, -4.0, "prop_ac_condenser"], [0.0, 3.0, "prop_vent_box"]], "roof plant (hall)")
	for r2: Dictionary in [LW, LB, SW]: c.roof_plant(r2, [[-6.0, -2.0, "prop_ac_condenser"], [6.0, -2.0, "prop_vent_box"]], "roof plant")
	for r3: Dictionary in [H, LW, LB, SW, CF, BK, KI]:
		for dr: Array in r3.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
