extends RefCounted
## High street fill, BLOCK 5 (east of Amber, 10th St to 11th St, Amber to B Ave, round the pilot's b_se and its hill
## row r_s and the residential quarter r_q_250_200_nw): the heights its pieces share. Places nothing.
## Frame: the pilot's (pieces at grid [0, 4.0, 0], yaw 0): x = u, z = v (south +v), local y = world - 4.0.
##
## Measured 19 Nov (scratch ground dump OUT/g_b5 of the 35 pieces round the block, 0.25 m raster):
##  - 10th St south walk (s_rs_b121_b): edge v 9.2, WALK10 10.045 (u 146) -> 10.150 (u 229..)
##  - B Ave west walk (s_res_dn4_b, j_rs_1l3r_c): edge u 240.8, BAVE 10.15 (v 9..22) falling to 8.24 (v 97)
##  - r_s (pilot hill row) back line v 51.2: one level lot per 15 m (RS_SEGS); its east side u 146 at 9.870
##  - r_q_250_200_nw (residential quarter): north edge v 100.0 (RQN_SEGS), west edge u 125.0 (RQW_SEGS): stepped lots
##  - b_se (pilot downtown block): east edge u 50.0 at 4.285, south edge v 97.5 at 4.150 .. 4.222
##  - Amber east walk (s_am_b044_b): edge u 16.0 at 4.150; 11th St north walk (s_rs_b129_a): edge v 190.3 (u <= 51) /
##    190.8 (u >= 54.77), N11 4.150 (Amber) -> 5.125 (u 125)
##  - alley mouths (legs_measured.json): 10th St at u 190 .. 196 (south side), B Ave at v 54 .. 60 (west side). None on
##    11th St or Amber.
## The ground is one surface, region by region (Coons patches through the measured edges; neighbouring regions share
## the same edge functions, so they meet exactly). The stepped edges of r_s and r_q are met by edge strips at their
## exact lot heights (hs_fill_lib.edge_strip), their faces 2 m inside my pieces.

const PAD_Y := 4.0
const WALK10 := [[146.0, 10.045], [153.0, 10.051], [161.0, 10.055], [169.0, 10.064], [177.0, 10.077], [185.0, 10.091], [193.0, 10.106],
	[201.0, 10.120], [209.0, 10.133], [217.0, 10.143], [225.0, 10.149], [229.0, 10.150], [240.8, 10.150]]
const BAVE := [[9.2, 10.15], [22.0, 10.15], [25.0, 10.13], [28.0, 10.12], [31.0, 10.09], [34.0, 10.06], [37.0, 10.02], [40.0, 9.97],
	[43.0, 9.92], [46.0, 9.86], [49.0, 9.79], [52.0, 9.72], [55.0, 9.65], [58.0, 9.57], [61.0, 9.48], [64.0, 9.39], [67.0, 9.30],
	[70.0, 9.21], [73.0, 9.11], [76.0, 9.01], [79.0, 8.90], [82.0, 8.80], [85.0, 8.69], [88.0, 8.58], [91.0, 8.47], [94.0, 8.36],
	[97.0, 8.24], [100.0, 8.12]]
const N11 := [[16.0, 4.150], [23.5, 4.150], [27.46, 4.152], [31.42, 4.159], [36.41, 4.172], [39.91, 4.186], [43.40, 4.202], [46.14, 4.217],
	[50.26, 4.242], [54.89, 4.275], [58.79, 4.305], [62.68, 4.339], [66.58, 4.375], [70.47, 4.413], [74.37, 4.454], [78.26, 4.497],
	[82.16, 4.542], [86.05, 4.589], [93.84, 4.688], [97.74, 4.740], [101.63, 4.792], [105.53, 4.846], [109.42, 4.901], [113.32, 4.956],
	[117.21, 5.012], [121.11, 5.068], [125.0, 5.125]]
## [u0, u1, h0, h1] (linear within a segment)
const RS_SEGS := [[50.0, 56.0, 4.382, 4.382], [56.0, 71.0, 4.843, 4.843], [71.0, 86.0, 5.812, 5.812], [86.0, 101.0, 6.979, 6.979],
	[101.0, 116.0, 8.164, 8.164], [116.0, 131.0, 9.188, 9.188], [131.0, 146.0, 9.870, 9.870]]
const RQN_SEGS := [[146.0, 146.75, 5.98, 5.98], [146.75, 168.25, 6.28, 6.28], [168.25, 190.0, 6.51, 6.51], [190.0, 204.0, 8.023, 8.048],
	[204.0, 240.8, 7.90, 7.90]]
const RQW_SEGS := [[100.0, 140.0, 5.98, 5.98], [140.0, 145.5, 5.772, 5.62], [145.5, 154.0, 5.61, 5.61], [154.0, 190.3, 5.22, 5.22]]
## the residents' alley behind r_s (v 54..60): through the r_s lots' middles, then along the hill top to B Ave
const YLANE := [[50.0, 4.285], [56.0, 4.55], [63.5, 4.84], [78.5, 5.81], [93.5, 6.98], [108.5, 8.16], [123.5, 9.19], [138.5, 9.87],
	[146.0, 9.87], [160.0, 9.90], [190.0, 9.85], [215.0, 9.75], [240.8, 9.59]]
const ALLEY := [54.0, 60.0]
const L100 := [[50.0, 4.27], [70.0, 4.75], [90.0, 5.40], [105.0, 5.90], [125.0, 5.98], [146.0, 6.13]]
const SRQ := [[146.0, 6.13], [150.0, 6.28], [166.0, 6.28], [170.0, 6.51], [188.0, 6.51], [194.0, 8.03], [204.0, 8.05], [206.0, 7.90],
	[232.0, 7.90], [240.8, 8.12]]
const M146 := [[9.2, 10.045], [13.0, 9.87], [60.0, 9.87], [100.0, 6.13]]
const W50 := [[51.2, 4.285], [60.0, 4.285], [97.5, 4.285], [100.0, 4.27], [190.8, 4.242]]
const E125 := [[100.0, 5.98], [140.0, 5.98], [140.5, 5.77], [145.5, 5.62], [154.0, 5.61], [175.0, 5.22], [190.8, 5.125]]     # (r_q's 0.39 m step at v 154 eased over 21 m; the edge strip meets it exactly)
const BSE_S := [[16.0, 4.15], [41.0, 4.153], [44.0, 4.175], [47.0, 4.222], [50.0, 4.27]]

static func tab(t: Array, x: float) -> float:
	if x <= float(t[0][0]): return float(t[0][1])
	for i in t.size() - 1:
		var a: Array = t[i]; var b: Array = t[i + 1]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6))
	return float(t[t.size() - 1][1])

static func walk10(u: float) -> float: return tab(WALK10, u)
static func bave(v: float) -> float: return tab(BAVE, v)
static func n11(u: float) -> float: return tab(N11, u)
static func north11(u: float) -> float:
	if u <= 51.0: return 190.3
	if u >= 54.77: return 190.8
	return lerpf(190.3, 190.8, (u - 51.0) / 3.77)

## the alley's surface: YLANE, meeting B Ave's falling walk across its mouth
static func ew(u: float) -> float: return smoothstep(226.0, 240.8, u)
static func alley(u: float, v: float) -> float: return tab(YLANE, u) + (bave(v) - bave(57.0)) * ew(u)

static func coons(u: float, v: float, u0: float, u1: float, v0: float, v1: float, N: Callable, S: Callable, W: Callable, E: Callable) -> float:
	var s := clampf((u - u0) / (u1 - u0), 0.0, 1.0); var t := clampf((v - v0) / (v1 - v0), 0.0, 1.0)
	var uc := lerpf(u0, u1, s); var vc := lerpf(v0, v1, t)
	return (1.0 - t) * float(N.call(uc)) + t * float(S.call(uc)) + (1.0 - s) * float(W.call(vc)) + s * float(E.call(vc)) \
		- ((1.0 - s) * (1.0 - t) * float(N.call(u0)) + s * (1.0 - t) * float(N.call(u1)) + (1.0 - s) * t * float(S.call(u0)) + s * t * float(S.call(u1)))

## the block's ground (world height)
static func g(u: float, v: float) -> float:
	if u >= 146.0 and v < ALLEY[0]:       # R1: the 10th St houses
		return coons(u, v, 146.0, 240.8, 9.2, ALLEY[0], func(x: float) -> float: return walk10(x), func(x: float) -> float: return alley(x, ALLEY[0]),
			func(z: float) -> float: return tab(M146, z), func(z: float) -> float: return bave(z))
	if v <= ALLEY[1] and u >= 50.0 and v >= ALLEY[0]:     # the alley
		return alley(u, v)
	if u >= 146.0:                         # R2: the school
		return coons(u, v, 146.0, 240.8, ALLEY[1], 100.0, func(x: float) -> float: return alley(x, ALLEY[1]), func(x: float) -> float: return tab(SRQ, x),
			func(z: float) -> float: return tab(M146, z), func(z: float) -> float: return bave(z))
	if u >= 50.0 and v < ALLEY[0]:         # behind r_s, up to the alley
		return tab(YLANE, u)
	if u >= 50.0 and v < 100.0:            # R3: the hillside
		return coons(u, v, 50.0, 146.0, ALLEY[1], 100.0, func(x: float) -> float: return tab(YLANE, x), func(x: float) -> float: return tab(L100, x),
			func(z: float) -> float: return tab(W50, z), func(z: float) -> float: return tab(M146, z))
	if u >= 50.0:                          # R4: down to 11th St
		return coons(u, v, 50.0, 125.0, 100.0, 190.8, func(x: float) -> float: return tab(L100, x), func(x: float) -> float: return n11(x),
			func(z: float) -> float: return tab(W50, z), func(z: float) -> float: return tab(E125, z))
	# R5: Amber's frontage
	return coons(u, v, 16.0, 50.0, 97.5, 190.8, func(x: float) -> float: return tab(BSE_S, x), func(x: float) -> float: return n11(x),
		func(_z: float) -> float: return 4.15, func(z: float) -> float: return tab(W50, maxf(z, 100.0)))

static func L(fn: Callable) -> Callable:
	return func(x: float, z: float) -> float: return float(fn.call(x, z)) - PAD_Y
static func Lseg(segs: Array) -> Array:
	var out: Array = []
	for s: Array in segs: out.append([s[0], s[1], float(s[2]) - PAD_Y, float(s[3]) - PAD_Y])
	return out
