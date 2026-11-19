extends RefCounted
## High street fill, BLOCK 3 (south of 11th St to the ring's Ocean Blvd, C Ave to Amber): the heights its pieces share
## (n_hs_b3_amber, n_hs_b3_cottages, n_hs_b3_dingbats, n_hs_b3_motel). Places nothing.
## Frame: the pilot's (pieces at grid [0, 4.0, 0], yaw 0): x = u, z = v (south is +v, toward the beach), y local = -4.0.
##
## Measured 19 Nov (scratch ground dump OUT/g_b3 of the 45 pieces round the block, 0.25 m raster and vertices):
##  - 11th St walk (s_rs_b128_a / _b, j_am_11th): edge v 209.20 (u <= -54.77) / 209.70 (u >= -51.0), height F11 rising
##    from 2.150 at C Ave to 4.150 by Amber (u -22)
##  - Amber walk (s_rg_b045, the stub to the ring): edge u -16.0, height AMBER falling from 4.150 (v 216) to 2.150
##    (v 313) toward the beach
##  - C Ave walk (s_rg_se_b035): edge u -190.80, 2.150 all along; its alley apron opens at v 254 .. 260
##  - Ocean Blvd (the ring, s_rg_se_b134_1 / _2 and its junctions): edge the line v = 314.47 + 0.05999 (u + 186.74)
##    (314.2 at C Ave, 324.7 at Amber), 2.150 all along
##  - 11th St's alley apron (south side) at u -146 .. -140. No other driveway or alley mouth on the four streets.
## The land under the block (terrain_grid.npz) is 2.0 .. 4.1: high only in the corner by Amber x 11th.
## Every edge of the block meets a street: the ground is ONE smooth surface through all four edge profiles (G).

const PAD_Y := 4.0
const LOW := 2.15

const F11 := [[-190.8, 2.150], [-179.25, 2.151], [-178.0, 2.152], [-174.0, 2.160], [-170.0, 2.175], [-166.0, 2.197], [-162.0, 2.225],
	[-158.0, 2.259], [-154.0, 2.299], [-150.0, 2.344], [-146.0, 2.394], [-142.0, 2.449], [-138.0, 2.507], [-134.0, 2.569],
	[-130.0, 2.634], [-126.0, 2.702], [-122.0, 2.773], [-118.0, 2.845], [-114.0, 2.920], [-110.0, 2.995], [-106.0, 3.071],
	[-102.0, 3.148], [-98.0, 3.224], [-94.0, 3.300], [-90.0, 3.376], [-86.0, 3.450], [-82.0, 3.523], [-78.0, 3.593],
	[-74.0, 3.662], [-70.0, 3.727], [-66.0, 3.789], [-62.0, 3.848], [-58.0, 3.903], [-54.0, 3.953], [-50.0, 3.999],
	[-46.0, 4.039], [-42.0, 4.073], [-38.0, 4.102], [-34.0, 4.124], [-30.0, 4.140], [-26.0, 4.148], [-22.0, 4.150], [-16.0, 4.150]]
const AMBER := [[209.2, 4.150], [216.1, 4.150], [220.0, 4.146], [227.7, 4.087], [235.4, 3.966], [243.1, 3.797], [250.8, 3.591],
	[255.8, 3.444], [262.8, 3.228], [267.8, 3.071], [274.8, 2.855], [279.8, 2.708], [286.8, 2.520], [291.8, 2.403], [298.8, 2.270],
	[303.4, 2.206], [309.8, 2.157], [313.2, 2.150], [325.0, 2.150]]

static func _lerp_tab(tab: Array, x: float) -> float:
	if x <= float(tab[0][0]): return float(tab[0][1])
	for i in tab.size() - 1:
		var a: Array = tab[i]; var b: Array = tab[i + 1]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6))
	return float(tab[tab.size() - 1][1])

static func f11(u: float) -> float: return _lerp_tab(F11, u)
static func amber(v: float) -> float: return _lerp_tab(AMBER, v)

## edges
static func north(u: float) -> float:
	if u <= -54.77: return 209.2
	if u >= -51.0: return 209.7
	return lerpf(209.2, 209.7, (u + 54.77) / 3.77)
static func south(u: float) -> float: return 314.47 + 0.05999 * (u + 186.74)
const WEST_U := -190.8
const EAST_U := -16.0

## the block's ground: the four street profiles joined by one smooth surface (the 11th St rise times Amber's fall:
## equal to 11th St along the north edge, to Amber along the east, 2.15 along C Ave and Ocean Blvd)
static func g(u: float, v: float) -> float:
	return LOW + (f11(u) - LOW) * (amber(v) - LOW) / (4.15 - LOW)

static func L(fn: Callable) -> Callable:
	return func(x: float, z: float) -> float: return float(fn.call(x, z)) - PAD_Y
