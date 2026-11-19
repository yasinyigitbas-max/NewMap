extends RefCounted
## High street fill, BLOCK 6 (east of Amber, 9th St to 10th St, Amber to B Ave, round the pilot's b_ne and its hill
## row r_n and the residential quarter r_q_250_m200_sw): the heights its pieces share. Places nothing.
## Frame: the pilot's (pieces at grid [0, 4.0, 0], yaw 0): x = u, z = v (north -v), local y = world - 4.0.
##
## Measured 19 Nov (scratch ground dump OUT/g_b6 of the 39 pieces round the block, 0.25 m raster):
##  - 10th St north walk (s_rs_b121_b): edge v -9.2, WALK10 10.045 (u 146) -> 10.150 (u 229..)
##  - B Ave west walk (s_res_up2_b, j_rs_1l3r_c): edge u 240.8, BAVE 10.15 (v -9 .. -17) RISING north to 11.11 (v -98)
##  - r_n (pilot hill row) back line v -51.2: one level lot per 15 m (RN_SEGS, the same as r_s); its east side u 146 9.870
##  - r_q_250_m200_sw: south edge v -100.0 (RQS_SEGS), west edge u 125.0 (RQW_SEGS): stepped lots, 9.27 .. 11.27
##  - b_ne (pilot downtown block): east edge u 50.0 at 4.285, north edge v -97.5 at 4.150 .. 4.222
##  - Amber east walk (s_am_b043_a): edge u 16.0, AMB rising 4.150 (v -98) -> 6.150 (v -188); 9th St south walk
##    (s_rs_b113_a): edge v -190.3 (u <= 51) / -190.8 (u >= 54.77), N9 6.150 (Amber) -> 9.08 (u 125)
##  - alley mouths (legs_measured.json): 10th St at u 190 .. 196 (north side), B Ave at v -60 .. -54 (west side). None
##    on 9th St or Amber.
## The steepest block of the zone: 7 m from Amber's foot (4.15) to the quarter's top (11.27). One surface, region by
## region (Coons patches through the measured edges, shared edge functions); r_n's and r_q's stepped lot lines met by
## edge strips at their exact heights.

const PAD_Y := 4.0
const WALK10 := [[146.0, 10.045], [153.0, 10.051], [161.0, 10.055], [169.0, 10.064], [177.0, 10.077], [185.0, 10.091], [193.0, 10.106],
	[201.0, 10.120], [209.0, 10.133], [217.0, 10.143], [225.0, 10.149], [229.0, 10.150], [240.8, 10.150]]
## B Ave by v (north is -v)
const BAVE := [[-100.0, 11.147], [-98.0, 11.110], [-92.0, 10.998], [-86.0, 10.888], [-80.0, 10.781], [-74.0, 10.678], [-68.0, 10.580],
	[-62.0, 10.490], [-59.0, 10.447], [-53.0, 10.369], [-47.0, 10.301], [-41.0, 10.244], [-35.0, 10.199], [-29.0, 10.168], [-23.0, 10.153],
	[-17.0, 10.150], [-9.2, 10.150]]
const AMB := [[-190.8, 6.150], [-188.0, 6.150], [-182.0, 6.148], [-176.0, 6.111], [-170.0, 6.022], [-164.0, 5.889], [-158.0, 5.721],
	[-152.0, 5.527], [-146.0, 5.317], [-140.0, 5.100], [-134.0, 4.885], [-128.0, 4.681], [-122.0, 4.499], [-116.0, 4.344], [-110.0, 4.232],
	[-104.0, 4.163], [-98.0, 4.150], [-97.5, 4.150]]
const N9 := [[16.0, 6.150], [25.0, 6.153], [29.0, 6.165], [35.0, 6.206], [41.0, 6.275], [45.0, 6.334], [47.0, 6.368], [49.0, 6.404],
	[51.0, 6.444], [53.0, 6.486], [55.0, 6.529], [57.0, 6.577], [59.0, 6.624], [65.0, 6.784], [71.0, 6.961], [77.0, 7.154], [83.0, 7.362],
	[89.0, 7.583], [95.0, 7.815], [101.0, 8.056], [107.0, 8.305], [113.0, 8.560], [119.0, 8.818], [125.0, 9.076]]
const RN_SEGS := [[50.6, 56.0, 4.382, 4.382], [56.0, 71.0, 4.843, 4.843], [71.0, 86.0, 5.812, 5.812], [86.0, 101.0, 6.979, 6.979],
	[101.0, 116.0, 8.164, 8.164], [116.0, 131.0, 9.188, 9.188], [131.0, 146.0, 9.870, 9.870]]
const RQS_SEGS := [[125.0, 146.75, 9.27, 9.27], [146.75, 168.25, 10.19, 10.19], [168.25, 190.0, 10.95, 10.95], [190.0, 195.25, 10.74, 10.834], [195.25, 204.0, 10.834, 10.834],
	[204.0, 238.6, 11.27, 11.27]]
const RQW_SEGS := [[-190.3, -154.0, 9.36, 9.36], [-154.0, -140.0, 8.805, 8.754], [-140.0, -100.0, 9.27, 9.27]]
## the residents' alley behind r_n (v -60..-54): through the r_n lots' middles, then up the hill top to B Ave
const YLANE := [[50.0, 4.285], [56.0, 4.55], [63.5, 4.84], [78.5, 5.81], [93.5, 6.98], [108.5, 8.16], [123.5, 9.19], [138.5, 9.87],
	[146.0, 9.87], [160.0, 9.95], [190.0, 10.10], [215.0, 10.25], [240.8, 10.42]]
const ALLEY := [-60.0, -54.0]
const L100 := [[50.0, 4.28], [60.0, 4.60], [70.0, 5.25], [80.0, 5.80], [90.0, 6.40], [100.0, 7.35], [110.0, 8.25], [120.0, 8.90],
	[125.0, 9.27], [146.0, 9.27]]
const SRQ := [[146.0, 9.27], [156.0, 10.19], [166.0, 10.19], [170.0, 10.95], [188.0, 10.95], [192.0, 10.76], [204.0, 10.83], [208.0, 11.27],
	[232.0, 11.27], [240.8, 11.147]]
const M146 := [[-100.0, 9.27], [-60.0, 9.87], [-13.0, 9.87], [-9.2, 10.045]]
const W50 := [[-190.8, 6.424], [-190.3, 6.424], [-184.0, 6.15], [-168.0, 5.55], [-152.0, 5.10], [-136.0, 4.75], [-120.0, 4.50], [-104.0, 4.30], [-100.0, 4.28],
	[-97.5, 4.285], [-51.2, 4.285]]
const E125 := [[-190.8, 9.076], [-186.0, 9.36], [-158.0, 9.36], [-148.0, 8.80], [-140.0, 8.754], [-130.0, 9.27], [-100.0, 9.27]]
const BNE_N := [[16.0, 4.15], [41.0, 4.153], [44.0, 4.175], [47.0, 4.222], [50.0, 4.285]]

static func tab(t: Array, x: float) -> float:
	if x <= float(t[0][0]): return float(t[0][1])
	for i in t.size() - 1:
		var a: Array = t[i]; var b: Array = t[i + 1]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6))
	return float(t[t.size() - 1][1])

static func walk10(u: float) -> float: return tab(WALK10, u)
static func bave(v: float) -> float: return tab(BAVE, v)
static func amb(v: float) -> float: return tab(AMB, v)
static func n9(u: float) -> float: return tab(N9, u)
static func north9(u: float) -> float:
	if u <= 51.0: return -190.3
	if u >= 54.77: return -190.8
	return lerpf(-190.3, -190.8, (u - 51.0) / 3.77)

static func ew(u: float) -> float: return smoothstep(226.0, 240.8, u)
static func alley(u: float, v: float) -> float: return tab(YLANE, u) + (bave(v) - bave(-57.0)) * ew(u)

static func coons(u: float, v: float, u0: float, u1: float, v0: float, v1: float, N: Callable, S: Callable, W: Callable, E: Callable) -> float:
	var s := clampf((u - u0) / (u1 - u0), 0.0, 1.0); var t := clampf((v - v0) / (v1 - v0), 0.0, 1.0)
	var uc := lerpf(u0, u1, s); var vc := lerpf(v0, v1, t)
	return (1.0 - t) * float(N.call(uc)) + t * float(S.call(uc)) + (1.0 - s) * float(W.call(vc)) + s * float(E.call(vc)) \
		- ((1.0 - s) * (1.0 - t) * float(N.call(u0)) + s * (1.0 - t) * float(N.call(u1)) + (1.0 - s) * t * float(S.call(u0)) + s * t * float(S.call(u1)))

## the block's ground (world height). In each patch v0 is the north (more negative) edge.
static func g(u: float, v: float) -> float:
	if u >= 146.0 and v > ALLEY[1]:       # R1: the 10th St houses
		return coons(u, v, 146.0, 240.8, ALLEY[1], -9.2, func(x: float) -> float: return alley(x, ALLEY[1]), func(x: float) -> float: return walk10(x),
			func(z: float) -> float: return tab(M146, z), func(z: float) -> float: return bave(z))
	if v >= ALLEY[0] and v <= ALLEY[1] and u >= 50.0:     # the alley
		return alley(u, v)
	if u >= 146.0:                         # R2: the hilltop courts
		return coons(u, v, 146.0, 240.8, -100.0, ALLEY[0], func(x: float) -> float: return tab(SRQ, x), func(x: float) -> float: return alley(x, ALLEY[0]),
			func(z: float) -> float: return tab(M146, z), func(z: float) -> float: return bave(z))
	if u >= 50.0 and v > ALLEY[1]:         # behind r_n, down to the alley
		return tab(YLANE, u)
	if u >= 50.0 and v > -100.0:           # R3: the terraces' south part
		return coons(u, v, 50.0, 146.0, -100.0, ALLEY[0], func(x: float) -> float: return tab(L100, x), func(x: float) -> float: return tab(YLANE, x),
			func(z: float) -> float: return tab(W50, z), func(z: float) -> float: return tab(M146, z))
	if u >= 50.0:                          # R4: up to 9th St (its walk edge at north9(u))
		return coons(u, v, 50.0, 125.0, north9(u), -100.0, func(x: float) -> float: return n9(x), func(x: float) -> float: return tab(L100, x),
			func(z: float) -> float: return tab(W50, z), func(z: float) -> float: return tab(E125, z))
	# R5: Amber's frontage
	return coons(u, v, 16.0, 50.0, -190.3, -97.5, func(x: float) -> float: return n9(x), func(x: float) -> float: return tab(BNE_N, x),
		func(z: float) -> float: return amb(z), func(z: float) -> float: return tab(W50, z))

static func L(fn: Callable) -> Callable:
	return func(x: float, z: float) -> float: return float(fn.call(x, z)) - PAD_Y
static func Lseg(segs: Array) -> Array:
	var out: Array = []
	for s: Array in segs: out.append([s[0], s[1], float(s[2]) - PAD_Y, float(s[3]) - PAD_Y])
	return out
