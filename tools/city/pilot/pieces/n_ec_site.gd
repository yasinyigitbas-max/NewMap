extends RefCounted
## The ec fill (claude/fill-high-street, 20 Nov; Yasin: "FILL THAT RED AREA WITH GRASS > SAND AND BEYOND IT SHOULD BE THE
## SEA, PUT LOTS OF RELEVANT PROPS IN THAT AREA, MAKE THE SEA SAND CONNECTION SEAMLESS AND BUBBLY LIKE THE WATERFRONT AND
## AROUND THE ISLAND"): the edges, lines and heights its pieces share. Places nothing.
## Frame: every ec piece at grid [0, 0, 0], yaw 0: x = u, z = v (north -v), local y = world y.
##
## The area (measured 20 Nov, read-only, from the city ground dump OUT/g_city with OUT/fill/ec/edges.py, and the land
## zoning/terrain_grid.npz with OUT/fill/ec/shore.py): all land beyond the ring road's EAST (outer) walk edge, v -500 .. 0,
## out to 25 m past the land's own 0 m line (the sea mesh reaches 25 m in under the land, SHORE_GUIDE.md).
##  - west: the ring's outer walk edge (RING, below; 4.150 all along): u 667.7 at v -504, 659.3 at the bend v -121,
##    645.6 at v -28 (a kerb bulge), 645.05 at v 0 (j_rg_se_e627_s0). The ring pieces and its two T junctions
##    (j_rg_se_e652_n400, j_rg_se_e647_n200) have NO apron on this side (zoning/legs_measured.json): no car comes in.
##  - north: v -500, builder eb's area beyond (v -1100 .. -500), working at the same time: both follow the same rule.
##  - south: v 0. Open land continues south of v 0 (to the waterfront's beaches): not filled, stopped at v 0.
##  - east: the sea: the land's 0 m line (ZERO) runs u 1401.8 at v -500, 1354.7 at v -390, 1454.6 at v -10.
## The land: 4.0 - 4.1 at the ring; a hill to 11.1 m round u 900, v -340 (falling to 7 m at v -500 and v -200, and to
## 2.4 m at v -80); east of u 1100 a low flat 0.5 - 1.5 m wide to the water, then a 1 : 8 drop into the sea.

const LAND := preload("res://tools/city/pilot/pieces/n_ec_land.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const LIFT := 0.05          # the ground 5 cm over the land ...
const WET := 10.0           # ... eased to 0 over the last 10 m before the land's 0 m line (smoothstep on the distance)
const EASE := 12.0          # the ground eased onto the ring's walk within 12 m
const RING_Y := 4.15
const STEP := 4.0           # soft ground on the land's own 4 m grid (paths, pads and curves cut it finer)
const U_W := 932.0          # the line between the hill pieces and the dune pieces
const U_E := 1200.0         # the line between the dune pieces and the beach pieces
const V_N := -500.0
const V_M := -250.0
const V_S := 0.0

## the ring's outer (east) walk edge: [v, u] every 2 m, measured on OUT/g_city (OUT/fill/ec/edges.py), height 4.150
const RING := [[-504.0, 667.686], [-502.0, 667.659], [-500.0, 667.632], [-498.0, 667.606], [-496.0, 667.579], [-494.0, 667.552], [-492.0, 667.526], [-490.0, 667.499], [-488.0, 667.472], [-486.0, 667.446], [-484.0, 667.419], [-482.0, 667.392], [-480.0, 667.366], [-478.0, 667.339], [-476.0, 667.312], [-474.0, 667.286], [-472.0, 667.259], [-470.0, 667.232], [-468.0, 667.206], [-466.0, 667.179], [-464.0, 667.152], [-462.0, 667.126], [-460.0, 667.099], [-458.0, 667.072], [-456.0, 667.046], [-454.0, 667.019], [-452.0, 666.992], [-450.0, 666.965], [-448.0, 666.939], [-446.0, 666.912], [-444.0, 666.885], [-442.0, 666.859], [-440.0, 666.832], [-438.0, 666.805], [-436.0, 666.779], [-434.0, 666.752], [-432.0, 666.725], [-430.0, 666.699], [-428.0, 666.672], [-426.0, 666.645], [-424.0, 666.619], [-422.0, 666.592], [-420.0, 666.565], [-418.0, 666.539], [-416.0, 666.512], [-414.0, 666.485], [-412.0, 666.459], [-410.0, 666.432], [-408.0, 666.405], [-406.0, 666.379], [-404.0, 666.352], [-402.0, 666.325], [-400.0, 666.299], [-398.0, 666.256], [-396.0, 666.206], [-394.0, 666.156], [-392.0, 666.106], [-390.0, 666.056], [-388.0, 666.006], [-386.0, 665.956], [-384.0, 665.906], [-382.0, 665.856], [-380.0, 665.806], [-378.0, 665.756], [-376.0, 665.706], [-374.0, 665.656], [-372.0, 665.606], [-370.0, 665.555], [-368.0, 665.505], [-366.0, 665.455], [-364.0, 665.405], [-362.0, 665.355], [-360.0, 665.305], [-358.0, 665.255], [-356.0, 665.205], [-354.0, 665.155], [-352.0, 665.105], [-350.0, 665.055], [-348.0, 665.005], [-346.0, 664.955], [-344.0, 664.905], [-342.0, 664.855], [-340.0, 664.805], [-338.0, 664.755], [-336.0, 664.705], [-334.0, 664.655], [-332.0, 664.605], [-330.0, 664.555], [-328.0, 664.505], [-326.0, 664.455], [-324.0, 664.405], [-322.0, 664.355], [-320.0, 664.305], [-318.0, 664.255], [-316.0, 664.205], [-314.0, 664.155], [-312.0, 664.105], [-310.0, 664.055], [-308.0, 664.005], [-306.0, 663.955], [-304.0, 663.905], [-302.0, 663.855], [-300.0, 663.805], [-298.0, 663.755], [-296.0, 663.705], [-294.0, 663.655], [-292.0, 663.605], [-290.0, 663.555], [-288.0, 663.505], [-286.0, 663.455], [-284.0, 663.405], [-282.0, 663.355], [-280.0, 663.305], [-278.0, 663.255], [-276.0, 663.205], [-274.0, 663.155], [-272.0, 663.105], [-270.0, 663.055], [-268.0, 663.005], [-266.0, 662.955], [-264.0, 662.905], [-262.0, 662.855], [-260.0, 662.805], [-258.0, 662.755], [-256.0, 662.705], [-254.0, 662.655], [-252.0, 662.605], [-250.0, 662.555], [-248.0, 662.505], [-246.0, 662.455], [-244.0, 662.405], [-242.0, 662.355], [-240.0, 662.305], [-238.0, 662.255], [-236.0, 662.205], [-234.0, 662.155], [-232.0, 662.104], [-230.0, 662.054], [-228.0, 662.004], [-226.0, 661.954], [-224.0, 661.904], [-222.0, 661.854], [-220.0, 661.804], [-218.0, 661.754], [-216.0, 661.704], [-214.0, 661.654], [-212.0, 661.604], [-210.0, 661.554], [-208.0, 661.504], [-206.0, 661.454], [-204.0, 661.404], [-202.0, 661.354], [-200.0, 661.304], [-198.0, 661.254], [-196.0, 661.204], [-194.0, 661.154], [-192.0, 661.104], [-190.0, 661.054], [-188.0, 661.004], [-186.0, 660.954], [-184.0, 660.904], [-182.0, 660.854], [-180.0, 660.804], [-178.0, 660.754], [-176.0, 660.704], [-174.0, 660.654], [-172.0, 660.604], [-170.0, 660.554], [-168.0, 660.504], [-166.0, 660.454], [-164.0, 660.404], [-162.0, 660.354], [-160.0, 660.304], [-158.0, 660.254], [-156.0, 660.204], [-154.0, 660.154], [-152.0, 660.104], [-150.0, 660.054], [-148.0, 660.004], [-146.0, 659.954], [-144.0, 659.904], [-142.0, 659.854], [-140.0, 659.804], [-138.0, 659.754], [-136.0, 659.704], [-134.0, 659.654], [-132.0, 659.604], [-130.0, 659.554], [-128.0, 659.504], [-126.0, 659.454], [-124.0, 659.404], [-122.0, 659.340], [-120.0, 659.242], [-118.0, 659.075], [-116.0, 658.839], [-114.0, 658.544], [-112.0, 658.237], [-110.0, 657.929], [-108.0, 657.621], [-106.0, 657.314], [-104.0, 657.006], [-102.0, 656.698], [-100.0, 656.391], [-98.0, 656.083], [-96.0, 655.775], [-94.0, 655.468], [-92.0, 655.160], [-90.0, 654.852], [-88.0, 654.545], [-86.0, 654.237], [-84.0, 653.929], [-82.0, 653.622], [-80.0, 653.314], [-78.0, 653.006], [-76.0, 652.699], [-74.0, 652.391], [-72.0, 652.083], [-70.0, 651.776], [-68.0, 651.468], [-66.0, 651.160], [-64.0, 650.853], [-62.0, 650.545], [-60.0, 650.237], [-58.0, 649.930], [-56.0, 649.622], [-54.0, 649.314], [-52.0, 649.006], [-50.0, 648.699], [-48.0, 648.391], [-46.0, 648.083], [-44.0, 647.776], [-42.0, 647.468], [-40.0, 647.160], [-38.0, 646.853], [-36.0, 646.545], [-34.0, 646.237], [-32.0, 645.930], [-30.0, 645.648], [-28.0, 645.552], [-26.0, 645.618], [-24.0, 645.799], [-22.0, 646.050], [-20.0, 646.326], [-18.0, 646.587], [-16.0, 646.788], [-14.0, 646.886], [-12.0, 646.833], [-10.0, 646.592], [-8.0, 646.285], [-6.0, 645.977], [-4.0, 645.669], [-2.0, 645.362], [0.0, 645.054], [2.0, 644.746], [4.0, 644.415], [6.0, 644.037], [8.0, 643.602]]
## the land's 0 m line: [v, u] every 4 m (bilinear on terrain_grid.npz, OUT/fill/ec/shore.py): the sea cuts the sand here
const ZERO := [[-508.0, 1403.00], [-504.0, 1402.51], [-500.0, 1401.84], [-496.0, 1401.03], [-492.0, 1400.08], [-488.0, 1399.01], [-484.0, 1397.80], [-480.0, 1396.47], [-476.0, 1394.98], [-472.0, 1393.40], [-468.0, 1391.71], [-464.0, 1389.96], [-460.0, 1388.16], [-456.0, 1386.29], [-452.0, 1384.33], [-448.0, 1382.21], [-444.0, 1379.89], [-440.0, 1377.29], [-436.0, 1374.43], [-432.0, 1371.34], [-428.0, 1368.14], [-424.0, 1365.01], [-420.0, 1362.19], [-416.0, 1359.83], [-412.0, 1357.94], [-408.0, 1356.59], [-404.0, 1355.69], [-400.0, 1355.11], [-396.0, 1354.79], [-392.0, 1354.68], [-388.0, 1354.70], [-384.0, 1354.85], [-380.0, 1355.10], [-376.0, 1355.41], [-372.0, 1355.80], [-368.0, 1356.26], [-364.0, 1356.81], [-360.0, 1357.46], [-356.0, 1358.24], [-352.0, 1359.17], [-348.0, 1360.24], [-344.0, 1361.45], [-340.0, 1362.75], [-336.0, 1364.11], [-332.0, 1365.49], [-328.0, 1366.84], [-324.0, 1368.13], [-320.0, 1369.38], [-316.0, 1370.57], [-312.0, 1371.74], [-308.0, 1372.90], [-304.0, 1374.08], [-300.0, 1375.27], [-296.0, 1376.47], [-292.0, 1377.70], [-288.0, 1378.93], [-284.0, 1380.14], [-280.0, 1381.34], [-276.0, 1382.51], [-272.0, 1383.67], [-268.0, 1384.71], [-264.0, 1385.74], [-260.0, 1386.74], [-256.0, 1387.73], [-252.0, 1388.72], [-248.0, 1389.72], [-244.0, 1390.72], [-240.0, 1391.75], [-236.0, 1392.74], [-232.0, 1393.75], [-228.0, 1394.74], [-224.0, 1395.74], [-220.0, 1396.72], [-216.0, 1397.71], [-212.0, 1398.73], [-208.0, 1399.77], [-204.0, 1400.83], [-200.0, 1401.92], [-196.0, 1403.02], [-192.0, 1404.13], [-188.0, 1405.22], [-184.0, 1406.29], [-180.0, 1407.33], [-176.0, 1408.37], [-172.0, 1409.40], [-168.0, 1410.44], [-164.0, 1411.58], [-160.0, 1412.64], [-156.0, 1413.77], [-152.0, 1414.91], [-148.0, 1416.03], [-144.0, 1417.13], [-140.0, 1418.17], [-136.0, 1419.19], [-132.0, 1420.16], [-128.0, 1421.13], [-124.0, 1422.11], [-120.0, 1423.13], [-116.0, 1424.20], [-112.0, 1425.30], [-108.0, 1426.44], [-104.0, 1427.58], [-100.0, 1428.72], [-96.0, 1429.85], [-92.0, 1430.96], [-88.0, 1432.08], [-84.0, 1433.20], [-80.0, 1434.37], [-76.0, 1435.65], [-72.0, 1436.89], [-68.0, 1438.22], [-64.0, 1439.64], [-60.0, 1440.96], [-56.0, 1442.33], [-52.0, 1443.70], [-48.0, 1445.05], [-44.0, 1446.41], [-40.0, 1447.74], [-36.0, 1449.02], [-32.0, 1450.24], [-28.0, 1451.36], [-24.0, 1452.37], [-20.0, 1453.23], [-16.0, 1453.93], [-12.0, 1454.43], [-8.0, 1454.70], [-4.0, 1454.69], [0.0, 1454.33], [4.0, 1453.62], [8.0, 1452.47]]
## the GRASS > SAND line (the dune edge), hand-drawn on the land (20 Nov): on the 2.5 m contour in the north (u 1113 -
## 1124, with small bays and points every 20 - 40 m), bending west with the hill's south foot (v -260 .. -100), held at
## u 1003 - 1010 on the low south flat (land 1.1 - 1.5 m there: following 2.5 m strictly would leave a 650 m wide beach
## and a 40 m grass strip; the park keeps a lawn and the beach is still 450 m wide). [v, u], smoothed (Catmull-Rom).
## North of v -492 it takes builder eb's dune line (n_eb_site.DUNE: 1124.94 at v -500), so the grass / sand line goes on
## across the seam without a step.
const DUNE := [[-512.0, 1130.93], [-504.0, 1126.65], [-500.0, 1124.94], [-492.0, 1122.16], [-480.0, 1118.0], [-460.0, 1113.0], [-440.0, 1117.0], [-420.0, 1122.0],
	[-400.0, 1119.0], [-380.0, 1113.0], [-360.0, 1116.0], [-340.0, 1121.0], [-320.0, 1117.0], [-300.0, 1110.0],
	[-280.0, 1106.0], [-260.0, 1100.0], [-240.0, 1095.0], [-220.0, 1087.0], [-200.0, 1078.0], [-180.0, 1068.0],
	[-160.0, 1058.0], [-140.0, 1046.0], [-120.0, 1033.0], [-100.0, 1022.0], [-80.0, 1014.0], [-60.0, 1009.0],
	[-40.0, 1006.0], [-20.0, 1004.0], [0.0, 1003.0], [8.0, 1003.0]]
const PROM_W := 9.0         # the promenade (3 m, plaza) runs 9 .. 6 m west of the dune line, the whole length
const PROM_E := 6.0

static func tab(t: Array, x: float) -> float:
	if x <= float(t[0][0]): return float(t[0][1])
	for i in t.size() - 1:
		var a: Array = t[i]; var b: Array = t[i + 1]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6))
	return float(t[t.size() - 1][1])

static func ring_u(v: float) -> float: return tab(RING, v)
static func zero_u(v: float) -> float: return tab(ZERO, v)
## the beach pieces' east edge: 25 m past the 0 m line (the sand goes on under the water, following the land)
static func sea_u(v: float) -> float: return zero_u(v) + 25.0
## the dune line, smooth (Catmull-Rom through DUNE)
static func dune_u(v: float) -> float:
	var n := DUNE.size()
	for i in n - 1:
		if v <= float(DUNE[i + 1][0]) or i == n - 2:
			var p0: Array = DUNE[maxi(i - 1, 0)]; var p1: Array = DUNE[i]; var p2: Array = DUNE[i + 1]; var p3: Array = DUNE[mini(i + 2, n - 1)]
			var t := clampf((v - float(p1[0])) / (float(p2[0]) - float(p1[0])), 0.0, 1.0)
			var a := float(p0[1]); var b := float(p1[1]); var c := float(p2[1]); var d := float(p3[1])
			return 0.5 * (2.0 * b + (-a + c) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t * t + (-a + 3.0 * b - 3.0 * c + d) * t * t * t)
	return float(DUNE[n - 1][1])
## the promenade meets eb's (n_eb_site.PROM: centre 1118.23 at v -500, 3 m wide) at the seam: 0.79 m further out there,
## eased back to 9 .. 6 m off the dune line by v -470
const PROM_FIX := 0.79
static func prom_w(v: float) -> float: return dune_u(v) - PROM_W + PROM_FIX * smoothstep(-470.0, -500.0, v)
static func prom_e(v: float) -> float: return dune_u(v) - PROM_E + PROM_FIX * smoothstep(-470.0, -500.0, v)
## the yaw that faces the sea at v (a prop's front, +z at yaw 0, turned to the outward normal of the 0 m line)
static func sea_yaw(v: float) -> float:
	var d := Vector2(zero_u(v + 8.0) - zero_u(v - 8.0), 16.0).normalized()
	return rad_to_deg(atan2(d.y, -d.x))
## the yaw that faces the sea across the dune line at v (benches on the promenade)
static func dune_yaw(v: float) -> float:
	var d := Vector2(dune_u(v + 4.0) - dune_u(v - 4.0), 8.0).normalized()
	return rad_to_deg(atan2(d.y, -d.x))

## (20 Nov, Yasin: "DONT FORGET TO TAKE THE LAND INTO CONSIDERATION"; SHORE_GUIDE: "SEAMLESS = your sand follows the land
## EXACTLY near the water") the ground FOLLOWS THE LAND: 5 cm over it (n_ec_land.gd: terrain_grid.npz's 4 m nodes,
## bilinear), the 5 cm eased to 0 over the last 10 m before the 0 m line, exactly the land beyond it (on under the
## water to the piece's sea edge), so the sea cuts the sand on the land's own 0 m line. Within 12 m of the ring's walk
## eased onto the walk (4.150), keeping the land's shape (target = land(p) + walk - land(foot)). World height.
## FOR THE NEIGHBOUR (eb, v -1100 .. -500): at v -500 this is the ground: land + 0.05 * smoothstep(0, 10, distance to
## the 0 m line), and within 12 m of the ring's walk the ease above: eb's own rule (n_eb_site.g).
## (the same rule as builder eb's n_eb_site.g, so the v -500 seam meets: the 5 cm eased by the DISTANCE to the 0 m line,
## smoothstep over 10 m, 0 on the water side of it)
static func zero_dist(u: float, v: float) -> float:
	if u >= zero_u(v): return 0.0
	var p := Vector2(u, v); var best := INF
	var i0 := clampi(int((v - float(ZERO[0][0])) / 4.0) - 4, 0, ZERO.size() - 2)
	for i in range(i0, mini(i0 + 9, ZERO.size() - 1)):
		var a := Vector2(ZERO[i][1], ZERO[i][0]); var b := Vector2(ZERO[i + 1][1], ZERO[i + 1][0])
		var t := clampf((p - a).dot(b - a) / maxf((b - a).length_squared(), 1e-9), 0.0, 1.0)
		best = minf(best, p.distance_to(a + (b - a) * t))
	return best
static func lift(u: float, v: float) -> float:
	if u < zero_u(v) - WET - 1.0: return LIFT
	return LIFT * smoothstep(0.0, WET, zero_dist(u, v))
static func g(u: float, v: float) -> float:
	var land: float = LAND.at(u, v)
	var y := land + lift(u, v)
	var ru := ring_u(v)
	var d := u - ru
	if d < EASE:
		var lf: float = LAND.at(ru, v)
		y = lerpf(land + (RING_Y - lf), y, smoothstep(0.0, EASE, maxf(d, 0.0)))
	return y

## Ground in rows (z) on the global grid, each row cut into BANDS between boundary lines that may curve with z (the
## ring's edge, the promenade, the dune line, the sea edge): xs = the boundaries west -> east (a float or a Callable of
## z), mats = each band's material ("-" = none). Inside a band the cells follow the global grid in x and every paint
## edge; the first and last cell of each band are trapezoids to its curved boundaries, so two bands share their
## vertices on the line (no crack, no stair-step). paints [x0, z0, x1, z1, mat] override by the cell's centre ("-" a hole).
static func _bx(b: Variant, z: float) -> float: return float(b.call(z)) if b is Callable else float(b)
static func rows(g: K.Ground, z0: float, z1: float, xs: Array, mats: Array, paints: Array, yfn: Callable, step := STEP) -> void:
	var ex: Array = []; var ez: Array = []
	for p: Array in paints: ex.append_array([float(p[0]), float(p[2])]); ez.append_array([float(p[1]), float(p[3])])
	var zs := H._lines(z0, z1, step, ez)
	for j in zs.size() - 1:
		var za: float = zs[j]; var zb: float = zs[j + 1]
		for k in mats.size():
			var la := _bx(xs[k], za); var lb := _bx(xs[k], zb); var ra := _bx(xs[k + 1], za); var rb := _bx(xs[k + 1], zb)
			if ra - la < 0.02 and rb - lb < 0.02: continue
			var lo := maxf(la, lb); var hi := minf(ra, rb)
			var inner: Array = []
			if hi - lo > 0.6:
				var ls := H._lines(lo, hi, step, ex)
				for x: float in ls:
					if x > lo + 0.3 and x < hi - 0.3: inner.append(x)
			var ca: Array = [la]; var cb: Array = [lb]
			for x: float in inner: ca.append(x); cb.append(x)
			ca.append(ra); cb.append(rb)
			for c in ca.size() - 1:
				var cx := (float(ca[c]) + float(ca[c + 1]) + float(cb[c]) + float(cb[c + 1])) * 0.25; var cz := (za + zb) * 0.5
				var m := String(mats[k])
				for p: Array in paints:
					if cx > float(p[0]) and cx < float(p[2]) and cz > float(p[1]) and cz < float(p[3]): m = String(p[4]); break
				if m == "-": continue
				g.quad(m, Vector3(ca[c], yfn.call(ca[c], za), za), Vector3(ca[c + 1], yfn.call(ca[c + 1], za), za),
					Vector3(cb[c + 1], yfn.call(cb[c + 1], zb), zb), Vector3(cb[c], yfn.call(cb[c], zb), zb))

## a building's footprint [u0, v0, u1, v1] from its kit bbox, at (cu, cv) turned by yaw (0, 90, 180, -90)
static func bbox(f: String) -> Array:
	var st := K.building_stats(f)
	if st.has("near") and (st.near as Dictionary).has("bbox"): return (st.near as Dictionary).bbox
	var wd: Array = st.footprint_wd
	return [[-float(wd[0]) * 0.5, 0.0, -float(wd[1]) * 0.5], [float(wd[0]) * 0.5, float(st.get("height", 6.0)), float(wd[1]) * 0.5]]
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(yaw - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]

## the grass > sand blend along the dune line between z0 and z1 (SHORE_GUIDE: "a soft, curving line, a 3-6 m blend"):
## sand blown onto the last metres of grass (pale sand-tinted patches, heavy overlap so no tile edge reads) and the
## first metres of sand a little darker where the dune plants hold it. Wear decals only, along the line (like f_sw's wet
## sand): nothing placed.
static func dune_blend(dec: K.Decals, z0: float, z1: float, yfn: Callable) -> void:
	var z := z0 + 0.8
	while z < z1 - 0.8:
		var x := dune_u(z); var ang := dune_yaw(z) - 90.0
		dec.add(4 + int(absf(z)) % 2, Vector2(x - 1.6, z), ang, 3.4, 2.2, yfn, Color(0.86, 0.79, 0.64, 0.55))
		dec.add(14, Vector2(x - 3.4, z + 0.6), ang, 2.6, 1.8, yfn, Color(0.86, 0.79, 0.64, 0.3))
		z += 1.6

## wet sand along the water (f_sw's band): a darker band the last metres above the 0 m line and a narrow darker strip
## where the swash runs up, following the line
static func wet_sand(dec: K.Decals, z0: float, z1: float, yfn: Callable) -> void:
	var z := z0 + 0.7
	while z < z1 - 0.7:
		var x := zero_u(z); var ang := sea_yaw(z) - 90.0
		dec.add(14, Vector2(x - 4.0, z), ang, 4.2, 2.6, yfn, Color(0.78, 0.68, 0.52, 0.4))
		dec.add(14, Vector2(x - 1.6, z), ang, 2.6, 1.6, yfn, Color(0.66, 0.57, 0.44, 0.5))
		z += 1.4

## a level pad (lookout, terrace) at the highest ground under it, faces round it: hs_fill_lib.level_pad
static func pad_top(x0: float, z0: float, x1: float, z1: float, yfn: Callable) -> float:
	return H.pad_height([x0, z0, x1, z1], 0.0, yfn, 0.0)
