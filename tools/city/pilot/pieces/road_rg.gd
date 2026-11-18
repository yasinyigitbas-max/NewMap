extends RefCounted
## Ring road kit (family "ring", road kit groups 2-5, stage 1, 17 Nov). The boulevard round the island: Alameda Blvd
## along the base fence, Ocean Blvd ~75 m behind the beach, Glorietta Blvd along the golf course and the bay, 1st St on
## the bay front. Brief: map_dc/coronado/city_kit/ROADKIT_SPEC.md. Shared helpers are only READ here (never edited).
##
## GEOMETRY (no jagged edges)
##  - The ring is ONE exact closed path of straight lines and circular arcs, FITTED to the sampled polylines of every
##    ring block in review/sites.json ("pts", ~8.4 m samples): straight runs are found and fitted, every corner between
##    two runs gets the tangent fillet whose radius the samples show (the skeleton rounds every corner with 45 m).
##    Every ring piece, T-junction and gap is cut from this one path, so all pieces share their edges exactly.
##  - A piece is built in (s, t) coordinates: s = arc length along the path, t = lateral offset, +t = the RIGHT of a
##    driver moving +s (right-hand traffic: +s traffic drives on t > 0). Every surface is a grid of (s, t) cells mapped
##    through the path, so kerbs, lane lines and the property lines follow the curves exactly. All cells of a piece
##    share one list of s cuts (paint edges, ramp steps, 2 m on arcs, 4 m on lines): no T-vertices on a curve, so no
##    cracks. Paint is cut into the asphalt (one plane), arrows are the smooth site.gd arrow2 polygons mapped through
##    the path with their outline densified (so a shaft on a curve bends with its lane).
##  - Kerb returns at the T-junctions are exact fillets between the stem's straight kerb and the ring's (possibly
##    curved) kerb: centre found by bisection, tangent points exact, 18 segments.
## HEIGHTS (grading plan): junction pads are level at sites.json "pad". Between two tiles a block rises with the kit's
##  smoothstep across its own length between the tile edges (road_lib family, generalised), max grade 1.5 H / L.
##  Cross-sections are level across (no crossfall), as every kit street.
## FRAMES: every ring piece is authored in the GRID frame (x = u, z = v, y up), translated so its anchor is the origin:
##  boulevard pieces: the path point at the piece start, y = ring height there; T-junctions: the junction centre on the
##  path, y = the pad. Layout row: pos = [anchor u, anchor y, anchor v] (+ the review offset [0, 0, -8000]), yaw 0.
##  Stubs follow the kit leg convention instead: authored along +z from the LATTICE junction centre (origin), placed
##  with yaw so +z points at the ring (Godot yaw: +z -> (sin yaw, cos yaw)), y = the lattice pad.
##
## CROSS-SECTION (the strip arterial, strip_lib): centre two-way left-turn lane |t| <= 1.8, lanes to 5.3 / 8.8, bike
##  lane to 10.3, kerb 10.3, palm parkway to 12.3, sidewalk to 14.3. Boulevard dress, side by side (reasons):
##  - inland side (the town): grass parkway with palms (fan and queen, a planted scheme per block, mixed ages), cobra
##    lamps over the road, a 2 m walk; bus stops get a concrete boarding pad through the parkway with the bench on it
##    (the 2 m walk stays clear for walkers).
##  - coast side facing the WATER (Ocean Blvd: the beach; 1st St and the W leg: the bay): a promenade. Walk 12.3-16.3
##    in weathered paving (people stroll, jog, push prams: 4 m lets two groups pass), then a planting strip 16.3-18.3
##    (mulch with agave and bird of paradise, canary date palms: salt and wind tolerant, no lawn to water) broken by
##    paved bench bays every ~38 m where benches face the water, with a bin (people eat ice cream there), bike racks
##    parallel to the walk and a drinking fountain once per block; pier lamps light the walk (pedestrian scale), the
##    cobras light the road; sand carried up from the beach on feet lies in drifts on the walk and in the gutter. Bus
##    shelters on the promenade side stand in a paved bay of the planting strip, so the 4 m walk stays clear.
##  - coast side on the golf course (Glorietta Blvd) and the base fence (Alameda Blvd): no promenade (nobody strolls
##    along a fence or a fairway): the standard 2 m walk; the fence / course beyond the property line are not road
##    kit (the base and the course stay outside the city kit).
## JUNCTION CONTROL: a stem of the strip arterial (strip, couplet = 3rd / 4th St) or Amber (hs) meets the ring at
##  signals; res / std / truck stems stop (the ring never stops). Bus stops: far side of the T, both directions, at
##  every signalised T and at stop-controlled T's so stops are never more than ~330 m apart along the loop (bus()).
## SITE MAP (how a site builder turns review/sites.json into pieces): see the API section at the end of this file.

const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const RL := preload("res://tools/city/pilot/pieces/road_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")

const SITES := "res://map_dc/coronado/city_kit/review/sites.json"
const REVIEW_OFS := Vector3(0.0, 0.0, -8000.0)
const KH := 0.15            # kerb height (site.gd KERB_H)
# ring cross-section (half widths from the centre line, metres)
const TL := 1.8             # two-way left-turn lane
const L1 := 5.3             # inner lane outer edge
const L2 := 8.8             # outer lane outer edge (bike lane 8.8 - 10.3)
const KB := 10.3            # kerb
const PK := 12.3            # parkway (palms) to here
const PR := 14.3            # inland / golf / base property line (2 m walk)
const PW := 16.3            # promenade walk outer edge (coast side facing the water)
const PROM := 18.3          # promenade property line (planting strip 16.3 - 18.3)
const STEP_LINE := 4.0      # surface cells along s on straights
const STEP_ARC := 2.0       # on arcs (2 m chords on the 34.7 m inner kerb: 1.4 cm sagitta)
const RAMP_STEP := 0.35
const SIGHT := 28.0         # no parkway trees this close to a junction centre (drivers' sight triangle)
const PIECE_MAX := 110.0    # boulevard pieces are split into near-equal parts no longer than this
const GAP := 45.0           # the ring gap left for the hand-made bridge Y (centred on the bridge node)
const FERRY := Vector2(350.0, -1600.0)   # where the ferry landing leaves 1st St (streets.py FERRY): a 45 m gap too
const XW_GAP := 0.8         # crosswalk starts this far beyond a kerb-return tangent point
const XW_W := 3.0
const STOP_GAP := 1.2       # stop bar this far before the crosswalk
const STOP_W := 0.6
const POCKET := 40.0        # left-turn pocket length before a T tile
const DASH := [3.0, 12.0]   # lane line dashes: 3 m line, 9 m gap (phase is global along the loop: continuous)
const TW_DASH := [3.0, 9.0] # two-way turn lane inner dashes
const BUS_LEN := 28.0
const BUS_SPACING := 330.0

## stem sections (half widths). z0 = the lattice junction tile edge where a stub starts (kit legs measured 17 Nov:
## s_res / s_apt 20, s_ind 22, s_strip_art 22); R = kerb return radius at the ring (the ring is an arterial: 8 m; trucks
## 12 m as ind_lib); sgnl = the stem gets signals (arterial or Amber), otherwise a stop sign.
const SEC := {
	"res": {"kerb": 5.7, "pkw": 7.2, "prop": 9.2, "lane": 3.3, "R": 8.0, "z0": 20.0, "signal": false},
	"std": {"kerb": 5.7, "pkw": 7.2, "prop": 9.2, "lane": 3.3, "R": 8.0, "z0": 20.0, "signal": false},
	"strip": {"kerb": 10.3, "pkw": 12.3, "prop": 14.3, "lane": 8.8, "R": 8.0, "z0": 22.0, "signal": true},
	"couplet": {"kerb": 10.3, "pkw": 12.3, "prop": 14.3, "lane": 8.8, "R": 8.0, "z0": 22.0, "signal": true},
	"ind": {"kerb": 6.7, "pkw": 6.7, "prop": 8.7, "lane": 4.2, "R": 12.0, "z0": 22.0, "signal": false},
	"hs": {"kerb": 11.5, "pkw": 11.5, "prop": 16.0, "lane": 9.1, "R": 8.0, "z0": 17.5, "signal": true},
	# hero legs (road_bridge.gd, 17 Nov; no ring T uses them): the bridge approach (divided 2 + 2, 4 m planted median,
	# 1 m shoulders, grass verge, 2 m walk) and the one-way off-ramp (two lanes at the ring, 0.9 m shoulders)
	"approach": {"kerb": 10.2, "pkw": 12.2, "prop": 14.2, "lane": 9.2, "R": 8.0, "z0": 0.0, "signal": true},
	"ramp": {"kerb": 4.5, "pkw": 6.0, "prop": 8.0, "lane": 3.6, "R": 8.0, "z0": 0.0, "signal": true},
}

## ======================================================================================================== the path
class Path:
	var prims: Array = []     # {"k": "L", s0, len, p0, d} / {"k": "A", s0, len, c, r, a0, sg}
	var length := 0.0
	var closed := false

	func add_line(p0: Vector2, p1: Vector2) -> void:
		var L := p0.distance_to(p1)
		if L < 1e-6: return
		prims.append({"k": "L", "s0": length, "len": L, "p0": p0, "d": (p1 - p0) / L})
		length += L

	func add_arc(c: Vector2, r: float, a0: float, sweep: float) -> void:
		var L := absf(sweep) * r
		if L < 1e-6: return
		prims.append({"k": "A", "s0": length, "len": L, "c": c, "r": r, "a0": a0, "sg": signf(sweep)})
		length += L

	func wrp(s: float) -> float:
		return fposmod(s, length) if closed else clampf(s, 0.0, length)

	func _find(w: float) -> int:
		var lo := 0; var hi := prims.size() - 1
		while lo < hi:
			var mid := (lo + hi + 1) / 2
			if float(prims[mid]["s0"]) <= w: lo = mid
			else: hi = mid - 1
		return lo

	func point(s: float) -> Vector2:
		var w := wrp(s)
		var p: Dictionary = prims[_find(w)]
		var u := w - float(p["s0"])
		if String(p["k"]) == "L": return (p["p0"] as Vector2) + (p["d"] as Vector2) * u
		var a: float = float(p["a0"]) + float(p["sg"]) * u / float(p["r"])
		return (p["c"] as Vector2) + Vector2(cos(a), sin(a)) * float(p["r"])

	func tangent(s: float) -> Vector2:
		var w := wrp(s)
		var p: Dictionary = prims[_find(w)]
		if String(p["k"]) == "L": return p["d"] as Vector2
		var a: float = float(p["a0"]) + float(p["sg"]) * (w - float(p["s0"])) / float(p["r"])
		return Vector2(-sin(a), cos(a)) * float(p["sg"])

	## right normal of the direction of travel (+s): +t side
	func normal(s: float) -> Vector2:
		var d := tangent(s)
		return Vector2(-d.y, d.x)

	func at(s: float, t: float) -> Vector2:
		return point(s) + normal(s) * t

	func is_arc(s: float) -> bool:
		return String(prims[_find(wrp(s))]["k"]) == "A"

	## nearest point: Vector2(s, t) (s in [0, length) when closed)
	func project(q: Vector2) -> Vector2:
		var best := INF; var bs := 0.0
		for p: Dictionary in prims:
			var u := 0.0
			var L: float = p["len"]
			if String(p["k"]) == "L":
				u = clampf((q - (p["p0"] as Vector2)).dot(p["d"] as Vector2), 0.0, L)
			else:
				var r: float = p["r"]
				var rel := fposmod(((q - (p["c"] as Vector2)).angle() - float(p["a0"])) * float(p["sg"]), TAU)
				var sw := L / r
				if rel <= sw: u = rel * r
				else: u = L if (rel - sw) < (TAU - rel) else 0.0
			var s := float(p["s0"]) + u
			var dd := q.distance_to(point(s))
			if dd < best: best = dd; bs = s
		if closed: bs = fposmod(bs, length)
		return Vector2(bs, (q - point(bs)).dot(normal(bs)))

	## primitive boundaries strictly inside (a, b) (unwrapped s values)
	func breaks(a: float, b: float) -> Array:
		var out: Array = []
		var k0 := floori(a / length) - 1 if closed else 0
		var k1 := floori(b / length) + 1 if closed else 0
		for k in range(k0, k1 + 1):
			for p: Dictionary in prims:
				var v: float = float(p["s0"]) + k * length
				if v > a + 1e-4 and v < b - 1e-4: out.append(v)
		return out

## ------------------------------------------------------------------------------------- fitting straights + arcs
## Fits an exact line/arc path to a sampled polyline made of straights joined by circular fillets (any polyline the
## street tools sample, e.g. the ring blocks' "pts"). Straight runs: consecutive segments whose heading stays within
## tol of the run's first segment; each run gets a least-squares line. Each corner between two runs gets the fillet of
## the radius its in-between samples show (median of all corners when a corner has no sample on its arc), rounded to
## 0.5 m. Returns the Path; prints the radii and the largest distance of any sample from the fitted path.
static func fit_polyline(src: PackedVector2Array, closed: bool, tol_deg := 0.3) -> Path:
	var pts := PackedVector2Array()
	for p in src:
		if pts.is_empty() or pts[pts.size() - 1].distance_to(p) > 0.05: pts.append(p)
	if closed and pts[0].distance_to(pts[pts.size() - 1]) < 0.05: pts.remove_at(pts.size() - 1)
	var n := pts.size()
	var nseg := n if closed else n - 1
	var hd: Array[float] = []
	for i in nseg: hd.append((pts[(i + 1) % n] - pts[i]).angle())
	var tol := deg_to_rad(tol_deg)
	# start a closed scan at a segment that breaks from its predecessor
	var st := 0
	if closed:
		for i in nseg:
			if absf(_wrapa(hd[i] - hd[(i - 1 + nseg) % nseg])) > tol: st = i; break
	var runs: Array = []      # [first seg, last seg] (indices mod nseg)
	var i := 0
	while i < nseg:
		var a := (st + i) % nseg
		var j := i
		while j + 1 < nseg and absf(_wrapa(hd[(st + j + 1) % nseg] - hd[a])) < tol: j += 1
		var L := 0.0
		for k in range(i, j + 1): L += pts[(st + k) % n].distance_to(pts[(st + k + 1) % n])
		if j - i + 1 >= 2 and L >= 12.0: runs.append([i, j])
		i = j + 1
	# line per run (in scan order), least squares
	var lines: Array = []     # [point, dir, first pt idx (scan), last pt idx (scan)]
	for r: Array in runs:
		var idx: Array = []
		for k in range(int(r[0]), int(r[1]) + 2): idx.append((st + k) % n)
		var m := Vector2.ZERO
		for k: int in idx: m += pts[k]
		m /= idx.size()
		var sxx := 0.0; var sxy := 0.0; var syy := 0.0
		for k: int in idx:
			var q := pts[k] - m
			sxx += q.x * q.x; sxy += q.x * q.y; syy += q.y * q.y
		var ang := 0.5 * atan2(2.0 * sxy, sxx - syy)
		var d := Vector2(cos(ang), sin(ang))
		if d.dot(pts[idx[idx.size() - 1]] - pts[idx[0]]) < 0.0: d = -d
		lines.append([m, d, int(r[0]), int(r[1]) + 1])
	var nl := lines.size()
	# corners: intersection, deflection, radius from the samples on the arc
	var corners: Array = []   # [X, delta, R or -1]
	var radii: Array = []
	for k in (nl if closed else nl - 1):
		var la: Array = lines[k]; var lb: Array = lines[(k + 1) % nl]
		var da: Vector2 = la[1]; var db: Vector2 = lb[1]
		var delta := _wrapa(db.angle() - da.angle())
		var X := _isect(la[0], da, lb[0], db)
		var R := -1.0
		if absf(delta) > deg_to_rad(0.05):
			var bis := (db - da).normalized()
			var c := cos(delta * 0.5)
			var A := 1.0 / (c * c) - 1.0
			var est: Array = []
			var p0: int = la[3] + 1; var p1: int = lb[2] if (k + 1) % nl != 0 or not closed else int(lb[2]) + nseg
			for q in range(p0, p1):
				var w := pts[(st + q) % n] - X
				var Bq := -2.0 * bis.dot(w) / c; var Cq := w.length_squared()
				var disc := Bq * Bq - 4.0 * A * Cq
				if disc < 0.0 or A < 1e-9: continue
				# the two roots multiply to |w|^2 / A <= R^2: the larger one is the fillet radius
				var rt := (-Bq + sqrt(disc)) / (2.0 * A)
				if rt > 5.0 and rt < 500.0: est.append(rt)
			if not est.is_empty():
				est.sort(); R = float(est[est.size() / 2]); radii.append(R)
		corners.append([X, delta, R])
	var med := 45.0
	if not radii.is_empty():
		var rs := radii.duplicate(); rs.sort(); med = float(rs[rs.size() / 2])
	var path := Path.new(); path.closed = closed
	var tang: Array = []      # per corner [A (on incoming line), B (on outgoing line), centre, R, a0, sweep]
	var rout: Array = []
	for k in corners.size():
		var X: Vector2 = corners[k][0]; var delta: float = corners[k][1]
		var R: float = corners[k][2] if float(corners[k][2]) > 0.0 else med
		R = roundf(R * 2.0) / 2.0
		var da: Vector2 = lines[k][1]; var db: Vector2 = lines[(k + 1) % nl][1]
		var T := R * tan(absf(delta) * 0.5)
		var A := X - da * T; var B := X + db * T
		var cc := A + Vector2(-da.y, da.x) * R * signf(delta)
		tang.append([A, B, cc, R, (A - cc).angle(), delta])
		rout.append(R)
	if closed:
		for k in tang.size():
			var prev: Array = tang[(k - 1 + tang.size()) % tang.size()]
			path.add_line(prev[1], tang[k][0])
			if absf(float(tang[k][5])) > deg_to_rad(0.05): path.add_arc(tang[k][2], tang[k][3], tang[k][4], tang[k][5])
	else:
		var d0: Vector2 = lines[0][1]
		var start: Vector2 = lines[0][0] + d0 * d0.dot(pts[0] - lines[0][0])
		var cur := start
		for k in tang.size():
			path.add_line(cur, tang[k][0])
			if absf(float(tang[k][5])) > deg_to_rad(0.05): path.add_arc(tang[k][2], tang[k][3], tang[k][4], tang[k][5])
			cur = tang[k][1]
		var dl: Vector2 = lines[nl - 1][1]
		path.add_line(cur, lines[nl - 1][0] + dl * dl.dot(pts[n - 1] - lines[nl - 1][0]))
	var dev := 0.0
	for p in pts: dev = maxf(dev, absf(path.project(p).y))
	print("RG fit: %d lines, %d corners, radii %s, length %.1f m, max sample distance %.3f m" % [nl, tang.size(), str(rout), path.length, dev])
	return path

static func _wrapa(a: float) -> float:
	return fposmod(a + PI, TAU) - PI

static func _isect(p: Vector2, d: Vector2, q: Vector2, e: Vector2) -> Vector2:
	var den := d.cross(e)
	if absf(den) < 1e-9: return (p + q) * 0.5
	return p + d * ((q - p).cross(e) / den)

static func _ss(t: float) -> float:
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

## Godot yaw (degrees) that turns a model's +Z toward the grid direction d (x = u, z = v)
static func _yaw(d: Vector2) -> float:
	return rad_to_deg(atan2(d.x, d.y))

static func nkey(u: float, v: float) -> String:
	return "%.1f,%.1f" % [u, v]

## piece-name id of a node: (-800, 288.7) -> "w800_s289"
static func nid(u: float, v: float) -> String:
	return "%s%d_%s%d" % ["w" if u < 0.0 else "e", absi(roundi(u)), "n" if v < 0.0 else "s", absi(roundi(v))]

## ===================================================================================================== ring data
static var _R := {}

## The ring: {path, inland (t sign of the town side), nodes {key: info}, blocks {id: info}, order [keys by s], st}
##  node info: key, u, v, pad, kind, owner, s, o (origin on the path), legs, stem {dir, sec, block, name} or {},
##   ctl ("signal" / "stop" / "gap" (bridge) / "sample" (W)), em / ep (tile extent along -s / +s), tg (T geometry),
##   outer (far-side property line of the T), bus, piece (junction piece name)
##  block info: id, name, coast ("beach" / "bay" / "golf" / "base"), outer (its coast-side property line), na / nb
##   (node keys in +s order), sa / sb (unwrapped s, sb > sa), rise (pad b - pad a), r0 / r1 (buildable range)
static func ring() -> Dictionary:
	if not _R.is_empty(): return _R
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SITES))
	var B := {}
	for b: Dictionary in d["blocks"]: B[String(b["id"])] = b
	var N := {}
	for n: Dictionary in d["nodes"]: N[nkey(float(n["u"]), float(n["v"]))] = n
	var ring_ids: Array = []
	for b: Dictionary in d["blocks"]:
		if String(b["kind"]) == "ring": ring_ids.append(String(b["id"]))
	# chain the ring blocks into the loop (all run a -> b; b131 first: Ocean Blvd eastward)
	var order: Array = []
	var cur := "b131"
	var start := nkey(float(B[cur]["a"][0]), float(B[cur]["a"][1]))
	var pts := PackedVector2Array()
	for guard in 100:
		var b: Dictionary = B[cur]
		var bp: Array = b["pts"]
		for k in bp.size():
			if k == 0 and not pts.is_empty(): continue
			pts.append(Vector2(float(bp[k][0]), float(bp[k][1])))
		order.append(cur)
		var e := nkey(float(b["b"][0]), float(b["b"][1]))
		if e == start: break
		var nxt := ""
		for id: String in ring_ids:
			if id != cur and nkey(float(B[id]["a"][0]), float(B[id]["a"][1])) == e: nxt = id
		if nxt == "": push_error("RG: ring chain broken at " + e); break
		cur = nxt
	var path := fit_polyline(pts, true)
	var R := {"path": path, "nodes": {}, "blocks": {}}
	# inland = the t side of the island's interior
	var poly := PackedVector2Array()
	var sN := 0.0
	while sN < path.length: poly.append(path.point(sN)); sN += 10.0
	var probe := path.length * 0.37
	R["inland"] = 1.0 if Geometry2D.is_point_in_polygon(path.at(probe, 60.0), poly) else -1.0
	var inl: float = R["inland"]
	# nodes on the loop
	var keys := {}
	for id: String in order:
		for e: String in ["a", "b"]:
			keys[nkey(float(B[id][e][0]), float(B[id][e][1]))] = true
	for k: String in keys:
		var n: Dictionary = N[k]
		var o := Vector2(float(n["u"]), float(n["v"]))
		var info := {"key": k, "u": float(n["u"]), "v": float(n["v"]), "pad": float(n["pad"]), "kind": String(n["kind"]),
			"owner": String(n["owner"]), "legs": n["legs"], "stem": {}, "piece": "j_rg_" + nid(float(n["u"]), float(n["v"]))}
		for lg: Dictionary in n["legs"]:
			var sec := String(lg["section"])
			if sec != "ring" and sec != "bridge":
				info["stem"] = {"dir": Vector2(float(lg["dir"][0]), float(lg["dir"][1])).normalized(), "sec": sec,
					"block": String(lg["block"]), "name": String(lg["name"])}
		# origin: where the stem's lattice line crosses the path (moves the sampled node by a few cm at most)
		if not (info["stem"] as Dictionary).is_empty():
			var ds: Vector2 = info["stem"]["dir"]
			var lo := -4.0; var hi := 4.0
			var f0 := path.project(o + ds * lo).y
			for it in 50:
				var mid := (lo + hi) * 0.5
				if signf(path.project(o + ds * mid).y) == signf(f0): lo = mid
				else: hi = mid
			o = o + ds * ((lo + hi) * 0.5)
		info["o"] = o
		info["s"] = path.project(o).x
		R["nodes"][k] = info
	# blocks
	for id: String in order:
		var b: Dictionary = B[id]
		var na := nkey(float(b["a"][0]), float(b["a"][1])); var nb := nkey(float(b["b"][0]), float(b["b"][1]))
		var sa: float = R["nodes"][na]["s"]; var sb: float = R["nodes"][nb]["s"]
		if sb <= sa: sb += path.length
		var nm := String(b["name"])
		var coast := "beach" if nm.begins_with("Ocean") else ("bay" if (nm.begins_with("1st") or nm.begins_with("W leg")) else ("golf" if nm.begins_with("Glorietta") else "base"))
		R["blocks"][id] = {"id": id, "name": nm, "coast": coast, "outer": PROM if coast in ["beach", "bay"] else PR,
			"na": na, "nb": nb, "sa": sa, "sb": sb, "rise": float(R["nodes"][nb]["pad"]) - float(R["nodes"][na]["pad"])}
	# T geometry, control, tile extents
	for k: String in R["nodes"]:
		var nd: Dictionary = R["nodes"][k]
		var stem: Dictionary = nd["stem"]
		nd["outer"] = PR
		for id: String in order:
			var bk: Dictionary = R["blocks"][id]
			if bk["na"] == k or bk["nb"] == k: nd["outer"] = maxf(float(nd["outer"]), float(bk["outer"]))
		if String(nd["kind"]) == "bridge":
			nd["ctl"] = "gap"; nd["em"] = GAP * 0.5; nd["ep"] = GAP * 0.5; nd["tg"] = {}
		elif String(nd["owner"]) == "sample":
			nd["ctl"] = "sample"; nd["em"] = 100.0; nd["ep"] = 100.0; nd["tg"] = {}     # set from the W transitions below
		elif not stem.is_empty() and SEC.has(String(stem["sec"])):
			var sg: bool = SEC[String(stem["sec"])]["signal"]
			nd["ctl"] = "signal" if sg else "stop"
			nd["tg"] = _tgeom(path, nd["o"], float(nd["s"]), stem["dir"], String(stem["sec"]), sg)
			nd["em"] = float(nd["tg"]["em"]); nd["ep"] = float(nd["tg"]["ep"])
		else:
			nd["ctl"] = "none"; nd["em"] = 0.0; nd["ep"] = 0.0; nd["tg"] = {}
	# W: its legs end 100 m out; the transitions (biarcs) join the ring at s_J; the ring blocks stop there
	for k: String in R["nodes"]:
		var nd: Dictionary = R["nodes"][k]
		if String(nd["ctl"]) != "sample": continue
		var tw := _w_joins(R, nd)
		nd["w"] = tw
		nd["em"] = float(nd["s"]) - float(tw["S"]["sJ"]) if float(tw["S"]["sJ"]) < float(nd["s"]) else float(nd["s"]) + path.length - float(tw["S"]["sJ"])
		nd["ep"] = fposmod(float(tw["N"]["sJ"]) - float(nd["s"]), path.length)
	# stations for the height profile, the loop order
	var ks: Array = R["nodes"].keys()
	ks.sort_custom(func(a: String, b: String) -> bool: return float(R["nodes"][a]["s"]) < float(R["nodes"][b]["s"]))
	R["order"] = ks
	var st: Array = []
	for k: String in ks:
		var nd: Dictionary = R["nodes"][k]
		st.append([float(nd["s"]), float(nd["pad"]), float(nd["em"]), float(nd["ep"])])
	R["st"] = st
	# bus stops: every sgnl; a stop-controlled T when the last stop pair is >= BUS_SPACING back; W has its own
	var first := 0
	for i in ks.size():
		if String(R["nodes"][ks[i]]["ctl"]) == "sample": first = i
	var since := 0.0
	var last_s: float = R["nodes"][ks[first]]["s"]
	for j in ks.size():
		var nd: Dictionary = R["nodes"][ks[(first + j) % ks.size()]]
		var s: float = nd["s"]
		var dist := fposmod(s - last_s, path.length)
		var ctl := String(nd["ctl"])
		var bus := ctl == "signal" or ctl == "sample" or (ctl == "stop" and dist >= BUS_SPACING)
		nd["bus"] = bus and ctl != "sample"
		if bus: last_s = s
	# buildable ranges and grades
	for id: String in order:
		var bk: Dictionary = R["blocks"][id]
		var A: Dictionary = R["nodes"][bk["na"]]; var Bn: Dictionary = R["nodes"][bk["nb"]]
		bk["r0"] = float(bk["sa"]) + float(A["ep"]); bk["r1"] = float(bk["sb"]) - float(Bn["em"])
		var span: float = float(bk["r1"]) - float(bk["r0"])
		var g := 1.5 * absf(float(bk["rise"])) / maxf(span, 1.0) if span > 1.0 else 0.0
		if g > 0.08: push_warning("RG: block %s grade %.1f %%" % [id, g * 100.0])
		bk["grade"] = g
	_R = R
	return R

## ---------------------------------------------------------------------------------------- the W transitions
## W (the waterfront sample, (570, 200), yaw 90) carries the ring on its own s_wfd legs, straight for 100 m to (570, 100)
## and (570, 300). Those two points are the ring polygon's corner VERTICES: the skeleton's fillets leave W's line 68 m
## (south) and 87 m (north) out, ~10 m inside the leg ends, so no path can follow both. The transitions are biarcs (two
## tangent arcs) from each leg end to a point J on the fitted ring: south, on Ocean Blvd's straight before the (470, 335)
## corner; north, the 10th St T's tile edge. Along them the section morphs from the boulevard to s_apt (a decision for
## Yasin: the ring leaves the locked skeleton line there by up to ~20 m, see the report).
static func _w_joins(R: Dictionary, nd: Dictionary) -> Dictionary:
	var path: Path = R["path"]
	var o := Vector2(float(nd["u"]), float(nd["v"]))
	var out := {}
	# south: J on Ocean Blvd 15 m west of where its straight ends (the (470, 335) fillet starts at about u 463)
	var sJs := path.project(Vector2(448.0, 336.0)).x
	var Es := o + Vector2(0.0, 100.0)
	var ps := biarc(path.point(sJs), path.tangent(sJs), Es, Vector2(0.0, -1.0))
	out["S"] = {"sJ": sJs, "E": Es, "path": ps, "from_ring": true}
	# north: from the leg end to the 10th St T's tile edge
	var kt := nkey(626.5, 0.0)
	var T: Dictionary = R["nodes"][kt]
	var sJn: float = float(T["s"]) - float(T["em"])
	var En := o + Vector2(0.0, -100.0)
	var pn := biarc(En, Vector2(0.0, -1.0), path.point(sJn), path.tangent(sJn))
	out["N"] = {"sJ": sJn, "E": En, "path": pn, "from_ring": false}
	return out

## two circular arcs, tangent where they meet, from (p0, t0) to (p1, t1) (unit tangents; equal tangent lengths)
static func biarc(p0: Vector2, t0: Vector2, p1: Vector2, t1: Vector2) -> Path:
	var v := p1 - p0
	var tt := t0 + t1
	var den := 2.0 * (1.0 - t0.dot(t1))
	var d := 0.0
	if absf(den) < 1e-6: d = v.length() * 0.5
	else: d = (-v.dot(tt) + sqrt(v.dot(tt) * v.dot(tt) + den * v.length_squared())) / den
	var q0 := p0 + t0 * d; var q1 := p1 - t1 * d
	var pm := (q0 + q1) * 0.5
	var path := Path.new()
	_arc_to(path, p0, t0, pm)
	_arc_to(path, pm, (q1 - q0).normalized(), p1)
	return path

static func _arc_to(path: Path, a: Vector2, ta: Vector2, b: Vector2) -> void:
	var c := b - a
	var n := Vector2(-ta.y, ta.x)
	var cn := c.dot(n)
	if absf(cn) < 1e-6:
		path.add_line(a, b); return
	var r := c.length_squared() / (2.0 * cn)
	var C := a + n * r
	var a0 := (a - C).angle(); var a1 := (b - C).angle()
	var ccw := Vector2(-(a - C).y, (a - C).x).dot(ta) > 0.0
	var sw := fposmod(a1 - a0, TAU) if ccw else -fposmod(a0 - a1, TAU)
	path.add_arc(C, absf(r), a0, sw)

## absolute ring road height at s (level pads on the tiles, smoothstep between the tile edges)
static func ring_h(s: float) -> float:
	var R := ring()
	var path: Path = R["path"]
	var st: Array = R["st"]
	var w := fposmod(s, path.length)
	var n := st.size()
	var i := n - 1
	for k in n:
		if float(st[k][0]) <= w: i = k
	if w < float(st[0][0]): w += path.length
	var j := (i + 1) % n
	var si: float = st[i][0]; var sj: float = st[j][0]
	if sj <= si: sj += path.length
	var a: float = si + float(st[i][3]); var b: float = sj - float(st[j][2])
	if w <= a: return float(st[i][1])
	if w >= b: return float(st[j][1])
	return float(st[i][1]) + (float(st[j][1]) - float(st[i][1])) * _ss((w - a) / (b - a))

## unwrapped s of a node near a reference s
static func _near(s: float, ref: float, L: float) -> float:
	return ref + _wrapa((s - ref) / L * TAU) / TAU * L

## ----------------------------------------------------------------------------------------------- T geometry
## Exact kerb returns where a straight stem (from o along ds) meets the ring kerb (possibly curved), the crosswalks,
## stop bars and the tile extents. Corner j = -1 / +1: the stem kerb at stem-lateral j * kerb (stem lateral = right of
## ds). The fillet centre lies on the stem kerb line offset by R into the block and at ring lateral sig*(KB + R).
static func _tgeom(path: Path, o: Vector2, s_n: float, ds: Vector2, sec: String, sgnl: bool) -> Dictionary:
	var sd: Dictionary = SEC[sec]
	var ks: float = sd["kerb"]; var psd: float = sd["prop"]; var R: float = sd["R"]
	var ns := Vector2(-ds.y, ds.x)
	var sig := signf(path.project(o + ds * 40.0).y)
	var corners: Array = []
	for j: float in [-1.0, 1.0]:
		var base := o + ns * j * (ks + R)
		var lo := 0.0; var hi := 90.0
		var flo := path.project(base).y - sig * (KB + R)
		for it in 60:
			var mid := (lo + hi) * 0.5
			if signf(path.project(base + ds * mid).y - sig * (KB + R)) == signf(flo): lo = mid
			else: hi = mid
		var zc := (lo + hi) * 0.5
		var c := base + ds * zc
		var s_t := _near(path.project(c).x, s_n, path.length)
		var Tr := path.at(s_t, sig * KB)
		var Ts := o + ns * j * ks + ds * zc
		var a0 := (Tr - c).angle(); var a1 := a0 + _wrapa((Ts - c).angle() - a0)
		var arc := K.arc(c, R, a0, a1, 18)
		# the corner's property-line meeting point X (stem prop line x ring prop line)
		var pb := o + ns * j * psd
		var lo2 := 0.0; var hi2 := 90.0
		var g0 := path.project(pb).y - sig * PR
		for it in 60:
			var mid := (lo2 + hi2) * 0.5
			if signf(path.project(pb + ds * mid).y - sig * PR) == signf(g0): lo2 = mid
			else: hi2 = mid
		var zX := (lo2 + hi2) * 0.5
		var X := pb + ds * zX
		var mid_dir := (arc[9] - c).normalized()     # from the centre toward the middle of the return (the corner)
		corners.append({"j": j, "c": c, "s_t": s_t, "Tr": Tr, "Ts": Ts, "z_t": zc, "arc": arc, "X": X, "zX": zX,
			"s_X": _near(path.project(X).x, s_n, path.length), "u": mid_dir})
	corners.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["s_t"]) < float(b["s_t"]))
	var clo: Dictionary = corners[0]; var chi: Dictionary = corners[1]
	var z_k := maxf(float(clo["z_t"]), float(chi["z_t"]))
	var tg := {"o": o, "s_n": s_n, "ds": ds, "ns": ns, "sig": sig, "sec": sec, "signal": sgnl, "ks": ks, "ps": psd,
		"R": R, "lo": clo, "hi": chi, "z_k": z_k}
	tg["z_xw"] = [z_k + XW_GAP, z_k + XW_GAP + XW_W]
	tg["z_stop"] = [z_k + XW_GAP + XW_W + STOP_GAP, z_k + XW_GAP + XW_W + STOP_GAP + STOP_W]
	tg["z_E"] = ceilf((float(tg["z_stop"][1]) + 1.5) * 2.0) / 2.0
	var slo: float = clo["s_t"]; var shi: float = chi["s_t"]
	if sgnl:
		tg["xw_lo"] = [slo - XW_GAP - XW_W, slo - XW_GAP]
		tg["xw_hi"] = [shi + XW_GAP, shi + XW_GAP + XW_W]
		tg["stop_lo"] = [slo - XW_GAP - XW_W - STOP_GAP - STOP_W, slo - XW_GAP - XW_W - STOP_GAP]     # +s approach
		tg["stop_hi"] = [shi + XW_GAP + XW_W + STOP_GAP, shi + XW_GAP + XW_W + STOP_GAP + STOP_W]     # -s approach
		tg["em"] = ceilf((s_n - float(tg["stop_lo"][0]) + 1.5) * 2.0) / 2.0
		tg["ep"] = ceilf((float(tg["stop_hi"][1]) - s_n + 1.5) * 2.0) / 2.0
	else:
		tg["em"] = ceilf((s_n - slo + 2.0) * 2.0) / 2.0
		tg["ep"] = ceilf((shi - s_n + 2.0) * 2.0) / 2.0
	return tg

## ========================================================================================== surface primitives
## piece context: the path, the origin (grid) the piece is authored about, the local road height ys(s) and the
## shared s cuts. Add every s edge (paint, ramps, polygon joins) to ctx.extra BEFORE _finalize.
static func _ctx(path: Path, o: Vector2, ys: Callable) -> Dictionary:
	return {"path": path, "ox": o.x, "oz": o.y, "ys": ys, "cuts": PackedFloat64Array(), "extra": []}

static func _finalize(ctx: Dictionary, s0: float, s1: float) -> void:
	var path: Path = ctx["path"]
	var hard: Array = [s0, s1]
	hard.append_array(path.breaks(s0, s1))
	for e: float in ctx["extra"]:
		if e > s0 + 1e-4 and e < s1 - 1e-4: hard.append(e)
	hard.sort()
	var hs: Array = []
	for v: float in hard:
		if hs.is_empty() or v - float(hs[hs.size() - 1]) > 2e-4: hs.append(v)
	var out := PackedFloat64Array()
	for i in hs.size() - 1:
		var a: float = hs[i]; var b: float = hs[i + 1]
		var step := STEP_ARC if path.is_arc((a + b) * 0.5) else STEP_LINE
		var n := maxi(1, ceili((b - a) / step - 1e-6))
		for k in n: out.append(lerpf(a, b, float(k) / n))
	out.append(float(hs[hs.size() - 1]))
	ctx["cuts"] = out

static func _sub(ctx: Dictionary, a: float, b: float) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.append(a)
	for c: float in ctx["cuts"]:
		if c > a + 2e-4 and c < b - 2e-4: out.append(c)
	out.append(b)
	return out

static func _F(ctx: Dictionary, s: float, t: float, y: float) -> Vector3:
	var tt := t
	if ctx.has("tmap"): tt = float((ctx["tmap"] as Callable).call(s, t))     # a section morph (W transitions)
	var p: Vector2 = (ctx["path"] as Path).at(s, tt)
	return Vector3(p.x - float(ctx["ox"]), y, p.y - float(ctx["oz"]))

static func _P(ctx: Dictionary, s: float, t: float, lift := KH) -> Vector3:
	return _F(ctx, s, t, float((ctx["ys"] as Callable).call(s)) + lift)

static func _L(ctx: Dictionary, p: Vector2) -> Vector2:
	return Vector2(p.x - float(ctx["ox"]), p.y - float(ctx["oz"]))

## the painted band: t0..t1 x s0..s1, paints [t0, s0, t1, s1, mat] (first match wins, "-" = hole), arrows from _arrow
static func _band(g: K.Ground, ctx: Dictionary, t0: float, t1: float, s0: float, s1: float, paints: Array, base := "asphalt", lift := 0.0, arrows: Array = []) -> void:
	var ys: Callable = ctx["ys"]
	var tset := {t0: true, t1: true}
	var inside: Array = []
	for a: Dictionary in arrows: inside.append([float(a["box"][0]), float(a["box"][1]), float(a["box"][2]), float(a["box"][3]), "-"])
	for p: Array in paints:
		var a0 := maxf(float(p[0]), t0); var a1 := minf(float(p[2]), t1)
		var b0 := maxf(float(p[1]), s0); var b1 := minf(float(p[3]), s1)
		if a1 - a0 < 1e-4 or b1 - b0 < 1e-4: continue
		inside.append([a0, b0, a1, b1, String(p[4])])
	for q: Array in inside:
		tset[float(q[0])] = true; tset[float(q[2])] = true
	var ta: Array = tset.keys(); ta.sort()
	var sc := _sub(ctx, s0, s1)
	for i in ta.size() - 1:
		var tA: float = ta[i]; var tB: float = ta[i + 1]
		if tB - tA < 1e-5 or tA < t0 - 1e-6 or tB > t1 + 1e-6: continue
		var tc := (tA + tB) * 0.5
		for j in sc.size() - 1:
			var sa := sc[j]; var sb := sc[j + 1]
			var scm := (sa + sb) * 0.5
			var m := base
			for q: Array in inside:
				if tc > float(q[0]) and tc < float(q[2]) and scm > float(q[1]) and scm < float(q[3]): m = String(q[4]); break
			if m == "-": continue
			var ya: float = float(ys.call(sa)) + lift; var yb: float = float(ys.call(sb)) + lift
			g.quad(m, _F(ctx, sa, tA, ya), _F(ctx, sb, tA, yb), _F(ctx, sb, tB, yb), _F(ctx, sa, tB, ya))
	for a: Dictionary in arrows: _arrow_fill(g, ctx, a, base, lift)

## register the s edges of paints / arrows
static func _reg(ctx: Dictionary, paints: Array, arrows: Array = []) -> void:
	for p: Array in paints:
		(ctx["extra"] as Array).append(float(p[1])); (ctx["extra"] as Array).append(float(p[3]))
	for a: Dictionary in arrows:
		(ctx["extra"] as Array).append(float(a["box"][1])); (ctx["extra"] as Array).append(float(a["box"][3]))

## a smooth arrow (site.gd arrow2) in (t, s): kind as the DRIVER sees it (left / right / through / left_through /
## through_right), lane centre t, tail s -> head s. (+t is the right of a +s driver; arrow2's frame has the driver's
## left on +x, so left and right are swapped before the call: the polygon then reads right on the ground.)
static func _arrow(kind: String, t: float, s_tail: float, s_head: float) -> Dictionary:
	var sw := {"left": "right", "right": "left", "left_through": "through_right", "through_right": "left_through", "through": "through"}
	return S.arrow2(String(sw[kind]), t, s_tail, s_head)

static func _densify(poly: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var p := poly[i]; var q := poly[(i + 1) % n]
		out.append(p)
		var k := ceili(absf(q.y - p.y) / step)
		for m in range(1, k): out.append(p.lerp(q, float(m) / k))
	return out

static func _split_at_t(poly: PackedVector2Array, c: float) -> Array:
	var pts: Array = []
	var n := poly.size()
	for i in n:
		var p := poly[i]; var q := poly[(i + 1) % n]
		pts.append(p)
		var dp := p.x - c; var dq := q.x - c
		if (dp < -1e-7 and dq > 1e-7) or (dp > 1e-7 and dq < -1e-7):
			pts.append(Vector2(c, lerpf(p.y, q.y, dp / (dp - dq))))
	var on: Array = []
	for i in pts.size():
		if absf((pts[i] as Vector2).x - c) < 1e-6: on.append(i)
	if on.size() < 2: return []
	var ia: int = on[0]; var ib: int = on[0]
	for i: int in on:
		if (pts[i] as Vector2).y < (pts[ia] as Vector2).y: ia = i
		if (pts[i] as Vector2).y > (pts[ib] as Vector2).y: ib = i
	var c1 := PackedVector2Array(); var k := ia
	for guard in pts.size() + 1:
		c1.append(pts[k])
		if k == ib: break
		k = (k + 1) % pts.size()
	var c2 := PackedVector2Array(); k = ib
	for guard in pts.size() + 1:
		c2.append(pts[k])
		if k == ia: break
		k = (k + 1) % pts.size()
	c2.reverse()
	var side := 0.0
	for p: Vector2 in c1: side += p.x - c
	return [c1, c2] if side < 0.0 else [c2, c1]

static func _tri_poly(g: K.Ground, ctx: Dictionary, poly: PackedVector2Array, m: String, lift: float) -> void:
	var p2 := PackedVector2Array()
	for p in poly:
		if p2.is_empty() or p2[p2.size() - 1].distance_to(p) > 1e-5: p2.append(p)
	if p2.size() > 2 and p2[0].distance_to(p2[p2.size() - 1]) < 1e-5: p2.remove_at(p2.size() - 1)
	var idx := Geometry2D.triangulate_polygon(p2)
	if idx.is_empty():
		push_warning("RG: arrow fill failed to triangulate"); return
	var ys: Callable = ctx["ys"]
	for k in range(0, idx.size(), 3):
		var a := p2[idx[k]]; var b := p2[idx[k + 1]]; var c := p2[idx[k + 2]]
		g.tri(m, _F(ctx, a.y, a.x, float(ys.call(a.y)) + lift), _F(ctx, b.y, b.x, float(ys.call(b.y)) + lift), _F(ctx, c.y, c.x, float(ys.call(c.y)) + lift))

## the arrow and the asphalt round it fill the arrow's box hole exactly; the box's long edges carry every shared s cut
static func _arrow_fill(g: K.Ground, ctx: Dictionary, a: Dictionary, base: String, lift: float) -> void:
	var bx: Array = a["box"]; var c: float = a["c"]
	var poly := _densify(a["poly"] as PackedVector2Array, 0.5)
	var hv := _split_at_t(poly, c)
	if hv.is_empty():
		push_warning("RG: arrow split failed"); return
	var t0: float = bx[0]; var s0: float = bx[1]; var t1: float = bx[2]; var s1: float = bx[3]
	var mid := _sub(ctx, s0, s1)
	var lo := PackedVector2Array([Vector2(c, s0)])
	for v: float in mid: lo.append(Vector2(t0, v))
	lo.append(Vector2(c, s1))
	var ch: PackedVector2Array = hv[0]
	for k in range(ch.size() - 1, -1, -1): lo.append(ch[k])
	var hi := PackedVector2Array([Vector2(c, s0)])
	hi.append_array(hv[1] as PackedVector2Array)
	hi.append(Vector2(c, s1))
	for k in range(mid.size() - 1, -1, -1): hi.append(Vector2(t1, mid[k]))
	_tri_poly(g, ctx, lo, base, lift)
	_tri_poly(g, ctx, hi, base, lift)
	var fm := String(a.get("fill", "white"))
	if fm != "": _tri_poly(g, ctx, poly, fm, lift)

## ramp zones of a strip: [a, b, ramp or null]
static func _zones(s0: float, s1: float, ramps: Array, flare: float) -> Array:
	var rs := ramps.duplicate()
	rs.sort_custom(func(p: Array, q: Array) -> bool: return float(p[0]) < float(q[0]))
	var out: Array = []
	var cur := s0
	for r: Array in rs:
		var a := maxf(float(r[0]) - float(r[1]) * 0.5 - flare, s0); var b := minf(float(r[0]) + float(r[1]) * 0.5 + flare, s1)
		if b <= a: continue
		if a > cur + 1e-4: out.append([cur, a, null])
		out.append([maxf(a, cur), b, r]); cur = b
	if cur < s1 - 1e-4: out.append([cur, s1, null])
	return out

## the s cuts a ramp needs (fine steps through the dip, exact flat-bottom edges)
static func _reg_ramps(ctx: Dictionary, ramps: Array, s0: float, s1: float, flare: float) -> void:
	var path: Path = ctx["path"]
	for r: Array in ramps:
		var c: float = r[0]; var w: float = r[1]
		var a := maxf(c - w * 0.5 - flare, s0); var b := minf(c + w * 0.5 + flare, s1)
		(ctx["extra"] as Array).append_array([a, b])
		# fine steps shared by every band only on a curve (there a vertex off a neighbour's chord would crack); on a
		# straight the ramp subdivides on its own (_strip), its neighbours' straight edges stay exact
		if _arc_in(path, a, b):
			var n := maxi(2, ceili((b - a) / RAMP_STEP))
			for k in n + 1: (ctx["extra"] as Array).append(lerpf(a, b, float(k) / n))
		for e: float in [c - w * 0.5, c + w * 0.5]:
			if e > a and e < b: (ctx["extra"] as Array).append(e)

## a walk / parkway strip from the kerb line tk out to `to` (any side), s0..s1, with directional kerb ramps
## [centre s, width] (run across the strip, flares along it, tactile 0.6 m at the bottom), and the kerb face
static func _arc_in(path: Path, a: float, b: float) -> bool:
	if path.is_arc(a) or path.is_arc(b) or path.is_arc((a + b) * 0.5): return true
	return not path.breaks(a, b).is_empty()

static func _strip(g: K.Ground, ctx: Dictionary, tk: float, to: float, s0: float, s1: float, ramps: Array, mat: String, run := 1.5, flare := 1.0, wall := true, tact := true) -> void:
	var ys: Callable = ctx["ys"]
	var path: Path = ctx["path"]
	var dir := signf(to - tk); var depth := absf(to - tk)
	for zn: Array in _zones(s0, s1, ramps, flare):
		var a: float = zn[0]; var b: float = zn[1]
		var sc := _sub(ctx, a, b)
		if zn[2] == null:
			for j in sc.size() - 1:
				var ya: float = float(ys.call(sc[j])) + KH; var yb: float = float(ys.call(sc[j + 1])) + KH
				g.quad(mat, _F(ctx, sc[j], tk, ya), _F(ctx, sc[j + 1], tk, yb), _F(ctx, sc[j + 1], to, yb), _F(ctx, sc[j], to, ya))
			if wall: _wall(g, ctx, tk, sc, dir, Callable())
			continue
		var r: Array = zn[2]; var c: float = r[0]; var w: float = r[1]
		if not _arc_in(path, a, b):
			var fine := PackedFloat64Array()
			var nf := maxi(2, ceili((b - a) / RAMP_STEP))
			for k in nf + 1: fine.append(lerpf(a, b, float(k) / nf))
			for e: float in [c - w * 0.5, c + w * 0.5]:
				if e > a and e < b: fine.append(e)
			fine.sort()
			sc = fine
		var drop := func(s: float, t: float) -> float:
			var ft := clampf(1.0 - t / run, 0.0, 1.0)
			var dsv := absf(s - c) - w * 0.5
			var fs := 1.0 if dsv <= 0.0 else clampf(1.0 - dsv / flare, 0.0, 1.0)
			return KH * ft * fs
		var nt := maxi(2, ceili(depth / RAMP_STEP))
		for j in sc.size() - 1:
			var sa := sc[j]; var sb := sc[j + 1]
			for i in nt:
				var ta := depth * float(i) / nt; var tb := depth * float(i + 1) / nt
				var m := "concrete"
				if tact and (ta + tb) * 0.5 < 0.6 and absf((sa + sb) * 0.5 - c) < w * 0.5: m = "tactile"
				g.quad(m, _F(ctx, sa, tk + dir * ta, float(ys.call(sa)) + KH - float(drop.call(sa, ta))),
					_F(ctx, sb, tk + dir * ta, float(ys.call(sb)) + KH - float(drop.call(sb, ta))),
					_F(ctx, sb, tk + dir * tb, float(ys.call(sb)) + KH - float(drop.call(sb, tb))),
					_F(ctx, sa, tk + dir * tb, float(ys.call(sa)) + KH - float(drop.call(sa, tb))))
		if wall: _wall(g, ctx, tk, sc, dir, drop)

static func _wall(g: K.Ground, ctx: Dictionary, tk: float, sc: PackedFloat64Array, dir: float, drop: Callable) -> void:
	var ys: Callable = ctx["ys"]
	var path: Path = ctx["path"]
	for j in sc.size() - 1:
		var sa := sc[j]; var sb := sc[j + 1]
		var ya: float = ys.call(sa); var yb: float = ys.call(sb)
		var da := 0.0 if drop.is_null() else float(drop.call(sa, 0.0))
		var db := 0.0 if drop.is_null() else float(drop.call(sb, 0.0))
		if KH - da < 0.002 and KH - db < 0.002: continue
		var o := path.normal((sa + sb) * 0.5) * (-dir)
		g.quad("curb", _F(ctx, sa, tk, ya), _F(ctx, sb, tk, yb), _F(ctx, sb, tk, yb + KH - db), _F(ctx, sa, tk, ya + KH - da), Vector3(o.x, 0.0, o.y), true)

## a plain surface strip t0..t1 with a constant lift (walks, planting strips, verges)
static func _plain(g: K.Ground, ctx: Dictionary, t0: float, t1: float, s0: float, s1: float, mat: String, lift := KH) -> void:
	_band(g, ctx, minf(t0, t1), maxf(t0, t1), s0, s1, [], mat, lift)

## a surface strip from |t| = ti out to a varying |t| = wfn(s) on side `side` (tapers)
static func _plain_var(g: K.Ground, ctx: Dictionary, side: float, ti: float, wfn: Callable, s0: float, s1: float, mat: String, lift := KH) -> void:
	var ys: Callable = ctx["ys"]
	var sc := _sub(ctx, s0, s1)
	for j in sc.size() - 1:
		var sa := sc[j]; var sb := sc[j + 1]
		var ya: float = float(ys.call(sa)) + lift; var yb: float = float(ys.call(sb)) + lift
		g.quad(mat, _F(ctx, sa, side * ti, ya), _F(ctx, sb, side * ti, yb), _F(ctx, sb, side * float(wfn.call(sb)), yb), _F(ctx, sa, side * float(wfn.call(sa)), ya))

## ------------------------------------------------------------------------------------ decal / prop helpers
static func _dec(dec: K.Decals, ctx: Dictionary, tile: int, s: float, t: float, across: float, along: float, yfn: Callable, tint: Color, rot := 0.0) -> void:
	var path: Path = ctx["path"]
	var tt := t
	if ctx.has("tmap"): tt = float((ctx["tmap"] as Callable).call(s, t))
	var p := _L(ctx, path.at(s, tt))
	dec.add(tile, p, _yaw(path.tangent(s)) + rot, across, along, yfn, tint)

## wheel paths and the dark centre stripe along one lane, in marks no longer than 4 m (they follow curves and slopes)
static func _lane_wear(dec: K.Decals, rr: RandomNumberGenerator, ctx: Dictionary, t: float, s0: float, s1: float, yr: Callable, a := 0.4) -> void:
	var s := s0 + rr.randf_range(0.0, 3.0)
	while s < s1 - 2.0:
		var L := minf(rr.randf_range(2.5, 4.0), s1 - s)
		for wp: float in [-0.85, 0.85]:
			_dec(dec, ctx, 14, s + L * 0.5, t + wp, 0.7, L, yr, Color(1, 1, 1, a * rr.randf_range(0.5, 0.8)))
		if rr.randf() < 0.5: _dec(dec, ctx, 6, s + L * 0.5, t, 0.8, L, yr, Color(1, 1, 1, a * 0.9))
		s += L + rr.randf_range(0.3, 2.5)

static func _cracks(dec: K.Decals, rr: RandomNumberGenerator, ctx: Dictionary, t0: float, t1: float, s0: float, s1: float, n: int, yr: Callable, sealed := 0.45) -> void:
	for i in n:
		var tint := Color(0.12, 0.12, 0.12, 0.95) if rr.randf() < sealed else Color(0.28, 0.27, 0.26, 0.9)
		_dec(dec, ctx, 0, rr.randf_range(s0, s1), rr.randf_range(t0, t1), rr.randf_range(1.2, 2.2), rr.randf_range(3.0, 5.0), yr, tint, rr.randf_range(0.0, 180.0))

## red kerb (face + top strip) along a kerb at t = tk (road on the side -dir), s a..b
static func _red_kerb(dec: K.Decals, ctx: Dictionary, tk: float, a: float, b: float, dir: float) -> void:
	var path: Path = ctx["path"]
	var ys: Callable = ctx["ys"]
	var n := maxi(1, ceili((b - a) / 1.5))
	for k in n:
		var sa := lerpf(a, b, float(k) / n); var sb := lerpf(a, b, float(k + 1) / n)
		var o := path.normal((sa + sb) * 0.5) * (-dir)
		var ya: float = ys.call(sa); var yb: float = ys.call(sb)
		dec.add_face(13, _F(ctx, sa, tk, ya), _F(ctx, sb, tk, yb), _F(ctx, sb, tk, yb + KH), _F(ctx, sa, tk, ya + KH), Vector3(o.x, 0.0, o.y), W.RED)
		var yfn := func(_x: float, _z: float) -> float: return (ya + yb) * 0.5 + KH
		_dec(dec, ctx, 13, (sa + sb) * 0.5, tk + dir * 0.075, 0.15, sb - sa, yfn, W.RED)

## height functions in a piece's local frame for decals (project back onto the path)
static func _yfns(ctx: Dictionary) -> Array:
	var path: Path = ctx["path"]
	var ys: Callable = ctx["ys"]
	var ox: float = ctx["ox"]; var oz: float = ctx["oz"]
	var yr := func(x: float, z: float) -> float: return float(ys.call(path.project(Vector2(x + ox, z + oz)).x))
	var yw := func(x: float, z: float) -> float: return float(ys.call(path.project(Vector2(x + ox, z + oz)).x)) + KH
	return [yr, yw]

static func _finish(root: Node3D, g: K.Ground, props: K.Props, dec: K.Decals, name: String, meta: Dictionary) -> void:
	for k: String in meta: root.set_meta(k, meta[k])
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: ground tris %d, props %d, decals %d" % [name, g.tri_count(), props.count(), dec.count])
	K.save_piece(root, name)

## ===================================================================================== boulevard: block layout
## The block's paint and furniture are laid out ONCE for the whole block (so dashes, palm rhythm, lamps run on across
## the split between two pieces of a block), then each piece takes what falls in its s range.
static var _BL := {}

static func block_layout(bid: String) -> Dictionary:
	if _BL.has(bid): return _BL[bid]
	var R := ring()
	var path: Path = R["path"]
	var bk: Dictionary = R["blocks"][bid]
	var A: Dictionary = R["nodes"][bk["na"]]; var B: Dictionary = R["nodes"][bk["nb"]]
	var S0: float = bk["r0"]; var S1: float = bk["r1"]
	var sA: float = bk["sa"]; var sB: float = bk["sb"]
	var inl: float = R["inland"]; var out := -inl
	var rr := W.rng_for("rg_block_" + bid)
	var tA: Dictionary = A["tg"]; var tB: Dictionary = B["tg"]
	var sigA: float = float(tA["sig"]) if not tA.is_empty() else 0.0
	var sigB: float = float(tB["sig"]) if not tB.is_empty() else 0.0
	var tA_ok := not tA.is_empty(); var tB_ok := not tB.is_empty()
	var sgA := String(A["ctl"]) == "signal"; var sgB := String(B["ctl"]) == "signal"
	var p: Array = []          # paints [t0, s0, t1, s1, mat] in unwrapped block s
	var arrows: Array = []
	# ---- bus zones (far side, the traffic LEAVING the T): +s leaving A drives on t > 0; -s leaving B on t < 0
	var bus: Array = []
	if bool(A.get("bus", false)) and S1 - S0 > 45.0:
		bus.append({"side": 1.0, "dir": 1.0, "s0": S0 + 3.0, "s1": S0 + 3.0 + BUS_LEN, "front": S0 + 3.0 + BUS_LEN})
	if bool(B.get("bus", false)) and S1 - S0 > 45.0:
		bus.append({"side": -1.0, "dir": -1.0, "s0": S1 - 3.0 - BUS_LEN, "s1": S1 - 3.0, "front": S1 - 3.0 - BUS_LEN})
	# ---- the centre lane: TWLTL (solid yellow edges, dashed inner yellows); a LEFT-TURN POCKET for the approach whose
	# left is the stem (its edge toward its own lanes turns solid white, arrows), a flush median (both edges solid
	# yellow, no dashes) for the approach whose left is the far side (nobody may turn there)
	var pkB := tB_ok and sigB < 0.0        # +s approaches B with the stem on its left (t < 0)
	var pkA := tA_ok and sigA > 0.0        # -s approaches A with the stem on its left (t > 0)
	var medB := tB_ok and not pkB; var medA := tA_ok and not pkA
	var e_pos: Array = []      # +TL edge: [s0, s1, mat]
	var e_neg: Array = []
	var a_end := S0 + (POCKET if (pkA or medA) else 0.0)
	var b_beg := S1 - (POCKET if (pkB or medB) else 0.0)
	e_pos.append([a_end, b_beg, "yellow"]); e_neg.append([a_end, b_beg, "yellow"])
	if pkA: e_pos.append([S0, a_end, "yellow"]); e_neg.append([S0, a_end, "white"])
	elif medA: e_pos.append([S0, a_end, "yellow"]); e_neg.append([S0, a_end, "yellow"])
	if pkB: e_pos.append([b_beg, S1, "white"]); e_neg.append([b_beg, S1, "yellow"])
	elif medB: e_pos.append([b_beg, S1, "yellow"]); e_neg.append([b_beg, S1, "yellow"])
	for e: Array in e_pos:
		if float(e[1]) - float(e[0]) > 0.01:
			if String(e[2]) == "white": p.append([TL - 0.2, e[0], TL - 0.05, e[1], "white"])
			else: p.append([TL - 0.15, e[0], TL - 0.05, e[1], "yellow"])
	for e: Array in e_neg:
		if float(e[1]) - float(e[0]) > 0.01:
			if String(e[2]) == "white": p.append([-TL + 0.05, e[0], -TL + 0.2, e[1], "white"])
			else: p.append([-TL + 0.05, e[0], -TL + 0.15, e[1], "yellow"])
	_dashes(p, [TL - 0.42, TL - 0.32], a_end + (6.0 if a_end > S0 else 0.0), b_beg - (6.0 if b_beg < S1 else 0.0), TW_DASH, "yellow")
	_dashes(p, [-TL + 0.32, -TL + 0.42], a_end + (6.0 if a_end > S0 else 0.0), b_beg - (6.0 if b_beg < S1 else 0.0), TW_DASH, "yellow")
	if pkB:
		for k: float in [9.0, 27.0]: arrows.append(_arrow("left", 0.0, S1 - k - 4.5, S1 - k))
	if pkA:
		for k: float in [9.0, 27.0]: arrows.append(_arrow("left", 0.0, S0 + k + 4.5, S0 + k))
	# ---- lane lines between the through lanes: dashed (global phase), solid for the last 20 m before a sgnl
	var l1p0 := S0; var l1p1 := S1 - (20.0 if sgB else 0.0)
	var l1n0 := S0 + (20.0 if sgA else 0.0); var l1n1 := S1
	_dashes(p, [L1 - 0.06, L1 + 0.06], l1p0, l1p1, DASH, "white")
	_dashes(p, [-L1 - 0.06, -L1 + 0.06], l1n0, l1n1, DASH, "white")
	if sgB: p.append([L1 - 0.06, l1p1, L1 + 0.06, S1, "white"])
	if sgA: p.append([-L1 - 0.06, S0, -L1 + 0.06, l1n0, "white"])
	# through arrows before a sgnl
	if sgB:
		arrows.append(_arrow("through", (TL + L1) * 0.5, S1 - 14.0, S1 - 9.5))
		arrows.append(_arrow("through_right" if sigB > 0.0 else "through", (L1 + L2) * 0.5, S1 - 14.0, S1 - 9.5))
	if sgA:
		arrows.append(_arrow("through", -(TL + L1) * 0.5, S0 + 14.0, S0 + 9.5))
		arrows.append(_arrow("through_right" if sigA < 0.0 else "through", -(L1 + L2) * 0.5, S0 + 14.0, S0 + 9.5))
	# ---- bike lane lines: solid; broken where cars cross them (the last 30 m before a right turn into the stem, and
	# along a bus zone, where the bus pulls in to the kerb)
	for side: float in [-1.0, 1.0]:
		var broken: Array = []
		if side > 0.0 and tB_ok and sigB > 0.0: broken.append([S1 - 30.0, S1])
		if side < 0.0 and tA_ok and sigA < 0.0: broken.append([S0, S0 + 30.0])
		for z: Dictionary in bus:
			if float(z["side"]) == side: broken.append([float(z["s0"]) - 4.0, float(z["s1"]) + 2.0])
		broken.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
		var cur := S0
		var tt: Array = [side * L2 - 0.08, side * L2 + 0.08]
		for br: Array in broken:
			var b0 := maxf(float(br[0]), S0); var b1 := minf(float(br[1]), S1)
			if b0 > cur: p.append([minf(tt[0], tt[1]), cur, maxf(tt[0], tt[1]), b0, "white"])
			var k := b0
			while k + 1.0 <= b1: p.append([minf(tt[0], tt[1]), k, maxf(tt[0], tt[1]), k + 1.0, "white"]); k += 2.0
			cur = maxf(cur, b1)
		if cur < S1: p.append([minf(tt[0], tt[1]), cur, maxf(tt[0], tt[1]), S1, "white"])
	# ---- furniture (each with its reason)
	var it: Array = []       # [base, cond, s, t, face, collide, scale]; face: "road" (+Z toward the road from that side),
							 # "out" (away from it), "fwd" (+s), "back" (-s), or a yaw offset in degrees added to "fwd"
	var taken := {-1.0: [], 1.0: []}     # [s, half] used in each parkway
	var pads: Array = []                 # [side, s0, s1] concrete through the parkway (bus boarding pads)
	var bays: Array = []                 # [s0, s1] paved bays in the promenade planting strip
	var red: Array = []                  # [side, s0, s1] red kerb
	var coast := String(bk["coast"])
	var prom := coast in ["beach", "bay"]
	for z: Dictionary in bus:
		var side: float = z["side"]; var dr: float = z["dir"]; var fr: float = z["front"]
		red.append([side, float(z["s0"]), float(z["s1"])])
		var pa := fr - dr * 9.5; var pb := fr - dr * 0.6
		pads.append([side, minf(pa, pb), maxf(pa, pb)])
		(taken[side] as Array).append([(pa + pb) * 0.5, 4.5 + 2.5])
		# the stop sign where the front door stops (traffic reads it from behind: faces the arriving bus)
		it.append(["prop_bus_stop_sign", "worn", fr - dr * 0.4, side * (KB + 0.45), "back" if dr > 0.0 else "fwd", true, 1.0])
		if side == out and prom:
			# promenade side: a shelter in a paved bay of the planting strip (the 4 m walk stays clear), a bin
			bays.append([minf(fr - dr * 10.0, fr - dr * 3.0), maxf(fr - dr * 10.0, fr - dr * 3.0)])
			it.append(["prop_bus_shelter", "worn", fr - dr * 6.5, side * (PW + 1.0), "road", true, 1.0])
			it.append(["prop_trash_receptacle", "dirty", fr - dr * 10.8, side * (PW - 0.5), 0.0, true, 1.0])
		else:
			# inland / plain side: the bench ON the boarding pad (people wait off the 2 m walk), a bin at its back end
			it.append(["prop_bench_bus_stop", "worn", fr - dr * 5.4, side * (PK - 0.45), "road", true, 1.0])
			it.append(["prop_trash_receptacle", "dirty", fr - dr * 8.6, side * (PK - 0.4), 0.0, true, 1.0])
	# cobra lamps over the road, both sides, staggered (block-global rhythm); one at the back end of a bus zone
	for side: float in [-1.0, 1.0]:
		var s := sA + (14.0 if side > 0.0 else 37.0)
		while s < S1 - 2.0:
			if s > S0 + 2.0:
				var ss := s
				for z: Dictionary in bus:
					if float(z["side"]) == side and ss > float(z["s0"]) - 3.0 and ss < float(z["s1"]) + 3.0:
						ss = float(z["s0"]) - 1.5 if float(z["dir"]) > 0.0 else float(z["s1"]) + 1.5
				if ss > S0 + 1.0 and ss < S1 - 1.0:
					it.append(["prop_lamp_cobra", "worn", ss, side * (KB + 0.9), "road", true, 1.0])
					(taken[side] as Array).append([ss, 3.0])
			s += 46.0
	# hydrants every ~140 m, alternating sides, in the parkway at the kerb; red kerb 4.5 m each way (no stopping)
	var hk := 0
	var hs := sA + 62.0
	while hs < S1 - 5.0:
		var side := 1.0 if hk % 2 == 0 else -1.0
		var hh := hs
		for z: Dictionary in bus:
			if float(z["side"]) == side and hh > float(z["s0"]) - 6.0 and hh < float(z["s1"]) + 6.0: hh = float(z["s1"]) + 7.0
		if hh > S0 + 5.0 and hh < S1 - 5.0:
			it.append(["prop_hydrant_red", "rusty" if rr.randf() < 0.4 else "worn", hh, side * (KB + 0.7), "road", true, 1.0])
			red.append([side, hh - 4.5, hh + 4.5])
			(taken[side] as Array).append([hh, 2.5])
		hk += 1; hs += 140.0
	# NO PARKING (bike lanes) every ~95 m each side, facing the traffic on that side
	for side: float in [-1.0, 1.0]:
		var s2 := sA + (52.0 if side > 0.0 else 75.0)
		while s2 < S1 - 4.0:
			if s2 > S0 + 4.0 and _free(taken[side], s2, 1.6):
				it.append(["prop_sign_no_parking", "worn", s2, side * (KB + 0.35), "back" if side > 0.0 else "fwd", true, 1.0])
				(taken[side] as Array).append([s2, 1.0])
			s2 += 95.0
	# speed limit for the traffic leaving each T (Coronado's boulevards are 25 mph), 45 m on, on its right
	if tA_ok and S1 - S0 > 60.0 and _free(taken[1.0], S0 + 45.0, 1.6):
		it.append(["prop_sign_speed25", "worn", S0 + 45.0, KB + 0.35, "back", true, 1.0]); (taken[1.0] as Array).append([S0 + 45.0, 1.0])
	if tB_ok and S1 - S0 > 60.0 and _free(taken[-1.0], S1 - 45.0, 1.6):
		it.append(["prop_sign_speed25", "worn", S1 - 45.0, -(KB + 0.35), "fwd", true, 1.0]); (taken[-1.0] as Array).append([S1 - 45.0, 1.0])
	# kerb inlets: water runs to the low end of the block (both kerbs); a flat block drains every ~70 m
	var inlets: Array = []
	if absf(float(bk["rise"])) > 0.05:
		var low := S0 + 8.0 if float(bk["rise"]) > 0.0 else S1 - 8.0     # the T tile has its own inlet at its edge
		inlets.append([low, 1.0]); inlets.append([low, -1.0])
	else:
		var q := sA + 35.0; var qk := 0
		while q < S1 - 3.0:
			if q > S0 + 3.0: inlets.append([q, 1.0 if qk % 2 == 0 else -1.0])
			q += 70.0; qk += 1
	for e: Array in inlets:
		var ok := true
		for z: Dictionary in bus:
			if float(z["side"]) == float(e[1]) and float(e[0]) > float(z["s0"]) - 1.0 and float(e[0]) < float(z["s1"]) + 1.0: ok = false
		if ok: it.append(["prop_storm_drain_curb_inlet", "dirty", float(e[0]), float(e[1]) * KB, "road", false, 1.0])
	# sewer manholes in the lanes every ~75 m
	var ms := sA + 30.0; var mk := 0
	while ms < S1 - 3.0:
		if ms > S0 + 3.0: it.append(["prop_manhole_cover", "worn", ms, (3.5 if mk % 2 == 0 else -7.0), "fwd", false, 1.0])
		ms += 75.0; mk += 1
	# ---- promenade (coast side facing the water): bench bays, pier lamps, planting
	var plant: Array = []    # [s, t, model, scale] in the planting strip
	if prom:
		var bs := sA + 21.0; var bkk := 0
		while bs < S1 - 4.0:
			if bs > S0 + 4.0 and _free_bays(bays, bs, 3.0):
				bays.append([bs - 2.2, bs + 2.2])
				if bkk % 4 == 2:
					# a bike bay (people ride the promenade to the beach): the rack parallel to the walk, a bin
					it.append(["prop_bike_rack", "worn", bs - 0.3, out * (PW + 0.9), "out", true, 1.0])
					it.append(["prop_trash_receptacle", "worn", bs + 1.75, out * (PW + 0.55), 0.0, true, 1.0])
				else:
					it.append(["prop_park_bench", "worn", bs, out * (PW + 1.15), "out", true, 1.0])     # facing the water
					it.append(["prop_trash_receptacle", "worn", bs + 1.75, out * (PW + 0.55), 0.0, true, 1.0])
					if bkk % 4 == 1: it.append(["prop_drinking_fountain", "worn", bs - 1.6, out * (PW + 0.5), "road", true, 1.0])
					if bkk % 4 == 0 and coast == "beach": it.append(["prop_beach_sign_rules", "worn", bs - 1.8, out * (PW + 1.6), "road", true, 1.0])
				bkk += 1
			bs += 38.0
		var ls := sA + 9.0
		while ls < S1 - 2.0:
			if ls > S0 + 2.0 and _free_bays(bays, ls, 1.0):
				it.append(["prop_pier_lamp", "worn", ls, out * (PW - 0.35), "road", true, 1.0])
			ls += 24.0
		# the planting strip: succulents every ~3.5 m, a canary date palm between bays (~45 m)
		var ps := S0 + 1.5
		while ps < S1 - 1.5:
			if _free_bays(bays, ps, 1.2):
				var m := "plant_agave_americana_small" if rr.randf() < 0.55 else ("plant_bird_of_paradise" if rr.randf() < 0.7 else "plant_agave_americana")
				plant.append([ps, out * (PW + rr.randf_range(0.7, 1.3)), m, rr.randf_range(0.8, 1.15)])
			ps += rr.randf_range(2.8, 4.2)
		var cps := sA + 40.0
		while cps < S1 - 6.0:
			if cps > S0 + 6.0 and _free_bays(bays, cps, 3.5):
				plant.append([cps, out * (PW + 1.0), "palm_canary_date_a" if rr.randf() < 0.5 else "palm_canary_date_b", rr.randf_range(0.85, 1.1)])
			cps += 45.0
	# ---- parkway palms: a planted scheme per block (fan only / fan and queen alternating / runs of queens), mixed ages
	var scheme: String = ["fan", "alt", "queen_runs"][rr.randi() % 3]
	var palms: Array = []
	var pk_i := 0
	for side: float in [-1.0, 1.0]:
		var s3 := S0 + 2.0 + (rr.randf_range(4.0, 7.0) if side > 0.0 else rr.randf_range(0.0, 2.5))
		var run_q := false
		while s3 < S1 - 2.0:
			var near_j := absf(s3 - sA) < SIGHT or absf(s3 - sB) < SIGHT
			var ok := not near_j and _free(taken[side], s3, 2.6)
			for pd: Array in pads:
				if float(pd[0]) == side and s3 > float(pd[1]) - 3.5 and s3 < float(pd[2]) + 3.5: ok = false     # 2.5 m clear of the sign
			if ok:
				if rr.randf() < 0.05:
					palms.append([s3, side * (KB + 1.0), "", 1.0])     # a dead palm taken out, never replaced: a worn patch
				else:
					var model := ""
					match scheme:
						"fan": model = ["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"][rr.randi() % 3]
						"alt": model = ("palm_mexican_fan_a" if rr.randf() < 0.5 else "palm_mexican_fan_c") if pk_i % 2 == 0 else ("palm_queen_a" if rr.randf() < 0.5 else "palm_queen_b")
						_:
							if rr.randf() < 0.3: run_q = not run_q
							model = ("palm_queen_a" if rr.randf() < 0.5 else "palm_queen_b") if run_q else ["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"][rr.randi() % 3]
					var sc := rr.randf_range(0.85, 1.15)
					if rr.randf() < 0.08: sc = rr.randf_range(0.62, 0.72)      # a young replacement
					palms.append([s3, side * (KB + 1.0), model, sc])
				pk_i += 1
				s3 += rr.randf_range(10.5, 12.5)
			else:
				s3 += 1.0
	var lay := {"paint": p, "arrows": arrows, "items": it, "pads": pads, "bays": bays, "red": red, "palms": palms,
		"plant": plant, "bus": bus, "scheme": scheme, "S0": S0, "S1": S1, "prom": prom, "coast": coast}
	_BL[bid] = lay
	return lay

static func _free(lst: Array, s: float, half: float) -> bool:
	for e: Array in lst:
		if absf(s - float(e[0])) < half + float(e[1]) * 0.5: return false
	return true

static func _free_bays(bays: Array, s: float, half: float) -> bool:
	for b: Array in bays:
		if s > float(b[0]) - half and s < float(b[1]) + half: return false
	return true

## dashed line [t0, t1] along s0..s1, dash phase global along the loop (continuous across pieces)
static func _dashes(p: Array, tt: Array, s0: float, s1: float, pat: Array, mat: String) -> void:
	var on: float = pat[0]; var cyc: float = pat[1]
	var k := floorf(s0 / cyc) * cyc
	while k < s1:
		var a := maxf(k, s0); var b := minf(k + on, s1)
		if b - a > 0.3: p.append([float(tt[0]), a, float(tt[1]), b, mat])
		k += cyc

## ================================================================================ boulevard: piece plan + build
## The pieces of a ring block: [{name, bid, s0, s1, i, n}] covering its buildable range (between the tile edges of its
## two end nodes) in near-equal parts no longer than PIECE_MAX. W (sample) ends are not served yet (transition, stage 2).
static func block_plan(bid: String) -> Array:
	var R := ring()
	var bk: Dictionary = R["blocks"][bid]
	var S0: float = bk["r0"]; var S1: float = bk["r1"]
	var out: Array = []
	if S1 - S0 < 1.0: return out      # nothing left between the tiles (b136: W's north transition carries it all)
	# the ferry landing (a hand-made hero junction later) cuts a 45 m gap out of the block it lies on
	var ranges: Array = [[S0, S1]]
	var fg := ferry_gap_s()
	if fg[0] > S0 and fg[1] < S1: ranges = [[S0, fg[0]], [fg[1], S1]]
	var idx := 0
	for r: Array in ranges:
		var a: float = r[0]; var b: float = r[1]
		var n := maxi(1, ceili((b - a) / PIECE_MAX))
		for i in n:
			idx += 1
			out.append({"name": "s_rg_%s_%d" % [bid, idx], "bid": bid, "s0": lerpf(a, b, float(i) / n), "s1": lerpf(a, b, float(i + 1) / n), "i": idx, "n": 0})
	for e: Dictionary in out: e["n"] = out.size()
	return out

## the ferry gap along the loop [s0, s1] (unwrapped near the ferry point)
static func ferry_gap_s() -> Array:
	var path: Path = ring()["path"]
	var sf := path.project(FERRY).x
	return [sf - GAP * 0.5, sf + GAP * 0.5]

static func ferry_gap() -> Array:
	var fg := ferry_gap_s()
	var path: Path = ring()["path"]
	var a := path.point(fg[0]); var b := path.point(fg[1])
	return [[a.x, ring_h(fg[0]), a.y], [b.x, ring_h(fg[1]), b.y]]

## Build boulevard piece `part` (1-based) of ring block bid.
static func build_boulevard(bid: String, part: int) -> void:
	S.hill_on = false
	var R := ring()
	var path: Path = R["path"]
	var pl: Dictionary = block_plan(bid)[part - 1]
	var name: String = pl["name"]
	var s0: float = pl["s0"]; var s1: float = pl["s1"]
	var bk: Dictionary = R["blocks"][bid]
	var lay := block_layout(bid)
	var inl: float = R["inland"]; var out := -inl
	var o := path.point(s0); var oy := ring_h(s0)
	var ys := func(s: float) -> float: return ring_h(s) - oy
	var ctx := _ctx(path, o, ys)
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var prom: bool = lay["prom"]
	var ow: float = bk["outer"]
	# ---- what lies in this piece
	var paints: Array = []
	for q: Array in lay["paint"]:
		if float(q[3]) > s0 and float(q[1]) < s1: paints.append(q)
	var arrows: Array = []
	for a: Dictionary in lay["arrows"]:
		if float(a["box"][1]) >= s0 - 1e-3 and float(a["box"][3]) <= s1 + 1e-3: arrows.append(a)
	_reg(ctx, paints, arrows)
	# parkway on each side: grass, concrete boarding pads at bus stops
	var pk_cuts := {-1.0: [], 1.0: []}
	for pd: Array in lay["pads"]:
		if float(pd[2]) > s0 and float(pd[1]) < s1:
			(pk_cuts[float(pd[0])] as Array).append([maxf(float(pd[1]), s0), minf(float(pd[2]), s1)])
			(ctx["extra"] as Array).append(float(pd[1])); (ctx["extra"] as Array).append(float(pd[2]))
	var bays: Array = []
	for b: Array in lay["bays"]:
		if float(b[1]) > s0 and float(b[0]) < s1:
			bays.append([maxf(float(b[0]), s0), minf(float(b[1]), s1)])
			(ctx["extra"] as Array).append(float(b[0])); (ctx["extra"] as Array).append(float(b[1]))
	for e: float in [s0, s1]:      # a smooth taper needs short cells (2 m) over its 20 m
		for k in 11: (ctx["extra"] as Array).append(e + (2.0 * k if e == s0 else -2.0 * k))
	_finalize(ctx, s0, s1)
	# ---- carriageway (paint cut into the asphalt), kerbs, parkways, walks
	_band(g, ctx, -KB, KB, s0, s1, paints, "asphalt", 0.0, arrows)
	for side: float in [-1.0, 1.0]:
		var cur := s0
		var segs: Array = (pk_cuts[side] as Array).duplicate()
		segs.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
		for sg: Array in segs:
			if float(sg[0]) > cur: _strip(g, ctx, side * KB, side * PK, cur, float(sg[0]), [], "grass")
			_strip(g, ctx, side * KB, side * PK, float(sg[0]), float(sg[1]), [], "concrete")
			cur = float(sg[1])
		if cur < s1: _strip(g, ctx, side * KB, side * PK, cur, s1, [], "grass")
		if side == out and prom:
			_plain(g, ctx, side * PK, side * PW, s0, s1, "plaza")
			var c2 := s0
			for b: Array in bays:
				if float(b[0]) > c2: _plain(g, ctx, side * PW, side * PROM, c2, float(b[0]), "mulch", KH - 0.04)
				_plain(g, ctx, side * PW, side * PROM, float(b[0]), float(b[1]), "plaza")
				c2 = float(b[1])
			if c2 < s1: _plain(g, ctx, side * PW, side * PROM, c2, s1, "mulch", KH - 0.04)
			# the planting strip sits 4 cm below the walk: a low edging face along both its edges (no gap)
			_edge_faces(g, ctx, side, s0, s1, bays)
			# where the promenade ends at a W transition, the strip's end face too (the transition's walk is level)
			for e3: Array in [[s0, String(R["nodes"][bk["na"]]["ctl"]), 1.0], [s1, String(R["nodes"][bk["nb"]]["ctl"]), -1.0]]:
				if String(e3[1]) != "sample" or not _free_bays(bays, float(e3[0]), 0.01): continue
				var se3: float = e3[0]
				var y3: float = float(ys.call(se3)) + KH
				var tg3 := path.tangent(se3) * float(e3[2])
				g.quad("curb", _F(ctx, se3, side * PW, y3 - 0.04), _F(ctx, se3, side * PROM, y3 - 0.04), _F(ctx, se3, side * PROM, y3), _F(ctx, se3, side * PW, y3), Vector3(-tg3.x, 0, -tg3.y), true)
		elif side == out:
			# a plain walk (golf course / base fence side); where it meets a junction whose far side is a promenade
			# (the next block faces the water), the walk widens to it over 20 m (smoothstep) so the property line
			# never steps
			var wA: float = float(R["nodes"][bk["na"]]["outer"]) if absf(s0 - float(bk["r0"])) < 0.01 else ow
			var wB: float = float(R["nodes"][bk["nb"]]["outer"]) if absf(s1 - float(bk["r1"])) < 0.01 else ow
			var wfn := func(sv: float) -> float:
				var w := ow
				if wA > ow + 0.01: w = maxf(w, ow + (wA - ow) * (1.0 - _ss((sv - s0) / 20.0)))
				if wB > ow + 0.01: w = maxf(w, ow + (wB - ow) * (1.0 - _ss((s1 - sv) / 20.0)))
				return w
			_plain_var(g, ctx, side, PK, wfn, s0, s1, "concrete")
		else:
			_plain(g, ctx, side * PK, side * PR, s0, s1, "concrete")
	# ---- props
	var yy := _yfns(ctx)
	var yr: Callable = yy[0]; var yw: Callable = yy[1]
	for e: Array in lay["items"]:
		var s: float = e[2]
		if s < s0 or s >= s1: continue
		var t: float = e[3]
		var lift := KH
		if String(e[0]) in ["prop_storm_drain_curb_inlet", "prop_manhole_cover"]: lift = 0.0 if String(e[0]).contains("inlet") else 0.002
		props.add(String(e[0]), String(e[1]), _P(ctx, s, t, lift), _face(path, s, t, e[4]), bool(e[5]), float(e[6]))
	for pm: Array in lay["palms"]:
		var s: float = pm[0]
		if s < s0 or s >= s1: continue
		if String(pm[2]) == "":
			_dec(dec, ctx, 14, s, float(pm[1]), 1.2, 1.2, yw, Color(0.75, 0.68, 0.55, 0.55), rr.randf_range(0, 90))
			continue
		props.add(String(pm[2]), "normal", _P(ctx, s, float(pm[1]), KH - 0.06), rr.randf_range(0.0, 360.0), true, float(pm[3]))
	for pm: Array in lay["plant"]:
		var s: float = pm[0]
		if s < s0 or s >= s1: continue
		props.add(String(pm[2]), "normal", _P(ctx, s, float(pm[1]), KH - 0.04), rr.randf_range(0.0, 360.0), String(pm[2]).begins_with("palm"), float(pm[3]))
	for rk: Array in lay["red"]:
		var a := maxf(float(rk[1]), s0); var b := minf(float(rk[2]), s1)
		if b - a > 0.2: _red_kerb(dec, ctx, float(rk[0]) * KB, a, b, float(rk[0]))
	# ---- wear (where the thing that makes it happens)
	for side: float in [-1.0, 1.0]:
		_lane_wear(dec, rr, ctx, side * (TL + L1) * 0.5, s0, s1, yr, 0.4)
		_lane_wear(dec, rr, ctx, side * (L1 + L2) * 0.5, s0, s1, yr, 0.45)
		_cracks(dec, rr, ctx, side * 2.0, side * 9.5, s0 + 1.0, s1 - 1.0, int((s1 - s0) / 9.0), yr, 0.55)   # the city seals its boulevards
		# gutter: grit and palm litter in the bike lane edge; on the coast side sand blown into it
		var gz := s0 + 1.0
		while gz < s1 - 1.5:
			var L := rr.randf_range(1.6, 2.8)
			var sandy: bool = side == out and String(lay["coast"]) in ["beach", "bay"]
			_dec(dec, ctx, 14, gz + L * 0.5, side * (KB - 0.3), 0.55, L, yr, Color(0.9, 0.82, 0.62, rr.randf_range(0.55, 0.8)) if sandy else Color(0.95, 0.9, 0.82, rr.randf_range(0.4, 0.62)))
			gz += L + rr.randf_range(1.5, 4.5)
		# the walking line: dirt where people walk (the promenade more, the plain walks less)
		var wz := s0 + 0.5
		var t_walk := side * (PK + 1.0) if not (side == out and prom) else side * rr.randf_range(PK + 1.0, PW - 1.0)
		while wz < s1 - 1.0:
			var Lw := rr.randf_range(2.0, 4.0)
			var pa := rr.randf_range(0.1, 0.2) if (side == out and prom) else rr.randf_range(0.22, 0.42)     # light paving shows dirt darker
			_dec(dec, ctx, 14, wz + Lw * 0.5, t_walk, 1.2, Lw, yw, Color(1, 1, 1, pa))
			wz += Lw + rr.randf_range(2.0, 6.0)
	if prom:
		for k in int((s1 - s0) / 7.0):     # sand carried up from the beach on feet: soft drifts along the walk (no squares)
			_dec(dec, ctx, 14, rr.randf_range(s0 + 2.0, s1 - 2.0), out * rr.randf_range(PK + 0.6, PW - 0.6), rr.randf_range(0.9, 1.6), rr.randf_range(2.0, 3.6), yw, Color(0.88, 0.8, 0.6, rr.randf_range(0.12, 0.22)), rr.randf_range(-12, 12))     # faint: the grime tile reads as stains on light paving
	# utility cuts: a trench patched across half the road, dark patches round some manholes
	if s1 - s0 > 30.0:      # a service trench cut along the inner lane and patched: a long narrow strip in 4 m pieces
		var tz := rr.randf_range(s0 + 4.0, s1 - 16.0)
		var tl := (TL + L1) * 0.5 * (1.0 if rr.randf() < 0.5 else -1.0) + rr.randf_range(-0.6, 0.6)
		for k in 3: _dec(dec, ctx, 3, tz + 2.0 + k * 4.0, tl, 0.8, 4.0, yr, Color(1, 1, 1, 0.6))
	for e: Array in lay["items"]:
		if String(e[0]) == "prop_manhole_cover" and float(e[2]) >= s0 and float(e[2]) < s1 and rr.randf() < 0.6:
			_dec(dec, ctx, 2, float(e[2]), float(e[3]), 2.2, 2.2, yr, Color(1, 1, 1, 0.75))
	# bus zones: the bus idles there (oil), people stand on the pad and step through the parkway (worn grass)
	for z: Dictionary in lay["bus"]:
		var fr: float = z["front"]; var dr: float = z["dir"]; var side: float = z["side"]
		if fr < s0 - 20.0 or fr > s1 + 20.0: continue
		for k in 4:
			var s := fr - dr * rr.randf_range(2.0, 11.0)
			if s > s0 + 1.0 and s < s1 - 1.0: W.oil(dec, rr, _L(ctx, path.at(s, side * (L2 + 0.4))), _yaw(path.tangent(s)), yr, 0.8)
		var pm := fr - dr * 5.0
		if pm > s0 + 3.0 and pm < s1 - 3.0: _dec(dec, ctx, 14, pm, side * (KB + 1.0), 1.6, 7.0, yw, Color(1, 1, 1, 0.55))
	# braking marks before a sgnl: in the last 14 m of the approach lanes
	for e2: Array in [[R["nodes"][bk["nb"]], 1.0], [R["nodes"][bk["na"]], -1.0]]:
		var nd: Dictionary = e2[0]; var dr2: float = e2[1]
		if String(nd["ctl"]) != "signal": continue
		var se: float = lay["S1"] if dr2 > 0.0 else lay["S0"]
		if (dr2 > 0.0 and absf(s1 - se) > 0.01) or (dr2 < 0.0 and absf(s0 - se) > 0.01): continue
		for lane: float in [(TL + L1) * 0.5, (L1 + L2) * 0.5]:
			for wp: float in [-0.8, 0.8]:
				var sm := se - dr2 * 6.0
				_dec(dec, ctx, 8, sm, dr2 * (lane + wp), 0.45, 6.0, yr, Color(1, 1, 1, 0.45))
			W.oil(dec, rr, _L(ctx, path.at(se - dr2 * 3.0, dr2 * lane)), _yaw(path.tangent(se)), yr, 0.7)
	var site := {"site": bid, "part": part, "kind": "boulevard", "pos": [o.x, oy, o.y], "yaw": 0.0, "s": [s0, s1],
		"block": bk["name"], "coast": bk["coast"], "scheme": lay["scheme"]}
	_finish(root, g, props, dec, name, {"rg": site})

## the planting strip's low edging (4 cm) along the walk side and its far side, and at the bay ends
static func _edge_faces(g: K.Ground, ctx: Dictionary, side: float, s0: float, s1: float, bays: Array) -> void:
	var ys: Callable = ctx["ys"]
	var path: Path = ctx["path"]
	var runs: Array = []
	var cur := s0
	for b: Array in bays:
		if float(b[0]) > cur: runs.append([cur, float(b[0])])
		cur = float(b[1])
	if cur < s1: runs.append([cur, s1])
	for r: Array in runs:
		var sc := _sub(ctx, float(r[0]), float(r[1]))
		for tline: float in [side * PW, side * PROM]:
			var dir := -side if absf(tline) < PW + 0.1 else side
			for j in sc.size() - 1:
				var sa := sc[j]; var sb := sc[j + 1]
				var ya: float = float(ys.call(sa)) + KH; var yb: float = float(ys.call(sb)) + KH
				var on := path.normal((sa + sb) * 0.5) * dir
				g.quad("curb", _F(ctx, sa, tline, ya - 0.04), _F(ctx, sb, tline, yb - 0.04), _F(ctx, sb, tline, yb), _F(ctx, sa, tline, ya), Vector3(on.x, 0, on.y), true)
		for e: float in [float(r[0]), float(r[1])]:
			if absf(e - s0) < 1e-3 or absf(e - s1) < 1e-3: continue
			var y: float = float(ys.call(e)) + KH
			var tg := path.tangent(e) * (1.0 if absf(e - float(r[0])) < 1e-3 else -1.0)
			g.quad("curb", _F(ctx, e, side * PW, y - 0.04), _F(ctx, e, side * PROM, y - 0.04), _F(ctx, e, side * PROM, y), _F(ctx, e, side * PW, y), Vector3(-tg.x, 0, -tg.y), true)

## yaw of a prop at (s, t) from a face code
static func _face(path: Path, s: float, t: float, f: Variant) -> float:
	var d := path.tangent(s); var n := path.normal(s)
	var side := signf(t) if absf(t) > 0.01 else 1.0
	if typeof(f) == TYPE_FLOAT or typeof(f) == TYPE_INT: return _yaw(d) + float(f)
	match String(f):
		"road": return _yaw(-n * side)
		"out": return _yaw(n * side)
		"fwd": return _yaw(d)
		"back": return _yaw(-d)
	return 0.0

## =========================================================================================== T-junction (b)
## j_rg_<node>: a stem of any section (SEC) meets the ring at its actual angle. Level pad at the node's height. Origin =
## the junction centre on the path. The ring tile runs s_n - em .. s_n + ep; the stem tile runs from the ring out to
## z_E along the stem (the stub / lattice leg starts there).
static func build_t(key: String) -> void:
	S.hill_on = false
	var R := ring()
	var path: Path = R["path"]
	var nd: Dictionary = R["nodes"][key]
	var tg: Dictionary = nd["tg"]
	var name: String = nd["piece"]
	var o: Vector2 = nd["o"]
	var s_n: float = nd["s"]; var em: float = nd["em"]; var ep: float = nd["ep"]
	var sa := s_n - em; var sb := s_n + ep
	var sig: float = tg["sig"]
	var sec: String = tg["sec"]
	var sd: Dictionary = SEC[sec]
	var ks: float = tg["ks"]; var psd: float = tg["ps"]; var pkw: float = sd["pkw"]
	var sgnl: bool = tg["signal"]
	var clo: Dictionary = tg["lo"]; var chi: Dictionary = tg["hi"]
	var slo: float = clo["s_t"]; var shi: float = chi["s_t"]
	var ds: Vector2 = tg["ds"]; var ns: Vector2 = tg["ns"]
	var z_k: float = tg["z_k"]; var z_E: float = tg["z_E"]
	var xw: Array = tg["z_xw"]; var zst: Array = tg["z_stop"]
	var zero := func(_s: float) -> float: return 0.0
	var ctx := _ctx(path, o, zero)
	var stem := Path.new(); stem.add_line(o, o + ds * 200.0)
	var cst := _ctx(stem, o, zero)
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var inl: float = R["inland"]; var out := -inl
	var ow: float = nd["outer"]
	var bkA: Dictionary = {}; var bkB: Dictionary = {}
	for bid: String in R["blocks"]:
		if R["blocks"][bid]["nb"] == key: bkA = R["blocks"][bid]
		if R["blocks"][bid]["na"] == key: bkB = R["blocks"][bid]
	var prom := ow > PR + 0.1
	# ================================================== ring carriageway through the tile
	var p: Array = []
	var xlo: Array = tg.get("xw_lo", []); var xhi: Array = tg.get("xw_hi", [])
	if sgnl:
		for xr: Array in [xlo, xhi]:     # continental crosswalks across the ring, bars along the traffic
			var t := -KB + 0.3
			while t + 0.6 <= KB - 0.3 + 1e-3:
				p.append([t, float(xr[0]), t + 0.6, float(xr[1]), "white"]); t += 1.2
		var stl: Array = tg["stop_lo"]; var sth: Array = tg["stop_hi"]
		# +s approach (arrives from the lo side, drives t > 0; its pocket is the centre lane when the stem is on its left)
		p.append([-TL if sig < 0.0 else TL, float(stl[0]), KB, float(stl[1]), "white"])
		p.append([-KB, float(sth[0]), TL if sig > 0.0 else -TL, float(sth[1]), "white"])
	# end of the approach paint: the stop bars (sgnl) or the mouth (stop control)
	var apl: float = float(tg["stop_lo"][0]) if sgnl else slo
	var aph: float = float(tg["stop_hi"][1]) if sgnl else shi
	# centre lane: the pocket / flush median carries on from the boulevard to the stop bar or the mouth
	var pk_p := sig < 0.0    # +s turns left into the stem
	var pk_n := sig > 0.0    # -s turns left into the stem
	p.append([TL - 0.2, sa, TL - 0.05, apl, "white"] if pk_p else [TL - 0.15, sa, TL - 0.05, apl, "yellow"])
	p.append([-TL + 0.05, sa, -TL + 0.15, apl, "yellow"])
	p.append([-TL + 0.05, aph, -TL + 0.2, sb, "white"] if pk_n else [-TL + 0.05, aph, -TL + 0.15, sb, "yellow"])
	p.append([TL - 0.15, aph, TL - 0.05, sb, "yellow"])
	# lane lines: solid on the sgnl approaches; at a stop-controlled T the ring's dashes run straight through
	if sgnl:
		p.append([L1 - 0.06, sa, L1 + 0.06, apl, "white"])
		p.append([-L1 - 0.06, aph, -L1 + 0.06, sb, "white"])
		_dashes(p, [-L1 - 0.06, -L1 + 0.06], sa, float(xlo[0]), DASH, "white")      # departure side of the lo half
		_dashes(p, [L1 - 0.06, L1 + 0.06], float(xhi[1]), sb, DASH, "white")
	else:
		_dashes(p, [L1 - 0.06, L1 + 0.06], sa, sb, DASH, "white")
		_dashes(p, [-L1 - 0.06, -L1 + 0.06], sa, sb, DASH, "white")
	# bike lines: the far side runs through (no turns cross it); the stem side breaks where turning cars cross it
	var far := -sig
	var tf: Array = [minf(far * L2 - 0.08, far * L2 + 0.08), maxf(far * L2 - 0.08, far * L2 + 0.08)]
	if sgnl:
		p.append([tf[0], sa, tf[1], float(xlo[0]), "white"]); p.append([tf[0], float(xlo[1]), tf[1], float(xhi[0]), "white"]); p.append([tf[0], float(xhi[1]), tf[1], sb, "white"])
	else:
		p.append([tf[0], sa, tf[1], sb, "white"])
	var tn: Array = [minf(sig * L2 - 0.08, sig * L2 + 0.08), maxf(sig * L2 - 0.08, sig * L2 + 0.08)]
	var near_end_lo: float = float(xlo[0]) if sgnl else slo
	var near_beg_hi: float = float(xhi[1]) if sgnl else shi
	# the approach toward the mouth on the stem side (right turners cross the bike lane): broken; the departure: solid
	var appr_lo := sig > 0.0     # +s traffic (t > 0) approaches the mouth from the lo side when the stem is on t > 0
	if appr_lo:
		var k := sa
		while k + 1.0 <= near_end_lo: p.append([tn[0], k, tn[1], k + 1.0, "white"]); k += 2.0
		p.append([tn[0], near_beg_hi, tn[1], sb, "white"])
	else:
		p.append([tn[0], sa, tn[1], near_end_lo, "white"])
		var k2 := near_beg_hi
		while k2 + 1.0 <= sb: p.append([tn[0], k2, tn[1], k2 + 1.0, "white"]); k2 += 2.0
	_reg(ctx, p)
	# ================================================== strips: ramps where the ring crosswalks land
	var ramps_lo: Array = []; var ramps_hi: Array = []; var ramps_far: Array = []
	if sgnl:
		ramps_lo.append([(float(xlo[0]) + float(xlo[1])) * 0.5, XW_W])
		ramps_hi.append([(float(xhi[0]) + float(xhi[1])) * 0.5, XW_W])
		ramps_far = [ramps_lo[0], ramps_hi[0]]
	_reg_ramps(ctx, ramps_lo, sa, slo, 1.0); _reg_ramps(ctx, ramps_hi, shi, sb, 1.0); _reg_ramps(ctx, ramps_far, sa, sb, 1.0)
	for e: float in [slo, shi, float(clo["s_X"]), float(chi["s_X"])]: (ctx["extra"] as Array).append(e)
	_finalize(ctx, sa, sb)
	_band(g, ctx, -KB, KB, sa, sb, p, "asphalt", 0.0)
	# stem side: parkway paved (the corner aprons where people wait), walk; far side: parkway paved at a sgnl (pole
	# bases, ramps), grass at a stop T; then the walk or the promenade (paved right through: the crossings land there)
	_strip(g, ctx, sig * KB, sig * PK, sa, slo, ramps_lo, "concrete", 1.8, 1.0)
	_strip(g, ctx, sig * KB, sig * PK, shi, sb, ramps_hi, "concrete", 1.8, 1.0)
	_plain(g, ctx, sig * PK, sig * PR, sa, slo, "concrete")
	_plain(g, ctx, sig * PK, sig * PR, shi, sb, "concrete")
	_strip(g, ctx, far * KB, far * PK, sa, sb, ramps_far, "concrete" if sgnl else "grass", 1.8, 1.0)
	if prom and far == out:
		_plain(g, ctx, far * PK, far * PW, sa, sb, "plaza")
		_plain(g, ctx, far * PW, far * PROM, sa, sb, "plaza")
	else:
		_plain(g, ctx, far * PK, far * (ow if far == out else PR), sa, sb, "concrete")
	# ================================================== stem: carriageway from the mouth to z_E, crosswalk, stop bar
	var ps: Array = []
	var t := -ks + 0.3
	while t + 0.6 <= ks - 0.3 + 1e-3:
		ps.append([t, float(xw[0]), t + 0.6, float(xw[1]), "white"]); t += 1.2
	var lane: float = sd["lane"]
	var sarrows: Array = []
	# the approach drives toward the ring (-z) on the stem's t < 0 side
	match sec:
		"res":
			ps.append([-lane, float(zst[0]), 0.0, float(zst[1]), "white"])
		"std", "ind":
			ps.append([-lane, float(zst[0]), 0.0, float(zst[1]), "white"])
			ps.append([-0.2, float(xw[1]), -0.1, z_E, "yellow"]); ps.append([0.1, float(xw[1]), 0.2, z_E, "yellow"])
			if sec == "ind":
				ps.append([-4.26, float(xw[1]), -4.14, z_E, "white"]); ps.append([4.14, float(xw[1]), 4.26, z_E, "white"])
		"hs":
			# Amber: median 2.5, lanes to 9.1 (line at 5.8), parking lane to the kerb (no parking at the junction)
			ps.append([-9.1, float(zst[0]), -2.5, float(zst[1]), "white"])
			ps.append([-5.86, float(zst[1]), -5.74, z_E, "white"])
			_dashes(ps, [5.74, 5.86], float(xw[1]) + 2.0, z_E, DASH, "white")
			ps.append([-9.18, float(zst[1]), -9.06, z_E, "white"]); ps.append([9.06, float(xw[1]), 9.18, z_E, "white"])
			var zn := float(xw[1]) + 1.0
			ps.append([-2.5, zn + 2.5, 2.5, z_E, "-"])                  # under the island
			var nose := PackedVector2Array()
			for k in 13: nose.append(Vector2(2.5 * cos(PI * k / 12.0), zn + 2.5 - 2.5 * sin(PI * k / 12.0)))
			sarrows.append({"box": [-2.6, zn - 0.1, 2.6, zn + 2.5], "poly": nose, "c": 0.0, "axis": "x", "fill": ""})
			tg["hs_nose"] = zn
		"strip", "couplet":
			ps.append([-L2, float(zst[0]), TL, float(zst[1]), "white"])
			ps.append([-TL + 0.05, float(zst[1]), -TL + 0.2, z_E, "white"])          # the left-turn lane's edge
			ps.append([TL - 0.15, float(xw[1]), TL - 0.05, z_E, "yellow"])
			ps.append([-L1 - 0.06, float(zst[1]), -L1 + 0.06, z_E, "white"])
			_dashes(ps, [L1 - 0.06, L1 + 0.06], float(xw[1]) + 2.0, z_E, DASH, "white")
			for sx: float in [-1.0, 1.0]: ps.append([minf(sx * L2 - 0.08, sx * L2 + 0.08), float(xw[1]) if sx > 0.0 else float(zst[1]), maxf(sx * L2 - 0.08, sx * L2 + 0.08), z_E, "white"])
			# lanes at a T: no through movement. Centre lane and inner lane turn left, the outer lane turns right
			var za := float(zst[1]) + 1.4
			if z_E - za > 5.0:
				sarrows.append(_arrow("left", 0.0, za + 4.5, za))
				sarrows.append(_arrow("left", -(TL + L1) * 0.5, za + 4.5, za))
				sarrows.append(_arrow("right", -(L1 + L2) * 0.5, za + 4.5, za))
	_reg(cst, ps, sarrows)
	var ramp_st: Array = [[(float(xw[0]) + float(xw[1])) * 0.5, XW_W]]
	_reg_ramps(cst, ramp_st, 0.0, z_E, 1.0)
	for e: float in [float(clo["z_t"]), float(chi["z_t"]), float(clo["zX"]), float(chi["zX"]), z_k]: (cst["extra"] as Array).append(e)
	_finalize(cst, 0.0, z_E)
	_band(g, cst, -ks, ks, z_k, z_E, ps, "asphalt", 0.0, sarrows)
	if tg.has("hs_nose"): _median(g, cst, float(tg["hs_nose"]), z_E, 2.5, true)
	# stem strips from each kerb return's tangent point to z_E: parkway (if the section has one) + walk, ramps at the
	# crosswalk; corner j sits at stem lateral j (stem t = j * ks)
	for c: Dictionary in [clo, chi]:
		var j: float = c["j"]; var zt: float = c["z_t"]
		if pkw > ks + 0.1:
			_strip(g, cst, j * ks, j * pkw, zt, z_E, ramp_st, "grass" if sec in ["res", "std"] else ("grass" if sec in ["strip", "couplet"] else "concrete"), 1.4, 0.0)
			_plain(g, cst, j * pkw, j * psd, zt, z_E, "concrete")
		else:
			_strip(g, cst, j * ks, j * psd, zt, z_E, ramp_st, "concrete", 1.8, 1.0)
	# ================================================== the mouth (kerb returns, asphalt fillets) and the corners
	var mouth := PackedVector2Array()
	for v: float in _sub(ctx, slo, shi): mouth.append(_L(ctx, path.at(v, sig * KB)))
	var ahi: PackedVector2Array = chi["arc"]
	for k in range(1, ahi.size()): mouth.append(_L(ctx, ahi[k]))
	var jh: float = chi["j"]; var jl: float = clo["j"]
	mouth.append(_L(ctx, o + ns * jh * ks + ds * z_k))
	mouth.append(_L(ctx, o + ns * jl * ks + ds * z_k))
	var alo: PackedVector2Array = clo["arc"]
	for k in range(alo.size() - 1, 0, -1): mouth.append(_L(ctx, alo[k]))
	var mclean := PackedVector2Array()
	for q in mouth:
		if mclean.is_empty() or mclean[mclean.size() - 1].distance_to(q) > 1e-4: mclean.append(q)
	if mclean[0].distance_to(mclean[mclean.size() - 1]) < 1e-4: mclean.remove_at(mclean.size() - 1)
	var zf := func(_x: float, _z: float) -> float: return 0.0
	var wf := func(_x: float, _z: float) -> float: return KH
	g.poly("asphalt", mclean, zf)
	var clips: Array = []
	for c: Dictionary in [clo, chi]:
		var arc: PackedVector2Array = c["arc"]
		var la := PackedVector2Array()
		for q in arc: la.append(_L(ctx, q))
		var dd := (la[1] - la[0]).normalized(); var left := Vector2(dd.y, -dd.x)
		g.wall_line("curb", la, zf, wf, signf(left.dot((arc[0] - (c["c"] as Vector2)).normalized())))
		# corner sidewalk: the return, the stem walk's end, the property corner X, the ring walk's end. When the return
		# is big for the walks (a 12 m truck return round 2 m walks) the property corner X falls outside the return's
		# circle: then the walk follows the return at its own widths (4 m on the ring side blending to the stem's) and
		# the lot corner behind it is clipped (meta "corner_clip" for the block builders)
		var j: float = c["j"]; var zt: float = c["z_t"]
		var cc: Vector2 = c["c"]
		var cp := PackedVector2Array()
		for q in la: cp.append(q)
		if (c["X"] as Vector2).distance_to(cc) < float(tg["R"]) - 0.3:
			cp.append(_L(ctx, o + ns * j * psd + ds * zt))
			cp.append(_L(ctx, c["X"]))
			var sX: float = c["s_X"]; var st0: float = c["s_t"]
			var ring_pts := _sub(ctx, minf(sX, st0), maxf(sX, st0))
			var rp: Array = []
			for v: float in ring_pts: rp.append(v)
			if sX > st0: rp.reverse()      # walk from X along the ring property line back to the tangent's s
			for k in range(1, rp.size()): cp.append(_L(ctx, path.at(float(rp[k]), sig * PR)))
		else:
			var arc3: PackedVector2Array = c["arc"]
			var n3 := arc3.size()
			var back: Array = []
			for k in range(n3 - 1, -1, -1):     # from the stem end back to the ring end, the walk's width blending
				var f := float(k) / float(n3 - 1)
				var w := lerpf(PR - KB, psd - ks, f)
				var dv := (arc3[k] - cc).normalized()
				back.append(cc + dv * (float(tg["R"]) - w))
			for q: Vector2 in back: cp.append(_L(ctx, q))
			clips.append(back)
		g.poly("concrete", cp, wf)
	# ================================================== furniture
	var yr := func(_x: float, _z: float) -> float: return 0.0
	var yw := func(_x: float, _z: float) -> float: return KH
	var pole := func(c: Dictionary, rot_deg: float) -> Vector3:
		var u: Vector2 = (c["u"] as Vector2).rotated(deg_to_rad(rot_deg))
		var q: Vector2 = (c["c"] as Vector2) + u * (float(tg["R"]) - 1.0)     # r - 1 from the return's centre: on the walk
		var l := _L(ctx, q)
		return Vector3(l.x, KH, l.y)
	var to_centre := func(v: Vector3) -> float: return _yaw(Vector2(-v.x, -v.z))
	var corner_of_side := {}       # which corner lies on the hi side (+s) / lo side
	if sgnl:
		# mast arms over the ring for both approaches, on the far-right of each (a stem corner, or the far side just
		# past the crosswalk where there is no corner); arm model: along -X, heads face +Z
		var dp := path.tangent(s_n)
		var d_pos := path.tangent(shi); var d_neg := path.tangent(slo)
		var hi_free := true; var lo_free := true
		if sig > 0.0:
			props.add("prop_signal_mast_arm", "worn", pole.call(chi, 0.0), _yaw(-d_pos)); hi_free = false
		else:
			var sp := float(xhi[1]) + 2.6     # 1.6 m past the ramp's flare
			props.add("prop_signal_mast_arm", "worn", _P(ctx, sp, KB + 1.0), _yaw(-path.tangent(sp)))
		if sig < 0.0:
			props.add("prop_signal_mast_arm", "worn", pole.call(clo, 0.0), _yaw(d_neg)); lo_free = false
		else:
			var sn := float(xlo[0]) - 2.6
			props.add("prop_signal_mast_arm", "worn", _P(ctx, sn, -(KB + 1.0)), _yaw(path.tangent(sn)))
		# the stem approach: heads on a post at the free corner and across the ring (far side, on the stem's line)
		var cfree: Dictionary = clo if lo_free else chi
		props.add("prop_signal_post", "worn", pole.call(cfree, 0.0), _yaw(ds))
		var sfar := _near(path.project(o).x, s_n, path.length)
		props.add("prop_signal_post", "worn", _P(ctx, sfar, far * (KB + 1.0)), _yaw(ds))
		# street names hang beside the poles on both corners; a cobra on the free corner lights the crossing
		for c: Dictionary in [clo, chi]:
			props.add("prop_sign_street_names", "worn", pole.call(c, 20.0 * float(c["j"])), 45.0 + _yaw(ds))
		props.add("prop_lamp_cobra", "worn", pole.call(cfree, -24.0 * float(cfree["j"])), float(to_centre.call(pole.call(cfree, -24.0 * float(cfree["j"])))))
		# people wait for the light at the corners: a bin each
		for c: Dictionary in [clo, chi]:
			props.add("prop_trash_receptacle", "worn", pole.call(c, -34.0 * float(c["j"])), 0.0)
		props.add("prop_newspaper_box_blue" if rr.randf() < 0.5 else "prop_newspaper_box_red", "worn", pole.call(cfree, 40.0 * float(cfree["j"])), _yaw(cfree["u"] as Vector2))
	else:
		# stop control on the stem only: the sign on the approach's right (stem t < 0 side), at the stop bar
		var sp2 := _P(cst, float(zst[1]) + 0.4, -(ks + 0.6))
		props.add("prop_sign_stop", "worn", sp2, _yaw(ds))
		props.add("prop_sign_street_names", "worn", pole.call(chi, 0.0), 45.0 + _yaw(ds))
		props.add("prop_lamp_cobra", "worn", pole.call(clo, 0.0), float(to_centre.call(pole.call(clo, 0.0))))
	# a hydrant on one corner, 1 m behind the kerb, clear of the ramps
	props.add("prop_hydrant_red", "worn", pole.call(chi, 30.0 * float(chi["j"])), _yaw(chi["u"] as Vector2))     # outlets face the street
	# kerb inlets upstream of the ring crossings (the stem's gutter drains in its own stub, at the stub's low end)
	var ring_in: Array = [[sa + 1.6, 1.0], [sb - 1.6, -1.0]]
	for e: Array in ring_in:
		var sv: float = e[0]
		props.add("prop_storm_drain_curb_inlet", "dirty", _P(ctx, sv, float(e[1]) * KB, 0.0), _yaw(-path.normal(sv) * float(e[1])), false)
	props.add("prop_manhole_cover", "worn", _P(ctx, s_n + rr.randf_range(-4.0, 4.0), -sig * 3.5, 0.002), 0.0, false)
	# ================================================== wear: a busy junction
	# braking marks and oil where the queues stop, turning arcs through the mouth, cracks, a duct trench, corner grime
	if sgnl:
		for e3: Array in [[float(tg["stop_lo"][0]), 1.0], [float(tg["stop_hi"][1]), -1.0]]:
			var se: float = e3[0]; var dr: float = e3[1]
			for ln: float in [(TL + L1) * 0.5, (L1 + L2) * 0.5]:
				for wp: float in [-0.8, 0.8]: _dec(dec, ctx, 8, se - dr * 3.0, dr * (ln + wp), 0.45, 5.5, yr, Color(1, 1, 1, 0.5))
				W.oil(dec, rr, _L(ctx, path.at(se - dr * 2.5, dr * ln)), _yaw(path.tangent(se)), yr, 0.7)
	for wp: float in [-0.8, 0.8]:
		_dec(dec, cst, 8, float(zst[1]) + 3.0, -lane * 0.5 + wp, 0.45, 5.0, yr, Color(1, 1, 1, 0.45))
	W.oil(dec, rr, _L(cst, stem.at(float(zst[1]) + 2.5, -lane * 0.5)), _yaw(ds), yr, 0.7)
	for k in 5:     # turning arcs: left turners sweep through the middle of the mouth
		var sv := rr.randf_range(slo + 2.0, shi - 2.0)
		_dec(dec, ctx, 8, sv, sig * rr.randf_range(1.0, 7.0), 0.6, 8.0, yr, Color(1, 1, 1, 0.38), rr.randf_range(25.0, 65.0) * (1.0 if rr.randf() < 0.5 else -1.0))
	_cracks(dec, rr, ctx, -9.0, 9.0, sa + 1.0, sb - 1.0, 12, yr, 0.5)
	for k in 4:     # the signal duct trench across the far half (cut to the far pole), a long narrow strip
		_dec(dec, ctx, 3, s_n + 2.0, -sig * (1.0 + k * 2.4), 0.7, 2.4, yr, Color(1, 1, 1, 0.55), 90.0)
	for c: Dictionary in [clo, chi]:
		var arc2: PackedVector2Array = c["arc"]
		for k in range(1, arc2.size() - 1, 3):
			var q: Vector2 = arc2[k] + (arc2[k] - (c["c"] as Vector2)).normalized() * 0.3
			var lq := _L(ctx, q)
			dec.add(14, lq, _yaw(arc2[k + 1] - arc2[k]), 0.5, 2.0, yr, Color(1, 1, 1, 0.55))
		var wq := _L(ctx, (c["c"] as Vector2) + (c["u"] as Vector2) * (float(tg["R"]) - 2.6))
		dec.add(14, wq, rr.randf_range(0, 90), 3.0, 2.2, yw, Color(1, 1, 1, 0.45))     # people wait here
	var site := {"site": key, "kind": "T", "ctl": nd["ctl"], "stem": tg["sec"], "pos": [o.x, float(nd["pad"]), o.y], "yaw": 0.0,
		"s": [sa, sb], "z_E": z_E, "bus": nd.get("bus", false)}
	if not clips.is_empty(): site["corner_clip"] = clips      # grid points: the back of the corner walk, lots keep behind it
	_finish(root, g, props, dec, name, {"rg": site})

## ===================================================================================================== stub (c)
## s_rg_<block>: the straight stem street from the last lattice junction's tile edge (z0, measured from the lattice
## node) to the T tile edge (block length - z_E). Authored along +z from the LATTICE node (kit leg convention), placed
## with yaw so +z points at the ring, y = the lattice pad; rises with the smoothstep across z0..z1.
static func stub_plan(bid: String) -> Dictionary:
	var R := ring()
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SITES))
	var b: Dictionary = {}
	var nodes := {}
	for x: Dictionary in d["blocks"]:
		if String(x["id"]) == bid: b = x
	for n: Dictionary in d["nodes"]: nodes[nkey(float(n["u"]), float(n["v"]))] = n
	var ka := nkey(float(b["a"][0]), float(b["a"][1])); var kb := nkey(float(b["b"][0]), float(b["b"][1]))
	var kt := ka if R["nodes"].has(ka) else kb
	var kl := kb if kt == ka else ka
	var T: Dictionary = R["nodes"][kt]
	var L: Dictionary = nodes[kl]
	var lp := Vector2(float(L["u"]), float(L["v"]))
	var to: Vector2 = T["o"]
	var ds := (to - lp).normalized()
	var length := lp.distance_to(to)
	var sec := String(b["section"])
	var z0: float = SEC[sec]["z0"]
	if String(L["owner"]) == "sample": z0 = 100.0       # a locked sample's own legs reach 100 m
	var z1: float = length - float(T["tg"]["z_E"])
	return {"name": "s_rg_" + bid, "bid": bid, "sec": sec, "lattice": kl, "t": kt, "o": lp, "ds": ds, "len": length,
		"z0": z0, "z1": z1, "pad0": float(L["pad"]), "pad1": float(T["pad"]), "yaw": _yaw(ds), "street": String(b["name"])}

static func build_stub(bid: String) -> void:
	S.hill_on = false
	var pl := stub_plan(bid)
	var name: String = pl["name"]
	var sec: String = pl["sec"]
	var z0: float = pl["z0"]; var z1: float = pl["z1"]; var Lb: float = pl["len"]
	var H: float = float(pl["pad1"]) - float(pl["pad0"])
	var hz := func(z: float) -> float: return H * _ss((z - z0) / maxf(z1 - z0, 1.0))
	var gz := func(z: float) -> float:
		var t := clampf((z - z0) / maxf(z1 - z0, 1.0), 0.0, 1.0)
		return H * 6.0 * t * (1.0 - t) / maxf(z1 - z0, 1.0)
	var yr := func(_x: float, z: float) -> float: return float(hz.call(z))
	var yw := func(_x: float, z: float) -> float: return float(hz.call(z)) + KH
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var sd: Dictionary = SEC[sec]
	var kb: float = sd["kerb"]; var pkw: float = sd["pkw"]; var prp: float = sd["prop"]; var lane: float = sd["lane"]
	var stalls: Array = []
	var Lr := Lb - 25.0          # the T's sight triangle: no trees closer to the ring junction than this
	match sec:
		"res", "std":
			_stub_two_lane(g, props, dec, rr, sec, z0, z1, Lr, H, hz, gz, yr, yw, stalls)
		"strip", "couplet":
			_stub_art(g, props, dec, rr, z0, z1, Lr, H, yr, yw)
		"ind":
			_stub_ind(g, props, dec, rr, z0, z1, H, yr, yw)
		"hs":
			_stub_hs(g, props, dec, rr, z0, z1, Lr, H, hz, gz, yr, yw, stalls)
		_:
			push_error("RG: no stub builder for section %s" % sec)
	var site := {"site": bid, "kind": "stub", "sec": sec, "pos": [float(pl["o"].x), float(pl["pad0"]), float(pl["o"].y)], "yaw": pl["yaw"],
		"z": [z0, z1], "street": pl["street"], "max_grade": absf(1.5 * H / maxf(z1 - z0, 1.0))}
	_finish(root, g, props, dec, name, {"rg": site, "stalls": stalls})

## residential / standard stub (the s_apt cross-section, road_lib's residential dress generalised to any length and rise)
static func _stub_two_lane(g: K.Ground, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sec: String, z0: float, z1: float, Lr: float, H: float, hz: Callable, gz: Callable, yr: Callable, yw: Callable, stalls: Array) -> void:
	var KBs := 5.7; var PKs := 7.2; var PRs := 9.2; var LN := 3.3
	var AL0 := 54.0; var AL1 := 60.0
	var alley := z1 - AL1 >= 12.0 and AL0 > z0 + 8.0      # the block's alley meets the street only where it fits
	var flat := absf(H) < 0.01
	var hside := 1.0 if rr.randf() < 0.5 else -1.0
	var hyd := z0 + 20.0
	# kerb parking, recorded for the parked-car layer [x, z, yaw, y, grade]: 7 m clear of the lattice crosswalk, 5 m short
	# of the ring tile (its stop bar and crosswalk are just beyond), clear of the hydrant and the alley mouth
	var marks: Array = []
	for sx: float in [-1.0, 1.0]:
		var blocked: Array = [[z0, z0 + 7.0], [z1 - 5.0, z1]]
		if alley: blocked.append([AL0 - 1.5, AL1 + 1.5])
		if sx == hside: blocked.append([hyd - 4.5, hyd + 4.5])
		var d := z0
		while d + 6.5 <= z1:
			var bad := false
			for r: Array in blocked:
				if d + 6.5 > float(r[0]) and d < float(r[1]): bad = true
			if bad:
				d += 0.5; continue
			var cz := d + 3.25; var cx := sx * (LN + 1.2)
			stalls.append([cx, cz, 180.0 if sx > 0.0 else 0.0, float(hz.call(cz)), float(gz.call(cz))])
			for e: float in [d, d + 6.5]: marks.append([minf(sx * LN, sx * (LN + 0.6)), e - 0.05, maxf(sx * LN, sx * (LN + 0.6)), e + 0.05, "white"])
			if rr.randf() < 0.6: W.oil(dec, rr, Vector2(cx, cz + (1.2 if sx > 0.0 else -1.2)), 0.0, yr, rr.randf_range(0.35, 0.7))
			d += 6.5
	# carriageway: residential = unmarked (a quiet street, cars give way to each other), standard = double yellow and
	# stall T-marks (a collector: busier, marked)
	var p: Array = []
	if sec == "std":
		p.append_array(marks)
		p.append([-0.2, z0, -0.1, z1, "yellow"]); p.append([0.1, z0, 0.2, z1, "yellow"])
	K.painted_rect(g, -KBs, z0, KBs, z1, p, yr)
	for sx: float in [-1.0, 1.0]:
		if alley:
			RL.strip_z(g, sx * KBs, sx * PKs, z0, AL0 - 1.0, [], "grass", yr, yw)
			RL.strip_z(g, sx * KBs, sx * PKs, AL0 - 1.0, AL1 + 1.0, [[(AL0 + AL1) * 0.5, AL1 - AL0]], "concrete", yr, yw)
			RL.strip_z(g, sx * KBs, sx * PKs, AL1 + 1.0, z1, [], "grass", yr, yw)
		else:
			RL.strip_z(g, sx * KBs, sx * PKs, z0, z1, [], "grass", yr, yw)
		g.rect("concrete", minf(sx * PKs, sx * PRs), z0, maxf(sx * PKs, sx * PRs), z1, yw)
	var taken := {-1.0: [], 1.0: []}
	# a hydrant every ~100 m (the block's one sits 20 m in), red kerb 4.5 m each way
	props.add("prop_hydrant_red", "worn", Vector3(hside * (KBs + 0.7), float(yw.call(0.0, hyd)), hyd), -90.0 * hside)
	RL.red_kerb_z(dec, hside * KBs, hyd - 4.5, hyd + 4.5, -hside, yr, yw)
	(taken[hside] as Array).append(hyd)
	# a cobra mid-way (the junctions have their own corner lamps), arm over the road
	var lz := clampf((z0 + z1) * 0.5 + 6.0, z0 + 6.0, z1 - 6.0)
	props.add("prop_lamp_cobra", "worn", Vector3(-hside * (KBs + 0.6), float(yw.call(0.0, lz)), lz), 90.0 * hside)
	(taken[-hside] as Array).append(lz)
	# street sweeping (weekly), one sign per side past the junction
	for sx: float in [-1.0, 1.0]:
		var sz := clampf(z0 + (14.0 if sx > 0.0 else 26.0), z0 + 3.0, z1 - 3.0)
		props.add("prop_sign_no_parking", "worn", Vector3(sx * (KBs + 0.35), float(yw.call(0.0, sz)), sz), -90.0 * sx)
		(taken[sx] as Array).append(sz)
	# drainage: a flat stub drains to a mid-block inlet each side; on a slope the water runs down to the stub's low end,
	# where an inlet each side takes it before the junction (the junction tiles keep their own crossings dry)
	for sx: float in [-1.0, 1.0]:
		var iz := (z0 + z1) * 0.5 + sx * 3.0 if flat else (z0 + 2.5 if H > 0.0 else z1 - 2.5)
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * KBs, float(yr.call(0.0, iz)), iz), -90.0 * sx, false)
		(taken[sx] as Array).append(iz)
	# trees: RES_MIX (planted over decades: runs of one species, mixed ages), 11-14 m rhythm, from 28 m off the lattice
	# junction (its sight triangle) to 25 m short of the ring junction (the stop sign's), clear of things in the parkway
	var grp := RL._pick_group(rr)
	for sx: float in [-1.0, 1.0]:
		var tz := maxf(z0 + 8.0, 28.0) + (rr.randf_range(3.0, 7.0) if sx > 0.0 else rr.randf_range(0.0, 2.0))
		while tz < minf(z1 - 2.0, Lr):
			if rr.randf() < 0.08:
				dec.add(14, Vector2(sx * (KBs + 0.75), tz), rr.randf_range(0, 180), 1.1, 1.1, yw, Color(0.75, 0.68, 0.55, 0.55))
				tz += rr.randf_range(11.0, 14.0); continue
			for shift: float in [0.0, 1.0, 2.0, 3.0, 4.0]:
				var z := tz + shift
				if z > minf(z1 - 2.0, Lr): break
				var ok := not (alley and z > AL0 - 3.5 and z < AL1 + 3.5)
				for o2: float in taken[sx]:
					if absf(z - o2) < 3.0: ok = false
				if ok:
					if rr.randf() < 0.45: grp = RL._pick_group(rr)
					var gp: Array = RL.RES_MIX[grp]
					var model := String((gp[0] as Array)[rr.randi() % (gp[0] as Array).size()])
					props.add(model, "normal", Vector3(sx * (KBs + 0.75), float(yw.call(0.0, z)) - 0.06, z), rr.randf_range(0.0, 360.0), true, rr.randf_range(float(gp[2]), float(gp[3])))
					(taken[sx] as Array).append(z)
					if rr.randf() < 0.6: dec.add(rr.randi() % 2, Vector2(sx * (PKs + 0.8), z + rr.randf_range(-0.8, 0.8)), rr.randf_range(60, 120), 1.9, 0.9, yw, Color(0.3, 0.29, 0.28, 0.8))
					if rr.randf() < 0.3: W.pale_patch(dec, rr, Vector2(sx * (PKs + 1.0), z + rr.randf_range(-1.0, 1.0)), 0.0, 1.9, 1.6, yw, 0.6)
					break
			tz += rr.randf_range(11.0, 14.0)
	# wear: wheel paths, cracks, gutter leaves (streaks downhill on a slope), utility cuts, the walking line
	for sx: float in [-1.0, 1.0]:
		RL.lane_wear_y(dec, rr, sx * LN * 0.5, z0, z1, yr, 0.35)
		W.cracks(dec, rr, minf(sx * 0.3, sx * KBs), z0 + 1.0, maxf(sx * 0.3, sx * KBs), z1 - 1.0, maxi(3, int((z1 - z0) / 9.0)), yr, 0.5)
		var gzz := z0 + 1.0
		while gzz < z1 - 1.5:
			var L := rr.randf_range(1.5, 2.6) if flat else rr.randf_range(2.8, 3.8)
			dec.add(14, Vector2(sx * (KBs - 0.28), gzz + L * 0.5), 0.0, 0.5, L, yr, Color(0.95, 0.9, 0.82, rr.randf_range(0.45, 0.7)))
			gzz += L + (rr.randf_range(2.0, 5.0) if flat else rr.randf_range(0.4, 1.5))
		var wz := z0 + 0.5
		while wz < z1 - 1.0:
			var Lw := rr.randf_range(2.0, 4.0)
			dec.add(14, Vector2(sx * rr.randf_range(PKs + 0.6, PRs - 0.6), wz + Lw * 0.5), 0.0, 1.1, Lw, yw, Color(1, 1, 1, rr.randf_range(0.2, 0.4)))
			wz += Lw + rr.randf_range(2.0, 6.0)
	var qz := rr.randf_range(z0 + 6.0, z1 - 6.0)
	dec.add(3, Vector2((1.0 if rr.randf() < 0.5 else -1.0) * KBs * 0.5, qz), 90.0, 1.0, KBs - 0.4, yr, Color(1, 1, 1, 0.7))   # a house's water service
	var mz := clampf(z0 + 26.0, z0 + 3.0, z1 - 3.0)
	props.add("prop_manhole_cover", "worn", Vector3(-1.6, float(yr.call(0.0, mz)) + 0.002, mz), 0.0, false)
	dec.add(2, Vector2(-1.6, mz), 0.0, 2.2, 2.0, yr, Color(1, 1, 1, 0.75))

## ================================================================================ preview-only review ground
## zz_ring_ground_<tag>: grass verges (exact, along the given ring range and stems) at the walk height minus 2 cm, and
## a deep grass field 1.5 m under the roads everywhere else, built in GRID coordinates (layout row pos [0, 0, -8000]).
## spec: {"ring": [s0, s1], "stems": [node keys], "stubs": [block ids], "lattice": [[u, v, pad]], "box": [u0, v0, u1, v1]}
static func build_review_ground(name: String, spec: Dictionary) -> void:
	var R := ring()
	var path: Path = R["path"]
	var g := K.Ground.new()
	var root := Node3D.new(); root.name = name
	var rs: Array = spec["ring"]
	var r0: float = rs[0]; var r1: float = rs[1]
	var inl: float = R["inland"]; var out := -inl
	var W_ := 45.0
	var ys := func(s: float) -> float: return ring_h(s) - 0.02
	var ctx := _ctx(path, Vector2.ZERO, ys)
	var cuts_extra: Array = []
	var skip: Array = []      # inland ring ranges replaced by stem corners: [sXlo, sXhi]
	for k: String in spec.get("stems", []):
		var nd: Dictionary = R["nodes"][k]
		var tg: Dictionary = nd["tg"]
		skip.append([float(tg["lo"]["s_X"]), float(tg["hi"]["s_X"])])
		cuts_extra.append(float(tg["lo"]["s_X"])); cuts_extra.append(float(tg["hi"]["s_X"]))
	ctx["extra"] = cuts_extra
	_finalize(ctx, r0, r1)
	# coast side: one verge; inland: verges between the stem corners
	var bo: float = PR
	for bid: String in R["blocks"]:
		var bk: Dictionary = R["blocks"][bid]
		if float(bk["sb"]) > r0 and float(bk["sa"]) < r1: bo = maxf(bo, float(bk["outer"]))
	_band(g, ctx, minf(out * bo, out * (bo + W_)), maxf(out * bo, out * (bo + W_)), r0, r1, [], "grass", KH)
	var cur := r0
	skip.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for sk: Array in skip:
		if float(sk[0]) > cur: _band(g, ctx, minf(inl * PR, inl * (PR + W_)), maxf(inl * PR, inl * (PR + W_)), cur, float(sk[0]), [], "grass", KH)
		cur = float(sk[1])
	if cur < r1: _band(g, ctx, minf(inl * PR, inl * (PR + W_)), maxf(inl * PR, inl * (PR + W_)), cur, r1, [], "grass", KH)
	# stems: verges from the corner X outward, 1 cm lower (no z-fight where they overlap the ring verge)
	for k: String in spec.get("stems", []):
		var nd: Dictionary = R["nodes"][k]
		var tg: Dictionary = nd["tg"]
		var ds: Vector2 = tg["ds"]; var o: Vector2 = nd["o"]
		var psd: float = tg["ps"]
		var stub_len := 0.0
		for bid: String in spec.get("stubs", []):
			var sp := stub_plan(bid)
			if String(sp["t"]) == k: stub_len = float(sp["len"]) - 20.0
		var zmax := maxf(stub_len + 20.0, float(tg["z_E"]) + 40.0)     # beside the stub, up to the lattice junction's centre
		var stem := Path.new(); stem.add_line(o, o + ds * 400.0)
		var pad: float = nd["pad"]
		var c2 := _ctx(stem, Vector2.ZERO, func(_s: float) -> float: return pad - 0.03)
		_finalize(c2, 0.0, zmax)
		var roads: Array = [path]
		for sd2: String in spec.get("w", []): roads.append(w_plan(sd2)["tw"]["path"])
		for c: Dictionary in [tg["lo"], tg["hi"]]:
			var j: float = c["j"]
			var wv := 20.0
			var zend := zmax
			var zz := float(c["zX"])
			while zz < zmax:
				var hit := false
				for rp: Path in roads:
					var pq := rp.project(stem.at(zz, j * (psd + wv)))
					if absf(pq.y) < PROM + 2.0 and pq.x > 0.5 and pq.x < rp.length - 0.5: hit = true
				if hit: zend = zz; break
				zz += 2.0
			if zend > float(c["zX"]) + 1.0:
				_band(g, c2, minf(j * psd, j * (psd + wv)), maxf(j * psd, j * (psd + wv)), float(c["zX"]), zend, [], "grass", KH)
	# W transitions: verges along their (morphing) section, 1 cm lower than the ring's
	for sd: String in spec.get("w", []):
		var pl := w_plan(sd)
		var tw: Dictionary = pl["tw"]
		var wp: Path = tw["path"]
		var Lw := wp.length
		var fr: bool = tw["from_ring"]
		var hJ := w_join_h(sd); var hW: float = pl["pad_w"]
		var h0 := hJ if fr else hW; var h1 := hW if fr else hJ
		var wy := func(sv: float) -> float: return h0 + (h1 - h0) * _ss(sv / Lw) - 0.03
		var cw := _ctx(wp, Vector2.ZERO, wy)
		cw["tmap"] = func(sv: float, tv: float) -> float: return _morph(tv, _ss(sv / Lw) if fr else _ss(1.0 - sv / Lw), signf(tv) == out)
		_finalize(cw, 0.0, Lw)
		_band(g, cw, minf(inl * PR, inl * (PR + W_)), maxf(inl * PR, inl * (PR + W_)), 0.0, Lw, [], "grass", KH)
		_band(g, cw, minf(out * PROM, out * (PROM + W_)), maxf(out * PROM, out * (PROM + W_)), 0.0, Lw, [], "grass", KH)
	for rq: Array in spec.get("rects", []):
		var ry2: float = rq[4]
		g.rect("grass", float(rq[0]), float(rq[1]), float(rq[2]), float(rq[3]), func(_x: float, _z: float) -> float: return ry2, 8.0)
	# deep field: everything else, 0.45 m under the walk height of the nearest ring point
	var bx: Array = spec["box"]
	var deep := func(x: float, z: float) -> float: return ring_h(path.project(Vector2(x, z)).x) - 1.5     # well under every road nearby
	g.rect("grass", float(bx[0]), float(bx[1]), float(bx[2]), float(bx[3]), deep, 10.0)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	print("%s: ground tris %d" % [name, g.tri_count()])
	K.save_piece(root, name)

## ============================================================================================ reports / tables
## The bridge gap's two ends (grid u, v, y) and the ring facts a site builder needs.
static func bridge_gap() -> Array:
	var R := ring()
	var path: Path = R["path"]
	for k: String in R["nodes"]:
		var nd: Dictionary = R["nodes"][k]
		if String(nd["ctl"]) == "gap":
			var s: float = nd["s"]
			var a := path.point(s - GAP * 0.5); var b := path.point(s + GAP * 0.5)
			return [[a.x, ring_h(s - GAP * 0.5), a.y], [b.x, ring_h(s + GAP * 0.5), b.y]]
	return []

## ================================================================================================== API
## For the site builders (stage 2), READ-ONLY: const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
##  RG.ring() -> Dictionary        the fitted loop + every ring node / block (fields: see ring() above); node keys are
##                                 RG.nkey(u, v) of sites.json ("-800.0,288.7"); the loop runs b131 -> b132 ... (+s)
##  RG.block_plan(bid) -> [{name, bid, s0, s1, i, n}]   boulevard pieces of ring block bid; [] when nothing is left
##                                 between its tiles (b136: the W transition carries it all)
##  RG.build_boulevard(bid, i)     builds + saves s_rg_<bid>_<i> (grid frame, anchor = path point at s0)
##  RG.build_t(node_key)           builds + saves j_rg_<RG.nid(u, v)> for a ring node with a stem (res / std / strip /
##                                 couplet / ind / hs); not for the bridge node or W
##  RG.stub_plan(bid) / RG.build_stub(bid)   s_rg_<bid>: the stem street of a ring-owned LATTICE block (res / std /
##                                 strip / couplet / ind / hs), from the lattice tile edge z0 to the T tile edge
##  RG.w_plan(side) / RG.build_w_transition(side)   side "S" -> s_rg_b161_w, "N" -> s_rg_b136_w
##  RG.ring_h(s), RG.bridge_gap(), RG.ferry_gap() (45 m gaps left for the hand-made bridge Y and ferry landing; their
##                                 two ends [u, y, v]), RG.biarc(), RG.fit_polyline()
##  Every piece saves meta "rg" {site, kind, pos [u, y, v] GRID, yaw, ...}; zz_ring_write.gd turns a list of built
##  pieces into review/ring.json (pos + [0, 0, -8000]) and review/ring_sites.json. Thin piece scripts (one per piece,
##  build.sh runs them): extends SceneTree; _init -> _run.call_deferred(); _run: RG.build_*(...); quit().
## ============================================================================== stubs: the other sections
## A raised planted median |t| <= hw from z_a to z_b along a straight ctx path, a round nose at z_a when nose (the
## asphalt round the nose is left by the caller: _arrow_fill with fill ""), kerb faces all round.
static func _median(g: K.Ground, ctx: Dictionary, z_a: float, z_b: float, hw: float, nose: bool) -> void:
	var ys: Callable = ctx["ys"]
	var zs := z_a + (hw if nose else 0.0)
	_plain(g, ctx, -hw, hw, zs, z_b, "grass", KH)
	var sc := _sub(ctx, zs, z_b)
	_wall(g, ctx, -hw, sc, 1.0, Callable()); _wall(g, ctx, hw, sc, -1.0, Callable())
	if nose:
		var pts := PackedVector2Array()
		for k in 13: pts.append(Vector2(hw * cos(PI * k / 12.0), zs - hw * sin(PI * k / 12.0)))
		var c := Vector2(0.0, zs)
		for k in 12:
			var a: Vector2 = pts[k]; var b: Vector2 = pts[k + 1]
			g.tri("grass", _F(ctx, c.y, c.x, float(ys.call(c.y)) + KH), _F(ctx, a.y, a.x, float(ys.call(a.y)) + KH), _F(ctx, b.y, b.x, float(ys.call(b.y)) + KH))
			var o := ((a + b) * 0.5 - c).normalized()
			var path: Path = ctx["path"]
			var ow := path.normal(a.y) * o.x + path.tangent(a.y) * o.y
			g.quad("curb", _F(ctx, a.y, a.x, float(ys.call(a.y))), _F(ctx, b.y, b.x, float(ys.call(b.y))), _F(ctx, b.y, b.x, float(ys.call(b.y)) + KH), _F(ctx, a.y, a.x, float(ys.call(a.y)) + KH), Vector3(ow.x, 0, ow.y), true)

## a stub's straight path in its own leg frame (+z from the lattice node toward the ring)
static func _leg_ctx(z0: float, z1: float, hz: Callable, extra: Array) -> Dictionary:
	var p := Path.new(); p.add_line(Vector2(0.0, -5.0), Vector2(0.0, z1 + 50.0))
	var ys := func(s: float) -> float: return float(hz.call(s - 5.0))
	var c := _ctx(p, Vector2.ZERO, ys)
	c["z_ofs"] = 5.0
	return c

## strip arterial stub (strip / couplet): TWLTL with left-turn pockets at both ends, 2+2 lanes, bike lanes, fan palm
## parkway, 2 m walk; far-side bus stops both directions; arrows for the T approach (centre and inner lane turn left,
## outer lane turns right: there is no through movement at a T) and for the lattice approach (through / through-right)
static func _stub_art(g: K.Ground, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, z0: float, z1: float, Lr: float, H: float, yr: Callable, yw: Callable) -> void:
	var p: Array = []; var arrows: Array = []
	var pz1 := z1 - POCKET; var pz0 := z0 + 30.0
	if pz0 > pz1: pz0 = (pz0 + pz1) * 0.5; pz1 = pz0
	# centre lane edges: white along a pocket (toward the lanes it belongs to), yellow elsewhere
	p.append([TL - 0.2, z0, TL - 0.05, pz0, "white"]); p.append([TL - 0.15, pz0, TL - 0.05, z1, "yellow"])
	p.append([-TL + 0.05, z0, -TL + 0.15, pz1, "yellow"]); p.append([-TL + 0.05, pz1, -TL + 0.2, z1, "white"])
	if pz1 - pz0 > 14.0:
		_dashes(p, [TL - 0.42, TL - 0.32], pz0 + 6.0, pz1 - 6.0, TW_DASH, "yellow")
		_dashes(p, [-TL + 0.32, -TL + 0.42], pz0 + 6.0, pz1 - 6.0, TW_DASH, "yellow")
	# arrows (site frame: a driver moving +z has his left on +x): the T approach drives +z on x < 0
	for k: float in [6.0, 24.0]:
		if z1 - k - 4.5 > pz1: arrows.append(S.arrow2("left", 0.0, z1 - k - 4.5, z1 - k))
		if z0 + k + 4.5 < pz0: arrows.append(S.arrow2("left", 0.0, z0 + k + 4.5, z0 + k))
	arrows.append(S.arrow2("left", -(TL + L1) * 0.5, z1 - 10.5, z1 - 6.0))
	arrows.append(S.arrow2("right", -(L1 + L2) * 0.5, z1 - 10.5, z1 - 6.0))
	arrows.append(S.arrow2("through", (TL + L1) * 0.5, z0 + 10.5, z0 + 6.0))
	arrows.append(S.arrow2("through_right", (L1 + L2) * 0.5, z0 + 10.5, z0 + 6.0))
	# lane lines: solid on the last 20 m of each approach, dashed elsewhere; bike lines broken where right turners cross
	_dashes(p, [-L1 - 0.06, -L1 + 0.06], z0, z1 - 20.0, DASH, "white"); p.append([-L1 - 0.06, z1 - 20.0, -L1 + 0.06, z1, "white"])
	_dashes(p, [L1 - 0.06, L1 + 0.06], z0 + 15.0, z1, DASH, "white"); p.append([L1 - 0.06, z0, L1 + 0.06, z0 + 15.0, "white"])
	var bus: Array = []
	if z1 - z0 > 75.0:
		bus.append({"side": -1.0, "a": z0 + 3.0, "b": z0 + 23.0, "front": z0 + 23.0, "dir": 1.0})
		bus.append({"side": 1.0, "a": z1 - 23.0, "b": z1 - 3.0, "front": z1 - 23.0, "dir": -1.0})
	for sx: float in [-1.0, 1.0]:
		var broken: Array = []
		if sx < 0.0: broken.append([z1 - 30.0, z1])
		for bz: Dictionary in bus:
			if float(bz["side"]) == sx: broken.append([float(bz["a"]) - 3.0, float(bz["b"]) + 1.0])
		broken.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		var cur := z0
		for br: Array in broken:
			if float(br[0]) > cur: p.append([sx * L2 - 0.08, cur, sx * L2 + 0.08, float(br[0]), "white"])
			var k := maxf(float(br[0]), cur)
			while k + 1.0 <= float(br[1]): p.append([sx * L2 - 0.08, k, sx * L2 + 0.08, k + 1.0, "white"]); k += 2.0
			cur = maxf(cur, float(br[1]))
		if cur < z1: p.append([sx * L2 - 0.08, cur, sx * L2 + 0.08, z1, "white"])
	for a: Dictionary in arrows: p.insert(0, (a["box"] as Array) + ["-"])
	K.painted_rect(g, -KB, z0, KB, z1, p, yr)
	for a: Dictionary in arrows: K.fill_arrow(g, a, yr)
	var taken := {-1.0: [], 1.0: []}
	for sx: float in [-1.0, 1.0]:
		var cur := z0
		for bz: Dictionary in bus:
			if float(bz["side"]) != sx: continue
			var fr: float = bz["front"]; var dr: float = bz["dir"]
			var pa := minf(fr - dr * 9.5, fr - dr * 0.6); var pb := maxf(fr - dr * 9.5, fr - dr * 0.6)
			RL.strip_z(g, sx * KB, sx * PK, cur, pa, [], "grass", yr, yw)
			RL.strip_z(g, sx * KB, sx * PK, pa, pb, [], "concrete", yr, yw)
			cur = pb
			(taken[sx] as Array).append([(pa + pb) * 0.5, 13.0])
			I.add(props, "prop_bus_stop_sign", "worn", Vector3(sx * (KB + 0.45), float(yw.call(0.0, fr - dr * 0.4)), fr - dr * 0.4), 180.0 if dr > 0.0 else 0.0)
			props.add("prop_bench_bus_stop", "worn", Vector3(sx * (PK - 0.45), float(yw.call(0.0, fr - dr * 5.4)), fr - dr * 5.4), -90.0 * sx)
			props.add("prop_trash_receptacle", "dirty", Vector3(sx * (PK - 0.4), float(yw.call(0.0, fr - dr * 8.6)), fr - dr * 8.6), 0.0)
			RL.red_kerb_z(dec, sx * KB, float(bz["a"]), float(bz["b"]), -sx, yr, yw)
			dec.add(14, Vector2(sx * (KB + 1.0), fr - dr * 5.0), 0.0, 1.6, 7.0, yw, Color(1, 1, 1, 0.55))
			for k in 3: W.oil(dec, rr, Vector2(sx * (L2 + 0.4), fr - dr * rr.randf_range(2.0, 10.0)), 0.0, yr, 0.8)
		RL.strip_z(g, sx * KB, sx * PK, cur, z1, [], "grass", yr, yw)
		g.rect("concrete", minf(sx * PK, sx * PR), z0, maxf(sx * PK, sx * PR), z1, yw)
	# cobra lamps over the road, both sides, staggered; a hydrant mid-block with its red kerb
	for sx: float in [-1.0, 1.0]:
		var lz := z0 + (8.0 if sx > 0.0 else 25.0)
		while lz < z1 - 3.0:
			if _free(taken[sx], lz, 1.5):
				props.add("prop_lamp_cobra", "worn", Vector3(sx * (KB + 0.9), float(yw.call(0.0, lz)), lz), -90.0 * sx)
				(taken[sx] as Array).append([lz, 3.0])
			lz += 34.0
	var hz2 := clampf((z0 + z1) * 0.5 + 4.0, z0 + 8.0, z1 - 8.0)
	if _free(taken[1.0], hz2, 3.0):
		props.add("prop_hydrant_red", "rusty", Vector3(KB + 0.7, float(yw.call(0.0, hz2)), hz2), -90.0)
		RL.red_kerb_z(dec, KB, hz2 - 4.5, hz2 + 4.5, -1.0, yr, yw); (taken[1.0] as Array).append([hz2, 3.0])
	# Mexican fan palms (the strip's signature), ~11 m, clear of the junctions' sight triangles, ages varied
	for sx: float in [-1.0, 1.0]:
		var z := maxf(z0 + 6.0, 28.0) + (rr.randf_range(2.0, 6.0) if sx > 0.0 else 0.0)
		while z < minf(z1 - 2.0, Lr):
			if _free(taken[sx], z, 2.2):
				var m: String = ["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"][rr.randi() % 3]
				props.add(m, "normal", Vector3(sx * (KB + 1.0), float(yw.call(0.0, z)) - 0.06, z), rr.randf_range(0, 360), true, rr.randf_range(0.82, 1.15))
				z += rr.randf_range(10.0, 12.5)
			else:
				z += 1.0
	# drainage, manholes
	if absf(H) < 0.01:
		for sx: float in [-1.0, 1.0]:
			var iz := (z0 + z1) * 0.5 + sx * 9.0
			if _free(taken[sx], iz, 2.0): props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * KB, float(yr.call(0.0, iz)), iz), -90.0 * sx, false)
	else:
		var low := z0 + 2.5 if H > 0.0 else z1 - 2.5
		for sx: float in [-1.0, 1.0]: props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * KB, float(yr.call(0.0, low)), low), -90.0 * sx, false)
	var mz := z0 + 30.0
	while mz < z1 - 4.0:
		props.add("prop_manhole_cover", "worn", Vector3(-3.5 if int(mz) % 2 == 0 else 7.0, float(yr.call(0.0, mz)) + 0.002, mz), 0.0, false)
		if rr.randf() < 0.6: dec.add(2, Vector2(-3.5 if int(mz) % 2 == 0 else 7.0, mz), 0.0, 2.2, 2.2, yr, Color(1, 1, 1, 0.75))
		mz += 70.0
	# wear: four lanes of wheel paths, the turn queues (oil, braking marks at the T approach), cracks, gutter grit
	for lc: float in [-(L1 + L2) * 0.5, -(TL + L1) * 0.5, (TL + L1) * 0.5, (L1 + L2) * 0.5]: RL.lane_wear_y(dec, rr, lc, z0, z1, yr, 0.42)
	for k in 5: W.oil(dec, rr, Vector2(rr.randf_range(-1.0, 1.0), rr.randf_range(maxf(pz1, z0 + 2.0), z1 - 2.0)), 0.0, yr, 0.8)
	for lc: float in [-(TL + L1) * 0.5, -(L1 + L2) * 0.5]:
		for wp: float in [-0.8, 0.8]: dec.add(8, Vector2(lc + wp, z1 - 3.5), 0.0, 0.45, 6.0, yr, Color(1, 1, 1, 0.45))
	for sx: float in [-1.0, 1.0]:
		W.cracks(dec, rr, minf(sx * 2.0, sx * 9.5), z0 + 1.0, maxf(sx * 2.0, sx * 9.5), z1 - 1.0, maxi(4, int((z1 - z0) / 9.0)), yr, 0.5)
		var gz := z0 + 1.0
		while gz < z1 - 1.5:
			var L := rr.randf_range(1.6, 2.8)
			dec.add(14, Vector2(sx * (KB - 0.3), gz + L * 0.5), 0.0, 0.55, L, yr, Color(0.95, 0.9, 0.82, rr.randf_range(0.4, 0.62)))
			gz += L + rr.randf_range(2.0, 5.0)
		var wz := z0 + 0.5
		while wz < z1 - 1.0:
			var Lw := rr.randf_range(2.0, 4.0)
			dec.add(14, Vector2(sx * rr.randf_range(PK + 0.5, PR - 0.5), wz + Lw * 0.5), 0.0, 1.1, Lw, yw, Color(1, 1, 1, rr.randf_range(0.2, 0.4)))
			wz += Lw + rr.randf_range(2.0, 6.0)

## truck street stub (ind_lib section): 4.2 m lanes with a double yellow, shoulders to 6.7 (trucks pull over), kerb,
## 2 m walk; 10 m aprons every 35 m from the lattice end (plots' gates), no street trees (industrial), a cobra lamp
## line on one side, no-parking signs at the aprons; heavy wear
static func _stub_ind(g: K.Ground, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, z0: float, z1: float, H: float, yr: Callable, yw: Callable) -> void:
	var LN := 4.2; var KBi := 6.7; var PRi := 8.7; var AW := 10.0
	var aprons: Array = []
	var a := z0 + 18.0
	while a + AW * 0.5 < z1 - 14.0:
		aprons.append(a); a += 35.0
	var p: Array = [[-0.2, z0, -0.1, z1, "yellow"], [0.1, z0, 0.2, z1, "yellow"]]
	for sx: float in [-1.0, 1.0]:
		var cur := z0
		for ap: float in aprons:
			p.append([sx * LN - 0.06, cur, sx * LN + 0.06, ap - AW * 0.5, "white"]); cur = ap + AW * 0.5
		p.append([sx * LN - 0.06, cur, sx * LN + 0.06, z1, "white"])
	for i in p.size():
		var q: Array = p[i]
		p[i] = [minf(float(q[0]), float(q[2])), q[1], maxf(float(q[0]), float(q[2])), q[3], q[4]]
	K.painted_rect(g, -KBi, z0, KBi, z1, p, yr)
	var ramps: Array = []
	for ap: float in aprons: ramps.append([ap, AW])
	for sx: float in [-1.0, 1.0]:
		RL.strip_z(g, sx * KBi, sx * PRi, z0, z1, ramps, "concrete", yr, yw, 2.0, 1.5)
		for ap: float in aprons:
			props.add("prop_sign_no_parking", "dirty", Vector3(sx * (KBi + 0.5), float(yw.call(0.0, ap - AW * 0.5 - 1.0)), ap - AW * 0.5 - 1.0), -90.0 * sx)
			W.pale_patch(dec, rr, Vector2(sx * (LN + 1.3), ap), 0.0, 2.6, AW - 1.0, yr, 0.7)
			dec.add(8, Vector2(sx * 3.2, ap + 4.0), sx * 30.0, 0.7, 6.0, yr, Color(1, 1, 1, 0.55))
			dec.add(8, Vector2(sx * 3.2, ap - 4.0), -sx * 30.0, 0.7, 6.0, yr, Color(1, 1, 1, 0.55))
		RL.lane_wear_y(dec, rr, sx * LN * 0.5, z0, z1, yr, 0.5)
		for k in maxi(2, int((z1 - z0) / 15.0)): W.oil(dec, rr, Vector2(sx * (LN + 1.25), rr.randf_range(z0 + 3.0, z1 - 3.0)), 0.0, yr, 0.85)
		W.cracks(dec, rr, minf(sx * 0.3, sx * KBi), z0 + 1.0, maxf(sx * 0.3, sx * KBi), z1 - 1.0, maxi(4, int((z1 - z0) / 7.0)), yr, 0.3)
		var wz := z0 + 0.5
		while wz < z1 - 1.0:
			var Lw := rr.randf_range(2.0, 5.0)
			dec.add(14, Vector2(sx * rr.randf_range(KBi + 0.5, PRi - 0.5), wz + Lw * 0.5), 0.0, 1.1, Lw, yw, Color(1, 1, 1, rr.randf_range(0.35, 0.6)))
			wz += Lw + rr.randf_range(1.0, 4.0)
	var lz := z0 + 10.0
	while lz < z1 - 3.0:
		var ok := true
		for ap: float in aprons:
			if absf(lz - ap) < AW * 0.5 + 1.5: ok = false
		if ok: props.add("prop_lamp_cobra", "rusty", Vector3(KBi + 0.9, float(yw.call(0.0, lz)), lz), -90.0)
		lz += 40.0 if ok else 3.0
	var hz2 := clampf(z0 + 6.0, z0 + 3.0, z1 - 3.0)
	props.add("prop_hydrant_red", "rusty", Vector3(-(KBi + 0.6), float(yw.call(0.0, hz2)), hz2), 90.0)
	RL.red_kerb_z(dec, -KBi, hz2 - 4.5, hz2 + 4.5, 1.0, yr, yw)
	var low := (z0 + z1) * 0.5 if absf(H) < 0.01 else (z0 + 2.5 if H > 0.0 else z1 - 2.5)
	for sx: float in [-1.0, 1.0]: props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * KBi, float(yr.call(0.0, low)), low), -90.0 * sx, false)
	var mz := z0 + 20.0
	props.add("prop_manhole_cover", "worn", Vector3(-2.0, float(yr.call(0.0, mz)) + 0.002, mz), 0.0, false)
	dec.add(3, Vector2(-2.1, mz + 6.0), 0.0, 1.0, 12.0, yr, Color(1, 1, 1, 0.7))      # the sewer trench, patched

## Amber divided avenue stub (the pilot's high street section, site.gd): raised planted median 2.5 with a round nose
## at the lattice end, 2+2 lanes, metered parallel parking, 4.5 m walks with round tree wells (queen palms alternate
## with jacarandas: audit #12, signs read between them), victorian lamps, bins and benches facing the street; far-side
## bus stops both ways with shelters at the back of the walk
static func _stub_hs(g: K.Ground, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, z0: float, z1: float, Lr: float, H: float, hz: Callable, gz: Callable, yr: Callable, yw: Callable, stalls: Array) -> void:
	var MED := 2.5; var LNE := 9.1; var KBh := 11.5; var BLD := 16.0; var STL := 6.7
	var bus: Array = []
	if z1 - z0 > 70.0:
		bus.append({"side": -1.0, "a": z0 + 3.0, "b": z0 + 28.0, "dir": 1.0})
		bus.append({"side": 1.0, "a": z1 - 28.0, "b": z1 - 3.0, "dir": -1.0})
	var p: Array = []; var arrows: Array = []
	# the median's nose at the lattice end: asphalt round it, the island on top
	var nose := PackedVector2Array()
	for k in 13: nose.append(Vector2(MED * cos(PI * k / 12.0), z0 + MED - MED * sin(PI * k / 12.0)))
	var ctx := _leg_ctx(z0, z1, hz, [])
	var off: float = ctx["z_ofs"]
	# the walks' tree wells and the lamps between them are laid out first: meters keep clear of them
	var wells_of := {}; var lamps_of := {}
	for sx: float in [-1.0, 1.0]:
		var wl: Array = []; var lp: Array = []
		var wz0 := z0 + 10.0 + (6.0 if sx > 0.0 else 0.0)
		var wi0 := 0
		while wz0 < minf(z1 - 3.0, Lr):
			var ok := true
			for bz: Dictionary in bus:
				if float(bz["side"]) == sx and wz0 > float(bz["a"]) - 1.0 and wz0 < float(bz["b"]) + 1.0: ok = false
			if ok:
				wl.append(wz0)
				if wi0 % 2 == 1 and wz0 + 6.0 < z1 - 2.0: lp.append(wz0 + 6.0)
				wi0 += 1
			wz0 += 12.0
		wells_of[sx] = wl; lamps_of[sx] = lp
	for sx: float in [-1.0, 1.0]:
		# lane line, solid on the last 20 m of each approach
		var app0 := sx > 0.0     # x > 0 drives -z: approaches the lattice junction
		if app0:
			p.append([sx * 5.8 - 0.06, z0, sx * 5.8 + 0.06, z0 + 20.0, "white"]); _dashes(p, [sx * 5.8 - 0.06, sx * 5.8 + 0.06], z0 + 20.0, z1, DASH, "white")
		else:
			_dashes(p, [-5.86, -5.74], z0, z1 - 20.0, DASH, "white"); p.append([-5.86, z1 - 20.0, -5.74, z1, "white"])
		# parking: stalls with T marks along the lane edge, none within 7 m of either end or in a bus zone
		var d := z0 + 7.0
		while d + STL <= z1 - 8.0:
			var bad := false
			for bz: Dictionary in bus:
				if float(bz["side"]) == sx and d + STL > float(bz["a"]) and d < float(bz["b"]): bad = true
			if bad:
				d += 0.5; continue
			for e: float in [d, d + STL]: p.append([minf(sx * LNE, sx * (LNE + 0.6)), e - 0.05, maxf(sx * LNE, sx * (LNE + 0.6)), e + 0.05, "white"])
			var cz := d + STL * 0.5
			stalls.append([sx * (LNE + 1.2), cz, 180.0 if sx > 0.0 else 0.0, float(hz.call(cz)), float(gz.call(cz))])
			if rr.randf() < 0.7: W.oil(dec, rr, Vector2(sx * (LNE + 1.2), cz + (1.2 if sx > 0.0 else -1.2)), 0.0, yr, rr.randf_range(0.5, 0.8))
			var clear := true
			for lz: float in lamps_of[sx]:
				if absf(lz - d) < 1.0: clear = false
			if clear: props.add("prop_parking_meter", "worn", Vector3(sx * (KBh + 0.55), float(yw.call(0.0, d)), d), -90.0 * sx)    # facing the car
			d += STL
	arrows.append(S.arrow2("left", -(MED + 5.8) * 0.5, z1 - 10.5, z1 - 6.0))
	arrows.append(S.arrow2("right", -(5.8 + LNE) * 0.5, z1 - 10.5, z1 - 6.0))
	arrows.append(S.arrow2("left_through", (MED + 5.8) * 0.5, z0 + 12.5, z0 + 8.0))
	arrows.append(S.arrow2("through_right", (5.8 + LNE) * 0.5, z0 + 12.5, z0 + 8.0))
	for a: Dictionary in arrows: p.insert(0, (a["box"] as Array) + ["-"])
	p.insert(0, [-MED, z0 + MED, MED, z1, "-"])          # the island stands here
	p.insert(0, [-MED - 0.1, z0, MED + 0.1, z0 + MED, "-"])     # the nose tip touches the tile edge (as s_amber)
	K.painted_rect(g, -KBh, z0, KBh, z1, p, yr)
	for a: Dictionary in arrows: K.fill_arrow(g, a, yr)
	# nose: the asphalt round it (exact), then the island
	var nb := {"box": [-MED - 0.1, z0 + off, MED + 0.1, z0 + MED + off], "poly": _shift(nose, off), "c": 0.0, "axis": "x", "fill": ""}
	(ctx["extra"] as Array).append_array([z0 + MED + off])
	_finalize(ctx, z0 + off, z1 + off)
	_arrow_fill(g, ctx, nb, "asphalt", 0.0)
	_median(g, ctx, z0 + off, z1 + off, MED, true)
	# median planting: queen palms (as the pilot's Amber median; a jacaranda crown would hang into the inner lanes),
	# from 15 m (the junction's sight lines)
	var mzz := z0 + 15.0; var mk := 0
	while mzz < minf(z1 - 4.0, Lr):
		var m := "palm_queen_a" if rr.randf() < 0.5 else "palm_queen_b"
		props.add(m, "normal", Vector3(0.0, float(yw.call(0.0, mzz)) - 0.06, mzz), rr.randf_range(0, 360), true, rr.randf_range(0.85, 1.1))
		mzz += 12.0; mk += 1
	# walks with round tree wells in the furniture zone; lamps between the trees; the bus stops
	for sx: float in [-1.0, 1.0]:
		var wells: Array = wells_of[sx]
		_walk_wells(g, ctx, sx, KBh, BLD, z0 + off, z1 + off, wells, off)
		var wi := 0
		for w: float in wells:
			var m2 := ("tree_jacaranda_a" if rr.randf() < 0.5 else "tree_jacaranda_b") if wi % 2 == 0 else ("palm_queen_a" if rr.randf() < 0.5 else "palm_queen_b")
			props.add(m2, "normal", Vector3(sx * (KBh + 0.75), float(yw.call(0.0, w)) - 0.06, w), rr.randf_range(0, 360), true, rr.randf_range(0.85, 1.1))
			wi += 1
		for lz: float in lamps_of[sx]: props.add("prop_lamp_victorian", "worn", Vector3(sx * (KBh + 0.6), float(yw.call(0.0, lz)), lz), 90.0)
		for bz: Dictionary in bus:
			if float(bz["side"]) != sx: continue
			var fr: float = float(bz["b"]) if float(bz["dir"]) > 0.0 else float(bz["a"])
			var dr: float = bz["dir"]
			RL.red_kerb_z(dec, sx * KBh, float(bz["a"]), float(bz["b"]), -sx, yr, yw)
			I.add(props, "prop_bus_stop_sign", "worn", Vector3(sx * (KBh + 0.45), float(yw.call(0.0, fr - dr * 0.4)), fr - dr * 0.4), 180.0 if dr > 0.0 else 0.0)
			props.add("prop_bus_shelter", "worn", Vector3(sx * (BLD - 1.15), float(yw.call(0.0, fr - dr * 8.0)), fr - dr * 8.0), -90.0 * sx)
			props.add("prop_trash_receptacle", "dirty", Vector3(sx * (KBh + 0.6), float(yw.call(0.0, fr - dr * 12.0)), fr - dr * 12.0), 0.0)
			dec.add(14, Vector2(sx * (KBh + 1.6), fr - dr * 8.0), 0.0, 2.6, 6.0, yw, Color(1, 1, 1, 0.55))
		# bins at the ends where people turn the corner, a bench facing the street mid-block
		props.add("prop_trash_receptacle", "worn", Vector3(sx * (BLD - 0.5), float(yw.call(0.0, z0 + 3.0)), z0 + 3.0), 0.0)
		var bzz := (z0 + z1) * 0.5 + sx * 7.0
		props.add("prop_bench_bus_stop", "worn", Vector3(sx * (BLD - 0.45), float(yw.call(0.0, bzz)), bzz), -90.0 * sx)
		# wear: wheel paths, cracks, gutter, the walking line in front of the shops
		for lc: float in [sx * (MED + 1.65), sx * (MED + 4.95)]: RL.lane_wear_y(dec, rr, lc, z0, z1, yr, 0.42)
		W.cracks(dec, rr, minf(sx * (MED + 0.3), sx * (LNE - 0.3)), z0 + 1.0, maxf(sx * (MED + 0.3), sx * (LNE - 0.3)), z1 - 1.0, maxi(4, int((z1 - z0) / 10.0)), yr, 0.5)
		var gz2 := z0 + 1.0
		while gz2 < z1 - 1.5:
			var L := rr.randf_range(1.5, 2.6)
			dec.add(14, Vector2(sx * (KBh - 0.28), gz2 + L * 0.5), 0.0, 0.5, L, yr, Color(0.95, 0.9, 0.82, rr.randf_range(0.45, 0.7)))
			gz2 += L + rr.randf_range(2.0, 5.0)
		var wz2 := z0 + 0.5
		while wz2 < z1 - 1.0:
			var Lw := rr.randf_range(2.0, 4.0)
			dec.add(14, Vector2(sx * rr.randf_range(KBh + 2.0, BLD - 0.8), wz2 + Lw * 0.5), 0.0, 1.4, Lw, yw, Color(1, 1, 1, rr.randf_range(0.25, 0.45)))
			wz2 += Lw + rr.randf_range(1.0, 4.0)
	var low := (z0 + z1) * 0.5 if absf(H) < 0.01 else (z0 + 2.5 if H > 0.0 else z1 - 2.5)
	for sx: float in [-1.0, 1.0]: props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * KBh, float(yr.call(0.0, low)), low), -90.0 * sx, false)

static func _shift(poly: PackedVector2Array, dz: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in poly: out.append(Vector2(q.x, q.y + dz))
	return out

## a walk from the kerb (t = sx * kb) to the building line with round tree wells (1.5 m cells, soil 6 cm down) in its
## furniture zone, on any slope (the leg frame: ctx path runs along +z shifted by off; t = -x there, so x side sx is
## t side -sx)
static func _walk_wells(g: K.Ground, ctx: Dictionary, sx: float, kb: float, bld: float, s0: float, s1: float, wells: Array, off: float) -> void:
	var ts := -sx
	var ys: Callable = ctx["ys"]
	var ws: Array = []
	for w: float in wells: ws.append(w + off)
	ws.sort()
	var ex: Array = []
	for w: float in ws: ex.append_array([w - 0.75, w + 0.75])
	# the shared cuts already exist up to the island's needs: add the well cell edges
	(ctx["extra"] as Array).append_array(ex)
	_finalize(ctx, float(ctx.get("f0", s0)), float(ctx.get("f1", s1)))
	var cur := s0
	for w: float in ws:
		if w - 0.75 > cur: _plain(g, ctx, ts * kb, ts * (kb + 1.5), cur, w - 0.75, "concrete")
		_well_cell(g, ctx, w, ts * (kb + 0.75))
		cur = w + 0.75
	if cur < s1: _plain(g, ctx, ts * kb, ts * (kb + 1.5), cur, s1, "concrete")
	_plain(g, ctx, ts * (kb + 1.5), ts * bld, s0, s1, "concrete")
	_wall(g, ctx, ts * kb, _sub(ctx, s0, s1), ts, Callable())

static func _well_cell(g: K.Ground, ctx: Dictionary, sc: float, tc: float, a := 0.75, r := 0.6) -> void:
	var ys: Callable = ctx["ys"]
	var n := 24
	for k in n:
		var t0 := TAU * k / n; var t1 := TAU * (k + 1) / n
		var d0 := Vector2(cos(t0), sin(t0)); var d1 := Vector2(cos(t1), sin(t1))
		var c0 := Vector2(tc, sc) + d0 * r; var c1 := Vector2(tc, sc) + d1 * r
		var q0 := Vector2(tc, sc) + d0 * (a / maxf(absf(d0.x), absf(d0.y))); var q1 := Vector2(tc, sc) + d1 * (a / maxf(absf(d1.x), absf(d1.y)))
		var y := func(q: Vector2) -> float: return float(ys.call(q.y)) + KH
		g.quad("concrete", _F(ctx, c0.y, c0.x, y.call(c0)), _F(ctx, c1.y, c1.x, y.call(c1)), _F(ctx, q1.y, q1.x, y.call(q1)), _F(ctx, q0.y, q0.x, y.call(q0)))
		g.tri("mulch", _F(ctx, sc, tc, float(y.call(Vector2(tc, sc))) - 0.06), _F(ctx, c0.y, c0.x, float(y.call(c0)) - 0.06), _F(ctx, c1.y, c1.x, float(y.call(c1)) - 0.06))
		var inward := -((d0 + d1) * 0.5)
		var path: Path = ctx["path"]
		var iw := path.normal(sc) * inward.x + path.tangent(sc) * inward.y
		g.quad("curb", _F(ctx, c0.y, c0.x, float(y.call(c0)) - 0.06), _F(ctx, c1.y, c1.x, float(y.call(c1)) - 0.06), _F(ctx, c1.y, c1.x, y.call(c1)), _F(ctx, c0.y, c0.x, y.call(c0)), Vector3(iw.x, 0, iw.y), true)

## ============================================================================ W transition piece (boulevard -> W)
## s_rg_<block>_w: the biarc from the ring to W's leg end, the cross-section morphing with a smoothstep along it.
## Lateral mapping (each side): the TWLTL's solid yellow edges close in to become W's double yellow, the inner lane
## becomes W's travel lane (3.5 -> 3.1 m), the outer lane narrows to nothing (a lane drop: its line runs solid and both
## lines end before it closes), the bike lane widens into W's parking lane, the kerb moves from 10.3 to 5.7, the
## parkway 2 -> 1.5 m (the palms stay centred in it), the walk ends 2 m wide like s_wfd's; on the coast side the
## promenade's 6 m close to s_wfd's walk (the promenade ends where the bay drive's plain walk begins).
const MORPH_N := [0.0, TL - 0.15, TL - 0.05, L1, L2, KB, PK, PR]
const MORPH_W := [0.0, 0.1, 0.2, 3.3, 3.3, 5.7, 7.2, 9.2]
const MORPH_NP := [0.0, TL - 0.15, TL - 0.05, L1, L2, KB, PK, PROM]
const MORPH_WP := [0.0, 0.1, 0.2, 3.3, 3.3, 5.7, 7.2, 9.2]

static func w_plan(side: String) -> Dictionary:
	var R := ring()
	for k: String in R["nodes"]:
		var nd: Dictionary = R["nodes"][k]
		if nd.has("w"):
			var tw: Dictionary = nd["w"][side]
			var bid := "b161" if side == "S" else "b136"
			return {"name": "s_rg_%s_w" % bid, "bid": bid, "w": nd, "tw": tw, "pad_w": float(nd["pad"])}
	return {}

## the ring's height where a W transition joins it, taken on the ring side of the join (south: the boulevard before J;
## north: the 10th St T's level tile after J), so the joint has no step
static func w_join_h(side: String) -> float:
	var tw: Dictionary = w_plan(side)["tw"]
	return ring_h(float(tw["sJ"]) + (-0.01 if bool(tw["from_ring"]) else 0.01))

static func _morph(t: float, u: float, coast: bool) -> float:
	var a: Array = MORPH_NP if coast else MORPH_N
	var b: Array = MORPH_WP if coast else MORPH_W
	var x := absf(t)
	var k := a.size() - 2
	for i in a.size() - 1:
		if x <= float(a[i + 1]): k = i; break
	var f := (x - float(a[k])) / maxf(float(a[k + 1]) - float(a[k]), 1e-6)
	var w := lerpf(float(b[k]), float(b[k + 1]), f)
	return signf(t) * lerpf(x, w, u)

static func build_w_transition(side: String) -> void:
	S.hill_on = false
	var R := ring()
	var pl := w_plan(side)
	var name: String = pl["name"]
	var tw: Dictionary = pl["tw"]
	var path: Path = tw["path"]
	var L := path.length
	var from_ring: bool = tw["from_ring"]
	var sJ: float = tw["sJ"]
	var hJ := w_join_h(side); var hW: float = pl["pad_w"]
	var h0 := hJ if from_ring else hW; var h1 := hW if from_ring else hJ
	var o := path.point(0.0)
	var ys := func(s: float) -> float: return h0 + (h1 - h0) * _ss(s / L) - h0
	var uf := func(s: float) -> float: return _ss(s / L) if from_ring else _ss(1.0 - s / L)     # 0 at the ring, 1 at W
	var inl: float = R["inland"]; var out := -inl
	var tmap := func(s: float, t: float) -> float: return _morph(t, float(uf.call(s)), signf(t) == out)
	var ctx := _ctx(path, o, ys)
	ctx["tmap"] = tmap
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	# where along s the lanes have nearly closed (u 0.8)
	var s_close := 0.0
	var best := 9.0
	for k in 101:
		var sv := L * k / 100.0
		var dv := absf(float(uf.call(sv)) - 0.8)
		if dv < best: best = dv; s_close = sv
	var r0 := minf(0.0, s_close); var lane_a := 0.0 if from_ring else s_close; var lane_b := s_close if from_ring else L
	var p: Array = []
	p.append([TL - 0.15, 0.0, TL - 0.05, L, "yellow"]); p.append([-TL + 0.05, 0.0, -TL + 0.15, L, "yellow"])
	for sx: float in [-1.0, 1.0]:
		p.append([minf(sx * L1 - 0.06, sx * L1 + 0.06), lane_a, maxf(sx * L1 - 0.06, sx * L1 + 0.06), lane_b, "white"])
		p.append([minf(sx * L2 - 0.08, sx * L2 + 0.08), lane_a, maxf(sx * L2 - 0.08, sx * L2 + 0.08), lane_b, "white"])
	_reg(ctx, p)
	_finalize(ctx, 0.0, L)
	_band(g, ctx, -KB, KB, 0.0, L, p, "asphalt", 0.0)
	for sx: float in [-1.0, 1.0]:
		_strip(g, ctx, sx * KB, sx * PK, 0.0, L, [], "grass")
		_plain(g, ctx, sx * PK, sx * (PROM if sx == out else PR), 0.0, L, "concrete")
	var yy := _yfns(ctx)
	var yr: Callable = yy[0]; var yw: Callable = yy[1]
	# fixed furniture first (cobras over the road, the hydrant, the no-parking signs where the bike lane still runs,
	# kerb inlets at the low end), then the palms in the gaps (fan and queen, like W's drive), pier lamps on the bay walk
	var taken := {-1.0: [], 1.0: []}
	for sx: float in [-1.0, 1.0]:
		var lz := 20.5 + (20.0 if sx > 0.0 else 0.0)
		while lz < L - 3.0:
			props.add("prop_lamp_cobra", "worn", _P(ctx, lz, sx * (KB + 0.9)), _yaw(-path.normal(lz) * sx)); (taken[sx] as Array).append([lz, 3.0])
			lz += 40.0
	var hs := L * 0.5
	props.add("prop_hydrant_red", "worn", _P(ctx, hs, inl * (KB + 0.7)), _yaw(-path.normal(hs) * inl)); (taken[inl] as Array).append([hs, 3.0])
	_red_kerb(dec, ctx, inl * KB, hs - 4.5, hs + 4.5, inl)
	for sx: float in [-1.0, 1.0]:
		var nz := lane_a + 8.0 if from_ring else lane_b - 8.0
		props.add("prop_sign_no_parking", "worn", _P(ctx, nz, sx * (KB + 0.35)), _yaw(-path.tangent(nz) if sx > 0.0 else path.tangent(nz))); (taken[sx] as Array).append([nz, 1.0])
	var low := 3.0 if h1 > h0 else L - 3.0
	if absf(h1 - h0) < 0.01: low = L * 0.5 + 6.0
	for sx: float in [-1.0, 1.0]:
		props.add("prop_storm_drain_curb_inlet", "dirty", _P(ctx, low, sx * KB, 0.0), _yaw(-path.normal(low) * sx), false); (taken[sx] as Array).append([low, 3.0])
	for sx: float in [-1.0, 1.0]:
		var sz := 6.0 + (4.0 if sx > 0.0 else 0.0)
		while sz < L - 4.0:
			if _free(taken[sx], sz, 1.2):
				var m: String = (["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"] if rr.randf() < 0.55 else ["palm_queen_a", "palm_queen_b"])[rr.randi() % 2]
				props.add(m, "normal", _P(ctx, sz, sx * (KB + 1.0), KH - 0.06), rr.randf_range(0, 360), true, rr.randf_range(0.82, 1.12))
				sz += rr.randf_range(10.5, 12.5)
			else:
				sz += 1.0
	var pz := 9.0
	while pz < L - 3.0:
		props.add("prop_pier_lamp", "worn", _P(ctx, pz, out * (PROM - 0.4)), 0.0)
		pz += 26.0
	props.add("prop_manhole_cover", "worn", _P(ctx, L * 0.3, 2.5, 0.002), 0.0, false)
	# wear
	for sx: float in [-1.0, 1.0]:
		_lane_wear(dec, rr, ctx, sx * (TL + L1) * 0.5, 0.0, L, yr, 0.4)
		_lane_wear(dec, rr, ctx, sx * (L1 + L2) * 0.5, lane_a, lane_b, yr, 0.3)
		_cracks(dec, rr, ctx, sx * 2.0, sx * 7.0, 1.0, L - 1.0, int(L / 10.0), yr, 0.5)
		var gz := 1.0
		while gz < L - 1.5:
			var Lg := rr.randf_range(1.6, 2.8)
			_dec(dec, ctx, 14, gz + Lg * 0.5, sx * (KB - 0.3), 0.5, Lg, yr, Color(0.9, 0.82, 0.62, rr.randf_range(0.5, 0.75)) if sx == out else Color(0.95, 0.9, 0.82, rr.randf_range(0.4, 0.6)))
			gz += Lg + rr.randf_range(2.0, 5.0)
	var site := {"site": "W_" + side, "kind": "w_transition", "pos": [o.x, h0, o.y], "yaw": 0.0, "len": L, "ring_join": [path.point(0.0 if from_ring else L).x, path.point(0.0 if from_ring else L).y],
		"w_end": [(tw["E"] as Vector2).x, (tw["E"] as Vector2).y]}
	print("RG transition %s: length %.1f m, arcs %s" % [name, L, str(path.prims.map(func(q: Dictionary) -> String: return "%s r %.1f len %.1f" % [q["k"], float(q.get("r", 0.0)), float(q["len"])]))])
	_finish(root, g, props, dec, name, {"rg": site})
