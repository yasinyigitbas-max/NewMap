extends RefCounted
## The north end (fill_east, prefix fn; 20 Nov): the edges and heights its pieces share. Places nothing.
## Area (BUILD_GUIDE fill_east, coordinator's brief): the three blocks between 1st St (the bay-front ring, north) and
## 3rd St (the v -1400 arterial, south), from the u -200 street to the hospital zone (n_hp_west at u 400).
## Frame: pieces at grid [0, PAD_Y, 0], yaw 0: x = u, z = v (north -v), local y = world - PAD_Y.
##
## Measured 20 Nov (city ground dump OUT/g_city, the street meshes' own edges, OUT/fill/fn/edge2.py; read-only):
##  - 1st St's south walk edge v -1585.7, walk 2.150 all along (flat). Between u 328 and 372 the 1st St piece has NO
##    walk and no road (the ferry gap): the edge there stands over open land (1.95 - 2.05).
##  - 3rd St's north walk edge v -1414.3; its walk climbs from 4.15 (u -190.8) to 8.15 at Amber (u -16 .. 16) and falls
##    to 2.15 at B Ave (u 228): table T3.
##  - the u -200 street (s_rg_nw_b028): east walk edge u -190.8, 2.15 at 1st St rising to 4.15 at 3rd St (table W1).
##    Its east apron (the only car opening into block 1): v -1461 .. -1453 (walk 3.86 - 3.97).
##  - Amber Ave (s_rg_nw_b036, 32 m): walk edges u -16.0 / +16.0, both 2.15 at 1st St rising to 8.15 at 3rd St
##    (table AM). NO aprons (legs_measured: none), so no car enters blocks 1 or 2 from Amber.
##  - B Ave (s_rg_nw_b046): walk edges u 240.8 / 259.2, flat 2.150; aprons on both sides v -1461 .. -1453 (the only
##    car openings into blocks 2 and 3).
##  - every corner of the three blocks is square (the junctions fill to the corner).
##  - n_hp_west (locked, hospital zone) meets block 3 at u 400: its edge there is the land + 5 cm eased onto 1st St and
##    3rd St within 12 m (n_hp_site.g); this file's g gives the same there (checked: within 3 mm on the dump).
##  - the land (zoning/terrain_grid.npz, n_fn_land.gd): Crown Hill's north foot. Block 1: 2.0 at the bay rising to 4.0
##    (SW) and 8.0 (SE, Amber x 3rd); block 2: 8.0 at Amber x 3rd falling east to 2.1 at B Ave; block 3 flat 1.9 - 2.1.

const PAD_Y := 2.0
const LAND := preload("res://tools/city/pilot/pieces/n_fn_land.gd")
const LIFT := 0.05
const EASE := 12.0
const FIRST := -1585.7
const THIRD := -1414.3
const B1 := [-190.8, -16.0]
const B2 := [16.0, 240.8]
const B3 := [259.2, 400.0]
const GAP := [328.0, 372.0]
const APRON := [-1461.0, -1453.0]
const WALK := 2.15
## the u -200 street's east walk edge (u -190.8): [v, world height]
const W1 := [
	[-1585.7, 2.150], [-1572.0, 2.153], [-1568.0, 2.162], [-1564.0, 2.179], [-1560.0, 2.204], [-1556.0, 2.236], [-1552.0, 2.274], [-1548.0, 2.319],
	[-1544.0, 2.369], [-1540.0, 2.424], [-1536.0, 2.484], [-1532.0, 2.548], [-1528.0, 2.616], [-1524.0, 2.687], [-1520.0, 2.760], [-1516.0, 2.837],
	[-1512.0, 2.915], [-1508.0, 2.994], [-1504.0, 3.074], [-1500.0, 3.155], [-1496.0, 3.236], [-1492.0, 3.316], [-1488.0, 3.395], [-1484.0, 3.473],
	[-1480.0, 3.549], [-1476.0, 3.622], [-1472.0, 3.693], [-1468.0, 3.760], [-1464.0, 3.824], [-1460.0, 3.883], [-1456.0, 3.938], [-1452.0, 3.987],
	[-1448.0, 4.031], [-1444.0, 4.068], [-1440.0, 4.099], [-1436.0, 4.123], [-1432.0, 4.140], [-1428.0, 4.148], [-1414.3, 4.150],
]
## Amber Ave's walk edges (u -16 and +16, the same heights): [v, world height]
const AM := [
	[-1585.7, 2.150], [-1572.0, 2.157], [-1568.0, 2.184], [-1564.0, 2.234], [-1560.0, 2.305], [-1556.0, 2.397], [-1552.0, 2.507], [-1548.0, 2.635],
	[-1544.0, 2.779], [-1540.0, 2.938], [-1536.0, 3.110], [-1532.0, 3.295], [-1528.0, 3.491], [-1524.0, 3.697], [-1520.0, 3.911], [-1516.0, 4.132],
	[-1512.0, 4.359], [-1508.0, 4.591], [-1504.0, 4.825], [-1500.0, 5.061], [-1496.0, 5.298], [-1492.0, 5.534], [-1488.0, 5.767], [-1484.0, 5.998],
	[-1480.0, 6.223], [-1476.0, 6.443], [-1472.0, 6.655], [-1468.0, 6.858], [-1464.0, 7.051], [-1460.0, 7.233], [-1456.0, 7.403], [-1452.0, 7.558],
	[-1448.0, 7.698], [-1444.0, 7.822], [-1440.0, 7.927], [-1436.0, 8.014], [-1432.0, 8.080], [-1428.0, 8.124], [-1424.0, 8.146], [-1414.3, 8.150],
]
## 3rd St's north walk edge (v -1414.3): [u, world height]
const T3 := [
	[-190.8, 4.150], [-190.0, 4.150], [-186.0, 4.150], [-182.0, 4.150], [-178.0, 4.150], [-174.0, 4.158], [-170.0, 4.181], [-166.0, 4.219],
	[-162.0, 4.270], [-158.0, 4.334], [-154.0, 4.410], [-150.0, 4.497], [-146.0, 4.594], [-142.0, 4.701], [-138.0, 4.816], [-134.0, 4.939],
	[-130.0, 5.069], [-126.0, 5.205], [-122.0, 5.346], [-118.0, 5.492], [-114.0, 5.641], [-110.0, 5.793], [-106.0, 5.947], [-102.0, 6.101],
	[-98.0, 6.257], [-94.0, 6.411], [-90.0, 6.565], [-86.0, 6.716], [-82.0, 6.863], [-78.0, 7.008], [-74.0, 7.147], [-70.0, 7.281],
	[-66.0, 7.408], [-62.0, 7.528], [-58.0, 7.641], [-54.0, 7.744], [-50.0, 7.837], [-46.0, 7.920], [-42.0, 7.991], [-38.0, 8.050],
	[-34.0, 8.096], [-30.0, 8.128], [-26.0, 8.145], [-22.0, 8.150], [-18.0, 8.150], [-16.0, 8.150], [16.0, 8.150], [18.0, 8.150],
	[22.0, 8.150], [26.0, 8.146], [30.0, 8.131], [34.0, 8.103], [38.0, 8.063], [42.0, 8.011], [46.0, 7.947], [50.0, 7.873],
	[54.0, 7.789], [58.0, 7.695], [62.0, 7.592], [66.0, 7.480], [70.0, 7.360], [74.0, 7.233], [78.0, 7.099], [82.0, 6.958],
	[86.0, 6.811], [90.0, 6.659], [94.0, 6.502], [98.0, 6.341], [102.0, 6.176], [106.0, 6.008], [110.0, 5.838], [114.0, 5.665],
	[118.0, 5.490], [122.0, 5.315], [126.0, 5.139], [130.0, 4.963], [134.0, 4.788], [138.0, 4.614], [142.0, 4.441], [146.0, 4.271],
	[150.0, 4.103], [154.0, 3.939], [158.0, 3.778], [162.0, 3.622], [166.0, 3.471], [170.0, 3.325], [174.0, 3.185], [178.0, 3.051],
	[182.0, 2.925], [186.0, 2.806], [190.0, 2.696], [194.0, 2.594], [198.0, 2.501], [202.0, 2.418], [206.0, 2.345], [210.0, 2.283],
	[214.0, 2.232], [218.0, 2.193], [222.0, 2.167], [226.0, 2.153], [230.0, 2.150], [234.0, 2.150], [238.0, 2.150], [240.8, 2.150],
]

static func tab(t: Array, x: float) -> float:
	if x <= float(t[0][0]): return float(t[0][1])
	for i in t.size() - 1:
		var a: Array = t[i]; var b: Array = t[i + 1]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6))
	return float(t[t.size() - 1][1])

## the land itself (world)
static func land(u: float, v: float) -> float: return LAND.at(u, v)

## (Yasin: "DONT FORGET TO TAKE THE LAND INTO CONSIDERATION, build according to it") the ground FOLLOWS THE LAND: 5 cm
## over the land's own surface (at least 2 cm), eased within 12 m of each walk onto that walk's height (smoothstep), one side after the
## other (the corners agree: every corner's two walks have the same height). In the ferry gap the north side eases to
## the nearest end of the walk (so nothing is eased onto a walk that is not there). World height.
static func g(u: float, v: float) -> float:
	var y := land(u, v) + LIFT
	var s3 := smoothstep(0.0, EASE, THIRD - v)
	y = lerpf(tab(T3, u), y, s3)
	var dx := maxf(0.0, minf(u - GAP[0], GAP[1] - u))
	y = lerpf(WALK, y, smoothstep(0.0, EASE, Vector2(v - FIRST, dx).length()))
	if u < 0.0:
		y = lerpf(tab(W1, v), y, smoothstep(0.0, EASE, u - B1[0]))
		y = lerpf(tab(AM, v), y, smoothstep(0.0, EASE, B1[1] - u))
	elif u < 250.0:
		y = lerpf(tab(AM, v), y, smoothstep(0.0, EASE, u - B2[0]))
		y = lerpf(WALK, y, smoothstep(0.0, EASE, B2[1] - u))
	else:
		y = lerpf(WALK, y, smoothstep(0.0, EASE, u - B3[0]))
	# never under the land: where an easing would take the ground below it (up to 3 cm inside Amber's east walk, where
	# the land rises a little faster than the walk), 2 cm over it. At every walk edge the land is lower than the walk
	# minus 2 cm (measured at 0.5 m along all of them), so the edges keep the walks' heights.
	return maxf(y, land(u, v) + 0.02)
## local height (piece frame)
static func y(u: float, v: float) -> float: return g(u, v) - PAD_Y
