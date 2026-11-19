extends RefCounted
## High street fill, BLOCK 1 (west of Amber, 10th to 11th St, around the pilot's pocket-park block b_sw): the heights
## its three pieces share, so every line where two of them meet has ONE height (n_hs_b1_amber, n_hs_b1_tenth,
## n_hs_b1_eleventh). Not a recipe: it places nothing, it only answers "how high is the ground here" for this block.
## Frame: the pilot's (pieces placed at grid [0, 4.0, 0], yaw 0): x = u, z = v, local y = world y - 4.0.
##
## Measured 19 Nov from the ground of the pieces round the block (scratch ground dump OUT/g_b1, 0.25 m raster):
##  - Amber walk (s_am_fill_hs, s_am_b044_b, j_am_11th) at u -16: 4.150 all along v 97.5..190.3
##  - 10th St walk (s_rs_b120_a, s_10th_w): 4.150; its edge v 9.20 (u <= -71.5) curving to 9.70 (u >= -60.5)
##  - b_sw (pilot, locked): 4.150 along its west edge u -50 (v 9.7..97.5) and its south edge v 97.5 (u -50..-16)
##  - 11th St walk (s_rs_b128_b, j_am_11th): edge v 190.80 for u <= -54.77, 190.30 for u >= -51.0 (a diagonal
##    between); height F11 below (3.195 at u -99.5 rising to 4.150 at u -23.5)
##  - the residential growth quadrants r_q_m200_0_se (v < 100) and r_q_m200_200_ne (v > 100) end at u -100.0. Their
##    edge carries faces whose top is the line WEST below; their two rear alleys (asphalt) meet our edge at
##    v 54..60 and v 140..146: we carry both alleys on through the block (alleys run through, as the pilot's do).
## The land under the block (zoning/terrain_grid.npz) is 3.0..4.1: high by Amber, falling west and south-west.

const T := 4.15                    # the walk / pad height of the pilot and Amber (world)
const PAD_Y := 4.0                 # the pieces' layout row height
const BANK := 17.0                 # west bank: from the residential edge up to the high street level over 17 m (<= 8 %)

## top of the residential quadrants' edge at u -100 (world heights), knots [v, y]; straight lines between
const WEST := [[9.2, 4.15], [46.0, 4.15], [54.0, 4.038], [56.6, 4.021], [57.4, 4.016], [60.0, 3.999], [64.0, 3.971],
	[68.0, 3.941], [72.0, 3.910], [76.0, 3.878], [80.0, 3.844], [84.0, 3.810], [88.0, 3.775], [92.0, 3.739], [96.0, 3.703],
	[100.0, 3.667], [104.0, 3.631], [108.0, 3.595], [112.0, 3.559], [116.0, 3.524], [120.0, 3.489], [124.0, 3.455],
	[128.0, 3.423], [132.0, 3.392], [136.0, 3.363], [140.0, 3.335], [142.6, 3.317], [143.4, 3.312], [146.0, 3.296],
	[154.0, 3.296], [163.68, 3.212], [167.56, 3.200], [173.37, 3.188], [179.18, 3.184], [190.8, 3.183]]

## the residential quadrants' own ground just outside our edge (u -100.15): lower than WEST where they stand on a
## lower terrace behind their edge face. Our skirt reaches 0.3 m under the lower of the two.
const WEST_LOW := [[9.2, 4.15], [44.0, 4.15], [46.0, 4.038], [54.0, 4.038], [60.0, 3.999], [98.0, 3.68], [99.9, 3.667],
	[100.1, 3.17], [139.9, 3.17], [140.0, 3.335], [146.0, 3.296], [152.0, 3.262], [153.9, 3.29], [154.1, 3.06], [190.8, 3.06]]

## 11th St walk at its edge, per metre of u (measured at u + 0.5), world heights
const F11 := [[-100.0, 3.186], [-99.5, 3.195], [-97.5, 3.234], [-95.5, 3.272], [-93.5, 3.310], [-91.5, 3.348], [-89.5, 3.385],
	[-87.5, 3.422], [-85.5, 3.459], [-83.5, 3.496], [-81.5, 3.532], [-79.5, 3.567], [-77.5, 3.602], [-75.5, 3.636],
	[-73.5, 3.670], [-71.5, 3.703], [-69.5, 3.735], [-67.5, 3.766], [-65.5, 3.797], [-63.5, 3.826], [-61.5, 3.855],
	[-59.5, 3.883], [-57.5, 3.909], [-55.5, 3.935], [-53.5, 3.959], [-51.5, 3.982], [-49.5, 4.004], [-47.5, 4.025],
	[-45.5, 4.044], [-43.5, 4.061], [-41.5, 4.077], [-39.5, 4.092], [-37.5, 4.105], [-35.5, 4.117], [-33.5, 4.127],
	[-31.5, 4.135], [-29.5, 4.142], [-27.5, 4.146], [-25.5, 4.149], [-23.5, 4.150], [-16.0, 4.150]]

static func _lerp_tab(tab: Array, x: float) -> float:
	if x <= float(tab[0][0]): return float(tab[0][1])
	for i in tab.size() - 1:
		var a: Array = tab[i]; var b: Array = tab[i + 1]
		if x <= float(b[0]):
			var t := (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6)
			return lerpf(float(a[1]), float(b[1]), t)
	return float(tab[tab.size() - 1][1])

## world heights
static func west(v: float) -> float: return _lerp_tab(WEST, v)
static func f11(u: float) -> float: return _lerp_tab(F11, u)
static func west_skirt_bot(v: float) -> float: return minf(west(v), _lerp_tab(WEST_LOW, v)) - 0.3 - PAD_Y

## the 11th St property line (v of the block's south edge) at u
static func edge11(u: float) -> float:
	if u <= -54.77: return 190.8
	if u >= -51.0: return 190.3
	return lerpf(190.8, 190.3, (u + 54.77) / 3.77)

## the 10th St property line (v of the block's north edge) at u (u <= -50)
static func edge10(u: float) -> float:
	if u <= -71.5: return 9.2
	if u >= -60.5: return 9.7
	var t := (u + 71.5) / 11.0
	return lerpf(9.2, 9.7, t * t * (3.0 - 2.0 * t))

## G: the west part's ground (u -100..-50, v <= 140): the residential edge line at u -100, rising over BANK metres
## (smoothstep: no crease) to the high street level, level from there to the alley. The parking, the garage pad and
## the north alley stand on its level part; the bank is lawn and planting.
static func g_west(u: float, v: float) -> float:
	var w := west(v)
	var t := clampf((u + 100.0) / BANK, 0.0, 1.0)
	return w + (T - w) * t * t * (3.0 - 2.0 * t)

## C: the 10th St court (v < 54): the edge line, up to the high street level within 2 m (the drop there is <= 11 cm)
static func g_court(u: float, v: float) -> float:
	var w := west(v)
	var t := clampf((u + 100.0) / 2.0, 0.0, 1.0)
	return w + (T - w) * t * t * (3.0 - 2.0 * t)

## A: the cross alley (v 140..146): straight from the residential alley at u -100 to the pilot's alley level at u -50
static func g_alley_s(u: float, v: float) -> float:
	var w := west(v)
	return w + (T - w) * clampf((u + 100.0) / 50.0, 0.0, 1.0)

## Y: the corner service yard behind the 11th St corner (u -54.8..-32, v 146..190.8): level with the alley, easing
## over its last 14 m to the 11th St walk at the property line
static func g_yard(u: float, v: float) -> float:
	var t := clampf((v - 176.0) / (edge11(u) - 176.0), 0.0, 1.0)
	return T + (f11(u) - T) * t * t * (3.0 - 2.0 * t)

## local heights (piece frame) of the above, as Callables for kit_lib's Ground
static func L(fn: Callable) -> Callable:
	return func(x: float, z: float) -> float: return float(fn.call(x, z)) - PAD_Y
