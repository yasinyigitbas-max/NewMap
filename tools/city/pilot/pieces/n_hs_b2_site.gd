extends RefCounted
## High street fill, BLOCK 2 (west of Amber, 9th to 10th St, around the pilot's block b_nw): the heights its four pieces
## share (n_hs_b2_amber, n_hs_b2_park, n_hs_b2_mews, n_hs_b2_ninth). Places nothing; it only answers "how high is the
## ground here" for this block, so every line where two of its pieces meet has ONE height.
## Frame: the pilot's (pieces at grid [0, 4.0, 0], yaw 0): x = u, z = v (north is -v), local y = world y - 4.0.
##
## Measured 19 Nov (scratch ground dump OUT/g_b2 of the 38 pieces round the block):
##  - Amber walk at u -16 (s_am_b043_a, s_am_fill_hs, j_am_9th): 4.150 at v -100 .. -97.5, rising smoothly to 6.150 at
##    v -182.5 (table AMBER; steepest 3.5 % at v -150), 6.150 on to 9th St.
##  - 9th St walk (s_rs_b112_b, j_am_9th): 6.150, flat; its edge v -190.80 for u <= -54.77, -190.30 for u >= -51.0
##  - 10th St walk (s_rs_b120_a, s_10th_w): 4.150; its edge v -9.20 (u <= -71.5) curving to -9.70 (u >= -60.5)
##  - b_nw (pilot, locked): 4.150 along u -50 (v -97.5 .. -9.7) and along v -97.5 (u -50 .. -16)
##  - the residential quadrants r_q_m200_0_ne (v > -100) and r_q_m200_m200_se (v < -100) end at u -100.0. WEST = the top
##    of their edge (their faces reach up to it); WEST_LOW = their ground just outside. Their rear alleys (asphalt)
##    meet our edge at v -60 .. -54 and v -146 .. -140: both carried on through the block.
## The land under the block (zoning/terrain_grid.npz) is 4.1 .. 6.1: low by 10th St, high by 9th St.

const T := 4.15
const PAD_Y := 4.0

const WEST := [[-190.80, 6.150], [-154.00, 6.150], [-152.00, 5.760], [-150.00, 5.714], [-148.00, 5.668], [-146.00, 5.620],
	[-143.40, 5.556], [-142.60, 5.536], [-140.00, 5.471], [-136.00, 5.370], [-132.00, 5.269], [-128.00, 5.169], [-124.00, 5.073],
	[-120.00, 4.981], [-116.00, 4.896], [-112.00, 4.819], [-108.00, 4.751], [-104.00, 4.694], [-100.00, 4.650], [-96.00, 4.613],
	[-92.00, 4.575], [-88.00, 4.538], [-84.00, 4.502], [-80.00, 4.466], [-76.00, 4.432], [-72.00, 4.398], [-68.00, 4.366],
	[-66.00, 4.350], [-64.00, 4.340], [-60.00, 4.340], [-57.40, 4.288], [-56.60, 4.283], [-54.00, 4.266], [-46.00, 4.266],
	[-44.06, 4.211], [-42.13, 4.202], [-40.19, 4.194], [-38.25, 4.186], [-36.32, 4.179], [-34.38, 4.173], [-32.44, 4.167],
	[-30.51, 4.162], [-28.57, 4.158], [-27.60, 4.150], [-9.20, 4.150]]
const WEST_LOW := [[-190.8, 6.15], [-154.1, 6.15], [-153.9, 5.62], [-146.0, 5.62], [-140.0, 5.471], [-101.0, 4.66], [-100.1, 4.66],
	[-99.9, 4.34], [-60.0, 4.34], [-54.0, 4.27], [-46.0, 4.27], [-45.0, 4.15], [-9.2, 4.15]]
const AMBER := [[-190.3, 6.150], [-182.5, 6.150], [-178.6, 6.137], [-174.6, 6.099], [-170.7, 6.039], [-166.8, 5.960], [-162.9, 5.864],
	[-158.9, 5.753], [-155.0, 5.631], [-151.1, 5.500], [-147.1, 5.363], [-143.2, 5.221], [-139.3, 5.079], [-135.4, 4.937],
	[-131.4, 4.800], [-127.5, 4.669], [-123.6, 4.547], [-119.6, 4.436], [-115.7, 4.340], [-111.8, 4.261], [-107.9, 4.201],
	[-103.9, 4.163], [-100.0, 4.150], [-9.2, 4.150]]

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
static func amber(v: float) -> float: return _lerp_tab(AMBER, v)
static func west_skirt_bot(v: float) -> float: return minf(west(v), _lerp_tab(WEST_LOW, v)) - 0.3 - PAD_Y

## 9th St property line (the block's north edge, v) at u; 10th St's (south edge)
static func edge9(u: float) -> float:
	if u <= -54.77: return -190.8
	if u >= -51.0: return -190.3
	return lerpf(-190.8, -190.3, (u + 54.77) / 3.77)
static func edge10(u: float) -> float:
	if u <= -71.5: return -9.2
	if u >= -60.5: return -9.7
	var t := (u + 71.5) / 11.0
	return lerpf(-9.2, -9.7, t * t * (3.0 - 2.0 * t))

## The block's ground: Amber's street profile across the whole high street part (u >= -50, flat across, rising
## north with the street), and from there a smooth 50 m blend west to the residential edge line (<= 2 %).
static func g(u: float, v: float) -> float:
	var a := amber(v)
	if u >= -50.0: return a
	var w := west(v)
	var t := clampf((u + 100.0) / 50.0, 0.0, 1.0)
	return w + (a - w) * t * t * (3.0 - 2.0 * t)

static func L(fn: Callable) -> Callable:
	return func(x: float, z: float) -> float: return float(fn.call(x, z)) - PAD_Y
