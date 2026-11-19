extends SceneTree
## Piece n_un_nw (UNIVERSITY CAMPUS, north-west quarter; claude/sharp-ride-16u9ik 19 Nov). Layout row (-600, 6.0, -600),
## local x = u + 600, z = v + 600. Covers u -790.8..-600, v -790.8..-600: the quarter on 6th St (north) and the west street.
## SITE (19 Nov dump + zoning/terrain_grid.npz): land 6.07..6.30 (the campus' low crown reaches in from the east), 6th St's
## and the west street's walks 6.15 all along; aprons on 6th St at u -746.6..-739.4 and -660.6..-653.4, on the west street
## at v -746.6..-739.4 and -660.6..-653.4 (the same four places on every side of the campus).
## PLANNER: the students' side. The STUDENT UNION stands at the gate across the north mall from the gate café (n_un_ne):
## students from the gritty edge cross 6th St into its plaza (tables, bikes, the events case). A one-way CAMPUS DRIVE runs
## inside 6th St between its two aprons (in at u -746, out at u -660) with a drop-off lay-by for the MUSEUM (the
## university's art museum, public, facing the street with its forecourt) and the CHAPEL; the union's deliveries leave it
## down a service lane to the yard behind the union. Visitors park in the lot off the west street's two aprons (the
## mirror of the faculty lot in n_un_ne). The WEST QUAD (bandstand for concerts, chairs on the lawn) is framed by the
## humanities wing (north), the arts wing (south-west) and the malls.
## GROUND (elevation): the ground follows the land 8 cm over it and eases over 8 m to walk level 6.15 at both streets;
## every building on a level pad at the highest ground under it (plinth faces, none sunk). Shared edges with the other
## quarters (x = 0, z = 0) are land + 0.08 on both sides, so they meet flush.
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(-600.0, 6.0, -600.0)
const LAND := {"x0": -196.0, "z0": -196.0, "step": 4.0, "nx": 51, "nz": 51, "h": [-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,-0.05,-0.05,0.10,0.10,0.10,0.10,0.11,0.10,0.10,0.11,0.11,0.10,0.10,0.11,0.10,0.11,0.11,0.10,0.11,0.11,0.11,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.12,0.11,0.11,0.12,0.12,0.11,0.11,0.12,0.11,0.12,0.12,0.12,0.12,0.12,0.12,0.12,-0.05,-0.05,0.10,0.10,0.11,0.11,0.11,0.11,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.12,0.11,0.11,0.11,0.11,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.13,0.12,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.14,0.14,-0.05,-0.05,0.10,0.10,0.11,0.11,0.11,0.11,0.11,0.12,0.11,0.12,0.11,0.12,0.12,0.11,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.13,0.14,0.13,0.14,0.13,0.13,0.14,0.14,0.14,0.14,0.15,0.14,0.15,0.14,0.14,0.15,0.15,0.15,0.15,0.15,0.15,0.16,0.16,-0.05,-0.05,0.10,0.10,0.10,0.11,0.11,0.12,0.11,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.15,0.15,0.15,0.15,0.16,0.15,0.16,0.16,0.16,0.16,0.16,0.16,0.16,0.17,0.16,0.17,0.17,0.17,0.17,-0.05,-0.05,0.10,0.11,0.10,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.13,0.13,0.13,0.14,0.14,0.13,0.14,0.14,0.14,0.14,0.15,0.15,0.15,0.15,0.15,0.16,0.16,0.16,0.16,0.16,0.16,0.17,0.17,0.17,0.17,0.17,0.18,0.17,0.18,0.18,0.18,0.18,0.18,0.19,0.19,0.19,-0.05,-0.05,0.10,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.13,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.15,0.15,0.15,0.15,0.16,0.16,0.16,0.16,0.16,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.18,0.18,0.18,0.18,0.19,0.19,0.20,0.20,0.19,0.20,0.20,0.20,0.20,0.20,-0.05,-0.05,0.10,0.11,0.11,0.12,0.12,0.12,0.13,0.13,0.13,0.13,0.14,0.14,0.14,0.14,0.14,0.14,0.14,0.15,0.15,0.16,0.16,0.16,0.16,0.16,0.17,0.17,0.17,0.17,0.18,0.18,0.19,0.19,0.18,0.19,0.19,0.19,0.19,0.20,0.20,0.21,0.21,0.20,0.21,0.21,0.21,0.21,0.22,0.22,0.22,-0.05,-0.05,0.10,0.11,0.11,0.11,0.12,0.12,0.13,0.13,0.13,0.13,0.14,0.14,0.14,0.15,0.15,0.15,0.15,0.16,0.15,0.16,0.16,0.16,0.17,0.17,0.18,0.18,0.18,0.18,0.19,0.19,0.19,0.19,0.19,0.20,0.20,0.21,0.21,0.21,0.21,0.21,0.22,0.22,0.22,0.22,0.23,0.23,0.24,0.23,0.23,-0.05,-0.05,0.10,0.10,0.11,0.12,0.12,0.12,0.13,0.13,0.14,0.14,0.14,0.15,0.15,0.16,0.15,0.16,0.16,0.16,0.16,0.16,0.17,0.17,0.18,0.17,0.18,0.18,0.19,0.19,0.19,0.20,0.20,0.21,0.21,0.21,0.21,0.22,0.22,0.22,0.22,0.22,0.23,0.23,0.23,0.23,0.24,0.24,0.24,0.25,0.24,-0.05,-0.05,0.10,0.10,0.11,0.12,0.13,0.13,0.14,0.14,0.14,0.14,0.14,0.15,0.15,0.16,0.16,0.16,0.16,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.19,0.20,0.20,0.20,0.20,0.21,0.21,0.22,0.22,0.22,0.23,0.23,0.23,0.23,0.24,0.24,0.25,0.25,0.25,0.25,0.25,0.26,0.25,-0.05,-0.05,0.10,0.11,0.12,0.12,0.13,0.13,0.13,0.14,0.14,0.15,0.15,0.16,0.16,0.16,0.16,0.16,0.17,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.19,0.20,0.20,0.21,0.21,0.21,0.22,0.22,0.22,0.22,0.23,0.23,0.23,0.23,0.24,0.24,0.25,0.25,0.25,0.25,0.25,0.26,0.26,0.27,0.27,-0.05,-0.05,0.10,0.10,0.11,0.12,0.12,0.13,0.13,0.14,0.14,0.15,0.15,0.15,0.16,0.16,0.16,0.17,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.20,0.20,0.20,0.21,0.21,0.22,0.22,0.22,0.22,0.23,0.23,0.24,0.24,0.24,0.25,0.25,0.25,0.25,0.25,0.26,0.26,0.26,0.27,0.27,0.28,0.28,-0.05,-0.05,0.10,0.10,0.11,0.12,0.12,0.13,0.13,0.14,0.14,0.15,0.15,0.15,0.16,0.16,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.20,0.20,0.20,0.21,0.21,0.22,0.22,0.23,0.23,0.23,0.24,0.24,0.24,0.25,0.25,0.25,0.26,0.26,0.26,0.26,0.27,0.27,0.27,0.27,0.27,0.28,-0.05,-0.05,0.10,0.11,0.11,0.12,0.12,0.13,0.13,0.14,0.14,0.15,0.15,0.16,0.16,0.16,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.19,0.19,0.20,0.20,0.21,0.21,0.21,0.22,0.22,0.23,0.23,0.23,0.23,0.24,0.24,0.25,0.25,0.25,0.26,0.26,0.26,0.26,0.27,0.27,0.27,0.28,0.28,0.29,-0.05,-0.05,0.10,0.11,0.11,0.12,0.12,0.13,0.13,0.13,0.14,0.14,0.15,0.15,0.16,0.16,0.17,0.17,0.17,0.18,0.18,0.19,0.19,0.19,0.20,0.20,0.21,0.21,0.21,0.21,0.22,0.22,0.23,0.23,0.24,0.24,0.24,0.25,0.24,0.25,0.25,0.26,0.26,0.27,0.27,0.27,0.28,0.28,0.28,0.28,0.29,-0.05,-0.05,0.10,0.11,0.11,0.12,0.12,0.12,0.13,0.13,0.14,0.14,0.15,0.15,0.16,0.16,0.16,0.17,0.17,0.18,0.18,0.19,0.19,0.20,0.19,0.19,0.20,0.20,0.21,0.21,0.22,0.22,0.23,0.23,0.23,0.23,0.24,0.24,0.24,0.25,0.25,0.26,0.26,0.26,0.26,0.26,0.27,0.27,0.28,0.28,0.29,-0.05,-0.05,0.10,0.11,0.11,0.11,0.12,0.12,0.13,0.13,0.14,0.14,0.15,0.15,0.15,0.16,0.16,0.17,0.17,0.18,0.17,0.18,0.18,0.18,0.19,0.19,0.20,0.20,0.21,0.21,0.21,0.22,0.22,0.22,0.23,0.23,0.24,0.24,0.25,0.24,0.25,0.25,0.25,0.26,0.26,0.26,0.27,0.27,0.28,0.27,0.27,-0.05,-0.05,0.10,0.10,0.11,0.11,0.12,0.12,0.13,0.13,0.14,0.14,0.14,0.15,0.15,0.16,0.15,0.16,0.16,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.19,0.20,0.20,0.21,0.21,0.21,0.22,0.22,0.23,0.23,0.23,0.23,0.24,0.24,0.24,0.25,0.25,0.25,0.25,0.25,0.26,0.26,0.27,0.27,0.27,-0.05,-0.05,0.10,0.10,0.11,0.11,0.12,0.12,0.13,0.13,0.14,0.13,0.14,0.14,0.15,0.15,0.15,0.16,0.16,0.17,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.20,0.20,0.20,0.21,0.21,0.21,0.21,0.22,0.22,0.23,0.23,0.23,0.24,0.23,0.24,0.24,0.24,0.25,0.25,0.26,0.26,0.26,0.27,0.26,-0.05,-0.05,0.10,0.10,0.11,0.11,0.12,0.12,0.12,0.13,0.13,0.14,0.14,0.14,0.15,0.15,0.16,0.16,0.16,0.16,0.17,0.17,0.17,0.18,0.18,0.19,0.19,0.19,0.19,0.20,0.20,0.20,0.21,0.21,0.22,0.22,0.22,0.22,0.22,0.23,0.23,0.23,0.24,0.24,0.25,0.24,0.24,0.25,0.25,0.26,0.26,-0.05,-0.05,0.10,0.10,0.11,0.11,0.12,0.12,0.12,0.13,0.13,0.14,0.13,0.14,0.14,0.15,0.15,0.15,0.16,0.16,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.19,0.20,0.20,0.20,0.20,0.21,0.21,0.21,0.22,0.22,0.22,0.23,0.22,0.23,0.23,0.23,0.24,0.24,0.25,0.25,0.26,0.26,-0.05,-0.05,0.10,0.10,0.11,0.11,0.11,0.12,0.12,0.12,0.12,0.13,0.13,0.14,0.14,0.14,0.15,0.15,0.15,0.15,0.16,0.16,0.17,0.17,0.17,0.18,0.18,0.18,0.18,0.19,0.19,0.19,0.20,0.20,0.20,0.21,0.21,0.21,0.21,0.21,0.22,0.22,0.22,0.23,0.23,0.24,0.23,0.24,0.24,0.24,0.25,-0.05,-0.05,0.10,0.11,0.10,0.11,0.11,0.12,0.12,0.12,0.13,0.13,0.13,0.13,0.13,0.14,0.14,0.14,0.15,0.15,0.16,0.16,0.16,0.16,0.16,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.19,0.19,0.19,0.20,0.20,0.20,0.21,0.21,0.21,0.22,0.21,0.22,0.22,0.23,0.23,0.24,0.24,0.24,0.24,-0.05,-0.05,0.10,0.10,0.10,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.14,0.14,0.14,0.15,0.14,0.14,0.15,0.15,0.16,0.16,0.17,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.19,0.20,0.20,0.20,0.20,0.20,0.21,0.21,0.22,0.22,0.23,0.23,0.23,0.23,0.23,0.23,-0.05,-0.05,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.12,0.12,0.12,0.13,0.13,0.13,0.13,0.13,0.14,0.14,0.14,0.14,0.15,0.15,0.16,0.15,0.16,0.16,0.16,0.17,0.17,0.18,0.18,0.18,0.19,0.18,0.18,0.19,0.19,0.19,0.20,0.20,0.21,0.21,0.21,0.21,0.21,0.22,0.22,0.22,0.22,0.23,-0.05,-0.05,0.10,0.10,0.10,0.11,0.11,0.11,0.12,0.12,0.11,0.12,0.12,0.12,0.13,0.13,0.13,0.14,0.14,0.14,0.14,0.14,0.14,0.15,0.15,0.15,0.16,0.16,0.17,0.16,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.19,0.19,0.20,0.20,0.20,0.21,0.21,0.21,0.22,0.22,0.21,0.22,-0.05,-0.05,0.10,0.11,0.11,0.11,0.10,0.11,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.13,0.12,0.13,0.13,0.13,0.13,0.14,0.14,0.14,0.15,0.14,0.15,0.15,0.16,0.16,0.16,0.17,0.17,0.17,0.17,0.17,0.17,0.18,0.18,0.19,0.19,0.19,0.20,0.20,0.20,0.20,0.20,0.20,0.21,0.21,0.21,-0.05,-0.05,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.11,0.12,0.11,0.11,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.14,0.14,0.15,0.15,0.15,0.16,0.16,0.15,0.16,0.16,0.16,0.17,0.17,0.18,0.18,0.18,0.18,0.18,0.19,0.19,0.19,0.20,0.20,0.20,0.20,0.21,0.20,-0.05,-0.05,0.10,0.10,0.10,0.11,0.11,0.10,0.11,0.11,0.11,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.14,0.14,0.14,0.14,0.14,0.15,0.15,0.15,0.15,0.16,0.16,0.17,0.16,0.16,0.17,0.17,0.18,0.18,0.18,0.19,0.19,0.18,0.19,0.19,0.19,0.20,0.20,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.10,0.11,0.11,0.11,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.14,0.14,0.14,0.14,0.15,0.14,0.15,0.15,0.15,0.16,0.16,0.17,0.17,0.17,0.17,0.17,0.18,0.18,0.18,0.18,0.19,0.19,0.20,0.20,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.11,0.10,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.12,0.12,0.12,0.13,0.13,0.12,0.13,0.13,0.13,0.14,0.14,0.14,0.15,0.15,0.16,0.15,0.16,0.16,0.16,0.17,0.17,0.17,0.17,0.18,0.17,0.18,0.18,0.18,0.19,-0.05,-0.05,0.10,0.10,0.09,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.11,0.11,0.11,0.11,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.14,0.13,0.14,0.14,0.15,0.15,0.15,0.16,0.16,0.16,0.16,0.16,0.16,0.17,0.17,0.18,0.18,0.18,0.18,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.10,0.11,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.11,0.12,0.11,0.11,0.12,0.12,0.13,0.13,0.14,0.14,0.14,0.14,0.14,0.14,0.15,0.15,0.15,0.16,0.16,0.17,0.17,0.17,0.17,0.17,0.17,-0.05,-0.05,0.10,0.10,0.10,0.10,0.09,0.10,0.09,0.09,0.09,0.09,0.10,0.09,0.10,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.10,0.11,0.10,0.10,0.10,0.10,0.11,0.11,0.12,0.12,0.12,0.13,0.12,0.13,0.13,0.13,0.14,0.14,0.14,0.15,0.15,0.15,0.15,0.15,0.16,0.16,0.16,0.16,0.17,-0.05,-0.05,0.10,0.10,0.10,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.08,0.09,0.09,0.09,0.09,0.10,0.10,0.10,0.11,0.10,0.11,0.11,0.11,0.11,0.12,0.12,0.12,0.13,0.13,0.13,0.13,0.14,0.14,0.14,0.15,0.15,0.15,0.16,0.16,0.15,0.16,-0.05,-0.05,0.10,0.10,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.08,0.09,0.08,0.09,0.09,0.08,0.08,0.08,0.08,0.08,0.09,0.09,0.09,0.09,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.11,0.11,0.12,0.12,0.13,0.13,0.13,0.14,0.14,0.14,0.14,0.14,0.14,0.15,0.15,0.16,-0.05,-0.05,0.10,0.10,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.08,0.08,0.07,0.07,0.08,0.07,0.08,0.08,0.08,0.08,0.07,0.07,0.08,0.08,0.08,0.09,0.09,0.09,0.09,0.09,0.09,0.09,0.10,0.10,0.11,0.11,0.12,0.12,0.12,0.12,0.12,0.12,0.13,0.13,0.13,0.14,0.14,0.15,0.15,0.14,-0.05,-0.05,0.10,0.10,0.10,0.09,0.09,0.08,0.08,0.08,0.08,0.07,0.07,0.07,0.07,0.07,0.07,0.07,0.06,0.07,0.07,0.07,0.07,0.07,0.08,0.08,0.07,0.07,0.08,0.08,0.08,0.09,0.09,0.10,0.10,0.10,0.10,0.10,0.11,0.11,0.11,0.12,0.12,0.12,0.13,0.12,0.13,0.13,0.13,0.14,0.14,-0.05,-0.05,0.10,0.09,0.09,0.09,0.08,0.08,0.08,0.08,0.07,0.07,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.07,0.07,0.07,0.08,0.08,0.08,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.11,0.11,0.10,0.11,0.11,0.12,0.12,0.12,0.13,0.13,0.14,0.14,-0.05,-0.05,0.10,0.09,0.09,0.09,0.09,0.08,0.07,0.07,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.05,0.05,0.05,0.05,0.05,0.06,0.06,0.06,0.06,0.06,0.06,0.06,0.07,0.07,0.07,0.08,0.08,0.08,0.09,0.08,0.09,0.09,0.10,0.10,0.11,0.11,0.11,0.12,0.11,0.12,0.12,0.12,0.13,-0.05,-0.05,0.10,0.10,0.09,0.08,0.08,0.07,0.07,0.07,0.06,0.06,0.06,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.05,0.05,0.05,0.04,0.04,0.05,0.05,0.05,0.05,0.06,0.06,0.07,0.07,0.06,0.07,0.07,0.08,0.08,0.09,0.09,0.10,0.10,0.09,0.10,0.10,0.11,0.11,0.11,0.12,0.12,0.12,-0.05,-0.05,0.10,0.09,0.09,0.08,0.08,0.07,0.07,0.06,0.05,0.05,0.05,0.04,0.04,0.04,0.04,0.04,0.04,0.03,0.03,0.03,0.03,0.04,0.04,0.04,0.04,0.05,0.04,0.05,0.05,0.05,0.06,0.06,0.06,0.07,0.07,0.08,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.10,0.11,0.10,0.10,0.11,0.11,-0.05,-0.05,0.10,0.10,0.09,0.08,0.07,0.06,0.06,0.05,0.05,0.04,0.04,0.04,0.04,0.03,0.03,0.02,0.03,0.03,0.02,0.03,0.03,0.03,0.02,0.03,0.03,0.03,0.04,0.04,0.04,0.05,0.05,0.05,0.05,0.05,0.06,0.06,0.07,0.07,0.08,0.08,0.09,0.08,0.09,0.09,0.09,0.10,0.10,0.11,0.11,-0.05,-0.05,0.10,0.09,0.08,0.08,0.07,0.06,0.06,0.05,0.04,0.03,0.03,0.03,0.02,0.02,0.02,0.02,0.02,0.02,0.01,0.01,0.01,0.02,0.02,0.02,0.02,0.03,0.03,0.02,0.03,0.03,0.04,0.04,0.05,0.05,0.05,0.06,0.06,0.06,0.06,0.07,0.07,0.08,0.08,0.09,0.09,0.09,0.10,0.09,0.10,-0.05,-0.05,0.10,0.09,0.08,0.08,0.06,0.05,0.05,0.04,0.03,0.03,0.02,0.02,0.02,0.02,0.00,0.00,0.00,0.00,0.00,0.01,0.01,0.01,0.01,0.00,0.01,0.01,0.02,0.02,0.02,0.03,0.03,0.04,0.04,0.04,0.04,0.05,0.05,0.06,0.06,0.07,0.07,0.07,0.07,0.07,0.08,0.08,0.09,0.09,0.10,-0.05,-0.05,0.10,0.09,0.08,0.07,0.06,0.05,0.04,0.03,0.03,0.01,0.01,0.01,0.00,0.00,-0.00,-0.00,-0.00,-0.00,-0.00,-0.01,-0.01,-0.01,-0.00,-0.00,0.00,0.00,0.01,0.01,0.01,0.01,0.02,0.02,0.03,0.03,0.04,0.04,0.05,0.05,0.05,0.05,0.06,0.06,0.07,0.07,0.08,0.08,0.09,0.09,0.08,-0.05,-0.05,0.10,0.09,0.08,0.07,0.06,0.04,0.03,0.02,0.01,0.01,0.00,-0.00,-0.01,-0.01,-0.01,-0.02,-0.02,-0.02,-0.02,-0.02,-0.02,-0.02,-0.01,-0.01,-0.01,-0.01,-0.01,-0.00,0.00,0.01,0.01,0.02,0.02,0.03,0.02,0.03,0.03,0.04,0.04,0.05,0.05,0.06,0.06,0.06,0.06,0.07,0.07,0.08,0.08,-0.05,-0.05,0.10,0.08,0.07,0.06,0.05,0.03,0.02,0.02,0.01,0.00,-0.01,-0.02,-0.02,-0.02,-0.03,-0.03,-0.03,-0.03,-0.03,-0.03,-0.03,-0.03,-0.03,-0.03,-0.02,-0.02,-0.01,-0.01,-0.01,0.00,-0.01,0.00,0.01,0.01,0.02,0.02,0.03,0.03,0.04,0.03,0.04,0.05,0.05,0.06,0.06,0.07,0.07,0.08,0.08]}

## the yaw that makes a prop at p face the point t (yaw 0 faces +z)
static func face(p: Vector2, t: Vector2) -> float: return rad_to_deg(atan2(t.x - p.x, t.y - p.y))

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("n_un_nw")
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z) + 0.08
	var flat := func(_x: float, _z: float) -> float: return 0.15
	var base := L.eased(land, [[Vector2(-190.8, -190.8), Vector2(0.0, -190.8), flat], [Vector2(-190.8, -190.8), Vector2(-190.8, 0.0), flat]], 8.0)
	var SITES := [["civic/civ_museum", Vector2(-150.0, -172.0), "n", "uni_museum"], ["public/pub_chapel", Vector2(-95.0, -172.0), "n", "uni_chapel"],
		["civic/civ_community_center", Vector2(-30.0, -172.0), "n", "uni_union"], ["civic/civ_school_wing", Vector2(-90.0, -125.0), "s", "uni_humanities"],
		["civic/civ_school_wing", Vector2(-166.0, -6.4), "s", "uni_arts"]]
	var pads: Array = []
	for st: Array in SITES:
		var r0: Array = L.bld_rect(String(st[0]), st[1], String(st[2]))
		pads.append([maxf(-190.8, float(r0[0]) - 0.3), maxf(-190.8, float(r0[1]) - 0.3), minf(0.0, float(r0[2]) + 0.3), minf(0.0, float(r0[3]) + 0.3)])
	var gl := L.grid_lots(-190.8, -190.8, 0.0, 0.0, pads, base)
	c.terrain(gl.lots)
	c.skirt_depth = 0.4
	# ---- surfaces (first paint wins)
	c.paint("plaza", -6.0, -190.8, 0.0, 0.0)                    # the north mall (east half: x -6..0 here)
	c.paint("plaza", -190.8, -6.0, 0.0, 0.0)                    # the west mall (north half)
	c.paint("plaza", -54.0, -190.8, -6.0, -172.0)               # the union plaza at the gate
	c.paint("asphalt", -146.0, -190.8, -140.0, -180.0)          # campus drive in (6th St apron at u -746)
	c.paint("asphalt", -146.0, -186.0, -54.0, -180.0)           # the drive with its drop-off lay-by
	c.paint("asphalt", -60.0, -190.8, -54.0, -140.0)            # the drive out (apron at u -660) and the union's service lane
	c.paint("asphalt", -54.0, -152.0, -12.0, -140.0)            # the union's loading yard
	c.paint("grass", -190.8, -190.8, -6.0, -186.0)              # the street lawn between the drive and 6th St
	c.paint("plaza", -186.0, -180.0, -110.0, -172.0)            # the museum forecourt
	c.paint("concrete", -110.0, -180.0, -60.0, -172.0)          # the chapel's walk along the drive
	c.paint("concrete", -165.0, -151.2, -135.0, -146.0)         # the museum's loading dock (from the lot lane)
	c.paint("asphalt", -190.8, -146.0, -146.0, -140.0)          # lot lane from the west street (apron v -746)
	c.paint("asphalt", -190.8, -60.0, -146.0, -54.0)            # lot lane to the west street (apron v -660)
	c.paint("asphalt", -177.0, -146.0, -146.0, -54.0)           # the visitors' lot
	c.paint("grass", -190.8, -140.0, -177.0, -60.0)             # planted buffer to the west street
	c.paint("concrete", -146.0, -146.0, -142.0, -6.0)           # the walk from the lot to the quad
	for qp: Array in [[-142.0, -125.0, -6.0, -123.0], [-142.0, -8.0, -6.0, -6.0], [-142.0, -125.0, -140.0, -6.0], [-8.0, -125.0, -6.0, -6.0], [-63.0, -125.0, -61.0, -6.0], [-142.0, -66.0, -6.0, -64.0]]:
		c.paint("concrete", float(qp[0]), float(qp[1]), float(qp[2]), float(qp[3]))      # the west quad's paths
	c.paint("concrete", -106.0, -101.0, -94.0, -89.0)           # the bandstand's slab
	c.paint("grass", -140.0, -123.0, -8.0, -8.0)                # the west quad lawn
	c.paint("concrete", -190.8, -24.5, -146.0, -6.0)            # the arts wing's walk and terrace
	c.paint("concrete", -125.0, -164.0, -101.0, -162.0)         # sculpture garden path
	c.paint("concrete", -134.0, -172.0, -132.0, -151.0)         # sculpture garden path to the museum's side door
	c.paint("grass", -190.8, -190.8, 0.0, 0.0)                  # everything else is lawn (sculpture garden, lawns)
	for wp: Array in [[-3.0, -170.0], [-3.0, -110.0], [-3.0, -50.0], [-40.0, -3.0], [-100.0, -3.0], [-160.0, -3.0], [-48.0, -184.0], [-12.0, -184.0], [-48.0, -176.0], [-12.0, -176.0], [-176.0, -176.0], [-120.0, -176.0]]:
		c.well(float(wp[0]), float(wp[1]))
	c.build_floor(L.rect_edges(-190.8, -190.8, 0.0, 0.0))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b089_a", Vector3(-800, 6, -800), 90.0], ["s_rs_b089_b", Vector3(-600, 6, -800), -90.0], ["s_rs_b004_a", Vector3(-800, 6, -800), 0.0], ["s_rs_b004_b", Vector3(-800, 6, -600), -180.0],
		["j_rs_3l1r_a", Vector3(-800, 6, -800), -90.0], ["j_rs_t_lll_a", Vector3(-600, 6, -800), 180.0], ["j_rs_t_lll_a", Vector3(-800, 6, -600), -90.0]], O)
	# ---- buildings (each by its real front, on its pad)
	var B := {}
	for k in SITES.size():
		var st2: Array = SITES[k]
		c.y0 = float(gl.pads[k][4])
		B[String(st2[3])] = c.bld(String(st2[0]), st2[1], String(st2[2]), false, String(st2[3]))
	c.y0 = 0.15
	var MU: Dictionary = B.uni_museum; var CH: Dictionary = B.uni_chapel; var UN: Dictionary = B.uni_union; var HU: Dictionary = B.uni_humanities; var AR: Dictionary = B.uni_arts
	# ---- the campus drive: one way, the drop-off lay-by, lamps and trees on the street lawn
	c.put("prop_sign_no_parking", "worn", c.gp(-139.4, -189.6), -90.0, "campus drive: drop-off only, no parking")
	c.put("prop_sign_no_parking", "worn", c.gp(-60.6, -189.6), 90.0, "campus drive: drop-off only, no parking")
	c.put("prop_sign_stop", "worn", c.gp(-61.0, -186.6), 180.0, "campus drive: stop before the walk and 6th St")
	for lx: float in [-160.0, -125.0, -90.0, -70.0]: c.put("prop_lamp_cobra", "worn", c.gp(lx, -187.6), 180.0, "campus drive: lit at night, lamps on the street lawn")
	for tx: Array in [[-176.0, "tree_coral_a"], [-150.0, "tree_coral_b"], [-108.0, "tree_coral_a"], [-80.0, "tree_coral_b"]]:
		c.put(String(tx[1]), "normal", c.gp(float(tx[0]), -188.4), c.rr.randf_range(0, 360), "street lawn: coral trees between the drive and 6th St", true, 0.8)
	for tm: Array in [[-143.0, -183.0, 60.0], [-57.0, -183.0, -60.0], [-125.0, -183.0, 90.0]]: c.tyre(Vector2(float(tm[0]), float(tm[1])), float(tm[2]), 6.0, 0.4)
	c.oil(Vector2(-128.0, -183.0), 90.0); c.oil(Vector2(-96.0, -183.0), 90.0)
	for bo: float in [-130.0, -120.0, -100.0, -90.0]: c.put("prop_bollard_concrete", "worn", c.gp(bo, -179.4), 0.0, "drop-off: bollards keep cars off the forecourt")
	# ---- the museum forecourt: trees in wells, benches facing the museum, the monument, bikes
	for wx: float in [-176.0, -120.0]: c.put("tree_magnolia_a", "normal", c.gp(wx, -176.0), c.rr.randf_range(0, 360), "museum forecourt: magnolias in wells", true, 0.85)
	for bn: float in [-168.0, -160.0, -140.0, -132.0]: c.put("prop_park_bench", "worn", c.gp(bn, -177.4), 0.0, "museum forecourt: benches facing the museum")
	for lp: float in [-164.0, -136.0]: c.put("prop_lamp_victorian", "worn", c.gp(lp, -174.0), 0.0, "museum forecourt: lamps either side of the doors")
	for pl: float in [-154.0, -146.0]: c.put("plant_potted_leafy", "normal", c.gp(pl, -173.2), 0.0, "museum: planters either side of the steps")
	c.put("prop_poster_case", "worn", c.gp(-158.0, -173.0), 0.0, "museum: the exhibition poster by the doors")
	c.put("prop_bike_rack", "worn", c.gp(-182.0, -176.0), 0.0, "museum forecourt: bikes off the walk")
	c.put("prop_trash_receptacle", "worn", c.gp(-150.0, -178.6), 0.0, "museum forecourt: a bin")
	c.put("prop_drinking_fountain", "worn", c.gp(-115.0, -174.0), 0.0, "museum forecourt: water by the garden gate")
	# ---- the sculpture garden (east of the museum): the monument, agave and bougainvillea beds, benches facing them
	c.put("prop_obelisk_monument", "worn", c.gp(-118.0, -158.0), 0.0, "sculpture garden: the tall piece at the end of the path")
	for ag: Array in [[-128.0, -168.0], [-122.0, -168.0], [-110.0, -168.0], [-128.0, -156.0], [-110.0, -156.0]]:
		c.put("plant_agave_americana", "normal", c.gp(float(ag[0]), float(ag[1])), c.rr.randf_range(0, 360), "sculpture garden: agave beds, a dry garden")
	for bg: Array in [[-106.0, -160.0], [-130.0, -160.0]]: c.put("plant_bougainvillea_mound", "normal", c.gp(float(bg[0]), float(bg[1])), c.rr.randf_range(0, 360), "sculpture garden: bougainvillea mounds")
	for sb: Array in [[-124.0, -165.0], [-112.0, -165.0]]: c.put("prop_park_bench", "worn", c.gp(float(sb[0]), float(sb[1])), face(Vector2(float(sb[0]), float(sb[1])), Vector2(-118.0, -158.0)), "sculpture garden: a bench facing the monument")
	c.put("tree_jacaranda_a", "normal", c.gp(-104.0, -150.0), c.rr.randf_range(0, 360), "sculpture garden: shade at its back", true, 0.85)
	# ---- the chapel: its walk, benches facing it, magnolias either side
	for cb: float in [-104.0, -86.0]: c.put("prop_park_bench", "worn", c.gp(cb, -177.0), 0.0, "chapel: benches facing its doors, for after the service")
	for cm: float in [-106.0, -84.0]: c.put("tree_magnolia_b", "normal", c.gp(cm, -166.0), c.rr.randf_range(0, 360), "chapel: magnolias either side of it, in the lawn", true, 0.8)
	for pp: float in [-98.0, -92.0]: c.put("plant_potted_succulent", "normal", c.gp(pp, -173.0), 0.0, "chapel: pots by its door")
	c.put("prop_lamp_victorian", "worn", c.gp(-88.0, -175.0), 0.0, "chapel: its walk lit")
	# the lawn between the chapel and the drive out: jacarandas and a picnic table
	for jt: Array in [[-78.0, -168.0, "tree_jacaranda_b"], [-68.0, -156.0, "tree_jacaranda_a"]]:
		c.put(String(jt[2]), "normal", c.gp(float(jt[0]), float(jt[1])), c.rr.randf_range(0, 360), "lawn: jacarandas by the service lane", true, 0.85)
	c.put("prop_picnic_table", "worn", c.gp(-74.0, -160.0), 0.0, "lawn: a table in the jacarandas' shade")
	# ---- the union plaza at the gate: tables, bikes, the events case, papers
	for ct: Array in [[-48.0, -180.0], [-40.0, -180.0], [-20.0, -180.0], [-12.0, -180.0], [-40.0, -186.0], [-20.0, -186.0]]:
		c.put("prop_cafe_table", "worn", c.gp(float(ct[0]), float(ct[1])), 0.0, "union plaza: tables outside the food hall")
		c.put("prop_cafe_chair", "worn", c.gp(float(ct[0]) - 0.8, float(ct[1])), 90.0, "union plaza: a chair at its table", false)
		c.put("prop_cafe_chair", "worn", c.gp(float(ct[0]) + 0.8, float(ct[1])), -90.0, "union plaza: a chair at its table", false)
	for fx: float in [-48.0, -12.0]:
		for fz: float in [-184.0, -176.0]: c.put("tree_ficus_b", "normal", c.gp(fx, fz), c.rr.randf_range(0, 360), "union plaza: ficus in wells shade the tables", true, 0.75)
	c.put("prop_poster_case", "worn", c.gp(-36.0, -173.4), 0.0, "union: the events case by its doors (gigs, clubs, rooms to let)")
	c.put("prop_menu_board", "worn", c.gp(-24.0, -173.6), 0.0, "union: today's food hall menu")
	for br: float in [-30.0, -27.0, -24.0]: c.put("prop_bike_rack", "worn", c.gp(br, -189.0), 0.0, "union plaza: bikes along the walk")
	c.put("prop_newspaper_box_red", "worn", c.gp(-8.5, -189.8), 180.0, "gate: the student paper")
	c.put("prop_usps_collection_box", "worn", c.gp(-52.0, -189.6), 180.0, "gate: a mailbox where students cross 6th St")
	for tb: Array in [[-44.0, -173.6, "prop_trash_receptacle"], [-16.0, -173.6, "prop_recycling_receptacle"]]: c.put(String(tb[2]), "worn", c.gp(float(tb[0]), float(tb[1])), 0.0, "union plaza: bins by the doors")
	for ul: float in [-52.0, -8.0]: c.put("prop_lamp_victorian", "worn", c.gp(ul, -173.0), 0.0, "union plaza: lamps")
	c.put("prop_vending_soda", "worn", c.gp(-15.0, -153.4), 0.0, "union: drinks machine at its side door off the yard")
	# ---- the union's loading yard: dumpsters, a delivery van's marks
	c.put("prop_dumpster_3yd_green", "worn", c.gp(-50.0, -150.6), 0.0, "union: food hall waste, collected from the service lane")
	c.put("prop_dumpster_3yd_blue", "worn", c.gp(-46.4, -150.6), 0.0, "union: cardboard recycling")
	c.tyre(Vector2(-57.0, -146.0), 45.0, 6.0, 0.45); c.oil(Vector2(-30.0, -146.0), 90.0); c.cracks(-54.0, -152.0, -12.0, -140.0, 6, 0.4)
	c.put("prop_sign_no_parking", "worn", c.gp(-12.6, -141.0), 0.0, "loading yard: keep clear for deliveries")
	# ---- the visitors' lot (mirror of the faculty lot)
	for k in 28:
		var sz := -137.0 + k * 2.7
		if sz > -63.0: break
		c.stalls.append([-154.5, sz, 90.0, c.yf(-154.5, sz)]); c.stalls.append([-159.5, sz, -90.0, c.yf(-159.5, sz)]); c.stalls.append([-170.5, sz, 90.0, c.yf(-170.5, sz)])
		if k % 4 == 2: c.oil(Vector2(-159.5, sz), 90.0)
	for lp2: float in [-125.0, -100.0, -75.0]: c.put("prop_lot_light_pole", "worn", c.gp(-157.0, lp2), 0.0, "lot: light poles on the line between the back-to-back rows")
	c.put("prop_pay_station", "worn", c.gp(-144.0, -138.0), 0.0, "lot: the pay station where visitors walk out to the quad")
	c.put("prop_sign_no_parking", "worn", c.gp(-152.6, -147.0), 0.0, "lot: keep the lane clear")
	c.tyre(Vector2(-187.0, -143.0), 80.0, 6.0, 0.4); c.tyre(Vector2(-187.0, -57.0), -80.0, 6.0, 0.4); c.tyre(Vector2(-149.0, -143.0), -30.0, 5.0, 0.35); c.tyre(Vector2(-165.0, -57.0), 30.0, 5.0, 0.35)
	c.cracks(-177.0, -146.0, -146.0, -54.0, 14, 0.4)
	for t2: Array in [[-180.0, -130.0, "tree_eucalyptus_b"], [-186.0, -110.0, "tree_eucalyptus_a"], [-180.0, -90.0, "tree_eucalyptus_b"], [-186.0, -70.0, "tree_eucalyptus_a"]]:
		c.put(String(t2[2]), "normal", c.gp(float(t2[0]), float(t2[1])), c.rr.randf_range(0, 360), "lot buffer: eucalyptus screen the lot from the street", true, 0.85)
	# the corner lawn west of the museum: a torrey pine grove, the quarter's transformer
	for gt: Array in [[-184.0, -166.0, "tree_torrey_pine_a"], [-176.0, -154.0, "tree_torrey_pine_b"]]:
		c.put(String(gt[2]), "normal", c.gp(float(gt[0]), float(gt[1])), c.rr.randf_range(0, 360), "corner lawn: torrey pines", true, 0.85)
	c.put("prop_transformer_substation", "worn", c.gp(-186.0, -150.0), 90.0, "the quarter's transformer, in the corner lawn by the lot lane")
	# ---- the west quad: the bandstand, chairs and benches facing it, paths lined one species each, tables, lamps
	var BS := Vector2(-100.0, -95.0)
	c.put("prop_bandstand", "worn", c.gp(BS.x, BS.y), 0.0, "west quad: the bandstand for lunchtime concerts and graduation")
	for ad: Array in [[-112.0, -80.0], [-106.0, -78.0], [-94.0, -78.0], [-88.0, -80.0], [-116.0, -88.0], [-84.0, -88.0]]:
		c.put("prop_adirondack_wood" if int(ad[0]) % 2 == 0 else "prop_adirondack_white", "worn", c.gp(float(ad[0]), float(ad[1])), face(Vector2(float(ad[0]), float(ad[1])), BS), "west quad: lawn chairs facing the bandstand")
	for qz: float in [-115.0, -95.0, -75.0, -55.0, -35.0, -15.0]:
		for side: float in [-3.0, 3.0]: c.put("tree_magnolia_a", "normal", c.gp(-62.0 + side, qz), c.rr.randf_range(0, 360), "west quad: magnolias line the north-south path", true, 0.8)
	for qx: float in [-130.0, -40.0, -20.0]:
		for side2: float in [-3.0, 3.0]: c.put("tree_jacaranda_b", "normal", c.gp(qx, -65.0 + side2), c.rr.randf_range(0, 360), "west quad: jacarandas line the cross path", true, 0.8)
	for bq: Array in [[-35.0, -67.4, 180.0], [-25.0, -62.6, 0.0], [-120.0, -62.6, 0.0], [-59.6, -100.0, -90.0], [-64.4, -30.0, 90.0], [-64.4, -105.0, 90.0]]:
		c.put("prop_park_bench", "worn", c.gp(float(bq[0]), float(bq[1])), float(bq[2]), "west quad: a bench on the path facing the lawn")
	for pt: Array in [[-30.0, -100.0], [-30.0, -30.0], [-110.0, -30.0], [-125.0, -45.0]]:
		c.put("prop_picnic_table", "worn", c.gp(float(pt[0]), float(pt[1])), 0.0, "west quad: a table on the lawn for lunch outdoors")
	for ql: Array in [[-62.0, -124.0], [-62.0, -65.0], [-62.0, -7.0], [-141.0, -65.0], [-7.0, -65.0], [-141.0, -20.0], [-141.0, -110.0]]:
		c.put("prop_lamp_victorian", "worn", c.gp(float(ql[0]) - 1.6, float(ql[1])), 0.0, "west quad: the paths lit at night")
	c.put("prop_drinking_fountain", "worn", c.gp(-64.6, -67.0), 0.0, "west quad: water where the paths cross")
	for tq: Array in [[-104.0, -102.0, "prop_trash_receptacle"], [-96.0, -102.0, "prop_recycling_receptacle"]]: c.put(String(tq[2]), "worn", c.gp(float(tq[0]), float(tq[1])), 0.0, "bandstand: bins at its back")
	c.put("prop_sprinkler_impact", "worn", c.gp(-125.0, -110.0), 0.0, "west quad: the lawn's sprinkler head")
	c.put("prop_sprinkler_impact", "worn", c.gp(-30.0, -50.0), 0.0, "west quad: the lawn's sprinkler head")
	# ---- the humanities wing's front (on the quad's north path): bikes and a bench
	for hb: float in [-110.0, -70.0]: c.put("prop_bike_rack", "worn", c.gp(hb, -128.0), 0.0, "humanities: bikes on the grass either side of the wing, off the path")
	c.put("prop_trash_receptacle", "worn", c.gp(-84.0, -123.4), 0.0, "humanities: a bin by the doors")
	# ---- the malls (half of each here): palms in wells, lamps
	for mz: float in [-170.0, -110.0, -50.0]: c.put("palm_canary_date_b", "normal", c.gp(-3.0, mz), c.rr.randf_range(0, 360), "north mall: date palms in wells, the campus axis", true, 0.9)
	for mx: float in [-40.0, -100.0, -160.0]: c.put("palm_canary_date_a", "normal", c.gp(mx, -3.0), c.rr.randf_range(0, 360), "west mall: date palms in wells, the campus axis", true, 0.9)
	for ml: float in [-140.0, -80.0, -20.0]: c.put("prop_lamp_victorian", "worn", c.gp(-4.6, ml), 0.0, "north mall: lamps")
	for ml2: float in [-70.0, -130.0, -186.0]: c.put("prop_lamp_victorian", "worn", c.gp(ml2, -4.6), 0.0, "west mall: lamps")
	# ---- the arts wing: its terrace (tables where students draw outside), bikes, the lawn north of it
	for at: Array in [[-186.0, -20.0], [-186.0, -12.0], [-146.6, -20.0]]:
		c.put("prop_picnic_table", "worn", c.gp(float(at[0]), float(at[1])), 90.0, "arts wing: a table on its terrace for drawing outdoors")
	c.put("prop_bike_rack", "worn", c.gp(-147.0, -12.0), 0.0, "arts wing: bikes by its east end")
	for ta: Array in [[-180.0, -40.0, "tree_ficus_a"], [-160.0, -36.0, "tree_coral_a"], [-150.0, -46.0, "tree_jacaranda_a"]]:
		c.put(String(ta[2]), "normal", c.gp(float(ta[0]), float(ta[1])), c.rr.randf_range(0, 360), "arts lawn: shade trees in the grass", true, 0.85)
	c.put("prop_park_bench", "worn", c.gp(-166.0, -30.0), 0.0, "arts lawn: a bench facing the wing")
	# ---- service sides, bins
	for r: Dictionary in [MU, UN, HU, AR]: c.services(r, 2.0, 1, false)
	c.put("prop_dumpster_3yd_green", "worn", c.gp(-140.0, -149.0), 90.0, "museum: waste by the loading dock")
	c.put("prop_dumpster_3yd_green", "worn", c.gp(-145.0, -26.4), 0.0, "arts wing: waste, collected from the lot lane side")
	# ---- roofs and doors
	# (no roof plant: these civic roofs are pitched, the library refuses every spot)
	for r3: Dictionary in [MU, CH, UN, HU, AR]:
		for dr: Array in r3.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
