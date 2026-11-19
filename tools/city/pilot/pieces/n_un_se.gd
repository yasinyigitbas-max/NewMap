extends SceneTree
## Piece n_un_se (UNIVERSITY CAMPUS, south-east quarter; claude/sharp-ride-16u9ik 19 Nov). Layout row (-600, 6.0, -600),
## local x = u + 600, z = v + 600. Covers u -600..-409.2, v -600..-409.2: the quarter on the east street (across it, the
## stadium the campus shares, ZONING.md) and the south street.
## SITE (19 Nov dump + zoning/terrain_grid.npz): land 6.02..6.11, nearly flat; both streets' walks 6.15 all along; aprons
## on the east street at v -546.6..-539.4 and -460.6..-453.4, on the south street at u -546.6..-539.4 and -460.6..-453.4.
## PLANNER: the ACTIVE quarter. The REC CENTRE ("the gym") and the kinesiology wing face the east mall near the campus
## centre, a short walk from the dorms (n_un_sw). Behind them the INTRAMURAL FIELD (lights for evening games, a running
## loop round it, benches on the sidelines) and four TENNIS COURTS in a chain-link cage on the south street. On the stadium
## side the CAMPUS GARAGE takes the cars: in from the east street's north apron, out down the campus drive to the south
## street (or the east street's south apron); on game days people walk from it across the STADIUM WALK (a plaza with
## the game-day kiosk and the shuttle shelter) to the stadium.
## GROUND (elevation): the ground follows the land 8 cm over it and eases over 8 m to walk level 6.15 at both streets;
## every building on a level pad at the highest ground under it; shared edges with the other quarters (x = 0, z = 0) are
## land + 0.08 on both sides.
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(-600.0, 6.0, -600.0)
const LAND := {"x0": -4.0, "z0": -4.0, "step": 4.0, "nx": 51, "nz": 51, "h": [0.09,0.09,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.11,0.11,0.10,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.08,0.07,0.07,0.07,0.07,0.08,0.08,0.08,0.08,0.09,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.09,0.09,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.11,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.08,0.08,0.08,0.08,0.08,0.08,0.07,0.08,0.08,0.07,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.07,0.08,0.08,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.08,0.08,0.07,0.07,0.07,0.07,0.07,0.07,0.08,0.08,0.08,0.09,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.06,0.06,0.07,0.07,0.08,0.08,0.08,0.09,0.08,0.08,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.08,0.08,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.06,0.06,0.07,0.07,0.07,0.07,0.07,0.08,0.08,0.08,0.09,0.09,0.09,0.08,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.08,0.08,0.08,0.08,0.08,0.08,0.07,0.07,0.07,0.06,0.06,0.06,0.06,0.07,0.07,0.07,0.08,0.08,0.09,0.08,0.09,0.09,0.10,0.10,0.10,0.10,-0.05,-0.05,0.04,0.05,0.05,0.06,0.06,0.07,0.07,0.08,0.08,0.07,0.08,0.08,0.08,0.08,0.09,0.09,0.09,0.09,0.09,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.07,0.07,0.06,0.06,0.06,0.06,0.06,0.06,0.07,0.07,0.07,0.07,0.08,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.04,0.05,0.05,0.06,0.06,0.06,0.06,0.07,0.07,0.07,0.08,0.08,0.08,0.09,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.09,0.08,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.06,0.06,0.06,0.05,0.06,0.06,0.06,0.07,0.07,0.08,0.08,0.09,0.09,0.09,0.09,0.10,0.10,0.10,-0.05,-0.05,0.04,0.04,0.04,0.05,0.05,0.06,0.06,0.07,0.07,0.07,0.07,0.07,0.07,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.07,0.07,0.07,0.07,0.06,0.06,0.05,0.05,0.05,0.06,0.06,0.06,0.07,0.07,0.07,0.07,0.08,0.08,0.09,0.09,0.10,0.10,0.10,0.10,-0.05,-0.05,0.03,0.03,0.04,0.05,0.05,0.06,0.05,0.05,0.06,0.06,0.07,0.07,0.07,0.08,0.08,0.07,0.07,0.07,0.07,0.08,0.08,0.08,0.08,0.08,0.08,0.07,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.05,0.05,0.06,0.06,0.07,0.08,0.08,0.09,0.09,0.09,0.09,0.10,0.10,0.10,-0.05,-0.05,0.03,0.03,0.03,0.03,0.04,0.04,0.05,0.05,0.06,0.06,0.07,0.06,0.06,0.06,0.07,0.07,0.07,0.07,0.08,0.08,0.08,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.06,0.06,0.05,0.05,0.05,0.05,0.05,0.05,0.06,0.06,0.07,0.07,0.07,0.07,0.08,0.09,0.09,0.09,0.10,0.10,0.10,-0.05,-0.05,0.02,0.02,0.03,0.03,0.04,0.04,0.05,0.04,0.05,0.05,0.06,0.06,0.06,0.07,0.07,0.07,0.06,0.06,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.06,0.06,0.06,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.06,0.06,0.07,0.08,0.08,0.09,0.09,0.09,0.09,0.10,0.10,-0.05,-0.05,0.01,0.02,0.03,0.02,0.03,0.03,0.04,0.04,0.05,0.05,0.06,0.06,0.05,0.06,0.06,0.06,0.06,0.07,0.07,0.07,0.07,0.07,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.05,0.04,0.04,0.04,0.04,0.05,0.05,0.06,0.06,0.07,0.07,0.07,0.08,0.08,0.09,0.09,0.10,0.10,0.10,-0.05,-0.05,0.00,0.01,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.04,0.05,0.05,0.05,0.06,0.06,0.06,0.07,0.07,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.05,0.05,0.05,0.05,0.04,0.04,0.04,0.05,0.05,0.05,0.05,0.05,0.06,0.07,0.07,0.08,0.08,0.09,0.10,0.09,0.10,0.10,-0.05,-0.05,0.00,0.01,0.01,0.02,0.02,0.02,0.03,0.03,0.04,0.04,0.05,0.05,0.06,0.05,0.05,0.05,0.06,0.06,0.06,0.06,0.06,0.06,0.07,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.03,0.03,0.04,0.04,0.05,0.05,0.06,0.06,0.07,0.08,0.07,0.08,0.09,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.01,-0.00,0.00,0.01,0.02,0.02,0.03,0.03,0.04,0.03,0.04,0.04,0.05,0.05,0.05,0.06,0.06,0.06,0.06,0.05,0.05,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.05,0.05,0.05,0.06,0.06,0.07,0.08,0.08,0.09,0.09,0.10,0.10,0.10,-0.05,-0.05,-0.01,-0.00,0.00,0.01,0.02,0.01,0.02,0.02,0.03,0.04,0.04,0.04,0.05,0.05,0.04,0.05,0.05,0.05,0.05,0.06,0.06,0.06,0.06,0.06,0.05,0.05,0.05,0.05,0.05,0.04,0.04,0.04,0.04,0.03,0.03,0.04,0.04,0.05,0.05,0.06,0.07,0.07,0.08,0.08,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.01,-0.01,-0.01,0.00,0.01,0.01,0.02,0.03,0.03,0.04,0.03,0.04,0.04,0.04,0.05,0.05,0.05,0.05,0.06,0.06,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.04,0.03,0.03,0.03,0.03,0.03,0.04,0.04,0.05,0.06,0.05,0.06,0.07,0.07,0.08,0.09,0.09,0.10,0.10,0.10,-0.05,-0.05,-0.02,-0.01,-0.01,0.00,0.01,0.02,0.01,0.02,0.02,0.03,0.03,0.04,0.04,0.05,0.05,0.04,0.04,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.03,0.04,0.04,0.03,0.04,0.04,0.05,0.05,0.06,0.07,0.08,0.08,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.02,-0.01,-0.02,-0.01,-0.00,0.01,0.01,0.02,0.02,0.03,0.04,0.03,0.03,0.04,0.04,0.04,0.05,0.05,0.05,0.05,0.06,0.04,0.05,0.05,0.05,0.05,0.05,0.05,0.04,0.04,0.03,0.03,0.03,0.03,0.03,0.03,0.04,0.04,0.05,0.06,0.06,0.06,0.07,0.08,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.03,-0.02,-0.02,-0.01,0.00,0.01,0.01,0.01,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.05,0.04,0.04,0.04,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.04,0.04,0.04,0.04,0.03,0.03,0.03,0.03,0.03,0.04,0.03,0.04,0.04,0.05,0.06,0.07,0.07,0.08,0.09,0.08,0.09,0.10,0.10,-0.05,-0.05,-0.03,-0.02,-0.01,-0.02,-0.01,-0.00,0.01,0.01,0.02,0.02,0.03,0.03,0.03,0.03,0.04,0.04,0.04,0.04,0.05,0.05,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.02,0.02,0.02,0.03,0.03,0.04,0.04,0.05,0.05,0.06,0.06,0.07,0.07,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.04,-0.03,-0.02,-0.02,-0.01,0.00,0.01,0.02,0.01,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.05,0.05,0.04,0.04,0.04,0.04,0.05,0.05,0.05,0.05,0.05,0.03,0.03,0.03,0.03,0.03,0.03,0.03,0.03,0.03,0.04,0.03,0.04,0.05,0.06,0.06,0.07,0.08,0.08,0.09,0.09,0.09,0.10,-0.05,-0.05,-0.04,-0.03,-0.02,-0.01,-0.02,-0.01,-0.00,0.01,0.01,0.02,0.02,0.03,0.03,0.03,0.03,0.03,0.04,0.04,0.04,0.05,0.05,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.03,0.03,0.02,0.02,0.02,0.03,0.03,0.04,0.04,0.05,0.06,0.07,0.06,0.07,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.05,-0.04,-0.03,-0.02,-0.01,-0.00,0.00,0.01,0.02,0.01,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.03,0.03,0.03,0.02,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.04,0.05,0.06,0.07,0.08,0.08,0.09,0.09,0.09,0.10,-0.05,-0.05,-0.05,-0.04,-0.03,-0.02,-0.01,-0.01,-0.01,0.00,0.01,0.02,0.02,0.03,0.03,0.04,0.03,0.03,0.04,0.04,0.04,0.04,0.04,0.05,0.05,0.05,0.04,0.04,0.03,0.03,0.03,0.03,0.03,0.03,0.03,0.02,0.02,0.02,0.03,0.03,0.04,0.05,0.06,0.06,0.07,0.07,0.08,0.08,0.09,0.10,0.10,-0.05,-0.05,-0.04,-0.05,-0.04,-0.03,-0.02,-0.01,-0.00,0.01,0.01,0.02,0.01,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.02,0.02,0.02,0.02,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.05,0.06,0.07,0.07,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.05,-0.04,-0.03,-0.02,-0.01,-0.00,-0.01,-0.00,0.01,0.01,0.02,0.02,0.03,0.03,0.04,0.03,0.03,0.04,0.04,0.04,0.04,0.04,0.04,0.05,0.05,0.03,0.03,0.03,0.03,0.03,0.03,0.02,0.02,0.02,0.03,0.02,0.02,0.03,0.04,0.05,0.05,0.06,0.07,0.08,0.08,0.08,0.09,0.09,0.10,-0.05,-0.05,-0.05,-0.04,-0.04,-0.03,-0.02,-0.01,-0.00,0.00,0.01,0.02,0.02,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.04,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.03,0.02,0.02,0.02,0.02,0.02,0.02,0.03,0.04,0.04,0.05,0.05,0.06,0.06,0.07,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.06,-0.04,-0.03,-0.02,-0.01,-0.01,0.00,-0.00,0.01,0.01,0.02,0.02,0.03,0.03,0.04,0.04,0.03,0.04,0.04,0.04,0.04,0.04,0.05,0.04,0.05,0.04,0.03,0.03,0.03,0.03,0.03,0.02,0.02,0.02,0.02,0.03,0.02,0.03,0.04,0.04,0.05,0.06,0.07,0.08,0.08,0.08,0.09,0.09,0.10,-0.05,-0.05,-0.05,-0.04,-0.03,-0.03,-0.02,-0.01,-0.00,0.00,0.01,0.02,0.02,0.03,0.02,0.03,0.03,0.04,0.04,0.04,0.04,0.05,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.03,0.03,0.02,0.02,0.02,0.02,0.02,0.03,0.03,0.04,0.05,0.06,0.05,0.06,0.07,0.08,0.08,0.09,0.10,0.10,-0.05,-0.05,-0.06,-0.05,-0.03,-0.02,-0.01,-0.01,0.00,0.01,0.01,0.01,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.05,0.04,0.04,0.04,0.04,0.05,0.04,0.05,0.04,0.04,0.03,0.03,0.03,0.03,0.02,0.02,0.02,0.02,0.03,0.03,0.03,0.04,0.04,0.05,0.06,0.07,0.07,0.08,0.09,0.09,0.09,0.10,-0.05,-0.05,-0.05,-0.04,-0.03,-0.02,-0.02,-0.01,-0.00,0.01,0.01,0.02,0.03,0.03,0.04,0.03,0.03,0.04,0.04,0.04,0.05,0.05,0.05,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.04,0.03,0.03,0.03,0.01,0.02,0.02,0.02,0.03,0.03,0.04,0.05,0.06,0.06,0.06,0.07,0.08,0.08,0.09,0.10,0.10,-0.05,-0.05,-0.05,-0.04,-0.03,-0.02,-0.01,-0.00,0.01,0.01,0.02,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.05,0.05,0.05,0.04,0.04,0.04,0.05,0.05,0.05,0.05,0.04,0.04,0.03,0.03,0.02,0.02,0.02,0.02,0.02,0.03,0.03,0.04,0.03,0.04,0.05,0.06,0.07,0.07,0.08,0.09,0.09,0.09,0.10,-0.05,-0.05,-0.05,-0.04,-0.02,-0.01,-0.00,-0.01,0.00,0.01,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.04,0.04,0.04,0.05,0.05,0.05,0.05,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.04,0.03,0.03,0.03,0.01,0.02,0.02,0.03,0.03,0.04,0.05,0.05,0.06,0.07,0.07,0.08,0.08,0.09,0.10,0.10,-0.05,-0.05,-0.04,-0.04,-0.03,-0.02,-0.01,0.00,0.01,0.02,0.02,0.03,0.03,0.03,0.04,0.04,0.04,0.05,0.05,0.05,0.06,0.06,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.03,0.03,0.02,0.02,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.05,0.06,0.06,0.07,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.04,-0.03,-0.02,-0.01,0.00,0.01,0.01,0.01,0.02,0.03,0.03,0.04,0.04,0.05,0.05,0.04,0.05,0.05,0.05,0.05,0.05,0.06,0.06,0.06,0.06,0.04,0.04,0.04,0.04,0.04,0.04,0.03,0.03,0.03,0.03,0.02,0.03,0.03,0.04,0.05,0.05,0.06,0.07,0.08,0.08,0.08,0.09,0.09,0.10,-0.05,-0.05,-0.03,-0.02,-0.02,-0.01,-0.00,0.01,0.02,0.02,0.03,0.04,0.04,0.03,0.04,0.04,0.05,0.05,0.05,0.06,0.06,0.06,0.06,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.04,0.03,0.03,0.02,0.03,0.03,0.03,0.03,0.04,0.05,0.05,0.05,0.06,0.07,0.07,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.03,-0.02,-0.01,0.00,0.01,0.02,0.03,0.02,0.03,0.03,0.04,0.04,0.05,0.05,0.06,0.06,0.05,0.05,0.05,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.05,0.04,0.04,0.04,0.04,0.04,0.03,0.03,0.03,0.04,0.03,0.04,0.04,0.05,0.06,0.06,0.07,0.08,0.09,0.08,0.09,0.09,0.10,-0.05,-0.05,-0.02,-0.01,0.00,0.00,0.01,0.02,0.03,0.03,0.04,0.04,0.05,0.06,0.05,0.05,0.05,0.06,0.06,0.06,0.06,0.07,0.07,0.07,0.06,0.06,0.06,0.05,0.06,0.05,0.05,0.05,0.05,0.03,0.03,0.03,0.03,0.03,0.04,0.04,0.05,0.06,0.06,0.06,0.07,0.07,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.02,-0.01,0.00,0.01,0.02,0.03,0.04,0.04,0.04,0.04,0.05,0.05,0.05,0.06,0.06,0.07,0.07,0.07,0.06,0.06,0.06,0.06,0.07,0.06,0.07,0.06,0.06,0.05,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.04,0.05,0.05,0.06,0.07,0.07,0.08,0.09,0.09,0.09,0.10,0.10,-0.05,-0.05,-0.00,0.01,0.02,0.02,0.02,0.03,0.04,0.04,0.05,0.05,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.07,0.07,0.07,0.07,0.07,0.07,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.05,0.05,0.03,0.03,0.03,0.04,0.04,0.05,0.05,0.06,0.07,0.07,0.07,0.07,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,0.00,0.01,0.02,0.03,0.03,0.04,0.05,0.05,0.06,0.05,0.05,0.06,0.06,0.07,0.07,0.07,0.08,0.08,0.08,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.05,0.05,0.05,0.05,0.04,0.04,0.05,0.05,0.05,0.06,0.05,0.06,0.06,0.07,0.08,0.08,0.09,0.09,0.10,0.10,0.10,-0.05,-0.05,0.02,0.02,0.03,0.04,0.05,0.04,0.05,0.05,0.06,0.06,0.06,0.07,0.07,0.08,0.07,0.07,0.07,0.07,0.08,0.08,0.08,0.08,0.08,0.08,0.07,0.07,0.07,0.07,0.06,0.06,0.06,0.06,0.06,0.04,0.04,0.04,0.05,0.05,0.06,0.06,0.07,0.08,0.08,0.08,0.08,0.09,0.09,0.10,0.10,-0.05,-0.05,0.02,0.03,0.04,0.05,0.05,0.06,0.06,0.07,0.07,0.07,0.06,0.07,0.07,0.07,0.08,0.08,0.08,0.08,0.09,0.09,0.07,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.07,0.06,0.06,0.05,0.05,0.05,0.05,0.05,0.06,0.06,0.07,0.06,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.10,-0.05,-0.05,0.04,0.05,0.05,0.06,0.06,0.07,0.06,0.07,0.07,0.07,0.08,0.08,0.08,0.08,0.09,0.07,0.08,0.08,0.08,0.09,0.08,0.09,0.09,0.09,0.09,0.08,0.07,0.07,0.08,0.07,0.07,0.07,0.07,0.06,0.07,0.05,0.06,0.06,0.07,0.07,0.08,0.08,0.09,0.09,0.09,0.09,0.10,0.10,0.10,-0.05,-0.05,0.06,0.07,0.06,0.06,0.07,0.07,0.07,0.08,0.08,0.09,0.09,0.08,0.08,0.08,0.08,0.08,0.09,0.09,0.09,0.10,0.09,0.08,0.08,0.08,0.08,0.09,0.09,0.09,0.09,0.08,0.07,0.07,0.07,0.06,0.07,0.07,0.07,0.08,0.08,0.08,0.08,0.08,0.08,0.09,0.09,0.10,0.10,0.10,0.10,-0.05,-0.05,0.07,0.07,0.07,0.08,0.08,0.09,0.09,0.08,0.08,0.08,0.09,0.09,0.09,0.09,0.09,0.10,0.08,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.10,0.09,0.08,0.08,0.09,0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.07,0.08,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.09,0.10,0.10,0.10,-0.05,-0.05,0.09,0.09,0.09,0.08,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.08,0.08,0.08,0.08,0.09,0.09,0.09,0.09,0.10,0.10,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05]}

## the yaw that makes a prop at p face the point t (yaw 0 faces +z)
static func face(p: Vector2, t: Vector2) -> float: return rad_to_deg(atan2(t.x - p.x, t.y - p.y))

## a chain-link fence from a to b: 2.0 m panels sharing their ends, a post at every joint and at both ends
static func chain(c: Object, a: Vector2, b: Vector2, reason: String) -> void:
	var n := maxi(1, int(ceil(a.distance_to(b) / 2.0)))
	var dir := (b - a).normalized(); var step := a.distance_to(b) / n
	var yaw := rad_to_deg(atan2(dir.x, dir.y)) + 90.0
	for i in n:
		var m: Vector2 = a + dir * (step * (i + 0.5))
		c.put("fence_chainlink_lot", "worn", Vector3(m.x, c._low(m, dir, step * 0.5), m.y), yaw, reason, false)
	for i in n + 1:
		var pp: Vector2 = a + dir * (step * i)
		c.put("fence_chainlink_lot_post", "worn", Vector3(pp.x, c.yf(pp.x, pp.y), pp.y), yaw, "fence post at every joint", false)

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_un_se")
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z) + 0.08
	var flat := func(_x: float, _z: float) -> float: return 0.15
	var base := L.eased(land, [[Vector2(190.8, 0.0), Vector2(190.8, 190.8), flat], [Vector2(0.0, 190.8), Vector2(190.8, 190.8), flat]], 8.0)
	var SITES := [["civic/civ_rec_center", Vector2(60.0, 14.0), "n", "uni_rec"], ["civic/civ_school_wing", Vector2(128.0, 14.0), "n", "uni_kinesiology"],
		["extras/ext_parking_garage", Vector2(165.0, 66.0), "n", "uni_garage"], ["commercial/com_kiosk", Vector2(176.0, 122.0), "e", "uni_gameday_kiosk"]]
	var pads: Array = []
	for st: Array in SITES:
		var r0: Array = L.bld_rect(String(st[0]), st[1], String(st[2]))
		pads.append([maxf(0.0, float(r0[0]) - 0.3), maxf(0.0, float(r0[1]) - 0.3), minf(190.8, float(r0[2]) + 0.3), minf(190.8, float(r0[3]) + 0.3)])
	var gl := L.grid_lots(0.0, 0.0, 190.8, 190.8, pads, base)
	c.terrain(gl.lots)
	c.skirt_depth = 0.4
	# ---- surfaces (first paint wins)
	c.paint("plaza", 0.0, 0.0, 6.0, 190.8)                      # the south mall (east half: x 0..6 here)
	c.paint("plaza", 0.0, 0.0, 190.8, 6.0)                      # the east mall (south half)
	c.paint("concrete", 36.0, 6.0, 84.0, 14.0)                  # the rec centre's forecourt
	c.paint("concrete", 108.0, 6.0, 140.0, 14.0)                # the kinesiology wing's walk
	c.paint("asphalt", 140.0, 54.0, 190.8, 60.0)                # garage drive in from the east street (apron v -546)
	c.paint("asphalt", 146.0, 60.0, 184.0, 66.0)                # the garage's entry apron
	c.paint("asphalt", 140.0, 54.0, 146.0, 190.8)               # the campus drive out to the south street (apron u -460)
	c.paint("asphalt", 146.0, 140.0, 190.8, 146.0)              # and to the east street (apron v -460)
	c.paint("plaza", 146.0, 97.5, 190.8, 140.0)                 # the stadium walk (game-day plaza)
	c.paint("grass", 14.0, 44.0, 124.0, 128.0)                  # the intramural field
	c.paint("concrete", 10.0, 40.0, 128.0, 132.0)               # the running loop round it
	c.paint("concrete", 16.0, 146.0, 88.0, 182.0)               # the tennis courts
	c.paint("concrete", 48.0, 132.0, 52.0, 146.0)               # path from the loop to the courts' gate
	c.paint("concrete", 6.0, 84.0, 10.0, 88.0)                  # the loop's link to the south mall
	c.paint("concrete", 92.0, 150.0, 124.0, 176.0)              # the shaded terrace by the courts
	c.paint("grass", 0.0, 0.0, 190.8, 190.8)                    # everything else is lawn
	for wp: Array in [[3.0, 50.0], [3.0, 110.0], [3.0, 170.0], [40.0, 3.0], [100.0, 3.0], [160.0, 3.0], [100.0, 155.0], [116.0, 155.0], [100.0, 171.0], [116.0, 171.0], [154.0, 104.0], [154.0, 132.0]]:
		c.well(float(wp[0]), float(wp[1]))
	c.build_floor(L.rect_edges(0.0, 0.0, 190.8, 190.8))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b023_a", Vector3(-400, 6, -600), 0.0], ["s_rs_b023_b", Vector3(-400, 6, -400), -180.0], ["s_rs_b104_a", Vector3(-600, 6, -400), 90.0], ["s_rs_b104_b", Vector3(-400, 6, -400), -90.0],
		["j_rs_t_lll_b", Vector3(-400, 6, -600), 90.0], ["j_rs_t_lll_b", Vector3(-400, 6, -400), -90.0], ["j_rs_t_lrl_a", Vector3(-600, 6, -400), 0.0], ["st_stadium", Vector3(-200, 6, -400), 0.0]], O)
	# ---- buildings
	var B := {}
	for k in SITES.size():
		var st2: Array = SITES[k]
		c.y0 = float(gl.pads[k][4])
		B[String(st2[3])] = c.bld(String(st2[0]), st2[1], String(st2[2]), false, String(st2[3]))
	c.y0 = 0.15
	var RC: Dictionary = B.uni_rec; var KN: Dictionary = B.uni_kinesiology; var GA: Dictionary = B.uni_garage; var KI: Dictionary = B.uni_gameday_kiosk
	# ---- the rec centre's forecourt: bikes in rows, the noticeboard, drinks, a bench facing the mall
	for br: float in [38.0, 41.0, 44.0, 76.0, 79.0, 82.0]: c.put("prop_bike_rack", "worn", c.gp(br, 9.0), 90.0, "rec centre: bikes of people in for a workout")
	c.put("prop_poster_case", "worn", c.gp(52.0, 13.0), 180.0, "rec centre: class times and intramural sign-ups by its doors")
	c.put("prop_vending_soda", "worn", c.gp(70.0, 13.2), 180.0, "rec centre: drinks by the doors")
	for tb: Array in [[48.0, 7.0, "prop_trash_receptacle"], [72.0, 7.0, "prop_recycling_receptacle"]]: c.put(String(tb[2]), "worn", c.gp(float(tb[0]), float(tb[1])), 0.0, "rec centre: bins by the forecourt")
	for lp: float in [36.6, 83.4]: c.put("prop_lamp_victorian", "worn", c.gp(lp, 12.0), 0.0, "rec centre: forecourt lamps")
	c.put("prop_drinking_fountain", "worn", c.gp(84.6, 10.0), 0.0, "rec centre: water for runners coming off the loop")
	# ---- kinesiology: bikes and a bench
	for kb: float in [110.0, 113.0]: c.put("prop_bike_rack", "worn", c.gp(kb, 9.0), 90.0, "kinesiology: bikes by its door")
	c.put("prop_park_bench", "worn", c.gp(136.0, 8.0), 180.0, "kinesiology: a bench facing the mall")
	# the lawn between them: shade trees and a table
	for gt: Array in [[92.0, 24.0, "tree_coral_a"], [100.0, 32.0, "tree_jacaranda_b"], [152.0, 24.0, "tree_ficus_a"], [172.0, 30.0, "tree_magnolia_b"], [184.0, 16.0, "tree_coral_b"]]:
		c.put(String(gt[2]), "normal", c.gp(float(gt[0]), float(gt[1])), c.rr.randf_range(0, 360), "lawns: shade trees in the grass", true, 0.85)
	c.put("prop_picnic_table", "worn", c.gp(96.0, 18.0), 0.0, "lawn: a table between the gym and the wing")
	c.put("prop_picnic_table", "worn", c.gp(166.0, 22.0), 0.0, "east lawn: a table in the shade")
	# ---- the intramural field: lights, sideline benches facing the field, the loop's lamps and bins
	var FC := Vector2(69.0, 86.0)
	for fl: Array in [[12.0, 42.0], [69.0, 42.0], [126.0, 42.0], [12.0, 130.0], [69.0, 130.0], [126.0, 130.0]]:
		c.put("prop_lot_light_pole", "worn", c.gp(float(fl[0]), float(fl[1])), 0.0 if float(fl[1]) < 86.0 else 180.0, "field: floodlights for evening games, on the loop's outer edge")
	for sb: Array in [[40.0, 45.0], [56.0, 45.0], [82.0, 45.0], [98.0, 45.0], [40.0, 127.0], [98.0, 127.0]]:
		c.put("prop_park_bench", "worn", c.gp(float(sb[0]), float(sb[1])), face(Vector2(float(sb[0]), float(sb[1])), Vector2(float(sb[0]), FC.y)), "field: a sideline bench facing the game")
	for sp: Array in [[40.0, 70.0], [98.0, 70.0], [40.0, 102.0], [98.0, 102.0]]: c.put("prop_sprinkler_popup", "worn", c.gp(float(sp[0]), float(sp[1])), 0.0, "field: pop-up sprinklers")
	for bn: Array in [[8.0, 60.0], [8.0, 110.0], [130.0, 86.0]]: c.put("prop_trash_receptacle", "worn", c.gp(float(bn[0]), float(bn[1])), 0.0, "running loop: a bin")
	c.put("prop_drinking_fountain", "worn", c.gp(8.0, 92.0), 0.0, "running loop: water where it meets the mall")
	c.put("prop_poster_case", "worn", c.gp(8.0, 80.0), 90.0, "field: the intramural league table")
	# a few spectators' chairs on the grass outside the loop
	for sc: Array in [[132.0, 70.0], [132.0, 100.0]]:
		c.put("prop_park_bench", "worn", c.gp(float(sc[0]), float(sc[1])), -90.0, "field: a bench outside the loop facing the game")
	for tl: Array in [[134.0, 50.0, "tree_eucalyptus_a"], [134.0, 120.0, "tree_eucalyptus_b"], [134.0, 160.0, "tree_eucalyptus_a"]]:
		c.put(String(tl[2]), "normal", c.gp(float(tl[0]), float(tl[1])), c.rr.randf_range(0, 360), "lawn: eucalyptus screen the field from the campus drive", true, 0.85)
	# ---- the tennis courts: four courts in a chain-link cage, gate on the north side, nets, benches
	chain(c, Vector2(16.0, 146.0), Vector2(49.0, 146.0), "tennis: the cage keeps balls in")
	chain(c, Vector2(51.0, 146.0), Vector2(88.0, 146.0), "tennis: the cage keeps balls in")
	chain(c, Vector2(88.0, 146.0), Vector2(88.0, 182.0), "tennis: the cage keeps balls in")
	chain(c, Vector2(88.0, 182.0), Vector2(16.0, 182.0), "tennis: the cage keeps balls in")
	chain(c, Vector2(16.0, 182.0), Vector2(16.0, 146.0), "tennis: the cage keeps balls in")
	for nx: float in [25.0, 43.0, 61.0, 79.0]:
		c.put("prop_tennis_net", "worn", c.gp(nx, 164.0), 0.0, "tennis: the net across the court")
		c.put("prop_park_bench", "worn", c.gp(nx + 7.6, 164.0), -90.0, "tennis: players' bench beside the net post, facing the court", false)
	c.put("prop_trash_receptacle", "worn", c.gp(53.0, 144.6), 0.0, "tennis: a bin by the gate")
	# ---- the shaded terrace by the courts: trees in wells, tables, bikes
	for tw: Array in [[100.0, 155.0], [116.0, 155.0], [100.0, 171.0], [116.0, 171.0]]:
		c.put("tree_ficus_a", "normal", c.gp(float(tw[0]), float(tw[1])), c.rr.randf_range(0, 360), "terrace: ficus in wells shade the tables", true, 0.8)
	for pt: Array in [[108.0, 158.0], [108.0, 168.0], [96.0, 163.0], [120.0, 163.0]]:
		c.put("prop_picnic_table", "worn", c.gp(float(pt[0]), float(pt[1])), 90.0, "terrace: tables between games")
	c.put("prop_bike_rack", "worn", c.gp(94.0, 174.6), 0.0, "terrace: bikes")
	c.put("prop_bike_rack", "worn", c.gp(122.0, 174.6), 0.0, "terrace: bikes")
	c.put("prop_vending_snack", "worn", c.gp(123.0, 151.2), 180.0, "terrace: snacks")
	# ---- the garage: in from the east street, signs, the pay station, marks where cars turn
	c.put("prop_sign_no_parking", "worn", c.gp(186.0, 61.0), 180.0, "garage drive: no stopping")
	c.put("prop_pay_station", "worn", c.gp(148.0, 99.0), 0.0, "garage: the pay station at its stair, on the stadium walk")
	c.put("prop_sign_stop", "worn", c.gp(146.8, 186.0), 0.0, "campus drive: stop before the south street")
	c.put("prop_sign_stop", "worn", c.gp(186.0, 146.8), 90.0, "campus drive: stop before the east street")
	c.put("prop_sign_speed25", "worn", c.gp(138.6, 74.0), 180.0, "campus drive: slow")
	for tm: Array in [[143.0, 57.0, 45.0], [187.0, 57.0, -80.0], [143.0, 143.0, -45.0], [143.0, 187.0, 10.0], [187.0, 143.0, 80.0], [165.0, 63.0, 0.0]]: c.tyre(Vector2(float(tm[0]), float(tm[1])), float(tm[2]), 6.0, 0.45)
	c.oil(Vector2(160.0, 63.0), 90.0); c.oil(Vector2(172.0, 63.0), 90.0); c.cracks(140.0, 54.0, 190.8, 66.0, 8, 0.4); c.cracks(140.0, 66.0, 146.0, 190.8, 10, 0.4)
	for dl: float in [80.0, 120.0, 170.0]: c.put("prop_lamp_cobra", "worn", c.gp(138.6, dl), -90.0, "campus drive: lamps on its west verge")
	# ---- the stadium walk: the game-day kiosk, the shuttle shelter on the street, trees in wells, benches, bins
	c.put("prop_bus_shelter", "worn", c.gp(188.4, 108.0), 90.0, "stadium walk: the game-day shuttle shelter, facing the east street")
	c.put("prop_bus_stop_sign", "worn", c.gp(189.4, 102.0), 90.0, "stadium walk: shuttle stop sign")
	for tw2: Array in [[154.0, 104.0], [154.0, 132.0]]: c.put("tree_magnolia_a", "normal", c.gp(float(tw2[0]), float(tw2[1])), c.rr.randf_range(0, 360), "stadium walk: magnolias in wells", true, 0.85)
	for sb2: Array in [[160.0, 112.0], [160.0, 128.0]]: c.put("prop_park_bench", "worn", c.gp(float(sb2[0]), float(sb2[1])), 90.0, "stadium walk: a bench facing the kiosk")
	for tb2: Array in [[166.0, 104.0, "prop_trash_receptacle"], [166.0, 136.0, "prop_recycling_receptacle"], [182.0, 116.0, "prop_trash_receptacle"]]: c.put(String(tb2[2]), "worn", c.gp(float(tb2[0]), float(tb2[1])), 0.0, "stadium walk: bins for game-day crowds")
	for sl: float in [100.0, 138.0]: c.put("prop_lamp_victorian", "worn", c.gp(186.0, sl), 0.0, "stadium walk: lamps")
	c.put("prop_newspaper_box_blue", "worn", c.gp(189.6, 130.0), 90.0, "stadium walk: the game-day programme box")
	for bo: float in [100.0, 104.0, 136.0]: c.put("prop_bollard_steel", "worn", c.gp(147.0, bo), 0.0, "stadium walk: bollards keep cars on the drive")
	# ---- the corner lawn by the two streets: a grove, a table, the quarter's transformer
	for ct: Array in [[160.0, 160.0, "tree_torrey_pine_a"], [178.0, 176.0, "tree_torrey_pine_b"], [184.0, 156.0, "tree_coral_a"], [156.0, 182.0, "tree_jacaranda_a"]]:
		c.put(String(ct[2]), "normal", c.gp(float(ct[0]), float(ct[1])), c.rr.randf_range(0, 360), "corner lawn: a grove by the two streets", true, 0.85)
	c.put("prop_picnic_table", "worn", c.gp(168.0, 168.0), 0.0, "corner lawn: tailgate picnics before the game")
	c.put("prop_transformer_substation", "worn", c.gp(186.0, 186.0), 0.0, "the quarter's transformer, in the corner lawn")
	# lawn west of the courts and the south mall: trees, a bench
	for wt: Array in [[10.0, 150.0, "tree_magnolia_b"], [10.0, 176.0, "tree_coral_b"], [100.0, 186.0, "tree_jacaranda_b"], [130.0, 186.0, "tree_coral_a"]]:
		c.put(String(wt[2]), "normal", c.gp(float(wt[0]), float(wt[1])), c.rr.randf_range(0, 360), "lawn: shade trees in the grass", true, 0.85)
	# ---- the malls (half of each here): palms in wells, lamps
	for mz: float in [50.0, 110.0, 170.0]: c.put("palm_canary_date_a", "normal", c.gp(3.0, mz), c.rr.randf_range(0, 360), "south mall: date palms in wells, the campus axis", true, 0.9)
	for mx: float in [40.0, 100.0, 160.0]: c.put("palm_canary_date_b", "normal", c.gp(mx, 3.0), c.rr.randf_range(0, 360), "east mall: date palms in wells, the campus axis", true, 0.9)
	for ml: float in [20.0, 80.0, 140.0]: c.put("prop_lamp_victorian", "worn", c.gp(4.6, ml), 0.0, "south mall: lamps")
	for ml2: float in [70.0, 130.0, 186.0]: c.put("prop_lamp_victorian", "worn", c.gp(ml2, 4.6), 0.0, "east mall: lamps")
	# ---- service sides, bins, roofs, doors
	for r: Dictionary in [RC, KN]: c.services(r, 2.0, 1, false)
	c.put("prop_dumpster_3yd_green", "worn", c.gp(138.0, 36.0), 0.0, "kinesiology and rec centre: waste, collected from the campus drive")
	c.put("prop_dumpster_3yd_blue", "worn", c.gp(138.0, 39.6), 0.0, "recycling, collected from the campus drive")
	c.roof_plant(RC, [[-6.0, -3.0, "prop_ac_condenser"], [6.0, -3.0, "prop_ac_condenser"], [0.0, 3.0, "prop_vent_box"]], "roof plant (rec centre: the gym's air)")
	for r3: Dictionary in [RC, KN, KI]:
		for dr: Array in r3.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	# ---- POLISH (19 Nov, Yasin: "run a polish pass ... plenty of life and relevant props")
	for hy: Array in [[186.0, 72.0], [138.6, 126.0], [90.0, 186.0], [86.0, 34.0]]: c.put("prop_hydrant_red", "worn", c.gp(float(hy[0]), float(hy[1])), 0.0, "fire hydrant within reach of every building")
	for sd: Array in [[143.0, 100.0], [143.0, 160.0], [175.0, 57.0]]: c.put("prop_storm_drain_grate", "worn", c.gp(float(sd[0]), float(sd[1])), 0.0, "storm drain at the low edge of the drive")
	c.put("prop_manhole_cover", "worn", c.gp(155.0, 57.0), 0.0, "sewer manhole in the garage drive")
	for sb: Array in [[56.0, 127.0], [82.0, 127.0], [69.0, 127.0]]:
		c.put("prop_park_bench", "worn", c.gp(float(sb[0]), float(sb[1])), 180.0, "field: a sideline bench facing the game")
	for wb: Array in [[30.0, 185.0], [70.0, 185.0]]: c.put("prop_park_bench", "worn", c.gp(float(wb[0]), float(wb[1])), 180.0, "tennis: a bench outside the cage for players waiting for a court")
	c.put("prop_drinking_fountain", "worn", c.gp(50.0, 186.0), 0.0, "tennis: water by the gate path")
	c.put("prop_drinking_fountain", "worn", c.gp(130.0, 40.0), 0.0, "field: water at the loop's corner")
	for vm: Array in [[174.0, 128.0, "prop_vending_soda"], [174.0, 116.0, "prop_vending_snack"]]: c.put(String(vm[2]), "worn", c.gp(float(vm[0]), float(vm[1])), 90.0, "stadium walk: machines beside the kiosk for the queue")
	c.put("prop_newspaper_box_red", "worn", c.gp(189.6, 133.0), 90.0, "stadium walk: the sports paper")
	for bk: float in [114.0, 124.0]: c.put("prop_bike_rack", "worn", c.gp(152.0, bk), 0.0, "stadium walk: bikes left for the game")
	c.put("prop_golf_cart_blue", "worn", c.gp(120.0, 35.5), 90.0, "athletics: the field crew's cart behind the kinesiology wing")
	for sp: Array in [[160.0, 40.0], [60.0, 186.0]]: c.put("prop_sprinkler_impact", "worn", c.gp(float(sp[0]), float(sp[1])), 0.0, "lawn: sprinkler head")
	c.put("prop_usps_collection_box", "worn", c.gp(88.0, 8.0), 0.0, "rec centre: a mailbox on the mall")
	c.finish()
	quit()
