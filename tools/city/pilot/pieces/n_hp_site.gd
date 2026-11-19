extends RefCounted
## Hospital zone (claude/fill-high-street, 19 Nov; Yasin: "Start working on hospital zone ... Place a bus station at
## hospital"): the edges and heights its pieces share. Places nothing.
## Zone (ZONING.md, zones.py "hosp"): u 400..640, v -1590..-1400, between 3rd St (the bridge route, south), Adela Ave,
## and the bay-front ring (1st St / Glorietta Blvd, north and east). Frame: pieces at grid [0, 2.0, 0], yaw 0:
## x = u, z = v (north -v), local y = world - 2.0.
##
## Measured 19 Nov (scratch ground dump of the assembled city, OUT/g_all; street meshes' own edges):
##  - every walk round the zone is at 2.150 (the streets are flat: max grade 0); the land under the blocks is
##    1.80 .. 2.13 (terrain_grid.npz), so the blocks are FLAT, built at the walk's height
##  - Adela Ave (s_rg_nw_b056): walk outer edges u 490.8 (west) / 509.2 (east); its two alley aprons (the only car
##    openings into either block; legs_measured.json: 54-60 m from the node at v -1400): v -1460 .. -1454, both sides
##  - 3rd St (s_rg_nw_b071 / s_ar_b070_b, arterial couplet, no aprons): north walk edge v -1414.3
##  - 1st St (s_rg_nw_b145_*, bay front, no aprons): south walk edge v -1585.7 (u 372 .. 545.7)
##  - the ring's curve (s_rg_nw_b163_*): its inner walk edge, table RING below (u, v), down to the junction at u 645.7
## No car can enter from 3rd St or the ring without changing those locked street pieces: ambulances, buses and cars
## all come in at Adela's apron, 57 m north of 3rd St.

const PAD_Y := 2.0
const WALK := 0.15          # local height of every walk round the zone (world 2.150)
const ADELA_E := 509.2
const ADELA_W := 490.8
const THIRD := -1414.3
const FIRST := -1585.7
const APRON := [-1460.0, -1454.0]
## the ring's inner walk edge (block A's north / east edge), u -> v
const RING := [[509.2, -1585.7], [545.7, -1585.7], [547.0, -1585.67], [549.0, -1585.52], [551.0, -1585.25], [553.0, -1584.85], [555.0, -1584.30],
	[557.0, -1583.62], [559.0, -1582.78], [561.0, -1581.76], [563.0, -1580.56], [565.0, -1579.21], [615.0, -1544.84], [617.0, -1543.42],
	[619.0, -1541.79], [621.0, -1539.86], [622.63, -1538.0], [624.12, -1536.0], [625.39, -1534.0], [626.46, -1532.0], [627.36, -1530.0],
	[628.09, -1528.0], [628.68, -1526.0], [629.13, -1524.0], [629.49, -1522.0], [629.83, -1520.0], [645.14, -1432.0], [645.44, -1430.0],
	[645.63, -1428.0], [645.70, -1426.0]]
const EAST := 645.7

static func tab(t: Array, x: float) -> float:
	if x <= float(t[0][0]): return float(t[0][1])
	for i in t.size() - 1:
		var a: Array = t[i]; var b: Array = t[i + 1]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6))
	return float(t[t.size() - 1][1])

## block A's north edge at u (the ring's walk); -1414.3 past the junction
static func ring_v(u: float) -> float: return tab(RING, u)
## the ring's walk edge at v (for u near the east side): the u where ring_v(u) = v, by bisection on the monotone part
static func ring_u(v: float) -> float:
	var lo := 565.0; var hi := EAST
	if v >= -1426.0: return EAST
	for _i in 40:
		var m := (lo + hi) * 0.5
		if ring_v(m) < v: lo = m
		else: hi = m
	return (lo + hi) * 0.5

static func flat(_x: float, _z: float) -> float: return WALK
