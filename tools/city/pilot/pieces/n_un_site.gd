extends RefCounted
## University campus (claude/fill-high-street, 19 Nov; Yasin: "make both indoors and outdoors, university itself
## included"): the edges and heights its pieces share. Places nothing.
## Site (ZONING.md MUST site, streets.py SUPERBLOCKS "university campus"): the 2 x 2 cell superblock between nodes
## (-800, -800) and (-400, -400): J Ave (west), the -800 street (north), the -400 street (east), the -400 cross street
## (south); the T junctions at the middle of each side close their stems against the campus.
## Frame: pieces at grid [0, 4.0, 0], yaw 0: x = u, z = v (north -v), local y = world - 4.0.
##
## Measured 19 Nov (scratch ground dump OUT/g_all, 0.5 m raster):
##  - walk outer edges (property lines): u -790.8 (J Ave), u -409.2 (east), v -790.8 (north), v -409.2 (south)
##  - north and east walks: 6.150 all along. J Ave's walk: 6.150 north of v -580, falling to 4.150 at v -420 (table W);
##    the south walk: 4.150 at J Ave rising to 6.150 at u -620 (table S). The campus's SW corner is 2 m below the rest.
##  - aprons (legs_measured.json, 54-60 m from every node, both sides of every leg): on each side of the campus at
##    54-60 m from the corner nodes and from the middle T's: -746 .. -740, -660 .. -654, -546 .. -540, -460 .. -454.
##  - the land under the campus: 3.95 .. 6.31; 6.0 - 6.3 over most of it, falling into the SW corner with the streets.
## The ground follows the land (see g below); every building stands on a level pad at its front's height.

const PAD_Y := 4.0
const LAND := preload("res://tools/city/pilot/pieces/n_un_land.gd")
const LIFT := 0.05
const EASE := 12.0
const TOP := 6.15
const E_W := -790.8
const E_E := -409.2
const E_N := -790.8
const E_S := -409.2
const K_IN := 0.0165
const W := [[-790.8, 6.15], [-580.0, 6.15], [-570.0, 6.126], [-560.0, 6.062], [-550.0, 5.962], [-540.0, 5.834], [-530.0, 5.682], [-520.0, 5.513],
	[-510.0, 5.332], [-500.0, 5.145], [-490.0, 4.959], [-480.0, 4.778], [-470.0, 4.61], [-460.0, 4.459], [-450.0, 4.332], [-440.0, 4.234],
	[-430.0, 4.172], [-420.0, 4.15], [-409.2, 4.15]]
const S := [[-790.8, 4.15], [-780.0, 4.15], [-770.0, 4.174], [-760.0, 4.238], [-750.0, 4.338], [-740.0, 4.466], [-730.0, 4.618], [-720.0, 4.787],
	[-710.0, 4.968], [-700.0, 5.155], [-690.0, 5.341], [-680.0, 5.522], [-670.0, 5.69], [-660.0, 5.841], [-650.0, 5.968], [-640.0, 6.066],
	[-630.0, 6.128], [-620.0, 6.15], [-409.2, 6.15]]

static func tab(t: Array, x: float) -> float:
	if x <= float(t[0][0]): return float(t[0][1])
	for i in t.size() - 1:
		var a: Array = t[i]; var b: Array = t[i + 1]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6))
	return float(t[t.size() - 1][1])

static func smin(a: float, b: float, k := 0.6) -> float:
	var h := clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)

## the campus ground (world height). (19 Nov, Yasin: "Don't forget about the elevation, build according to it") it
## FOLLOWS THE LAND: 5 cm over the land's own surface (n_un_land.gd, the 4 m nodes of terrain_grid.npz, bilinear), and
## within 12 m of each walk eased onto that walk's height (smoothstep), one side after the other (the corners agree).
static func g(u: float, v: float) -> float:
	var y := LAND.at(u, v) + LIFT
	y = lerpf(tab(W, v), y, smoothstep(0.0, EASE, u - E_W))
	y = lerpf(TOP, y, smoothstep(0.0, EASE, E_E - u))
	y = lerpf(TOP, y, smoothstep(0.0, EASE, v - E_N))
	y = lerpf(tab(S, u), y, smoothstep(0.0, EASE, E_S - v))
	return y

## distance to the nearest of the campus's four walks (graded aprons ease back onto the ground before it)
static func edge_d(u: float, v: float) -> float: return minf(minf(u - E_W, E_E - u), minf(v - E_N, E_S - v))

## local height (piece frame)
static func y(u: float, v: float) -> float: return g(u, v) - PAD_Y
