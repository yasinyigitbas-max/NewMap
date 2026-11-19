extends RefCounted
## BLOCK 2 land (apartment fill, B Ave - Adela, 7th - 6th St; claude/fill-apartments, 19 Nov). Data, not a recipe:
## the street heights MEASURED on the built pieces round the block (OUT/apt/probe_lines.py on a ground dump of the area,
## 2 m apart, 1 cm; the B Ave walk just outside the block at x 258.9, the 6th St walk at z -408.9), and the block's base
## surface made from them. Frame: the block-2 pieces' own (layout pos [250, 6, -600], sx = +1, sz = +1: u = x, v = z,
## local y = world - 6).
##   B Ave (west edge): level 6.15 m to v 100 (the sample a_se), rising 2.00 m to 8.15 at v 178.7 (s_rs_b051_b), level to
##     6th St.  6th St (south edge, v 190.8): 8.15 m to u 25, falling 2.00 m to 6.15 at u 225 (s_rs_b106_a / _b).
##     Adela (east edge) and 7th St (north edge) and a_se's ground: 6.15 m.
## surface(u, v) = 0.15 + 2 * f(v) * g(u), with f = the B Ave rise (0..1) and g = the 6th St fall (1..0): it equals every
## measured edge exactly (west: g = 1; south: f = 1; north, east, a_se: f = 0 or g = 0) and is a smooth corner hill
## between, steepest about 3.5 % (the B Ave profile's own).
const BAVE := [[100.0, 6.15], [102.0, 6.16], [104.0, 6.16], [106.1, 6.19], [108.1, 6.21], [110.1, 6.24], [112.1, 6.27], [114.1, 6.32], [116.1, 6.36], [118.2, 6.41], [120.2, 6.47], [122.2, 6.53], [124.2, 6.59], [126.2, 6.66], [128.2, 6.72], [130.3, 6.79], [132.3, 6.86], [134.3, 6.94], [136.3, 7.01], [138.3, 7.09], [140.4, 7.16], [142.4, 7.24], [144.4, 7.31], [146.4, 7.39], [148.4, 7.46], [150.4, 7.53], [152.5, 7.60], [154.5, 7.67], [156.5, 7.73], [158.5, 7.79], [160.5, 7.85], [162.6, 7.90], [164.6, 7.95], [166.6, 8.00], [168.6, 8.04], [170.6, 8.07], [172.6, 8.10], [174.7, 8.12], [176.7, 8.14], [178.7, 8.15]]
const SIXTH := [[25.0, 8.15], [27.0, 8.14], [29.0, 8.14], [31.0, 8.13], [33.0, 8.13], [35.0, 8.12], [37.0, 8.11], [39.0, 8.10], [41.0, 8.09], [43.0, 8.08], [45.0, 8.07], [47.0, 8.06], [49.0, 8.05], [51.0, 8.03], [53.0, 8.02], [55.0, 8.00], [57.0, 7.99], [59.0, 7.97], [61.0, 7.95], [63.0, 7.93], [65.0, 7.91], [67.0, 7.89], [69.0, 7.87], [71.0, 7.85], [73.0, 7.83], [75.0, 7.81], [77.0, 7.79], [79.0, 7.76], [81.0, 7.74], [83.0, 7.72], [85.0, 7.69], [87.0, 7.67], [89.0, 7.64], [91.0, 7.62], [93.0, 7.59], [95.0, 7.57], [97.0, 7.54], [99.0, 7.51], [101.0, 7.49], [103.0, 7.46], [105.0, 7.43], [107.0, 7.40], [109.0, 7.38], [111.0, 7.35], [113.0, 7.32], [115.0, 7.29], [117.0, 7.26], [119.0, 7.24], [121.0, 7.21], [123.0, 7.18], [125.0, 7.15], [127.0, 7.12], [129.0, 7.09], [131.0, 7.06], [133.0, 7.04], [135.0, 7.01], [137.0, 6.98], [139.0, 6.95], [141.0, 6.92], [143.0, 6.90], [145.0, 6.87], [147.0, 6.84], [149.0, 6.81], [151.0, 6.79], [153.0, 6.76], [155.0, 6.73], [157.0, 6.71], [159.0, 6.68], [161.0, 6.66], [163.0, 6.63], [165.0, 6.61], [167.0, 6.58], [169.0, 6.56], [171.0, 6.54], [173.0, 6.51], [175.0, 6.49], [177.0, 6.47], [179.0, 6.45], [181.0, 6.43], [183.0, 6.41], [185.0, 6.39], [187.0, 6.37], [189.0, 6.35], [191.0, 6.33], [193.0, 6.31], [195.0, 6.30], [197.0, 6.28], [199.0, 6.27], [201.0, 6.25], [203.0, 6.24], [205.0, 6.23], [207.0, 6.22], [209.0, 6.21], [211.0, 6.20], [213.0, 6.19], [215.0, 6.18], [217.0, 6.17], [219.0, 6.17], [221.0, 6.16], [223.0, 6.16], [225.0, 6.15]]

static func _lerp_table(t: Array, x: float) -> float:
	if x <= float(t[0][0]): return float(t[0][1])
	for i in t.size() - 1:
		var a: Array = t[i]; var b: Array = t[i + 1]
		if x <= float(b[0]): return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / (float(b[0]) - float(a[0])))
	return float(t[t.size() - 1][1])

## the B Ave rise, 0 at v <= 100 .. 1 at v >= 178.7
static func f(v: float) -> float: return (_lerp_table(BAVE, v) - 6.15) / 2.0
## the 6th St fall, 1 at u <= 25 .. 0 at u >= 225
static func g(u: float) -> float: return (_lerp_table(SIXTH, u) - 6.15) / 2.0

## base surface, piece-local (x = u, z = v), local y
static func surface(x: float, z: float) -> float:
	return 0.15 + 2.0 * f(z) * g(x)
