extends RefCounted
## High street fill, BLOCK 4 (east of Amber, 11th St to the ring's Ocean Blvd, Amber to B Ave): the heights its pieces
## share (n_hs_b4_amber, n_hs_b4_eleventh, n_hs_b4_cottages, n_hs_b4_ocean). Places nothing.
## Frame: the pilot's (pieces at grid [0, 4.0, 0], yaw 0): x = u, z = v (south +v toward the beach), local y = -4.0.
##
## Measured 19 Nov (scratch ground dump OUT/g_b4 of the 34 pieces round the block, vertices):
##  - 11th St walk (s_rs_b129_a / _b, j_am_11th, j_rs_2l2r_opp_a): edge v 209.70 (u <= 51.0) / 209.20 (u >= 54.77),
##    height N11 rising 4.150 (Amber) -> 6.150 (u 230)
##  - Amber walk (s_rg_b045): edge u 16.0, height AMBER falling 4.150 (v 217) -> 2.150 (v 313)
##  - B Ave walk (s_rg_se_b055, the stub to the ring): edge u 240.8, height BAVE falling 6.150 (v 220) -> 4.150 (v 319)
##  - Ocean Blvd (the ring, s_rg_se_b135_1 / _2, s_rg_se_b161_1): edge v = 326.10 + 0.02 (u - 20.22), height RING
##    rising 2.150 -> 4.150 eastward
##  - alley mouths: 11th St at u 190 .. 196 (south side), B Ave at v 254 .. 260 (west side). Amber and the ring: none.
## The land under the block (terrain_grid.npz) is 2.0 .. 6.1: high in the north-east, low in the south-west.
## Every edge meets a street: the ground is ONE smooth surface through the four profiles (G).

const PAD_Y := 4.0
const N11 := [[16.0, 4.150], [23.5, 4.150], [27.46, 4.152], [31.42, 4.159], [36.41, 4.172], [39.91, 4.186], [43.40, 4.202], [46.14, 4.217],
	[50.26, 4.242], [54.89, 4.275], [58.79, 4.305], [62.68, 4.339], [66.58, 4.375], [70.47, 4.413], [74.37, 4.454], [78.26, 4.497],
	[82.16, 4.542], [86.05, 4.589], [93.84, 4.688], [97.74, 4.740], [101.63, 4.792], [105.53, 4.846], [109.42, 4.901], [113.32, 4.956],
	[117.21, 5.012], [121.11, 5.068], [125.00, 5.125], [128.89, 5.181], [132.78, 5.237], [136.67, 5.294], [140.56, 5.349], [144.44, 5.405],
	[148.33, 5.459], [152.22, 5.513], [156.11, 5.565], [160.00, 5.616], [163.89, 5.666], [167.78, 5.715], [171.67, 5.761], [175.56, 5.806],
	[179.44, 5.849], [183.33, 5.890], [187.22, 5.928], [191.11, 5.964], [195.00, 5.997], [198.89, 6.027], [202.78, 6.055], [206.67, 6.079],
	[210.56, 6.100], [214.44, 6.118], [218.33, 6.132], [222.22, 6.142], [230.00, 6.150], [240.8, 6.150]]
const RING := [[16.0, 2.150], [26.22, 2.150], [32.78, 2.155], [38.78, 2.169], [44.78, 2.193], [50.78, 2.224], [56.77, 2.264], [63.19, 2.314],
	[69.48, 2.370], [75.19, 2.427], [81.19, 2.492], [87.19, 2.562], [92.63, 2.628], [99.18, 2.713], [105.18, 2.793], [110.29, 2.864],
	[116.29, 2.948], [122.29, 3.034], [128.29, 3.121], [134.28, 3.208], [140.28, 3.294], [146.28, 3.380], [153.17, 3.476], [159.17, 3.558],
	[165.17, 3.636], [171.05, 3.710], [177.17, 3.783], [183.17, 3.850], [189.98, 3.919], [195.17, 3.967], [200.80, 4.014], [206.79, 4.057],
	[212.29, 4.090], [218.79, 4.120], [224.79, 4.139], [230.79, 4.149], [240.8, 4.150]]
const AMBER := [[209.2, 4.150], [217.5, 4.150], [223.2, 4.130], [229.6, 4.062], [234.2, 3.987], [244.8, 3.754], [248.5, 3.654], [252.2, 3.548],
	[258.2, 3.368], [262.8, 3.228], [266.5, 3.111], [272.5, 2.924], [276.2, 2.810], [280.8, 2.680], [286.8, 2.520], [291.8, 2.403],
	[298.8, 2.270], [306.6, 2.176], [313.0, 2.150], [332.0, 2.150]]
const BAVE := [[209.2, 6.150], [220.0, 6.150], [224.0, 6.141], [227.9, 6.114], [231.9, 6.071], [235.8, 6.013], [239.8, 5.942], [243.7, 5.860],
	[247.7, 5.767], [251.7, 5.667], [255.6, 5.559], [259.6, 5.446], [263.5, 5.329], [267.5, 5.210], [271.5, 5.090], [275.4, 4.971],
	[279.4, 4.854], [283.3, 4.741], [287.3, 4.633], [291.2, 4.533], [295.2, 4.440], [299.2, 4.358], [303.1, 4.287], [307.1, 4.229],
	[311.0, 4.186], [315.0, 4.159], [318.9, 4.150], [332.0, 4.150]]
const WEST_U := 16.0
const EAST_U := 240.8

static func _lerp_tab(tab: Array, x: float) -> float:
	if x <= float(tab[0][0]): return float(tab[0][1])
	for i in tab.size() - 1:
		var a: Array = tab[i]; var b: Array = tab[i + 1]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6))
	return float(tab[tab.size() - 1][1])

static func n11(u: float) -> float: return _lerp_tab(N11, u)
static func ring(u: float) -> float: return _lerp_tab(RING, u)
static func amber(v: float) -> float: return _lerp_tab(AMBER, v)
static func bave(v: float) -> float: return _lerp_tab(BAVE, v)

static func north(u: float) -> float:
	if u <= 51.0: return 209.7
	if u >= 54.77: return 209.2
	return lerpf(209.7, 209.2, (u - 51.0) / 3.77)
static func south(u: float) -> float: return 326.10 + 0.02 * (u - 20.22)

## the block's ground: between the ring's profile (south) and 11th St's (north), with the fall of Amber on the west and
## of B Ave on the east blended across: equal to each street at its edge
static func g(u: float, v: float) -> float:
	var s := ring(u); var n := n11(u)
	var tw := (amber(v) - 2.15) / 2.0; var te := (bave(v) - 4.15) / 2.0
	var t := lerpf(tw, te, clampf((u - WEST_U) / (EAST_U - WEST_U), 0.0, 1.0))
	return s + (n - s) * t

static func L(fn: Callable) -> Callable:
	return func(x: float, z: float) -> float: return float(fn.call(x, z)) - PAD_Y
