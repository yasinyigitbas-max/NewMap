extends RefCounted
## The fe fill (claude/fill-high-street, 20 Nov; Yasin: "populate them. act like architects and city planners ... take the
## elevation of the map into consideration"): the edges and heights its pieces share. Places nothing.
## Frame: every fe piece at grid [0, 4.0, 0], yaw 0: x = u, z = v (north -v), local y = world - 4.0.
##
## The area (measured 20 Nov from the city ground dump OUT/g_city, OUT/fill/fe/edges_fe.py / edges_fe2.py; read-only):
##  B1  u 259 .. 491, v -991 .. -809, an L: the empty part of the block between the u 250 and u 500 streets (the
##      residential quadrant r_q_250_m1000_se holds u 259 .. 375, v -991 .. -900). Pieces n_fe_b1w (u 259 .. 375) and
##      n_fe_b1e (u 375 .. 491); they share the line u 375 (v -900 .. -809) and one height function, so the seam is exact.
##  B2  u 509 .. the ring, v -985.7 .. -809 (s_rg_b087's south walk .. the -800 street's north walk): n_fe_b2.
##  The RING STRIP south of -800: there is NO u 600 street there (the cross streets run from the u 500 street straight
##      to the ring), so each block is u 509 .. the ring's inner walk (130 m wide, not 30 - 60): n_fe_r7 (v -791 .. -609),
##      n_fe_r5 (-591 .. -409), n_fe_r3 (-391 .. -209), n_fe_r1 (-191 .. -9; its ring edge bends at v -121 toward the
##      v 0 junction).
##  The ring strip north of -1000 (v -1400 .. -1200) is NOT empty: m_gr_ad3se and m_gr_e4n reach the ring's walk; nothing
##  to fill there (measured: no empty cell between u 509 and the ring).
## Walks: every edge below is the outer edge of a street's walk (its property line) with its height measured along it
## (tables, world m). The ring's inner walk is 4.150 all along; the cross streets fall from 6.150 (8.150 at -200) at
## u 519 to 4.150 at u 626; the u 500 street's east walk is in the U509_* tables.
## Aprons (zoning/legs_measured.json, 54 - 60 m from a node, both sides; checked on the ground dump): on the u 500
## street v -946..-940, -860..-854, -746..-740, -660..-654, -546..-540, -460..-454, -346..-340, -260..-254,
## -146..-140, -60..-54; on every cross street east of u 500: u 554..560 (both sides); on the u 250 street (B1's west
## walk): v -860..-854; on the -800 street west of u 500: u 304..310 and u 440..446; on the -1000 street (B1's north):
## u 440..446. s_rg_b087 (B2's north) and the ring have none: no car comes in from them.

const PAD_Y := 4.0
const LAND := preload("res://tools/city/pilot/pieces/n_fe_land.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const LIFT := 0.05
const EASE := 12.0
const RING_Y := 4.15

const U491 := [[-991.00, 4.150], [-973.50, 4.150], [-968.50, 4.158], [-963.50, 4.177], [-958.50, 4.207], [-953.50, 4.247], [-948.50, 4.297], [-941.00, 4.387], [-936.00, 4.456], [-928.50, 4.571], [-921.00, 4.698], [-911.00, 4.880], [-883.50, 5.410], [-873.50, 5.593], [-866.00, 5.721], [-858.50, 5.837], [-853.50, 5.907], [-848.50, 5.970], [-843.50, 6.024], [-838.50, 6.070], [-833.50, 6.106], [-828.50, 6.132], [-823.50, 6.147], [-811.00, 6.150], [-809.00, 6.150]]
const U375 := [[-991.00, 5.107], [-988.50, 5.200], [-946.00, 5.199], [-938.50, 5.249], [-926.00, 5.349], [-913.50, 5.465], [-901.00, 5.589], [-900.00, 5.600]]
const V900 := [[259.00, 6.150], [294.00, 6.150], [296.50, 6.072], [304.00, 6.072], [316.50, 6.010], [329.00, 5.936], [346.50, 5.816], [374.00, 5.606], [375.00, 5.600]]
const V991 := [[375.00, 5.106], [395.00, 4.818], [407.50, 4.649], [417.50, 4.525], [425.00, 4.441], [432.50, 4.365], [437.50, 4.319], [445.00, 4.260], [452.50, 4.212], [460.00, 4.177], [467.50, 4.156], [475.00, 4.150], [490.00, 4.150], [491.00, 4.150]]
const V809 := [[259.00, 6.150], [491.50, 6.150], [494.00, 6.000], [504.00, 6.000], [506.50, 6.150], [519.00, 6.150], [524.00, 6.142], [529.00, 6.112], [531.50, 6.090], [536.50, 6.031], [541.50, 5.954], [544.00, 5.911], [549.00, 5.813], [554.00, 5.704], [559.00, 5.585], [564.00, 5.460], [586.50, 4.862], [594.00, 4.674], [599.00, 4.558], [604.00, 4.453], [609.00, 4.360], [611.50, 4.318], [616.50, 4.248], [619.00, 4.219], [624.00, 4.176], [626.50, 4.162], [629.00, 4.154], [634.00, 4.150], [641.50, 4.150]]
const V791 := [[509.00, 6.150], [519.00, 6.150], [524.00, 6.142], [529.00, 6.112], [531.50, 6.090], [536.50, 6.031], [541.50, 5.954], [544.00, 5.911], [549.00, 5.813], [554.00, 5.704], [559.00, 5.585], [564.00, 5.460], [586.50, 4.862], [594.00, 4.674], [599.00, 4.558], [604.00, 4.453], [609.00, 4.360], [611.50, 4.318], [616.50, 4.248], [619.00, 4.219], [624.00, 4.176], [626.50, 4.162], [629.00, 4.154], [634.00, 4.150], [641.50, 4.150]]
const V609 := [[509.00, 6.150], [519.00, 6.150], [524.00, 6.142], [529.00, 6.110], [531.50, 6.087], [536.50, 6.025], [541.50, 5.945], [544.00, 5.900], [549.00, 5.798], [554.00, 5.685], [559.00, 5.562], [566.50, 5.365], [584.00, 4.886], [591.50, 4.692], [596.50, 4.573], [601.50, 4.462], [606.50, 4.367], [609.00, 4.323], [614.00, 4.250], [616.50, 4.220], [619.00, 4.196], [621.50, 4.176], [624.00, 4.162], [626.50, 4.154], [631.50, 4.150], [641.50, 4.150]]
const V591 := [[509.00, 6.150], [519.00, 6.150], [524.00, 6.142], [529.00, 6.110], [531.50, 6.087], [536.50, 6.025], [541.50, 5.945], [544.00, 5.900], [549.00, 5.798], [554.00, 5.685], [559.00, 5.562], [566.50, 5.365], [584.00, 4.886], [591.50, 4.692], [596.50, 4.573], [601.50, 4.462], [606.50, 4.367], [609.00, 4.323], [614.00, 4.250], [616.50, 4.220], [619.00, 4.196], [621.50, 4.176], [624.00, 4.162], [626.50, 4.154], [631.50, 4.150], [641.50, 4.150]]
const V409 := [[509.00, 6.150], [519.00, 6.150], [524.00, 6.142], [529.00, 6.108], [531.50, 6.084], [536.50, 6.019], [539.00, 5.980], [544.00, 5.888], [549.00, 5.782], [554.00, 5.664], [559.00, 5.537], [569.00, 5.263], [584.00, 4.843], [591.50, 4.648], [596.50, 4.529], [601.50, 4.422], [606.50, 4.328], [611.50, 4.253], [614.00, 4.221], [619.00, 4.176], [621.50, 4.161], [626.50, 4.150], [639.00, 4.150], [641.50, 4.150]]
const V391 := [[509.00, 6.150], [519.00, 6.150], [524.00, 6.142], [529.00, 6.108], [531.50, 6.084], [536.50, 6.019], [539.00, 5.980], [544.00, 5.888], [549.00, 5.782], [554.00, 5.664], [559.00, 5.537], [569.00, 5.263], [584.00, 4.843], [591.50, 4.648], [596.50, 4.529], [601.50, 4.422], [606.50, 4.328], [611.50, 4.253], [614.00, 4.221], [619.00, 4.176], [621.50, 4.161], [626.50, 4.150], [639.00, 4.150], [641.50, 4.150]]
const V209 := [[509.00, 8.150], [519.00, 8.150], [521.50, 8.143], [524.00, 8.131], [526.50, 8.099], [529.00, 8.057], [531.50, 8.006], [534.00, 7.938], [536.50, 7.862], [539.00, 7.777], [541.50, 7.681], [544.00, 7.578], [546.50, 7.467], [551.50, 7.225], [554.00, 7.094], [559.00, 6.821], [564.00, 6.534], [576.50, 5.796], [581.50, 5.507], [586.50, 5.232], [589.00, 5.101], [594.00, 4.855], [596.50, 4.744], [599.00, 4.639], [601.50, 4.540], [604.00, 4.455], [606.50, 4.376], [609.00, 4.307], [611.50, 4.253], [614.00, 4.207], [616.50, 4.175], [619.00, 4.159], [621.50, 4.150], [634.00, 4.150], [641.50, 4.150]]
const V191 := [[509.00, 8.150], [519.00, 8.150], [521.50, 8.143], [524.00, 8.131], [526.50, 8.099], [529.00, 8.057], [531.50, 8.006], [534.00, 7.938], [536.50, 7.862], [539.00, 7.777], [541.50, 7.681], [544.00, 7.578], [546.50, 7.467], [551.50, 7.225], [554.00, 7.094], [559.00, 6.821], [564.00, 6.534], [576.50, 5.796], [581.50, 5.507], [586.50, 5.232], [589.00, 5.101], [594.00, 4.855], [596.50, 4.744], [599.00, 4.639], [601.50, 4.540], [604.00, 4.455], [606.50, 4.376], [609.00, 4.307], [611.50, 4.253], [614.00, 4.207], [616.50, 4.175], [619.00, 4.159], [621.50, 4.150], [634.00, 4.150], [641.50, 4.150]]
const V9 := [[509.00, 4.150], [614.00, 4.150]]
const U509_B2 := [[-985.70, 4.150], [-971.60, 4.152], [-966.60, 4.164], [-961.60, 4.187], [-955.60, 4.229], [-949.60, 4.285], [-943.60, 4.353], [-935.60, 4.461], [-927.60, 4.585], [-918.60, 4.740], [-907.60, 4.945], [-882.60, 5.427], [-872.60, 5.609], [-864.60, 5.744], [-856.60, 5.865], [-849.60, 5.956], [-842.60, 6.033], [-836.60, 6.085], [-831.60, 6.117], [-827.60, 6.136], [-822.60, 6.147], [-813.60, 6.150], [-809.00, 6.150]]
const U509_R7 := [[-791.00, 6.150], [-609.00, 6.150]]
const U509_R5 := [[-591.00, 6.150], [-409.00, 6.150]]
const U509_R3 := [[-391.00, 6.150], [-377.90, 6.152], [-372.90, 6.162], [-367.90, 6.183], [-362.90, 6.214], [-356.90, 6.263], [-350.90, 6.325], [-345.90, 6.384], [-338.90, 6.478], [-330.90, 6.600], [-321.90, 6.750], [-309.90, 6.965], [-284.90, 7.430], [-273.90, 7.622], [-264.90, 7.766], [-256.90, 7.880], [-249.90, 7.966], [-243.90, 8.029], [-237.90, 8.080], [-232.90, 8.113], [-227.90, 8.136], [-222.90, 8.147], [-214.90, 8.150], [-209.00, 8.150]]
const U509_R1 := [[-191.00, 8.150], [-178.90, 8.148], [-175.90, 8.142], [-171.90, 8.120], [-167.90, 8.085], [-163.90, 8.037], [-158.90, 7.959], [-154.90, 7.885], [-150.90, 7.800], [-146.90, 7.706], [-142.90, 7.604], [-137.90, 7.464], [-132.90, 7.314], [-126.90, 7.120], [-120.90, 6.916], [-111.90, 6.593], [-86.90, 5.663], [-79.90, 5.412], [-71.90, 5.140], [-65.90, 4.949], [-59.90, 4.772], [-54.90, 4.639], [-50.90, 4.541], [-46.90, 4.452], [-42.90, 4.373], [-38.90, 4.305], [-34.90, 4.249], [-31.90, 4.213], [-27.90, 4.178], [-23.90, 4.157], [-18.90, 4.150], [-9.00, 4.150]]
## the ring's inner walk edge per block: [v, u] (lines fitted to the measured edge, OUT/py/curve_edge.py; within 5 cm)
const RING_B2 := [[-985.7, 645.509], [-809.0, 643.147]]
const RING_R7 := [[-791.0, 642.913], [-609.0, 640.483]]
const RING_R5 := [[-591.0, 640.243], [-409.0, 637.813]]
const RING_R3 := [[-391.0, 637.47], [-209.0, 632.92]]
const RING_R1 := [[-191.0, 632.47], [-121.21, 630.715], [-9.0, 613.45]]

static func tab(t: Array, x: float) -> float:
	if x <= float(t[0][0]): return float(t[0][1])
	for i in t.size() - 1:
		var a: Array = t[i]; var b: Array = t[i + 1]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6))
	return float(t[t.size() - 1][1])

## the ring's walk edge (u) at v for a block's RING table
static func ring_u(r: Array, v: float) -> float: return tab(r, v)

## edges of a block: [ax, az, bx, bz, height]: height = a table keyed by u (an edge along u) or by v (along v), or a
## number (a flat walk)
static func _edges(name: String) -> Array:
	match name:
		"b1": return [[259.0, -900.0, 259.0, -809.0, 6.15], [259.0, -900.0, 375.0, -900.0, V900], [375.0, -991.0, 375.0, -900.0, U375],
				[375.0, -991.0, 491.0, -991.0, V991], [491.0, -991.0, 491.0, -809.0, U491], [259.0, -809.0, 491.0, -809.0, V809]]
		"b2": return [[509.0, -985.7, 645.509, -985.7, 4.15], [509.0, -985.7, 509.0, -809.0, U509_B2], [509.0, -809.0, 643.147, -809.0, V809],
				[645.509, -985.7, 643.147, -809.0, RING_Y]]
		"r7": return [[509.0, -791.0, 642.913, -791.0, V791], [509.0, -609.0, 640.483, -609.0, V609], [509.0, -791.0, 509.0, -609.0, U509_R7],
				[642.913, -791.0, 640.483, -609.0, RING_Y]]
		"r5": return [[509.0, -591.0, 640.243, -591.0, V591], [509.0, -409.0, 637.813, -409.0, V409], [509.0, -591.0, 509.0, -409.0, U509_R5],
				[640.243, -591.0, 637.813, -409.0, RING_Y]]
		"r3": return [[509.0, -391.0, 637.47, -391.0, V391], [509.0, -209.0, 632.92, -209.0, V209], [509.0, -391.0, 509.0, -209.0, U509_R3],
				[637.47, -391.0, 632.92, -209.0, RING_Y]]
		"r1": return [[509.0, -191.0, 632.47, -191.0, V191], [509.0, -9.0, 613.45, -9.0, V9], [509.0, -191.0, 509.0, -9.0, U509_R1],
				[632.47, -191.0, 630.715, -121.21, RING_Y], [630.715, -121.21, 613.45, -9.0, RING_Y]]
	return []
static var _cache := {}
static func edges(name: String) -> Array:
	if not _cache.has(name): _cache[name] = _edges(name)
	return _cache[name]

## (20 Nov, Yasin: "DONT FORGET TO TAKE THE LAND INTO CONSIDERATION, build according to it") a block's ground FOLLOWS
## THE LAND: 5 cm over the land's own surface (n_fe_land.gd, terrain_grid.npz's 4 m nodes, bilinear), and within 12 m
## of each walk eased onto that walk's height, one edge after the other. The ease keeps the land's own shape: at a
## point p near an edge with foot f, the target is land(p) + (walk(f) - land(f)), and every walk is at least 5 cm over
## the land at its edge (measured), so the ground is never under the land and meets every walk exactly. World height.
static func g(blk: String, u: float, v: float) -> float:
	var land := LAND.at(u, v)
	var y := land + LIFT
	var p := Vector2(u, v)
	for e: Array in edges(blk):
		var a := Vector2(e[0], e[1]); var b := Vector2(e[2], e[3])
		var t := clampf((p - a).dot(b - a) / maxf((b - a).length_squared(), 1e-9), 0.0, 1.0)
		var f := a + (b - a) * t
		var d := p.distance_to(f)
		if d >= EASE: continue
		var hv: Variant = e[4]
		var walk: float = float(hv) if not (hv is Array) else (tab(hv, f.x) if absf(b.y - a.y) < 1e-6 else tab(hv, f.y))
		var target := land + (walk - LAND.at(f.x, f.y))
		y = lerpf(target, y, smoothstep(0.0, EASE, d))
	return y
## local height (piece frame)
static func y(blk: String, u: float, v: float) -> float: return g(blk, u, v) - PAD_Y

## Ground between a straight west line x0 and a slanted east edge xr(z) (the ring's walk), rows on the global grid in z
## (z0 .. z1), columns on the global grid in x, the last column of each row a trapezoid to the edge; each cell takes the
## first paint [x0, z0, x1, z1, mat] containing its centre ("-" = a hole), else `base`. (hs_fill_lib.paint_band turned
## a quarter: the ring runs along v.)
static func paint_rows(g: K.Ground, x0: float, z0: float, z1: float, xr: Callable, paints: Array, base: String, yfn: Callable, step := 2.0) -> void:
	var ex: Array = []; var ez: Array = []
	for p: Array in paints: ex.append_array([float(p[0]), float(p[2])]); ez.append_array([float(p[1]), float(p[3])])
	var zs := H._lines(z0, z1, step, ez)
	for j in zs.size() - 1:
		var za: float = zs[j]; var zb: float = zs[j + 1]
		var ra: float = xr.call(za); var rb: float = xr.call(zb)
		var inner := H._lines(x0, minf(ra, rb) - 0.25, step, ex)
		inner.pop_front(); inner.pop_back()
		var xa: Array = [x0]; var xb: Array = [x0]
		for x: float in inner: xa.append(x); xb.append(x)
		xa.append(ra); xb.append(rb)
		for c in xa.size() - 1:
			var cz := (za + zb) * 0.5; var cx := (float(xa[c]) + float(xa[c + 1]) + float(xb[c]) + float(xb[c + 1])) * 0.25
			var m := base
			for p: Array in paints:
				if cx > float(p[0]) and cx < float(p[2]) and cz > float(p[1]) and cz < float(p[3]): m = String(p[4]); break
			if m == "-": continue
			g.quad(m, Vector3(xa[c], yfn.call(xa[c], za), za), Vector3(xa[c + 1], yfn.call(xa[c + 1], za), za),
				Vector3(xb[c + 1], yfn.call(xb[c + 1], zb), zb), Vector3(xb[c], yfn.call(xb[c], zb), zb))
