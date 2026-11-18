extends RefCounted
## =====================================================================================================================
## road_amber.gd - the amber family's road kit (17 Nov 2026, road kit groups 2-5). Brief: map_dc/coronado/city_kit/
## ROADKIT_SPEC.md. Yasin, 17 Nov: "act like an architect, city planner and exterior designer, no jagged edges".
## Prefixes: j_am_ (junctions), s_am_ (legs and fillers), zz_amber_ (preview-only ground). Integration table:
## map_dc/coronado/city_kit/review/amber_sites.json (every owned site -> piece, yaw, y). Review rows: review/amber.json
## (review origin (1600, 0, -3000) + the grid position). Never edits a shared helper: it CALLS kit_lib, site, wear_lib,
## road_lib (RES_MIX, _pick_group, red_kerb_z, lane_wear_y); what it needed on slopes is written here (tree wells, kerb
## tapers, the median nose).
##
## ---------------------------------------------------------------------------------------------------------- THE PLAN
## Amber Ave (grid u = 0) is the town's spine: a divided avenue, raised planted median 2.5 m each side of the centre,
## two 3.3 m lanes each way (lane line at 5.8, lanes to 9.1), from Crown Hill's crest at 4th St down through the
## residential blocks, the city centre (6th - 8th), past the stadium (8th, west side) and the high street (9th - 11th).
## What the family owns (review/sites.json owner "amber"): 7 junctions, 8 blocks.
## 1. Cross-sections (half widths from the centre line; the building / property line is 16.0 on every section, so the
##    blocks of every zone line up):
##      hs   the pilot's high street (site.gd): parking lane 9.1-11.5 with T marks and meters, kerb 11.5, 4.5 m walk with
##           round tree wells in the 1.5 m furniture zone (jacaranda / queen palm alternating: audit #12), victorian
##           lamps between the trees, bins and benches, far-side bus shelters at the back of the walk.
##      cc   the city centre (s_cc_amber): no parking lane, kerb on the lane edge 9.1, 6.9 m walk, wells every 12 m.
##      res  NEW: the residential avenue up Crown Hill (b037-b039) and between the centre and the high street (b042):
##           the same median and lanes (median queen palms kept, a few old mexican fans among them), an edge line and
##           unmarked kerb parking (residents and their visitors, free: no meters), kerb 11.5, a 2 m GRASS PARKWAY
##           (11.5-13.5) with mixed street trees (road_lib RES_MIX, runs of a species, young to mature), a 2.5 m walk
##           to the property line 16. Front-yard character lives in the parkway: owners water it (sprinkler heads),
##           some pulled the lawn for mulch and succulents (water restrictions), some poured a concrete carriage step
##           where their front walk meets the street, so visitors step out of a parked car onto paving. Garages are
##           on the alleys behind (Coronado's pattern), so no driveway cuts. Cobra lamps over the four lanes, staggered.
## 2. Junctions (j_am_*): every Amber crossing is SIGNALISED. Level pads at the grading plan's heights. Corners: 6 m kerb
##    returns (12-segment arcs) everywhere on Amber (the pilot's radius: even radii along the whole avenue; the parking
##    lane and the arterial's bike lane add to the turning radius), two directional ramps per corner aimed at their
##    crosswalks, continental crosswalks 3 m wide on every leg, stop bars 1.2 m behind them, kerb inlets upstream of
##    the crosswalks only where water arrives (flat legs and legs falling toward the pad; a crest drains away).
##    Signal poles on the corner walks at r - 1 from the kerb return's centre (audit #1: never on the asphalt fillet).
##    - Amber x residential / high-street / centre streets (5th, 6th, 9th, 11th): the pilot's control - mast arms over
##      Amber on the far-right corners (SW for southbound, NE for northbound), posts for the side street (NW, SE),
##      street names on the post corners.
##    - Amber x 3rd St, Amber x 4th St (two-way arterials, strip section: turn lane, 2+2 lanes, bike lanes, palm
##      parkway, kerb 10.3): the two biggest crossings - mast arms on all four corners, each over its approach.
##    - Amber x 8th St (T, east only: the stadium closes the west side): mast arm for southbound on the west walk, post
##      for 8th St's westbound traffic on the west walk, mast arm for northbound on the NE corner; both Amber
##      crosswalks (stadium crowds cross here), steel bollards along the west walk where the crowds wait.
##    Tile edges: side streets 23.5 (the pilot's; resstd and art legs start there), Amber 17.5 (22.5 at the arterials).
##    Junctions in the centre (6th, 8th) are cc all round: the residential legs leaving them start with a kerb
##    extension (bulb-out: kerb 9.1 tapering to 11.5 on one smoothstep over 12 m in 0.5 m slices; parking starts after
##    it) - shorter crossings where the avenue leaves the centre, no step in the kerb.
## 3. Legs (s_am_<block>_<a|b>): from the junction tile edge along +z to the block's mid-point seam (100), the leg from
##    end a or b of the block. Approach traffic on +x (drives -z to the junction), departure on -x.
##    - Lane lines are planned per BLOCK (planner): 3 m dashes every 12 m, solid for the last 20+ m before every stop
##      bar, one phase per carriageway so the two legs of a block meet with their dashes continuing (never a half dash
##      at a seam); next to a locked sample the phase continues the sample's own (pilot / centre legs).
##    - Smooth polygon arrows (site.arrow2 + kit_lib.fill_arrow) 8.5-13 m from the tile: left+through / through+right;
##      at the 8th St T only the moves that exist (southbound: left+through, through; northbound: through,
##      through+right).
##    - Far-side bus stops both ways at every junction: each leg carries the stop of the traffic leaving its junction
##      (departure side): red kerb, the sign at the front door, a boarding pad through the parkway at the doors,
##      a bench (or a shelter where the walk is wide or the stop is busy: 3rd, 4th, the stadium at 8th).
## 4. Heights: junction pads level; a block's rise H is one smoothstep between the two junction tiles; next to a locked
##    sample (pilot P, centre C) the whole rise is inside our leg, ending flat where the sample's leg (97.5) plus our
##    2.5 m filler ends (100). Steepest: b037 Amber 3rd -> 4th, 6 m over 155 m = 5.8 %.
## 5. Fillers (s_am_fill_hs / s_am_fill_cc): the pilot's and the centre's Amber legs end at 97.5 (measured); a 2.5 m
##    piece of their exact section takes each to the lattice mid-point, placed at the sample's junction.
## 6. Dress: every item with its reason, next to the code or the spec that places it. Variety: every leg has its own
##    seed, tree runs, parkway character, wear age; no two are the same.
## =====================================================================================================================

const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const RL := preload("res://tools/city/pilot/pieces/road_lib.gd")

const MED := 2.5         # median half width
const LL := 5.8          # lane line between the two lanes
const LANE := 9.1        # outer edge of the traffic lanes
const KB_P := 11.5       # kerb with a parking lane (hs, res)
const KB_C := 9.1        # kerb without (cc)
const BLD := 16.0        # building / property line
const PKW := 13.5        # res: grass parkway 11.5 - 13.5, walk 13.5 - 16
const KH := 0.15
const STALL_R := 6.5     # unmarked residential stall length (parked-car layer)
## side streets at the junctions: kerb, parkway outer edge (= kerb: none), property line, centre line, lane half width
const SIDE := {
	"res": [5.7, 7.2, 9.2, false, 3.3],
	"hs": [5.7, 5.7, 9.7, true, 3.3],
	"cc": [3.3, 3.3, 9.7, true, 3.3],
	"art": [10.3, 12.3, 14.3, false, 8.8],
}

static func ss(t: float) -> float:
	var u := clampf(t, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

## height of a leg at z: sum of h * smoothstep over [p0, p1]
static func py(prof: Array, z: float) -> float:
	var v := 0.0
	for p: Array in prof:
		v += float(p[2]) * ss((z - float(p[0])) / (float(p[1]) - float(p[0])))
	return v

static func pg(prof: Array, z: float) -> float:
	var v := 0.0
	for p: Array in prof:
		var d := float(p[1]) - float(p[0]); var t := (z - float(p[0])) / d
		if t > 0.0 and t < 1.0: v += float(p[2]) * 6.0 * t * (1.0 - t) / d
	return v

## occupancy of the walks: [Vector2 position, radius]; things that stand somewhere keep their distance
class Occ:
	var pts: Array = []
	func is_free(p: Vector2, r: float) -> bool:
		for o: Array in pts:
			if p.distance_to(o[0]) < r + float(o[1]): return false
		return true
	func take(p: Vector2, r: float) -> void:
		pts.append([p, r])

## place a prop if its spot (or one up to 3 m along z) is free; returns true when placed
static func put(props: K.Props, occ: Occ, base: String, cond: String, p: Vector3, yaw: float, r: float, yfn: Callable, collide := true, shifts: Array = [0.0, 0.6, -0.6, 1.2, -1.2, 2.0, -2.0, 3.0, -3.0]) -> bool:
	for s: float in shifts:
		var q := Vector2(p.x, p.z + s)
		if occ.is_free(q, r):
			props.add(base, cond, Vector3(q.x, float(yfn.call(q.x, q.y)), q.y), yaw, collide)
			occ.take(q, r)
			return true
	print("SKIP %s at %.1f, %.1f (no free spot)" % [base, p.x, p.z])
	return false

## round tree well on any height function (site.tree_well is flat): 1.5 m cell, soil 6 cm down, rim face
static func tree_well_y(g: K.Ground, c: Vector2, yfn: Callable, a := 0.75, r := 0.6) -> void:
	var n := 24
	for k in n:
		var t0 := TAU * k / n; var t1 := TAU * (k + 1) / n
		var d0 := Vector2(cos(t0), sin(t0)); var d1 := Vector2(cos(t1), sin(t1))
		var c0 := c + d0 * r; var c1 := c + d1 * r
		var s0 := c + d0 * (a / maxf(absf(d0.x), absf(d0.y))); var s1 := c + d1 * (a / maxf(absf(d1.x), absf(d1.y)))
		var h0 := float(yfn.call(c0.x, c0.y)); var h1 := float(yfn.call(c1.x, c1.y))
		g.quad("concrete", Vector3(c0.x, h0, c0.y), Vector3(c1.x, h1, c1.y), Vector3(s1.x, float(yfn.call(s1.x, s1.y)), s1.y), Vector3(s0.x, float(yfn.call(s0.x, s0.y)), s0.y))
		var hc := float(yfn.call(c.x, c.y)) - 0.06
		g.tri("mulch", Vector3(c.x, hc, c.y), Vector3(c0.x, h0 - 0.06, c0.y), Vector3(c1.x, h1 - 0.06, c1.y))
		var inward := Vector3(-(d0.x + d1.x), 0, -(d0.y + d1.y))
		g.quad("curb", Vector3(c0.x, h0 - 0.06, c0.y), Vector3(c1.x, h1 - 0.06, c1.y), Vector3(c1.x, h1, c1.y), Vector3(c0.x, h0, c0.y), inward, true)

static func _zpts(x: float, a: float, b: float, step := 2.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := maxi(1, ceili((b - a) / step))
	for i in n + 1: out.append(Vector2(x, lerpf(a, b, float(i) / n)))
	return out

## =============================================================================================================== legs
## Build one leg / filler from its spec (written in the piece script by the planner, with the reasons):
##   sec        "res" | "hs" | "cc";  z0, z1  extent along +z;  prof  [[p0, p1, h], ...] height (0 at the junction)
##   nose       the median starts with a round nose at z0 (legs from a junction); fillers continue it straight
##   taper      [za, zb]: kerb extension - the kerb runs at 9.1 to za, then a smoothstep to 11.5 at zb (res legs off
##              a centre junction)
##   lines      {"app": [[za, zb], ...], "dep": [...]} lane line paint per side (planned per block)
##   arrows     [inner, outer] kinds on the approach lanes ("" = none)
##   tmarks     {"app": [z...], "dep": [...]} (hs) stall-end T marks, the sample's phase continued
##   wells      {"app": [[z, model], ...], "dep": [...]} (hs, cc) tree wells and their trees
##   palms      [z...] median palms;  fan  share of mexican fans among them
##   lamps      [[z, side], ...] (side +1 approach / -1 departure);  hyd  [z, side];  inlets [[z, side], ...]
##   bus        {"a", "b", "kind": shelter | bench | plaza} on the departure side
##   manholes   [[x, z], ...];  trees_to  res: last street tree (the other leg plants from the seam's other side)
##   age        res / hs / cc wear: "new" (resurfaced), "mid", "old"
##   carriage   res: share of frontages with a concrete carriage step;  mulch  share with a mulch + succulent parkway
##   extras     [[base, cond, side, z, off, yaw], ...]: off >= 0 from the kerb, off < 0 from the property line;
##              yaw "street" = facing the road
static func build_leg(name: String, L: Dictionary) -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var prof: Array = L.get("prof", [])
	var yr := func(_x: float, z: float) -> float: return py(prof, z)
	var yw := func(_x: float, z: float) -> float: return py(prof, z) + KH
	var z0 := float(L["z0"]); var z1 := float(L["z1"])
	var sec := String(L["sec"])
	var kb := KB_C if sec == "cc" else KB_P
	var tp: Array = L.get("taper", [])
	var kz := func(z: float) -> float:
		if tp.is_empty(): return kb
		return lerpf(KB_C, KB_P, ss((z - float(tp[0])) / (float(tp[1]) - float(tp[0]))))
	var occ := Occ.new()
	var bus: Dictionary = L.get("bus", {})
	var age := String(L.get("age", "mid"))
	# ---------------------------------------------------------------- carriageway (paint cut into the asphalt)
	var lines: Dictionary = L.get("lines", {})
	var tmarks: Dictionary = L.get("tmarks", {})
	for sx: float in [-1.0, 1.0]:
		var key := "app" if sx > 0.0 else "dep"
		var p: Array = []
		var arrows: Array = []
		if sx > 0.0:
			var kinds: Array = L.get("arrows", ["left_through", "through_right"])
			var lc := [sx * (MED + 1.65), sx * (MED + 4.95)]
			for i in 2:
				if String(kinds[i]) != "": arrows.append(S.arrow2(String(kinds[i]), float(lc[i]), z0 + 13.0, z0 + 8.5))
			for a: Dictionary in arrows: p.append((a["box"] as Array) + ["-"])
		for ln: Array in lines.get(key, []):
			p.append([minf(sx * (LL - 0.06), sx * (LL + 0.06)), float(ln[0]), maxf(sx * (LL - 0.06), sx * (LL + 0.06)), float(ln[1]), "white"])
		for tm: float in tmarks.get(key, []):     # T mark: a short line across the parking lane at each stall end
			p.append([minf(sx * LANE, sx * (LANE + 1.8)), tm - 0.05, maxf(sx * LANE, sx * (LANE + 1.8)), tm + 0.05, "white"])
		if sec != "cc":      # edge line between the lanes and the parking (from where the parking starts)
			var ez0 := z0 if tp.is_empty() else float(tp[1])
			p.append([minf(sx * (LANE - 0.06), sx * (LANE + 0.06)), ez0, maxf(sx * (LANE - 0.06), sx * (LANE + 0.06)), z1, "white"])
		var xin := sx * MED; var xk := sx * (KB_C if not tp.is_empty() else kb)
		K.painted_rect(g, minf(xin, xk), z0, maxf(xin, xk), z1, p, yr)
		for a2: Dictionary in arrows: K.fill_arrow(g, a2, yr)
		if not tp.is_empty():
			# the parking lane beyond the kerb extension, and the asphalt slivers along the taper (0.5 m slices)
			K.painted_rect(g, minf(sx * KB_C, sx * KB_P), float(tp[1]), maxf(sx * KB_C, sx * KB_P), z1, p, yr)
			var za := float(tp[0]); var zb := float(tp[1])
			var n := ceili((zb - za) / 0.5)
			for i in n:
				var q0 := lerpf(za, zb, float(i) / n); var q1 := lerpf(za, zb, float(i + 1) / n)
				var k0 := float(kz.call(q0)); var k1 := float(kz.call(q1))
				if absf(k0 - KB_C) < 1e-4 and absf(k1 - KB_C) < 1e-4: continue
				g.quad("asphalt", Vector3(sx * KB_C, py(prof, q0), q0), Vector3(sx * k0, py(prof, q0), q0), Vector3(sx * k1, py(prof, q1), q1), Vector3(sx * KB_C, py(prof, q1), q1))
	# ---------------------------------------------------------------- median: raised, planted, round nose at the junction
	var nose: bool = L.get("nose", true)
	var mz0 := z0
	if nose:
		var nc := Vector2(0.0, z0 + MED)
		var outline := K.arc(nc, MED, -PI, 0.0, 12)       # (-2.5, z0+2.5) -> tip (0, z0) -> (2.5, z0+2.5)
		g.poly("grass", outline, yw)
		for hx: float in [-1.0, 1.0]:      # asphalt in the two corners between the nose and the lane edges
			var fill := PackedVector2Array([Vector2(0.0, z0), Vector2(hx * MED, z0), Vector2(hx * MED, z0 + MED)])
			var q := K.arc(nc, MED, atan2(0.0, hx), -PI * 0.5, 8)
			for i in range(1, q.size() - 1): fill.append(q[i])
			g.poly("asphalt", fill, yr)
		var d := (outline[1] - outline[0]).normalized(); var left := Vector2(d.y, -d.x)
		g.wall_line("curb", outline, yr, yw, signf(left.dot(outline[0] - nc)))
		mz0 = z0 + MED
	g.rect("grass", -MED, mz0, MED, z1, yw)
	g.wall_line("curb", _zpts(MED, mz0, z1), yr, yw, 1.0)
	g.wall_line("curb", _zpts(-MED, mz0, z1), yr, yw, -1.0)
	var fan := float(L.get("fan", 0.0))
	var pi := 0
	for mz: float in L.get("palms", []):
		var m := "palm_queen_a" if (pi + int(mz)) % 2 == 0 else "palm_queen_b"
		if rr.randf() < fan: m = "palm_mexican_fan_a" if rr.randf() < 0.5 else "palm_mexican_fan_c"    # an older planting survives
		props.add(m, "normal", Vector3(0.0, py(prof, mz) + KH - 0.06, mz), rr.randf_range(0.0, 360.0), true, rr.randf_range(0.88, 1.1))
		pi += 1
		if sec == "res" and rr.randf() < 0.35:     # the city waters the median lawn: pop-up sprinkler heads between the palms
			var sz2 := mz + rr.randf_range(4.0, 8.0)
			# (17 Nov review, Yasin: they read as sunk lamps at eye level) no sprinkler heads in street lawns; the random
			# draws stay so every other prop keeps its place
			if sz2 < z1 - 0.5: rr.randf_range(-1.6, 1.6)
	# ---------------------------------------------------------------- walks
	var wells: Dictionary = L.get("wells", {})
	var mulch_runs := {-1.0: [], 1.0: []}
	var pads := {-1.0: [], 1.0: []}         # concrete through the parkway [za, zb]
	if not bus.is_empty():
		var bb := float(bus["b"])
		match String(bus["kind"]):
			"bench": (pads[-1.0] as Array).append([bb - 9.0, bb - 1.5])
			"plaza": (pads[-1.0] as Array).append([bb - 14.0, bb - 1.5])
	for sx: float in [-1.0, 1.0]:
		var key2 := "app" if sx > 0.0 else "dep"
		if sec == "res":
			# kerb face (follows the taper), parkway (grass / mulch / concrete), walk
			var kp := PackedVector2Array()
			var zq := z0
			while zq < z1 - 1e-4:
				kp.append(Vector2(sx * float(kz.call(zq)), zq))
				var stp := 0.5 if (not tp.is_empty() and zq >= float(tp[0]) - 0.5 and zq < float(tp[1])) else 2.0
				zq = minf(zq + stp, z1)
			kp.append(Vector2(sx * float(kz.call(z1)), z1))
			g.wall_line("curb", kp, yr, yw, -sx)
			var zp := z0
			if not tp.is_empty():       # the kerb extension is paved from the kerb to the walk
				var za2 := float(tp[0]); var zb2 := float(tp[1])
				g.rect("concrete", minf(sx * KB_C, sx * PKW), z0, maxf(sx * KB_C, sx * PKW), za2, yw)
				var n2 := ceili((zb2 - za2) / 0.5)
				for i in n2:
					var q0 := lerpf(za2, zb2, float(i) / n2); var q1 := lerpf(za2, zb2, float(i + 1) / n2)
					var k0 := float(kz.call(q0)); var k1 := float(kz.call(q1))
					var h0 := py(prof, q0) + KH; var h1 := py(prof, q1) + KH
					g.quad("concrete", Vector3(sx * k0, h0, q0), Vector3(sx * PKW, h0, q0), Vector3(sx * PKW, h1, q1), Vector3(sx * k1, h1, q1))
				zp = zb2
			# parkway runs: lawn by default; carriage steps and mulch frontages by chance (each ~15 m frontage)
			var segs: Array = []       # [za, zb, mat]
			for pd: Array in pads[sx]: segs.append([float(pd[0]), float(pd[1]), "concrete"])
			var fz := zp + rr.randf_range(2.0, 9.0)
			while fz < z1 - 8.0:
				var fl := rr.randf_range(13.0, 17.0)
				var clear := true
				for s2: Array in segs:
					if fz + fl > float(s2[0]) - 1.0 and fz < float(s2[1]) + 1.0: clear = false
				if clear:
					var roll := rr.randf()
					if roll < float(L.get("mulch", 0.15)):
						segs.append([fz + 1.0, minf(fz + fl - 1.0, z1 - 0.5), "mulch"])
						(mulch_runs[sx] as Array).append([fz + 1.0, minf(fz + fl - 1.0, z1 - 0.5)])
					elif roll < float(L.get("mulch", 0.15)) + float(L.get("carriage", 0.2)):
						var cz := fz + fl * 0.5 + rr.randf_range(-2.0, 2.0)
						segs.append([cz - 0.6, cz + 0.6, "concrete"])
						(pads[sx] as Array).append([cz - 0.6, cz + 0.6])
				fz += fl
			segs.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
			var cur := zp
			for s3: Array in segs:
				var a3 := maxf(float(s3[0]), zp); var b3 := minf(float(s3[1]), z1)
				if b3 <= a3: continue
				if a3 > cur: g.rect("grass", minf(sx * KB_P, sx * PKW), cur, maxf(sx * KB_P, sx * PKW), a3, yw)
				g.rect(String(s3[2]), minf(sx * KB_P, sx * PKW), a3, maxf(sx * KB_P, sx * PKW), b3, yw)
				cur = b3
			if cur < z1: g.rect("grass", minf(sx * KB_P, sx * PKW), cur, maxf(sx * KB_P, sx * PKW), z1, yw)
			g.rect("concrete", minf(sx * PKW, sx * BLD), z0, maxf(sx * PKW, sx * BLD), z1, yw)
		else:
			# furniture zone with round wells (soil, not cement), the walk behind it, the kerb face
			var fz2 := kb + 1.5
			var ws: Array = []
			for w: Array in wells.get(key2, []): ws.append(float(w[0]))
			ws.sort()
			var cur2 := z0
			for wz: float in ws:
				g.rect("concrete", minf(sx * kb, sx * fz2), cur2, maxf(sx * kb, sx * fz2), wz - 0.75, yw)
				tree_well_y(g, Vector2(sx * (kb + 0.75), wz), yw)
				cur2 = wz + 0.75
				occ.take(Vector2(sx * (kb + 0.75), wz), 0.8)
			g.rect("concrete", minf(sx * kb, sx * fz2), cur2, maxf(sx * kb, sx * fz2), z1, yw)
			g.rect("concrete", minf(sx * fz2, sx * BLD), z0, maxf(sx * fz2, sx * BLD), z1, yw)
			g.wall_line("curb", _zpts(sx * kb, z0, z1), yr, yw, -sx)
			for w2: Array in wells.get(key2, []):
				var wz2 := float(w2[0])
				props.add(String(w2[1]), "normal", Vector3(sx * (kb + 0.75), py(prof, wz2) + KH - 0.06, wz2), rr.randf_range(0.0, 360.0), true, rr.randf_range(0.9, 1.08))
				if rr.randf() < 0.35:      # roots lift the slabs beside some trees
					dec.add(rr.randi() % 2, Vector2(sx * (kb + 2.2), wz2 + rr.randf_range(-0.6, 0.6)), rr.randf_range(60, 120), 2.0, 0.9, yw, Color(0.3, 0.29, 0.28, 0.8))
	# ---------------------------------------------------------------- the bus stop (departure side, far side of the junction)
	if not bus.is_empty():
		var a := float(bus["a"]); var b := float(bus["b"]); var kind := String(bus["kind"])
		var sx3 := -1.0
		RL.red_kerb_z(dec, sx3 * kb, a, b, -sx3, yr, yw)          # California: no stopping in the bus zone
		var signz := b - 4.0 if kind == "shelter" else b - 2.1    # front door: the driver stops the bus at the sign
		props.add("prop_bus_stop_sign", "worn", Vector3(sx3 * (kb + 0.45), py(prof, signz) + KH, signz), -90.0 * sx3)
		occ.take(Vector2(sx3 * (kb + 0.45), signz), 2.5)       # nothing within 2.5 m of the sign (audit #15)
		if sec != "cc":   # where there is a parking lane, a sign at the zone's start keeps cars out of it
			put(props, occ, "prop_sign_no_parking", "worn", Vector3(sx3 * (kb + 0.4), 0.0, a + 0.7), -90.0 * sx3, 0.3, yw)
		match kind:
			"shelter", "plaza":
				# the shelter at the back of the walk (open to the street) keeps the kerb side clear for boarding
				var shz := b - 10.5 if kind == "shelter" else b - 8.2
				props.add("prop_bus_shelter", "worn", Vector3(sx3 * (BLD - 0.95), py(prof, shz) + KH, shz), -90.0 * sx3)
				occ.take(Vector2(sx3 * (BLD - 0.95), shz - 1.6), 1.0); occ.take(Vector2(sx3 * (BLD - 0.95), shz), 1.0); occ.take(Vector2(sx3 * (BLD - 0.95), shz + 1.6), 1.0)
				put(props, occ, "prop_trash_receptacle", "dirty", Vector3(sx3 * (BLD - 0.5), 0.0, shz - 4.1), 0.0, 0.4, yw)
				dec.add(14, Vector2(sx3 * (BLD - 2.6), shz), 0.0, 2.4, 5.5, yw, Color(1, 1, 1, 0.55))     # waiting feet
			"bench":
				put(props, occ, "prop_bench_bus_stop", "worn", Vector3(sx3 * (BLD - 0.45), 0.0, b - 7.5), -90.0 * sx3, 1.0, yw)
				put(props, occ, "prop_trash_receptacle", "dirty", Vector3(sx3 * (BLD - 0.5), 0.0, b - 4.6), 0.0, 0.4, yw)
				dec.add(14, Vector2(sx3 * (BLD - 1.6), b - 7.5), 0.0, 1.8, 4.0, yw, Color(1, 1, 1, 0.55))
		if kind != "shelter":
			dec.add(14, Vector2(sx3 * (kb + 1.0), b - 5.3), 0.0, 1.2, 6.0, yw, Color(1, 1, 1, 0.5))    # the pad people step onto
		for k in 2: W.oil(dec, rr, Vector2(sx3 * (kb - 1.4), b - 3.0 - k * 6.0), 0.0, yr, 0.75)     # buses idle with the doors open
	# ---------------------------------------------------------------- hydrant, lamps, inlets, manholes
	var hyd: Array = L.get("hyd", [])
	if not hyd.is_empty():
		var hz := float(hyd[0]); var hs := float(hyd[1])
		put(props, occ, "prop_hydrant_red", "worn" if age != "old" else "rusty", Vector3(hs * (kb + 0.7), 0.0, hz), -90.0 * hs, 0.5, yw, true, [0.0])
		RL.red_kerb_z(dec, hs * kb, hz - 4.5, hz + 4.5, -hs, yr, yw)      # 15 ft each way: the engine needs the kerb
	for lp: Array in L.get("lamps", []):
		var lz := float(lp[0]); var ls := float(lp[1])
		if sec == "res":    # cobra heads reach over the four lanes
			put(props, occ, "prop_lamp_cobra", "worn", Vector3(ls * (KB_P + 0.6), 0.0, lz), -90.0 * ls, 0.45, yw, true, [0.0, 1.0, -1.0, 2.0, -2.0])
		else:
			put(props, occ, "prop_lamp_victorian", "worn", Vector3(ls * (kb + 0.6), 0.0, lz), 90.0, 0.45, yw, true, [0.0, 0.8, -0.8, 1.6, -1.6])
	# kerb inlets: the box reaches 0.55 m under the walk and 1.4 m along the kerb, so each takes a free stretch of kerb
	# (clear of the hydrant, lamps and the bus stop placed above), shifted along the gutter if it must
	for il: Array in L.get("inlets", []):
		var iz0 := float(il[0]); var isx := float(il[1])
		for sh: float in [0.0, 2.0, -2.0, 4.0, -4.0, 6.0, -6.0, 8.0, -8.0]:
			var iz := iz0 + sh
			if iz < z0 + 2.0 or iz > z1 - 2.0: continue
			var ok := true
			for dz: float in [-1.0, 0.0, 1.0]:
				if not occ.is_free(Vector2(isx * (float(kz.call(iz)) + 0.3), iz + dz), 0.5): ok = false
			if not ok: continue
			props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(isx * float(kz.call(iz)), py(prof, iz), iz), -90.0 * isx, false)
			for dz2: float in [-1.0, 0.0, 1.0]: occ.take(Vector2(isx * (float(kz.call(iz)) + 0.3), iz + dz2), 0.5)
			dec.add(4 + rr.randi() % 2, Vector2(isx * (float(kz.call(iz)) - 0.6), iz - 2.0 * signf(pg(prof, iz) + 1e-6)), 0.0, 1.0, 2.6, yr, Color(0.62, 0.57, 0.48, 0.55))   # silt where the water slows
			break
	for mh: Array in L.get("manholes", []):
		var mx := float(mh[0]); var mzz := float(mh[1])
		props.add("prop_manhole_cover", "worn", Vector3(mx, py(prof, mzz) + 0.002, mzz), 0.0, false)
		dec.add(2 + rr.randi() % 2, Vector2(mx, mzz), rr.randf_range(-8, 8), 2.5, 2.2, yr, Color(1, 1, 1, 0.8))   # the trench was opened at least once
	# ---------------------------------------------------------------- extras (each with its reason in the spec)
	for e: Array in L.get("extras", []):
		var es := float(e[2]); var ez := float(e[3]); var eo := float(e[4])
		var ex := es * (kb + eo) if eo >= 0.0 else es * (BLD + eo)
		var eyaw := -90.0 * es if typeof(e[5]) == TYPE_STRING else float(e[5])
		var er := 0.35
		var eb := String(e[0])
		if eb.contains("bench") or eb.contains("bike_rack"): er = 1.0
		elif eb.contains("trash") or eb.contains("recycling") or eb.contains("newspaper") or eb.contains("usps"): er = 0.4
		put(props, occ, eb, String(e[1]), Vector3(ex, 0.0, ez), eyaw, er, yw)
	# ---------------------------------------------------------------- meters (hs): one per stall end, facing the car
	if sec == "hs":
		for sx4: float in [-1.0, 1.0]:
			for tm2: float in tmarks.get("app" if sx4 > 0.0 else "dep", []):
				var mp := Vector2(sx4 * (KB_P + 0.55), tm2)
				if occ.is_free(mp, 0.45):
					props.add("prop_parking_meter", "worn", Vector3(mp.x, py(prof, tm2) + KH, tm2), -90.0 * sx4)
					occ.take(mp, 0.3)
	# ---------------------------------------------------------------- residential street trees (last: they fill the gaps)
	if sec == "res":
		var grp := RL._pick_group(rr)
		var tz_end := float(L.get("trees_to", z1 - 5.5))
		var tz0 := maxf(26.0, (float(tp[1]) + 1.5) if not tp.is_empty() else 0.0)     # 25 m sight triangle at the signal
		for sx5: float in [-1.0, 1.0]:
			var tz := tz0 + (rr.randf_range(0.0, 3.0) if sx5 < 0.0 else rr.randf_range(4.0, 7.5))     # staggered
			while tz < tz_end:
				if rr.randf() < 0.08:      # one died and was never replaced: a bare, worn patch in the lawn
					var bare := Vector2(sx5 * (KB_P + 1.0), tz)
					if occ.is_free(bare, 1.0): dec.add(14, bare, rr.randf_range(0, 180), 1.1, 1.1, yw, Color(0.75, 0.68, 0.55, 0.55))
					tz += rr.randf_range(11.0, 14.0)
					continue
				for shift: float in [0.0, 1.0, -1.0, 2.0, 3.0]:
					var z := tz + shift
					if z > tz_end: break
					var tpnt := Vector2(sx5 * (KB_P + 1.0), z)
					var in_pad := false
					for pd3: Array in pads[sx5]:
						if z > float(pd3[0]) - 1.6 and z < float(pd3[1]) + 1.6: in_pad = true
					if in_pad or not occ.is_free(tpnt, 2.2): continue
					if rr.randf() < 0.45: grp = RL._pick_group(rr)     # else the run of one species goes on
					var gp: Array = RL.RES_MIX[grp]
					var model := String((gp[0] as Array)[rr.randi() % (gp[0] as Array).size()])
					props.add(model, "normal", Vector3(tpnt.x, py(prof, z) + KH - 0.06, z), rr.randf_range(0.0, 360.0), true, rr.randf_range(float(gp[2]), float(gp[3])))
					occ.take(tpnt, 0.6)
					if rr.randf() < 0.6:     # roots lift the walk beside most trees; slabs the city replaced
						dec.add(rr.randi() % 2, Vector2(sx5 * (PKW + 0.9), z + rr.randf_range(-0.8, 0.8)), rr.randf_range(60, 120), 1.9, 0.9, yw, Color(0.3, 0.29, 0.28, 0.8))
					if rr.randf() < 0.3: W.pale_patch(dec, rr, Vector2(sx5 * (PKW + 1.1), z + rr.randf_range(-1.0, 1.0)), 0.0, 1.9, 1.6, yw, 0.6)
					break
				tz += rr.randf_range(11.0, 14.0)
		# mulch frontages: succulents and a bird of paradise, low (below the drivers' eyes), clear of the trees
		for sx6: float in [-1.0, 1.0]:
			for mr: Array in mulch_runs[sx6]:
				var mz2 := float(mr[0]) + 1.2
				while mz2 < float(mr[1]) - 1.0:
					var pl: String = ["plant_agave_americana_small", "plant_agave_americana_small", "plant_bird_of_paradise"][rr.randi() % 3]
					var pp := Vector2(sx6 * (KB_P + rr.randf_range(0.8, 1.2)), mz2)
					if occ.is_free(pp, 1.0):
						props.add(String(pl), "normal", Vector3(pp.x, py(prof, mz2) + KH, mz2), rr.randf_range(0.0, 360.0))
						occ.take(pp, 0.7)
					mz2 += rr.randf_range(2.2, 3.4)
		# lawn parkways are watered by their owners: sprinkler heads along the walk edge
		for sx7: float in [-1.0, 1.0]:
			var spz := z0 + rr.randf_range(4.0, 8.0)
			while spz < z1 - 1.0:
				var sp := Vector2(sx7 * (PKW - 0.25), spz)
				var on_lawn := true
				for pd4: Array in pads[sx7]:
					if spz > float(pd4[0]) - 0.3 and spz < float(pd4[1]) + 0.3: on_lawn = false
				for mr2: Array in mulch_runs[sx7]:
					if spz > float(mr2[0]) and spz < float(mr2[1]): on_lawn = false
				if not tp.is_empty() and spz < float(tp[1]): on_lawn = false
				pass    # (17 Nov review) no sprinkler heads in the street parkway: they belong to front yards (read as sunk lamps)
				spz += rr.randf_range(8.0, 12.0)
	# ---------------------------------------------------------------- parking (recorded for the parked-car layer)
	var stalls: Array = []
	if sec == "hs":
		for sx8: float in [-1.0, 1.0]:
			var ms: Array = tmarks.get("app" if sx8 > 0.0 else "dep", []).duplicate(); ms.sort()
			for i in range(ms.size() - 1):
				var m0 := float(ms[i]); var m1 := float(ms[i + 1])
				if absf(m1 - m0 - 6.7) > 0.05: continue
				var cz2 := (m0 + m1) * 0.5
				stalls.append([sx8 * (LANE + 1.2), cz2, 180.0 if sx8 > 0.0 else 0.0, py(prof, cz2), pg(prof, cz2)])
				if rr.randf() < 0.7: W.oil(dec, rr, Vector2(sx8 * (LANE + 1.2), cz2 + (1.2 if sx8 > 0.0 else -1.2)), 0.0, yr, rr.randf_range(0.5, 0.85))
	elif sec == "res":
		for sx9: float in [-1.0, 1.0]:
			var blocked: Array = []
			if sx9 < 0.0 and not bus.is_empty(): blocked.append([float(bus["a"]), float(bus["b"])])
			if not hyd.is_empty() and float(hyd[1]) == sx9: blocked.append([float(hyd[0]) - 4.5, float(hyd[0]) + 4.5])
			var d := (float(tp[1]) + 0.5) if not tp.is_empty() else z0 + 4.0      # 20 ft clear of the crosswalk
			while d + STALL_R <= z1:
				var bad := false
				for r2: Array in blocked:
					if d + STALL_R > float(r2[0]) and d < float(r2[1]): bad = true
				if bad:
					d += 0.5; continue
				var cz3 := d + STALL_R * 0.5; var cx3 := sx9 * (LANE + 1.2)
				stalls.append([cx3, cz3, 180.0 if sx9 > 0.0 else 0.0, py(prof, cz3), pg(prof, cz3)])
				if rr.randf() < 0.55: W.oil(dec, rr, Vector2(cx3, cz3 + (1.2 if sx9 > 0.0 else -1.2)), 0.0, yr, rr.randf_range(0.35, 0.7))   # overnight drips
				d += STALL_R
	root.set_meta("stalls", stalls)
	# ---------------------------------------------------------------- wear (where the thing that makes it happens)
	var crack_n: int = {"new": 3, "mid": 8, "old": 14}[age]
	for sx10: float in [-1.0, 1.0]:
		for lc2: float in [sx10 * (MED + 1.65), sx10 * (MED + 4.95)]:
			RL.lane_wear_y(dec, rr, lc2, z0, z1, yr, 0.3 if age == "new" else 0.42)
		W.cracks(dec, rr, minf(sx10 * (MED + 0.3), sx10 * (LANE - 0.3)), z0 + 1.0, maxf(sx10 * (MED + 0.3), sx10 * (LANE - 0.3)), z1 - 1.0, maxi(1, int(crack_n * (z1 - z0) / 80.0)), yr, 0.75 if age == "new" else 0.45)
		# gutter: leaves and grime the rain carries to the kerb; on a slope long streaks running downhill
		var slope := absf(pg(prof, (z0 + z1) * 0.5)) > 0.01
		var gz := z0 + 1.0 + (float(tp[1]) - z0 if not tp.is_empty() else 0.0)
		while gz < z1 - 1.5:
			var gl := rr.randf_range(2.8, 3.8) if slope else rr.randf_range(1.5, 2.6)
			var tint := Color(0.95, 0.9, 0.82, rr.randf_range(0.45, 0.7)) if sec == "res" else Color(1, 1, 1, rr.randf_range(0.35, 0.6))
			dec.add(14, Vector2(sx10 * (kb - 0.28), gz + gl * 0.5), 0.0, 0.5, gl, yr, tint)
			gz += gl + (rr.randf_range(0.4, 1.5) if slope else rr.randf_range(2.0, 5.0))
		# the walking line: busier on the high street and in the centre
		var wz := z0 + 0.5
		var wa: Array = {"res": [0.18, 0.36], "hs": [0.3, 0.5], "cc": [0.35, 0.6]}[sec]
		var wx0 := PKW + 0.5 if sec == "res" else kb + 2.0
		while wz < z1 - 1.0:
			var wl := rr.randf_range(2.0, 4.0)
			dec.add(14, Vector2(sx10 * rr.randf_range(wx0, BLD - 0.6), wz + wl * 0.5), 0.0, 1.2, wl, yw, Color(1, 1, 1, rr.randf_range(float(wa[0]), float(wa[1]))))
			wz += wl + (rr.randf_range(1.0, 3.0) if sec != "res" else rr.randf_range(2.0, 6.0))
	if nose:
		# the queue at the light: braking marks in both wheel paths of both approach lanes, oil where engines idle
		for lc3: float in [MED + 1.65, MED + 4.95]:
			for wp: float in [-0.8, 0.8]:
				dec.add(8, Vector2(lc3 + wp, z0 + 6.0), 0.0, 0.45, 8.0, yr, Color(1, 1, 1, 0.42))
			W.oil(dec, rr, Vector2(lc3, z0 + 2.6), 0.0, yr, 0.6)
			W.oil(dec, rr, Vector2(lc3, z0 + 9.2), 0.0, yr, 0.45)
	for tr: Array in L.get("trenches", []):      # service trenches across lanes: long patches, square ends
		dec.add(3, Vector2(float(tr[0]), float(tr[1])), 90.0, 1.2, float(tr[2]), yr, Color(1, 1, 1, 0.82))
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	var mg := 0.0
	var zg := z0
	while zg <= z1:
		mg = maxf(mg, absf(pg(prof, zg))); zg += 0.5
	print("%s (%s %.1f-%.1f, rise %.2f, max grade %.1f %%): ground tris %d, props %d, stalls %d" % [name, sec, z0, z1, py(prof, z1), mg * 100.0, g.tri_count(), props.count(), stalls.size()])
	K.save_piece(root, name)


## ========================================================================================================== junctions
## A signalised Amber junction on a level pad (local frame = grid frame, yaw 0: -z north, +x east). Spec:
##   ka        Amber kerb (11.5 with parking, 9.1 in the centre);  w, e  side street sections ("" = no leg: a T)
##   r, jz, jx tile; xw_a / stop_a across Amber (|z|), xw_s / stop_s across the side streets (|x|)
##   poles     {"sw": "arm", "ne": "arm", "nw": "post", "se": "post"} (T: "w_s", "w_n" on the west walk)
##   names     corners with street name signs;  hyd [[x, z, yaw], ...];  inlets [[x, z, yaw], ...]
##   extras    [[base, cond, x, z, yaw], ...];  bollards  [[x, z], ...];  age  "mid" / "old"
static func build_junction(name: String, J: Dictionary) -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var ry := S.road_y; var yw := S.walk_y
	var kA := float(J["ka"]); var R := float(J["r"]); var JZ := float(J["jz"]); var JX := float(J["jx"])
	var xwA: Array = J["xw_a"]; var stA: Array = J["stop_a"]; var xwS: Array = J["xw_s"]; var stS: Array = J["stop_s"]
	var sides := {-1.0: String(J["w"]), 1.0: String(J["e"])}
	var kS := 0.0
	for sx: float in [-1.0, 1.0]:
		if String(sides[sx]) != "": kS = maxf(kS, float((SIDE[sides[sx]] as Array)[0]))
	var occ := Occ.new()
	# ---------------------------------------------------------------- asphalt and paint (three bands, cut exactly)
	for sz: float in [-1.0, 1.0]:
		var p: Array = []
		var za := float(xwA[0]) * sz; var zb := float(xwA[1]) * sz
		var x := -kA + 0.3
		while x + 0.6 <= kA - 0.3 + 1e-3:      # continental bars, 0.6 m every 1.2 m, running with the traffic
			p.append([x, minf(za, zb), x + 0.6, maxf(za, zb), "white"]); x += 1.2
		if sz < 0.0: p.append([-LANE, -float(stA[1]), -MED, -float(stA[0]), "white"])     # southbound stop bar
		else: p.append([MED, float(stA[0]), LANE, float(stA[1]), "white"])               # northbound
		K.painted_rect(g, -kA, minf(sz * kS, sz * JZ), kA, maxf(sz * kS, sz * JZ), p, ry)
	var pm: Array = []
	var xlo := -JX if String(sides[-1.0]) != "" else -kA
	var xhi := JX if String(sides[1.0]) != "" else kA
	for sx: float in [-1.0, 1.0]:
		var sec := String(sides[sx])
		if sec == "": continue
		var sd: Array = SIDE[sec]
		var xa := float(xwS[0]) * sx; var xb := float(xwS[1]) * sx
		var span := 2.0 * kS - 0.6
		var nb := int(floor((span + 0.6) / 1.2)); var used := nb * 0.6 + (nb - 1) * 0.6
		var z := -kS + 0.3 + (span - used) * 0.5
		for i in nb:
			pm.append([minf(xa, xb), z, maxf(xa, xb), z + 0.6, "white"]); z += 1.2
		# stop bars: eastbound (west leg) uses z > 0, westbound (east leg) z < 0; the arterial's covers its turn pocket
		var s0 := float(stS[0]); var s1 := float(stS[1])
		if sec == "art":
			if sx < 0.0: pm.append([-s1, -1.8, -s0, kS, "white"])
			else: pm.append([s0, -kS, s1, 1.8, "white"])
		else:
			var ln := float(sd[4])
			if sx < 0.0: pm.append([-s1, 0.0, -s0, ln, "white"])
			else: pm.append([s0, -ln, s1, 0.0, "white"])
		if bool(sd[3]):     # double yellow from the crosswalk to the tile edge, carried on by the side leg
			var c0 := float(xwS[1]) + 0.3
			pm.append([minf(sx * c0, sx * JX), -0.2, maxf(sx * c0, sx * JX), -0.1, "yellow"])
			pm.append([minf(sx * c0, sx * JX), 0.1, maxf(sx * c0, sx * JX), 0.2, "yellow"])
	K.painted_rect(g, xlo, -kS, xhi, kS, pm, ry)
	# ---------------------------------------------------------------- corners (or the straight west walk of a T)
	var zcA := (float(xwA[0]) + float(xwA[1])) * 0.5; var xcS := (float(xwS[0]) + float(xwS[1])) * 0.5
	var poles := {}
	for sx: float in [-1.0, 1.0]:
		var sec2 := String(sides[sx])
		if sec2 == "":
			S.sidewalk_strip(g, "z", sx * kA, sx * BLD, -JZ, JZ, [[-zcA, 1.8], [zcA, 1.8]])
			for sz: float in [-1.0, 1.0]:
				dec.add(14, Vector2(sx * (kA + 1.6), sz * zcA), 0.0, 2.6, 3.4, yw, Color(1, 1, 1, 0.45))
			continue
		var sd2: Array = SIDE[sec2]
		var kSc := float(sd2[0]); var pS := float(sd2[2])
		for sz: float in [-1.0, 1.0]:
			var c := Vector2(sx * (kA + R), sz * (kSc + R))
			var a0 := atan2(0.0, -sx); var a1 := atan2(-sz, 0.0)
			if a1 - a0 > PI: a1 -= TAU
			if a0 - a1 > PI: a1 += TAU
			var arc := K.arc(c, R, a0, a1, 12)
			var fil := arc.duplicate(); fil.append(Vector2(sx * kA, sz * kSc)); g.poly("asphalt", fil, ry)
			var dd := (arc[1] - arc[0]).normalized(); var left := Vector2(dd.y, -dd.x)
			g.wall_line("curb", arc, ry, yw, signf(left.dot((arc[0] - c).normalized())))
			# the corner walk: an exact L between the kerb return and the two property lines. Where the return ends
			# inside the property line (the centre's narrow side kerb: 15.1 < 16), the L closes on the property line
			# itself - never a self-crossing outline (the pilot's j_cc shape folds there)
			var X := maxf(BLD, kA + R); var Z := maxf(pS, kSc + R)
			var patch := arc.duplicate()
			for q: Vector2 in [Vector2(X, kSc), Vector2(X, pS), Vector2(BLD, pS), Vector2(BLD, Z), Vector2(kA, Z)]:
				var qq := Vector2(sx * q.x, sz * q.y)
				if qq.distance_to(patch[patch.size() - 1]) > 1e-3 and qq.distance_to(patch[0]) > 1e-3: patch.append(qq)
			g.poly("concrete", patch, yw)
			# the straight bits of kerb between the return's ends and where the strips start (face toward the road)
			if X > kA + R + 1e-3:
				g.wall_line("curb", PackedVector2Array([Vector2(sx * (kA + R), sz * kSc), Vector2(sx * X, sz * kSc)]), ry, yw, sx * sz)
			if Z > kSc + R + 1e-3:
				g.wall_line("curb", PackedVector2Array([Vector2(sx * kA, sz * (kSc + R)), Vector2(sx * kA, sz * Z)]), ry, yw, -sx * sz)
			# the Amber walk inside the tile (concrete: the parkway starts with the leg) with its crosswalk ramp
			S.sidewalk_strip(g, "z", sx * kA, sx * BLD, minf(sz * Z, sz * JZ), maxf(sz * Z, sz * JZ), [[sz * zcA, 1.8]])
			# the side street walk with its ramp; the arterial's palm parkway resumes after the ramp
			if sec2 == "art":
				var xr := xcS + 0.9 + 1.2
				S.sidewalk_strip(g, "x", sz * kSc, sz * pS, minf(sx * X, sx * xr), maxf(sx * X, sx * xr), [[sx * xcS, 1.8]])
				S.sidewalk_strip(g, "x", sz * kSc, sz * float(sd2[1]), minf(sx * xr, sx * JX), maxf(sx * xr, sx * JX), [], "grass")
				g.rect("concrete", minf(sx * xr, sx * JX), minf(sz * float(sd2[1]), sz * pS), maxf(sx * xr, sx * JX), maxf(sz * float(sd2[1]), sz * pS), yw)
			else:
				S.sidewalk_strip(g, "x", sz * kSc, sz * pS, minf(sx * X, sx * JX), maxf(sx * X, sx * JX), [[sx * xcS, 1.8]])
			# people wait at the ramps; gutter grime (leaves on the residential corners) round the return
			dec.add(14, Vector2(sx * (kA + 1.6), sz * zcA), 0.0, 2.6, 3.4, yw, Color(1, 1, 1, 0.45))
			dec.add(14, Vector2(sx * xcS, sz * (kSc + 1.6)), 90.0, 2.6, 3.4, yw, Color(1, 1, 1, 0.45))
			var leaf := Color(0.95, 0.9, 0.82, 0.6) if kA > 10.0 else Color(1, 1, 1, 0.55)
			for k in range(1, arc.size() - 1, 3):
				var gp := arc[k] + (arc[k] - c).normalized() * 0.3
				dec.add(14, gp, rad_to_deg(atan2((arc[k] - c).x, (arc[k] - c).y)) + 90.0, 0.5, 2.0, ry, leaf)
			if rr.randf() < 0.6:
				dec.add(0, c + Vector2(-sx, -sz).normalized() * (R - 2.4), rr.randf_range(0, 180), 1.6, 0.8, yw, Color(0.3, 0.29, 0.28, 0.8))
			# the corner's pole stands on the walk 1 m behind the kerb return (r - 1 from its centre, audit #1)
			var pp := c + Vector2(-sx, -sz).normalized() * (R - 1.0)
			poles[("n" if sz < 0.0 else "s") + ("w" if sx < 0.0 else "e")] = pp
	poles["w_s"] = Vector2(-(kA + 1.0), 8.0); poles["w_n"] = Vector2(-(kA + 1.0), -8.0)
	# ---------------------------------------------------------------- signals: mast arms over their approach, posts, names
	var yaw_of := {"sw": 180.0, "ne": 0.0, "nw": 90.0, "se": -90.0, "w_s": 180.0, "w_n": 90.0}
	var pl: Dictionary = J["poles"]
	for key: String in pl:
		var pv: Vector2 = poles[key]
		var kind := String(pl[key])
		props.add("prop_signal_mast_arm" if kind == "arm" else "prop_signal_post", "worn", Vector3(pv.x, KH, pv.y), float(yaw_of[key]))
		occ.take(pv, 0.6)
		if kind == "arm":      # keep the arm's footprint clear (validator: 6.95 x 1.01 about the pole)
			var along_x := key in ["sw", "ne", "w_s"]
			for t: float in [-3.0, -1.5, 1.5, 3.0]:
				occ.take(pv + (Vector2(t, 0.0) if along_x else Vector2(0.0, t)), 0.55)
		if kind == "post" and not key.begins_with("w_"):
			# the signal wiring's pull box in the walk beside the post (conduits run under the corner); never beside a
			# mast arm (its footprint), never where the name sign stands
			var vb := pv + Vector2(1.2 if key.ends_with("e") else -1.2, 0.0)
			if occ.is_free(vb, 0.4):
				props.add("prop_vent_box", "worn", Vector3(vb.x, KH, vb.y), 0.0, false); occ.take(vb, 0.4)
	for nk: String in J.get("names", []):
		var pv2: Vector2 = poles[nk]
		var off := Vector2(0.0, 1.2 if nk.begins_with("s") else -1.2)
		if nk in ["nw", "se"] and String(pl.get(nk, "")) == "arm": off = Vector2(1.3 if nk.ends_with("e") else -1.3, 0.0)
		if nk.begins_with("w_"): off = Vector2(-1.2, 0.0)
		put(props, occ, "prop_sign_street_names", "worn", Vector3(pv2.x + off.x, 0.0, pv2.y + off.y), 45.0, 0.45, yw, true, [0.0])
	for h: Array in J.get("hyd", []):
		put(props, occ, "prop_hydrant_red", "worn", Vector3(float(h[0]), 0.0, float(h[1])), float(h[2]), 0.45, yw, true, [0.0])
	for il: Array in J.get("inlets", []):
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(float(il[0]), 0.0, float(il[1])), float(il[2]), false)
	for b: Array in J.get("bollards", []):
		put(props, occ, "prop_bollard_steel", "worn", Vector3(float(b[0]), 0.0, float(b[1])), 0.0, 0.2, yw, true, [0.0])
	for e: Array in J.get("extras", []):
		var eb := String(e[0])
		var er := 1.0 if (eb.contains("bench") or eb.contains("rack")) else 0.4
		put(props, occ, eb, String(e[1]), Vector3(float(e[2]), 0.0, float(e[3])), float(e[4]), er, yw, true, [0.0, 0.5, -0.5, 1.0, -1.0])
	props.add("prop_manhole_cover", "worn", Vector3(-1.8 if kA > 10.0 else 1.6, 0.002, 1.8), 0.0, false)
	# ---------------------------------------------------------------- wear: turning arcs, scuffed bars in the wheel paths
	var old := String(J.get("age", "mid")) == "old"
	for q: Array in [[-6.0, -4.0, 35.0], [6.0, 4.0, 35.0], [-5.0, 4.5, -40.0], [5.0, -4.5, -40.0], [-1.5, 0.0, 10.0], [1.5, 0.0, -10.0]]:
		dec.add(8, Vector2(float(q[0]), float(q[1])), float(q[2]), 0.5, 8.0, ry, Color(1, 1, 1, 0.4 if old else 0.32))
	for sz2: float in [-1.0, 1.0]:
		for lx: float in [-7.45, -4.15, 4.15, 7.45]:
			for wp: float in [-0.8, 0.8]:
				dec.add(14, Vector2(lx + wp, sz2 * zcA), 0.0, 0.7, 3.2, ry, Color(1, 1, 1, 0.7))
	for sx3: float in [-1.0, 1.0]:
		var sec3 := String(sides[sx3])
		if sec3 == "": continue
		var lanes: Array = [-7.05, -3.55, 3.55, 7.05] if sec3 == "art" else [-1.65, 1.65]
		for lz: float in lanes:
			for wp2: float in [-0.8, 0.8]:
				dec.add(14, Vector2(sx3 * xcS, lz + wp2), 90.0, 0.7, 3.2, ry, Color(1, 1, 1, 0.65))
	W.cracks(dec, rr, -kA + 1.0, -kS - 2.0, kA - 1.0, kS + 2.0, 14 if old else 9, ry, 0.5)
	for lx2: float in [-7.45, -4.15, 4.15, 7.45]: W.lane_wear(dec, rr, lx2, -JZ, JZ, true, ry)
	dec.add(2 + rr.randi() % 2, Vector2(rr.randf_range(-4.0, 4.0), rr.randf_range(-2.0, 2.0)), rr.randf_range(0, 30), 2.4, 2.0, ry, Color(1, 1, 1, 0.85))
	dec.add(3, Vector2(rr.randf_range(-3.0, 3.0), 0.0), 90.0, 1.2, 2.0 * kA - 1.0, ry, Color(1, 1, 1, 0.8))     # a duct crossing, cut and patched
	var wmi := dec.build()
	if wmi: root.add_child(wmi)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: ground tris %d, props %d" % [name, g.tri_count(), props.count()])
	K.save_piece(root, name)


## ===================================================================================================== review ground
## PREVIEW ONLY (never in the game): grass beside Amber in the review area, in the GRID frame with absolute heights
## (the piece sits at the review origin, y 0). Per block and side a Coons patch between the property lines: the Amber
## walk height along x = 16, the side streets' walk heights along their property lines, linear on the far edge.
## G: {"blocks": [[vA, vB, padA, prof, pSA_w, pSA_e, pSB_w, pSB_e, sideA_w, sideA_e, sideB_w, sideB_e]], "xe": float,
##     "fills": [[x0, z0, x1, z1, y]]}; side* = [pad, prof] of the side street (prof along |x| from the centre)
static func build_ground(name: String, G: Dictionary) -> void:
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new()
	var xe := float(G["xe"])
	for bl: Array in G["blocks"]:
		var vA := float(bl[0]); var vB := float(bl[1]); var padA := float(bl[2]); var prof: Array = bl[3]
		for sx: float in [-1.0, 1.0]:
			var i := 0 if sx < 0.0 else 1
			var za := vA + float(bl[4 + i]); var zb := vB - float(bl[6 + i])
			var sa: Array = bl[8 + i]; var sb: Array = bl[10 + i]
			var amb := func(z: float) -> float: return padA + py(prof, z - vA) + 0.13
			var top := func(ax: float) -> float: return float(sa[0]) + py(sa[1], ax) + 0.13
			var bot := func(ax: float) -> float: return float(sb[0]) + py(sb[1], ax) + 0.13
			var nu := ceili((xe - BLD) / 6.0); var nv := maxi(1, ceili((zb - za) / 6.0))
			var hgt := func(u: float, v: float) -> float:
				var ax := lerpf(BLD, xe, u); var z := lerpf(za, zb, v)
				var Lv := float(amb.call(z)); var Tu := float(top.call(ax)); var Bu := float(bot.call(ax))
				var Rv := lerpf(float(top.call(xe)), float(bot.call(xe)), v)
				var corner := (1.0 - u) * (1.0 - v) * float(top.call(BLD)) + u * (1.0 - v) * float(top.call(xe)) + (1.0 - u) * v * float(bot.call(BLD)) + u * v * float(bot.call(xe))
				return (1.0 - u) * Lv + u * Rv + (1.0 - v) * Tu + v * Bu - corner
			for iu in nu:
				for iv in nv:
					var u0 := float(iu) / nu; var u1 := float(iu + 1) / nu; var v0 := float(iv) / nv; var v1 := float(iv + 1) / nv
					var P := func(u: float, v: float) -> Vector3: return Vector3(sx * lerpf(BLD, xe, u), float(hgt.call(u, v)), lerpf(za, zb, v))
					g.quad("grass", P.call(u0, v0), P.call(u1, v0), P.call(u1, v1), P.call(u0, v1))
	for f: Array in G.get("fills", []):
		g.rect("grass", float(f[0]), float(f[1]), float(f[2]), float(f[3]), func(_x: float, _z: float) -> float: return float(f[4]), 8.0)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	print("%s: ground tris %d" % [name, g.tri_count()])
	K.save_piece(root, name)
