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
## GROUND (elevation): the land here is a low crown (6.13..6.30); the ground follows it 8 cm over it and eases to walk level 6.15 at
## both streets and their aprons; buildings on level pads at the highest ground under each (plinth faces, none sunk).
## EXTERIOR: shelters, benches, timetable cases, bike racks, bollards, lamps on the platform; the plaza (lamps, trees in
## wells, benches facing the hall, planters, a fountain); the quad (paths lined one species each, benches facing the
## lawn, tables, lamps); the café terrace; the lot (stalls, light poles, meters, oil, tyre marks at the aprons).
## GATE SHOPS (19 Nov night, Yasin: "swap the models with explorable ones"): the café is com_cafe_seaside and the
## bookstore com_realty (both with real shop doors; the com_shallow_* models had house doors the room cut does not open);
## their terrace stands beside them on the gate plaza, the bikes along its east edge.
## TREES (19 Nov late, Yasin: "remove every tree, fill their wells ... place new trees according to the tree plan"): this
## piece has NO trees and no tree wells (each well paved over in the material round it); the campus trees are the
## hand-placed layer t_un_campus (docs/TREE_PLAN.md).
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(-600.0, 6.0, -600.0)
const LAND := {"x0": -4.0, "z0": -196.0, "step": 4.0, "nx": 51, "nz": 51, "h": [-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.11,0.11,0.10,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.13,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.12,0.11,0.12,0.11,0.11,0.10,0.10,-0.05,-0.05,0.15,0.16,0.16,0.15,0.15,0.15,0.16,0.16,0.16,0.16,0.16,0.16,0.15,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.15,0.15,0.15,0.15,0.15,0.15,0.14,0.14,0.14,0.13,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.10,-0.05,-0.05,0.17,0.17,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.18,0.17,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.17,0.18,0.17,0.18,0.17,0.18,0.17,0.17,0.16,0.16,0.16,0.15,0.16,0.15,0.15,0.15,0.15,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.13,0.13,0.13,0.11,0.11,0.10,-0.05,-0.05,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.19,0.19,0.19,0.18,0.18,0.18,0.18,0.17,0.17,0.17,0.16,0.16,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.14,0.13,0.13,0.12,0.12,0.10,-0.05,-0.05,0.20,0.20,0.20,0.20,0.21,0.21,0.21,0.21,0.21,0.21,0.21,0.21,0.21,0.22,0.22,0.21,0.22,0.22,0.22,0.21,0.21,0.21,0.21,0.21,0.21,0.21,0.20,0.20,0.19,0.19,0.18,0.19,0.18,0.17,0.17,0.17,0.17,0.17,0.16,0.16,0.16,0.16,0.15,0.15,0.15,0.14,0.13,0.12,0.10,-0.05,-0.05,0.22,0.22,0.22,0.22,0.22,0.22,0.22,0.23,0.23,0.23,0.23,0.24,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.24,0.23,0.23,0.23,0.22,0.22,0.21,0.21,0.21,0.21,0.20,0.20,0.20,0.19,0.18,0.18,0.18,0.18,0.18,0.17,0.17,0.17,0.17,0.16,0.15,0.15,0.13,0.12,0.10,-0.05,-0.05,0.24,0.23,0.23,0.23,0.23,0.24,0.24,0.25,0.24,0.25,0.24,0.24,0.25,0.24,0.25,0.25,0.25,0.25,0.25,0.25,0.24,0.24,0.24,0.24,0.24,0.24,0.23,0.23,0.23,0.21,0.21,0.21,0.21,0.20,0.20,0.19,0.20,0.19,0.19,0.18,0.18,0.18,0.17,0.17,0.16,0.15,0.14,0.12,0.10,-0.05,-0.05,0.24,0.25,0.24,0.25,0.25,0.26,0.25,0.26,0.26,0.25,0.26,0.26,0.26,0.26,0.27,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.25,0.24,0.24,0.24,0.23,0.23,0.22,0.22,0.22,0.22,0.20,0.20,0.20,0.19,0.20,0.19,0.19,0.18,0.18,0.16,0.15,0.14,0.12,0.10,-0.05,-0.05,0.25,0.26,0.25,0.26,0.26,0.27,0.27,0.27,0.27,0.27,0.28,0.27,0.27,0.27,0.28,0.28,0.27,0.28,0.28,0.28,0.28,0.27,0.27,0.27,0.26,0.26,0.26,0.25,0.25,0.25,0.24,0.23,0.23,0.22,0.22,0.22,0.21,0.21,0.21,0.21,0.20,0.20,0.19,0.18,0.17,0.16,0.15,0.12,0.10,-0.05,-0.05,0.26,0.27,0.27,0.27,0.27,0.27,0.28,0.27,0.28,0.28,0.28,0.28,0.29,0.29,0.29,0.29,0.29,0.28,0.28,0.29,0.28,0.29,0.28,0.28,0.28,0.27,0.27,0.26,0.26,0.25,0.25,0.24,0.24,0.23,0.23,0.23,0.22,0.22,0.21,0.21,0.21,0.20,0.20,0.18,0.18,0.16,0.14,0.12,0.10,-0.05,-0.05,0.27,0.28,0.28,0.27,0.28,0.28,0.28,0.28,0.29,0.29,0.30,0.30,0.29,0.29,0.29,0.30,0.29,0.30,0.29,0.30,0.29,0.29,0.29,0.28,0.28,0.28,0.28,0.27,0.27,0.26,0.26,0.25,0.24,0.24,0.23,0.23,0.22,0.23,0.22,0.21,0.21,0.20,0.19,0.18,0.18,0.16,0.15,0.12,0.10,-0.05,-0.05,0.27,0.27,0.28,0.28,0.29,0.29,0.29,0.29,0.29,0.29,0.29,0.30,0.30,0.30,0.30,0.31,0.30,0.31,0.30,0.29,0.30,0.29,0.30,0.29,0.29,0.29,0.29,0.27,0.27,0.26,0.26,0.26,0.25,0.25,0.24,0.24,0.23,0.22,0.22,0.21,0.21,0.20,0.20,0.18,0.18,0.16,0.14,0.12,0.10,-0.05,-0.05,0.28,0.28,0.29,0.29,0.29,0.29,0.29,0.29,0.29,0.30,0.30,0.31,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.29,0.29,0.29,0.28,0.28,0.27,0.27,0.26,0.26,0.24,0.24,0.23,0.23,0.23,0.22,0.22,0.21,0.21,0.20,0.19,0.18,0.16,0.15,0.13,0.12,0.10,-0.05,-0.05,0.28,0.28,0.29,0.29,0.29,0.29,0.29,0.30,0.30,0.30,0.30,0.30,0.30,0.31,0.30,0.30,0.31,0.30,0.31,0.30,0.30,0.30,0.30,0.29,0.29,0.29,0.28,0.28,0.27,0.27,0.26,0.26,0.25,0.24,0.24,0.23,0.23,0.22,0.21,0.20,0.20,0.19,0.18,0.17,0.16,0.15,0.14,0.12,0.10,-0.05,-0.05,0.28,0.28,0.29,0.29,0.29,0.29,0.29,0.29,0.29,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.29,0.29,0.28,0.28,0.28,0.27,0.27,0.27,0.26,0.25,0.25,0.24,0.23,0.22,0.22,0.21,0.21,0.20,0.19,0.19,0.18,0.17,0.15,0.14,0.13,0.12,0.10,-0.05,-0.05,0.28,0.27,0.27,0.28,0.28,0.29,0.29,0.29,0.29,0.30,0.29,0.29,0.29,0.29,0.30,0.29,0.30,0.30,0.30,0.30,0.28,0.29,0.28,0.28,0.28,0.28,0.27,0.27,0.26,0.25,0.25,0.24,0.23,0.22,0.22,0.21,0.21,0.21,0.21,0.19,0.18,0.18,0.17,0.16,0.15,0.14,0.13,0.12,0.10,-0.05,-0.05,0.27,0.27,0.27,0.28,0.28,0.28,0.28,0.28,0.28,0.29,0.29,0.28,0.29,0.29,0.29,0.28,0.29,0.28,0.29,0.28,0.28,0.28,0.28,0.28,0.27,0.27,0.26,0.26,0.25,0.24,0.24,0.23,0.23,0.22,0.22,0.20,0.20,0.20,0.19,0.19,0.18,0.18,0.17,0.16,0.15,0.14,0.13,0.11,0.10,-0.05,-0.05,0.26,0.27,0.26,0.27,0.27,0.27,0.27,0.28,0.28,0.28,0.28,0.27,0.28,0.28,0.28,0.28,0.28,0.28,0.28,0.28,0.28,0.27,0.26,0.27,0.26,0.26,0.25,0.25,0.25,0.24,0.23,0.22,0.21,0.21,0.21,0.20,0.19,0.19,0.19,0.18,0.17,0.17,0.16,0.16,0.15,0.14,0.13,0.11,0.10,-0.05,-0.05,0.25,0.26,0.26,0.26,0.26,0.27,0.27,0.26,0.27,0.27,0.27,0.27,0.27,0.27,0.28,0.28,0.27,0.27,0.26,0.27,0.26,0.27,0.26,0.26,0.26,0.25,0.24,0.23,0.23,0.23,0.22,0.21,0.21,0.20,0.20,0.20,0.18,0.18,0.18,0.18,0.17,0.17,0.16,0.15,0.15,0.13,0.12,0.11,0.10,-0.05,-0.05,0.25,0.26,0.26,0.25,0.25,0.25,0.26,0.26,0.26,0.26,0.27,0.27,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.26,0.25,0.24,0.24,0.24,0.24,0.23,0.23,0.22,0.22,0.20,0.19,0.19,0.18,0.18,0.18,0.18,0.17,0.17,0.17,0.15,0.15,0.14,0.14,0.13,0.12,0.11,0.10,-0.05,-0.05,0.24,0.24,0.25,0.25,0.25,0.25,0.26,0.26,0.25,0.25,0.26,0.26,0.25,0.26,0.26,0.26,0.26,0.26,0.25,0.25,0.25,0.24,0.24,0.24,0.24,0.23,0.23,0.22,0.22,0.21,0.20,0.20,0.19,0.19,0.18,0.18,0.18,0.17,0.16,0.16,0.16,0.15,0.15,0.14,0.14,0.13,0.12,0.11,0.10,-0.05,-0.05,0.24,0.24,0.24,0.24,0.24,0.24,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.24,0.24,0.24,0.24,0.23,0.23,0.22,0.22,0.22,0.21,0.21,0.20,0.20,0.18,0.18,0.17,0.17,0.17,0.16,0.16,0.16,0.16,0.15,0.14,0.14,0.13,0.13,0.12,0.11,0.10,-0.05,-0.05,0.23,0.23,0.23,0.23,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.25,0.24,0.24,0.24,0.23,0.23,0.23,0.23,0.22,0.23,0.22,0.21,0.21,0.20,0.19,0.19,0.18,0.18,0.17,0.17,0.16,0.16,0.16,0.15,0.15,0.15,0.14,0.14,0.14,0.13,0.13,0.12,0.11,0.10,-0.05,-0.05,0.22,0.22,0.23,0.23,0.24,0.23,0.23,0.23,0.23,0.24,0.24,0.24,0.24,0.24,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.22,0.21,0.21,0.20,0.20,0.19,0.19,0.18,0.18,0.17,0.17,0.16,0.15,0.15,0.15,0.15,0.15,0.15,0.14,0.14,0.13,0.13,0.12,0.12,0.11,0.10,-0.05,-0.05,0.22,0.21,0.22,0.22,0.22,0.22,0.22,0.23,0.23,0.23,0.22,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.23,0.22,0.21,0.21,0.21,0.21,0.21,0.20,0.20,0.19,0.18,0.17,0.17,0.16,0.16,0.16,0.15,0.15,0.15,0.15,0.14,0.14,0.14,0.13,0.13,0.13,0.12,0.12,0.11,0.10,-0.05,-0.05,0.21,0.21,0.21,0.22,0.22,0.22,0.21,0.22,0.22,0.22,0.22,0.22,0.22,0.22,0.23,0.22,0.22,0.22,0.22,0.21,0.21,0.21,0.21,0.21,0.20,0.19,0.19,0.19,0.18,0.17,0.17,0.16,0.16,0.16,0.16,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.13,0.13,0.12,0.12,0.11,0.11,0.10,-0.05,-0.05,0.20,0.21,0.20,0.21,0.21,0.21,0.21,0.22,0.22,0.22,0.22,0.21,0.21,0.21,0.21,0.21,0.22,0.21,0.21,0.21,0.21,0.20,0.20,0.20,0.19,0.19,0.19,0.18,0.18,0.17,0.16,0.15,0.15,0.15,0.15,0.14,0.14,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.12,0.12,0.11,0.11,0.10,-0.05,-0.05,0.19,0.20,0.20,0.20,0.20,0.21,0.21,0.20,0.20,0.20,0.21,0.21,0.21,0.21,0.21,0.21,0.21,0.20,0.20,0.20,0.20,0.20,0.19,0.20,0.19,0.19,0.18,0.17,0.17,0.16,0.16,0.15,0.15,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.11,0.11,0.10,0.10,-0.05,-0.05,0.19,0.20,0.20,0.19,0.19,0.19,0.20,0.20,0.20,0.20,0.21,0.21,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.20,0.18,0.18,0.18,0.17,0.17,0.17,0.17,0.16,0.16,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.10,-0.05,-0.05,0.18,0.18,0.19,0.19,0.19,0.19,0.20,0.20,0.19,0.19,0.19,0.19,0.19,0.20,0.20,0.20,0.20,0.20,0.19,0.19,0.18,0.18,0.18,0.18,0.18,0.17,0.17,0.16,0.16,0.15,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.10,0.10,-0.05,-0.05,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.19,0.19,0.19,0.19,0.19,0.19,0.19,0.18,0.19,0.18,0.19,0.18,0.18,0.18,0.18,0.18,0.17,0.17,0.16,0.16,0.16,0.15,0.15,0.14,0.14,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.12,0.11,0.11,0.11,0.10,-0.05,-0.05,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.19,0.18,0.18,0.18,0.17,0.17,0.17,0.17,0.17,0.17,0.16,0.16,0.16,0.14,0.14,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.11,0.11,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.16,0.16,0.17,0.17,0.18,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.18,0.18,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.16,0.15,0.15,0.15,0.14,0.14,0.13,0.13,0.13,0.13,0.11,0.11,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.11,0.11,0.10,-0.05,-0.05,0.16,0.15,0.16,0.16,0.16,0.17,0.17,0.17,0.17,0.17,0.16,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.17,0.16,0.16,0.16,0.15,0.15,0.15,0.15,0.15,0.14,0.13,0.12,0.12,0.12,0.11,0.11,0.11,0.11,0.11,0.12,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,-0.05,-0.05,0.15,0.15,0.16,0.16,0.16,0.16,0.15,0.16,0.16,0.16,0.16,0.17,0.17,0.17,0.17,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.15,0.15,0.15,0.14,0.14,0.14,0.13,0.13,0.12,0.12,0.12,0.11,0.11,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.15,0.15,0.14,0.15,0.15,0.15,0.15,0.16,0.16,0.16,0.16,0.15,0.16,0.15,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.15,0.14,0.14,0.14,0.14,0.14,0.14,0.13,0.13,0.11,0.11,0.11,0.10,0.11,0.10,0.11,0.11,0.11,0.11,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.13,0.14,0.14,0.14,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.15,0.16,0.16,0.16,0.15,0.15,0.15,0.14,0.15,0.14,0.14,0.14,0.14,0.13,0.12,0.12,0.12,0.11,0.11,0.11,0.10,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.10,-0.05,-0.05,0.13,0.14,0.14,0.13,0.13,0.14,0.14,0.14,0.15,0.15,0.15,0.15,0.14,0.14,0.15,0.14,0.14,0.15,0.14,0.15,0.14,0.15,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.10,0.10,0.10,0.09,0.10,0.10,0.10,0.10,0.11,0.11,0.10,0.10,0.10,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.12,0.12,0.13,0.13,0.13,0.13,0.14,0.14,0.13,0.13,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.15,0.13,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.10,0.10,0.10,-0.05,-0.05,0.12,0.12,0.12,0.13,0.12,0.12,0.13,0.13,0.13,0.13,0.14,0.14,0.14,0.13,0.13,0.13,0.13,0.13,0.13,0.14,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.10,0.11,0.11,0.11,0.12,0.12,0.13,0.13,0.13,0.12,0.12,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.11,0.11,0.11,0.10,0.10,-0.05,-0.05,0.10,0.11,0.11,0.11,0.12,0.11,0.11,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.09,0.08,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.10,0.09,0.10,0.10,0.11,0.11,0.11,0.11,0.12,0.12,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.10,0.09,0.09,0.08,0.08,0.08,0.08,0.08,0.09,0.09,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.11,0.10,-0.05,-0.05,0.09,0.09,0.10,0.10,0.10,0.11,0.10,0.10,0.11,0.11,0.11,0.11,0.12,0.12,0.12,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.09,0.09,0.09,0.08,0.08,0.08,0.08,0.07,0.08,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.09,0.09,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.11,0.11,0.10,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.08,0.07,0.07,0.07,0.07,0.08,0.08,0.08,0.08,0.09,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.09,0.09,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.08,0.08,0.08,0.08,0.08,0.08,0.07,0.08,0.08,0.07,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.07,0.08,0.08,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.08,0.08,0.07,0.07,0.07,0.07,0.07,0.07,0.08,0.08,0.08,0.09,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_un_ne")
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z) + 0.08     # 8 cm over the land (the preview's land mesh interpolates a few cm differently; ground exactly on it flickers)
	var flat := func(_x: float, _z: float) -> float: return 0.15
	# ELEVATION: the ground follows the land (its low crown up to 6.30 m) and eases smoothly, over 8 m, to walk level 6.15
	# at 6th St and the east street (and their aprons); every building stands on a level pad at the highest ground
	# under it (a plinth face where the ground falls away, never a building sunk on one side)
	var base := L.eased(land, [[Vector2(0.0, -190.8), Vector2(190.8, -190.8), flat], [Vector2(190.8, -190.8), Vector2(190.8, 0.0), flat]], 8.0)
	var SITES := [["public/pub_university", Vector2(100.0, -150.0), "n", "uni_hall"], ["civic/civ_school_wing", Vector2(30.0, -125.0), "s", "uni_lecture_west"],
		["civic/civ_library", Vector2(120.0, -66.0), "w", "uni_library"], ["civic/civ_school_wing", Vector2(166.0, -6.4), "s", "uni_science"],
		["commercial/com_cafe_seaside", Vector2(14.0, -189.5), "n", "uni_gate_cafe"], ["commercial/com_realty", Vector2(22.6, -189.5), "n", "uni_gate_books"],
		["commercial/com_kiosk", Vector2(100.0, -172.6), "s", "uni_bus_kiosk"]]
	var pads: Array = []
	for st: Array in SITES:
		var r0: Array = L.bld_rect(String(st[0]), st[1], String(st[2]))
		pads.append([maxf(0.0, float(r0[0]) - 0.3), maxf(-190.8, float(r0[1]) - 0.3), minf(190.8, float(r0[2]) + 0.3), minf(0.0, float(r0[3]) + 0.3)])
	var gl := L.grid_lots(0.0, -190.8, 190.8, 0.0, pads, base)
	c.terrain(gl.lots)
	c.skirt_depth = 0.4
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
	c.build_floor(L.rect_edges(0.0, -190.8, 190.8, 0.0))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b090_a", Vector3(-600, 6, -800), 90.0], ["s_rs_b090_b", Vector3(-400, 6, -800), -90.0], ["s_rs_b022_a", Vector3(-400, 6, -800), 0.0], ["s_rs_b022_b", Vector3(-400, 6, -600), -180.0],
		["j_apt", Vector3(-400, 6, -800), 0.0], ["j_rs_t_lll_a", Vector3(-600, 6, -800), 180.0], ["j_rs_t_lll_b", Vector3(-400, 6, -600), 90.0]], O)
	var y := 0.15     # (props below take c.yf at their own spot)
	# ---- buildings (each by its real front, at walk level)
	var B := {}
	for k in SITES.size():
		var st2: Array = SITES[k]
		c.y0 = float(gl.pads[k][4])
		B[String(st2[3])] = c.bld(String(st2[0]), st2[1], String(st2[2]), false, String(st2[3]))
	c.y0 = 0.15
	var H: Dictionary = B.uni_hall; var LW: Dictionary = B.uni_lecture_west; var LB: Dictionary = B.uni_library; var SW: Dictionary = B.uni_science
	var CF: Dictionary = B.uni_gate_cafe; var BK: Dictionary = B.uni_gate_books; var KI: Dictionary = B.uni_bus_kiosk
	# ---- the bus station: shelters face the bus lane, benches and timetables, bikes on the island's street side
	for sx: float in [70.0, 84.0, 116.0, 130.0]:
		c.put("prop_bus_shelter", "worn", c.gp(sx, -173.6), 0.0, "bus station: a shelter on the platform edge, facing the buses")
	c.put("prop_bus_stop_sign", "worn", c.gp(62.0, -172.6), 0.0, "bus station: stop sign where the buses pull in")
	c.put("prop_bus_stop_sign", "worn", c.gp(138.0, -172.6), 0.0, "bus station: stop sign for the second bay")
	for px: float in [77.0, 123.0]: c.put("prop_poster_case", "worn", c.gp(px, -174.0), 0.0, "bus station: timetable and campus map case between the shelters")
	for tx: float in [96.9, 103.1]: c.put("prop_trash_receptacle", "worn", c.gp(tx, -174.0), 0.0, "bus station: a bin against the kiosk's side wall")
	for bx: float in [66.0, 74.0, 82.0, 118.0, 126.0, 134.0]: c.put("prop_bike_rack", "worn", c.gp(bx, -188.6), 0.0, "bus station: bikes along the island's street side, parallel to the walk")
	for bo: float in [-189.0, -185.0, -181.0, -177.0]:
		c.put("prop_bollard_steel", "worn", c.gp(60.6, bo), 0.0, "bus station: bollards keep cars off the island")
		c.put("prop_bollard_steel", "worn", c.gp(139.4, bo), 0.0, "bus station: bollards keep cars off the island")
	c.put("prop_sign_no_parking", "worn", c.gp(53.4, -189.6), 90.0, "bus lane: buses only, no stopping")
	c.put("prop_sign_no_parking", "worn", c.gp(146.6, -189.6), -90.0, "bus lane: buses only, no stopping")
	for lx: float in [64.0, 100.0, 136.0]: c.put("prop_lamp_cobra", "worn", c.gp(lx, -183.0), 0.0, "bus station: the platform lit at night")
	for bz: Array in [[70.0], [84.0], [116.0], [130.0]]: c.put("prop_bench_bus_stop", "worn", c.gp(float(bz[0]), -165.4), 180.0, "bus station: seats on the campus side of the lane, facing the bays")
	c.put("prop_vending_soda", "worn", c.gp(93.0, -178.6), 0.0, "bus station: drinks beside the coffee kiosk")
	c.put("prop_vending_snack", "worn", c.gp(107.0, -178.6), 0.0, "bus station: snacks beside the kiosk's back")
	for tm: Array in [[57.0, -175.0, 45.0], [143.0, -175.0, -45.0], [80.0, -169.0, 90.0], [124.0, -169.0, 90.0]]: c.tyre(Vector2(float(tm[0]), float(tm[1])), float(tm[2]), 6.0, 0.45)
	c.oil(Vector2(78.0, -169.0), 90.0); c.oil(Vector2(122.0, -169.0), 90.0)
	# ---- University Plaza
	for lp: float in [70.0, 86.0, 114.0, 130.0]: c.put("prop_lamp_victorian", "worn", c.gp(lp, -153.0), 0.0, "plaza: lamps along the hall's front")
	for bn: float in [70.0, 78.0, 122.0, 130.0]: c.put("prop_park_bench", "worn", c.gp(bn, -160.6), 0.0, "plaza: benches facing the hall")
	c.put("prop_obelisk_monument", "worn", c.gp(100.0, -159.0), 0.0, "plaza: the founders' monument on the axis of the hall's door")
	for pl: float in [91.0, 109.0]: c.put("plant_potted_leafy", "normal", c.gp(pl, -151.0), 0.0, "plaza: planters either side of the hall's steps")
	c.put("prop_drinking_fountain", "worn", c.gp(140.0, -152.0), 0.0, "plaza: water for people off the buses")
	# the plaza and the hall's terraces: trees in wells down both sides, flower beds flanking the hall, bikes by its doors
	for fb: Array in [[72.0, -146.0], [128.0, -146.0], [72.0, -138.0], [128.0, -138.0]]:
		for fo: float in [-2.0, 0.0, 2.0]: c.put("plant_bird_of_paradise", "normal", c.gp(float(fb[0]) + fo, float(fb[1])), c.rr.randf_range(0, 360), "hall: a flower bed either side of it")
	for hb: float in [-144.0, -140.0]: c.put("prop_bike_rack", "worn", c.gp(80.4, hb), 0.0, "hall: bikes beside its west wall, off the plaza")
	c.put("prop_trash_receptacle", "worn", c.gp(88.0, -151.0), 0.0, "hall: a bin by the steps")
	c.put("prop_recycling_receptacle", "worn", c.gp(112.0, -151.0), 0.0, "hall: recycling by the steps")
	# ---- the gate corner: café terrace, bookstore, bikes (students from the gritty edge come in here)
	for ct: Array in [[31.0, -184.0], [37.0, -184.0], [43.0, -184.0], [31.0, -178.0], [37.0, -178.0], [43.0, -178.0]]:
		c.put("prop_cafe_table", "worn", c.gp(float(ct[0]), float(ct[1])), 0.0, "café terrace: tables in the sun by the gate")
		c.put("prop_cafe_chair", "worn", c.gp(float(ct[0]) - 0.8, float(ct[1])), 90.0, "café terrace: a chair at its table", false)
		c.put("prop_cafe_chair", "worn", c.gp(float(ct[0]) + 0.8, float(ct[1])), -90.0, "café terrace: a chair at its table", false)
	c.put("prop_menu_board", "worn", c.gp(28.0, -188.0), 0.0, "café: the day's menu where the terrace meets the walk")
	for br: float in [-188.0, -184.0, -180.0, -176.0, -172.0]: c.put("prop_bike_rack", "worn", c.gp(50.0, br), 0.0, "gate corner: students' bikes in a column along the plaza's east edge, off the walk")
	c.put("prop_newspaper_box_red", "worn", c.gp(7.5, -190.0), 180.0, "gate corner: the student paper at the gate")
	c.put("prop_newspaper_box_blue", "worn", c.gp(8.3, -190.0), 180.0, "gate corner: papers at the gate")
	# ---- the lecture wing's lawn
	c.put("prop_picnic_table", "worn", c.gp(30.0, -152.0), 0.0, "lecture lawn: a table between classes")
	# ---- the main quad: paths lined one species each, benches facing the lawn, tables, lamps
	for bq: Array in [[26.0, -67.4, 180.0], [46.0, -62.6, 0.0], [78.0, -67.4, 180.0], [98.0, -62.6, 0.0], [59.6, -100.0, 90.0], [64.4, -30.0, -90.0], [59.6, -40.0, 90.0], [64.4, -90.0, -90.0]]:
		c.put("prop_park_bench", "worn", c.gp(float(bq[0]), float(bq[1])), float(bq[2]), "quad: a bench on the path facing the lawn")
	for pt: Array in [[30.0, -100.0], [94.0, -40.0], [30.0, -30.0]]:
		c.put("prop_picnic_table", "worn", c.gp(float(pt[0]), float(pt[1])), 0.0, "quad: a table on the lawn for lunch outdoors")
	for ql: Array in [[62.0, -124.0], [62.0, -65.0], [62.0, -7.0], [7.0, -65.0], [117.0, -65.0]]:
		c.put("prop_lamp_victorian", "worn", c.gp(float(ql[0]) + 1.6, float(ql[1])), 0.0, "quad: the paths lit at night")
	c.put("prop_drinking_fountain", "worn", c.gp(64.6, -67.0), 0.0, "quad: water where the paths cross")
	# ---- the malls (half of each in this piece): palms in wells, lamps, benches facing the quad
	for ml: float in [-140.0, -80.0, -20.0]: c.put("prop_lamp_victorian", "worn", c.gp(4.6, ml), 0.0, "north mall: lamps")
	for ml2: float in [70.0, 130.0, 186.0]: c.put("prop_lamp_victorian", "worn", c.gp(ml2, -4.6), 0.0, "east mall: lamps")
	# ---- the library's forecourt
	c.put("prop_bike_rack", "worn", c.gp(124.0, -84.0), 90.0, "library: bikes beside the entrance, parallel to the wall")
	c.put("prop_bike_rack", "worn", c.gp(124.0, -48.0), 90.0, "library: bikes beside the entrance, parallel to the wall")
	c.put("prop_park_bench", "worn", c.gp(118.8, -100.0), -90.0, "library: a bench looking over the quad")
	c.put("prop_trash_receptacle", "worn", c.gp(119.0, -76.0), 0.0, "library: a bin by the door")
	# ---- the faculty lot: two stall rows each side of an aisle, lights, meter, signs
	for k in 28:
		var sz := -137.0 + k * 2.7
		if sz > -63.0: break
		c.stalls.append([154.5, sz, -90.0, c.yf(154.5, sz)]); c.stalls.append([159.5, sz, 90.0, c.yf(159.5, sz)]); c.stalls.append([170.5, sz, -90.0, c.yf(170.5, sz)])
		if k % 4 == 1: c.oil(Vector2(159.5, sz), 90.0)
	for lp2: float in [-125.0, -100.0, -75.0]: c.put("prop_lot_light_pole", "worn", c.gp(157.0, lp2), 0.0, "lot: light poles on the line between the back-to-back rows")
	c.put("prop_parking_meter", "worn", c.gp(176.4, -138.0), 0.0, "lot: the pay station by the entrance lane")
	c.put("prop_sign_no_parking", "worn", c.gp(152.6, -147.0), 0.0, "lot: keep the lane clear")
	c.tyre(Vector2(187.0, -143.0), -80.0, 6.0, 0.4); c.tyre(Vector2(187.0, -57.0), 80.0, 6.0, 0.4); c.tyre(Vector2(149.0, -143.0), 30.0, 5.0, 0.35); c.tyre(Vector2(165.0, -57.0), -30.0, 5.0, 0.35)
	c.cracks(146.0, -146.0, 177.0, -54.0, 14, 0.4)
	c.put("prop_transformer_substation", "worn", c.gp(150.0, -186.0), 0.0, "the campus quarter's transformer, in the corner lawn off the bus lane")
	# the corner lawn: a grove where students wait out of the sun for the bus
	c.put("prop_picnic_table", "worn", c.gp(170.0, -164.0), 0.0, "corner lawn: a table in the grove's shade")
	c.put("prop_park_bench", "worn", c.gp(147.4, -170.0), 90.0, "corner lawn: a bench facing the bus lane, to watch for the bus")
	# ---- service sides, bins
	for r: Dictionary in [H, LW, LB, SW, CF, BK]: c.services(r, 2.0, 1, false)
	c.put("prop_dumpster_3yd_green", "worn", c.gp(117.8, -131.0), 90.0, "hall: waste against its east wall, collected from the forecourt")
	c.put("prop_dumpster_3yd_blue", "worn", c.gp(117.8, -134.6), 90.0, "hall and library: paper recycling against the hall's east wall")
	# ---- roofs and doors
	for r3: Dictionary in [H, LW, LB, SW, CF, BK, KI]:
		for dr: Array in r3.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	# ---- POLISH (19 Nov, Yasin: "run a polish pass ... plenty of life and relevant props")
	for sd: Array in [[57.0, -178.0], [143.0, -178.0], [161.5, -100.0], [100.0, -168.0]]: c.put("prop_storm_drain_grate", "worn", c.gp(float(sd[0]), float(sd[1])), 0.0, "storm drain at the low edge of the asphalt")
	for mh: Array in [[120.0, -169.0], [165.0, -143.0]]: c.put("prop_manhole_cover", "worn", c.gp(float(mh[0]), float(mh[1])), 0.0, "sewer manhole in the lane")
	for nb: Array in [[97.0, -189.5, "prop_newspaper_box_red"], [103.0, -189.5, "prop_newspaper_box_blue"]]: c.put(String(nb[2]), "worn", c.gp(float(nb[0]), float(nb[1])), 180.0, "bus station: papers for the ride")
	for fb2: Array in [[57.0, -60.0], [67.0, -60.0], [57.0, -70.0], [67.0, -70.0]]:
		c.put("plant_bird_of_paradise", "normal", c.gp(float(fb2[0]), float(fb2[1])), c.rr.randf_range(0, 360), "quad: flowers round the crossing")
	for pt2: Array in [[94.0, -100.0], [100.0, -20.0], [20.0, -110.0]]: c.put("prop_picnic_table", "worn", c.gp(float(pt2[0]), float(pt2[1])), 0.0, "quad: more tables for lunch on the lawn")
	for sp: Array in [[40.0, -40.0], [90.0, -110.0], [100.0, -30.0]]: c.put("prop_sprinkler_popup", "worn", c.gp(float(sp[0]), float(sp[1])), 0.0, "quad: pop-up sprinklers")
	c.put("prop_bike_rack", "worn", c.gp(186.0, -12.0), 90.0, "science wing: bikes at its east end")
	c.put("prop_bike_rack", "worn", c.gp(186.0, -16.0), 90.0, "science wing: bikes at its east end")
	c.put("prop_usps_collection_box", "worn", c.gp(130.0, -151.0), 0.0, "hall: the campus mailbox by its steps")
	c.finish()
	quit()
