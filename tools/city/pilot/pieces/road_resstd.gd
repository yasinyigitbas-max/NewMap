extends RefCounted
## =====================================================================================================================
## road_resstd.gd - the resstd family's road kit (17 Nov 2026, road kit groups 2-5). Brief: map_dc/coronado/city_kit/
## ROADKIT_SPEC.md. Yasin, 17 Nov: "act like an architect, city planner and exterior designer, no jagged edges".
## Prefixes: j_rs_ (junctions), s_rs_ (legs and fillers), zz_resstd_ (preview-only ground). Integration table:
## map_dc/coronado/city_kit/review/resstd_sites.json (every owned site -> piece, yaw, y). Review rows: review/resstd.json.
## Never edits a shared helper: it CALLS road_lib (strip_z, red_kerb_z, lane_wear_y, RES_MIX, _pick_group), kit_lib,
## site, wear_lib, ind_lib; anything it needed changed is written here instead (tree wells and tapers on z-slopes).
##
## ---------------------------------------------------------------------------------------------------------- THE PLAN
## What the family owns (review/sites.json, owner "resstd"): 35 junctions, 78 blocks.
## 1. Cross-sections. Residential (res) and standard (std) streets share the s_apt section exactly (lanes 3.3, parking to
##    the kerb at 5.7, grass parkway to 7.2, sidewalk to the property line at 9.2), so every res / std leg fits every
##    res / std junction. What differs is the MARKING and the DRESS:
##      res   no centre line, unmarked kerb parking, mixed street trees (road_lib RES_MIX), cobra lamps: a quiet street
##      std   double yellow, stall-end ticks, bus stop on the departure side (std streets are the bus collectors), the
##            zone's dress: apt (apartment band, Crown Hill west slope), civ (civic heart AND the university / hospital
##            campus edges: formal avenue trees in pairs, heritage lamps), grt (gritty edge: hardy trees, many died),
##            wfd (bay drive)
##      resc  a residential street WITH a double yellow: the side streets that lead off the high street (9th, 10th,
##            11th St) carry the pilot's 10th St centre line all the way to the next junction, so no centre line ever
##            ends in the middle of a block (Yasin: "no half lane markers")
##      pres  the pilot's own residential section (2 m parkway to 7.7, 1.5 m sidewalk): only where 10th St meets the
##            pilot's s_10th_e at x 150
##      hs    the high street's side-street section (pilot s_10th_w): 4 m sidewalk to the building line 9.7, tree wells,
##            marked stalls. Like the pilot, it runs from the Amber tile to the first alley (44-50 from Amber); beyond
##            the alley the street is residential again (the pilot's 10th St east does exactly this at x 50)
##      cc    the city centre's side-street section (s_cc_10th): no parking, kerb on the lane edge at 3.3, 6.4 m sidewalk
##            to 9.7 under the tall blocks, wells, heritage lamps, benches facing the street, a bus shelter
##      ind   the industrial truck street (s_ind): one 4.2 m lane + shoulder per side, kerb 6.7, sidewalk to 8.7
##    Changes of section happen where a planner would put them: at an alley mouth (the property line is broken there
##    anyway) and, where the kerb itself moves (std -> cc, cc -> std, res -> ind), with a smooth TAPER: kerb, parkway
##    and property line blend with a smoothstep over 12 m, tessellated every 0.5 m (no jag, no step). Parking ends
##    before a taper; the parkway grass ends square against the concrete where the taper starts.
## 2. Junctions. All-way stops (res / std are never signalled). A leg is marked 'L' (centre line stub + continental
##    crosswalk: busier, a std or resc street) or 'r' (no stub, plain two-line crosswalk), or '-' closed (a T: the
##    superblock - campus, stadium - or the shore ends the street; the kerb, parkway and sidewalk run straight across).
##    Reused where they truly fit: j_res (rrrr) and j_apt (LLLL). Built: the mixes 3L1r, 1L3r, 2L2r (adjacent and
##    opposite), the T's, and dress variants of rrrr so 14 residential corners are not one copy. Every corner: 6 m kerb
##    return (12-segment arc), corner furniture at r - 1 from the arc centre (on the walk, never the asphalt fillet:
##    audit #1), two directional ramps per corner aimed at the crosswalks, stop sign + bar on every approach, kerb
##    inlets upstream of the crosswalks, no trees on the corners (sight triangle).
## 3. Legs. A leg runs from its junction's tile edge (20 m for res / std; 23.5 from an Amber junction like
##    j_amber_10th; 26 from an arterial junction like j_strip) along +z to the seam where it meets the leg from the
##    other end (mid-block) or a locked sample's leg (measured: s_apt / s_civ / s_grt / s_ind to 100, s_cc_10th and
##    s_10th_w to 56, s_10th_e to 150). 200 m blocks between two of our junctions reuse the locked res legs
##    (s_res_a/b/c, s_res_up/dn*) and the flat std legs (s_apt, s_civ, s_grt) where they fit; every other block gets
##    its own pair of legs (own seed: own trees, wear, so no two are the same).
## 4. Heights. Junction pads are level at the grading plan's height. A block's rise H is one smoothstep between the
##    two junction TILES (whatever their size: span = length - both tiles), so the two legs meet at the seam with the
##    same height and grade; next to a flat sample leg, the whole rise happens inside our leg (a smoothstep is flat at
##    both ends, so the joint has no kink). Profile per leg: y(z) = sum of h * ss((z - p0) / (p1 - p0)).
##    Max grade 1.5 H / span: the steepest is 6.1 % (C Ave, 3rd-4th St, 6 m over 148 m), within Yasin's 8 %.
## 5. Dress, every item with its reason, next to the code that places it.
## 6. What was built (17 Nov), from the inventory (planner: scratch resstd_plan.py; table: review/resstd_sites.json):
##    junctions: 35 sites = j_res x3 + j_rs_4r_b..e (rrrr, 7), j_apt x3 (LLLL), j_rs_3l1r_a..d (7), j_rs_1l3r_a..c (5),
##    j_rs_2l2r_adj_a (2), j_rs_2l2r_opp_a (1), T's j_rs_t_lll_a/b (4: campus and stadium edges), j_rs_t_lrl_a,
##    j_rs_t_lrr_a, j_rs_t_rrr_a; symmetric pieces are turned differently at each copy.
##    legs: 78 blocks; the locked s_res_* / s_apt / s_grt are reused at most twice each where they fit exactly (200 m,
##    both junctions ours, plain residential or flat std); every other half-block has its own s_rs_<block>_<a|b>
##    (the leg from end a or b of review/sites.json's block), plus the two 7th St fillers s_rs_b098_fill (civic sample ->
##    centre sample) and s_rs_b099_fill (centre sample -> apartment sample).
## =====================================================================================================================

const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const RL := preload("res://tools/city/pilot/pieces/road_lib.gd")

const KH := 0.15
const LANE := 3.3
const STALL := 6.5
const HS_STALL := 6.7
## kind -> [kerb, parkway outer edge (= kerb: no parkway), property line, parking, centre line]
const XSEC := {
	"res": [5.7, 7.2, 9.2, true, false],
	"resc": [5.7, 7.2, 9.2, true, true],
	"pres": [5.7, 7.7, 9.2, true, true],
	"std": [5.7, 7.2, 9.2, true, true],
	"hs": [5.7, 5.7, 9.7, true, true],
	"cc": [3.3, 3.3, 9.7, false, true],
	"ind": [6.7, 6.7, 8.7, false, true],
}

static func ss(t: float) -> float:
	var u := clampf(t, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

## ------------------------------------------------------------------------------------------------ leg geometry model
static func _y(L: Dictionary, z: float) -> float:
	var v := 0.0
	for p: Array in L.prof:
		v += float(p[2]) * ss((z - float(p[0])) / (float(p[1]) - float(p[0])))
	return v

static func _grade(L: Dictionary, z: float) -> float:
	var v := 0.0
	for p: Array in L.prof:
		var d := float(p[1]) - float(p[0]); var t := (z - float(p[0])) / d
		if t > 0.0 and t < 1.0: v += float(p[2]) * 6.0 * t * (1.0 - t) / d
	return v

static func _zone(L: Dictionary, z: float) -> Array:
	for zn: Array in L.zones:
		if z >= float(zn[0]) - 1e-4 and z < float(zn[1]) - 1e-4: return zn
	return L.zones[L.zones.size() - 1]

## cross-section at z: [kerb, parkway outer, property line, parking, centre line, kind, dress]
static func _xs(L: Dictionary, z: float) -> Array:
	var zn := _zone(L, z)
	if String(zn[2]) == "taper":
		var a: Array = XSEC[zn[3]]; var b: Array = XSEC[zn[4]]
		var t := ss((z - float(zn[0])) / (float(zn[1]) - float(zn[0])))
		var k := lerpf(float(a[0]), float(b[0]), t)
		var pk := k
		if float(a[1]) > float(a[0]) + 0.01 and float(b[1]) > float(b[0]) + 0.01: pk = lerpf(float(a[1]), float(b[1]), t)
		return [k, pk, lerpf(float(a[2]), float(b[2]), t), false, bool(a[4]) and bool(b[4]), "taper", ""]
	var x: Array = XSEC[zn[2]]
	return [float(x[0]), float(x[1]), float(x[2]), bool(x[3]), bool(x[4]), String(zn[2]), String(zn[3]) if zn.size() > 3 else ""]

static func _in_alley(L: Dictionary, z: float, pad := 0.0) -> bool:
	for al: Array in L.alleys:
		if z > float(al[0]) - pad and z < float(al[1]) + pad: return true
	return false

## is z clear of everything already standing on side sx (within d metres)?
static func _clear(L: Dictionary, sx: float, z: float, d: float) -> bool:
	for o: float in L.taken[sx]:
		if absf(z - o) < d: return false
	return true

static func _take(L: Dictionary, sx: float, z: float) -> void:
	(L.taken[sx] as Array).append(z)

## =============================================================================================================== legs
## Build one leg / filler from its spec (written in the piece script, with the reason for every choice):
##   z0, z1      extent along +z (z0 = the junction tile edge, or the sample leg's end for a filler)
##   start       "j" (our junction, all-way stop), "amber" (signals), "art" (arterial junction), "seam" (filler)
##   prof        [[p0, p1, h], ...] height profile in this leg's frame (relative to the pad the piece is placed at)
##   zones       [[za, zb, kind, dress], ...] contiguous z0..z1; a taper is [za, zb, "taper", from kind, to kind]
##   alleys      [[a0, a1], ...] alley mouths crossing this leg (aprons)
##   bus         true: a bus stop on the departure side near the start (std / cc legs off a junction)
##   trees       optional species list (civic avenues: one species per street, planted at one time)
##   seed        optional extra seed text
static func build_leg(name: String, sp: Dictionary) -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var L := {"name": name, "z0": float(sp.z0), "z1": float(sp.z1), "prof": sp.get("prof", []), "zones": sp.zones,
		"alleys": sp.get("alleys", []), "start": String(sp.get("start", "j")), "taken": {-1.0: [], 1.0: []},
		"wells": {-1.0: [], 1.0: []}, "pads": [], "nopark": [], "stalls": [], "red": []}
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for(name + String(sp.get("seed", "")))
	var yr := func(_x: float, z: float) -> float: return _y(L, z)
	var yw := func(_x: float, z: float) -> float: return _y(L, z) + KH
	L.yr = yr; L.yw = yw
	var z0: float = L.z0; var z1: float = L.z1
	var jstart: bool = L.start != "seam"
	# ---------------------------------------------------------------- fixed furniture first (each with its reason)
	var first: Array = _zone(L, z0 + 0.5)
	var bus: bool = bool(sp.get("bus", false)) and jstart
	var b0 := z0 + 7.0; var b1 := z0 + 27.0
	for al: Array in L.alleys:
		if float(al[0]) - 1.5 > b0 and float(al[0]) - 1.5 < b1: b1 = float(al[0]) - 1.5
	if bus and String(first[2]) == "std":
		_bus_stop(L, props, dec, rr, b0, b1, String(first[3]))
	elif bus and String(first[2]) == "cc":
		_bus_shelter(L, props, dec, rr, b0, b1)
	# hydrant: one per leg (~100 m apart along a street, alternate sides by the leg rotations), 1 m behind the kerb,
	# 15 ft of red kerb each way where cars could park in front of it
	var hz := z0 + 20.0
	while _in_alley(L, hz, 3.0) or String(_xs(L, hz)[5]) == "taper": hz += 3.0
	if hz < z1 - 3.0:
		var hx: Array = _xs(L, hz)
		I.add(props, "prop_hydrant_red", "rusty" if String(first[3]) == "grt" else "worn", Vector3(float(hx[0]) + 0.7, float(yw.call(0.0, hz)), hz), -90.0)
		_take(L, 1.0, hz)
		if bool(hx[3]):
			L.nopark.append([1.0, hz - 4.5, hz + 4.5])
			L.red.append([1.0, hz - 4.5, hz + 4.5])
	_lamps(L, props, rr)
	_signs(L, props, dec, rr)
	_trees(L, props, dec, rr, sp)
	_stalls(L, rr)
	_extras(L, props, dec, rr)
	# ---------------------------------------------------------------- ground
	for zn: Array in L.zones:
		if String(zn[2]) == "taper": _taper_ground(L, g, zn)
		else: _const_ground(L, g, zn)
	# red kerbs (hydrants, bus zones): paint on the face and top of the kerb, following the slope
	for rk: Array in L.red:
		var sx: float = rk[0]; var kx := float(_xs(L, float(rk[1]))[0])
		RL.red_kerb_z(dec, sx * kx, float(rk[1]), float(rk[2]), -sx, yr, yw)
	_wear(L, props, dec, rr)
	root.set_meta("stalls", L.stalls)
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	var gmax := 0.0
	var zz := z0
	while zz <= z1:
		gmax = maxf(gmax, absf(_grade(L, zz))); zz += 1.0
	print("%s: z %.1f-%.1f, rise %.2f, max grade %.1f %%, ground tris %d, props %d, stalls %d" % [name, z0, z1, _y(L, z1) - _y(L, z0), gmax * 100.0, g.tri_count(), props.count(), L.stalls.size()])
	K.save_piece(root, name)

## ----------------------------------------------------------------------------------------------------- leg ground
static func _const_ground(L: Dictionary, g: K.Ground, zn: Array) -> void:
	var za: float = zn[0]; var zb: float = zn[1]; var kind: String = zn[2]
	var x: Array = XSEC[kind]
	var k: float = x[0]; var pk: float = x[1]; var P: float = x[2]
	var paints: Array = []
	# stall marks first (painted_rect: the first matching paint wins)
	for st: Array in L.stalls:
		var cz: float = st[1]; var sx := signf(float(st[0]))
		if cz < za or cz > zb: continue
		var hl := (HS_STALL if kind == "hs" else STALL) * 0.5
		for e: float in [cz - hl, cz + hl]:
			if kind == "std": paints.append([minf(sx * LANE, sx * (LANE + 0.6)), e - 0.05, maxf(sx * LANE, sx * (LANE + 0.6)), e + 0.05, "white"])
			elif kind == "hs": paints.append([minf(sx * LANE, sx * (LANE + 1.8)), e - 0.05, maxf(sx * LANE, sx * (LANE + 1.8)), e + 0.05, "white"])
	if bool(x[4]):
		paints.append([-0.2, za, -0.1, zb, "yellow"]); paints.append([0.1, za, 0.2, zb, "yellow"])
	if kind == "ind":      # the truck street's edge line (shoulder), as s_ind
		paints.append([-4.26, za, -4.14, zb, "white"]); paints.append([4.14, za, 4.26, zb, "white"])
	K.painted_rect(g, -k, za, k, zb, paints, L.yr)
	for sx: float in [-1.0, 1.0]:
		if pk > k + 0.01:
			_parkway(L, g, sx, k, pk, za, zb)
			g.rect("concrete", minf(sx * pk, sx * P), za, maxf(sx * pk, sx * P), zb, L.yw)
		else:
			_walk(L, g, sx, k, P, za, zb)

## grass parkway between the kerb and pk, with concrete alley aprons (dropped kerb) and bus boarding pads (level)
static func _parkway(L: Dictionary, g: K.Ground, sx: float, k: float, pk: float, za: float, zb: float) -> void:
	var cuts: Array = []
	for al: Array in L.alleys:
		cuts.append([float(al[0]) - 1.0, float(al[1]) + 1.0, [[(float(al[0]) + float(al[1])) * 0.5, float(al[1]) - float(al[0])]]])
	for pd: Array in L.pads:
		if float(pd[0]) == sx: cuts.append([float(pd[1]), float(pd[2]), []])
	cuts.sort_custom(func(p: Array, q: Array) -> bool: return float(p[0]) < float(q[0]))
	var cur := za
	for c: Array in cuts:
		var a := maxf(float(c[0]), za); var b := minf(float(c[1]), zb)
		if b <= a: continue
		if a > cur: RL.strip_z(g, sx * k, sx * pk, cur, a, [], "grass", L.yr, L.yw, pk - k)
		var rp: Array = []
		for r: Array in c[2]:
			if float(r[0]) > a and float(r[0]) < b: rp.append(r)
		RL.strip_z(g, sx * k, sx * pk, a, b, rp, "concrete", L.yr, L.yw, pk - k)
		cur = b
	if zb > cur: RL.strip_z(g, sx * k, sx * pk, cur, zb, [], "grass", L.yr, L.yw, pk - k)

## sidewalk with no parkway (hs / cc / ind): round tree wells cut out of the slab, alley mouths as dropped kerbs
static func _walk(L: Dictionary, g: K.Ground, sx: float, k: float, P: float, za: float, zb: float) -> void:
	var ramps: Array = []
	for al: Array in L.alleys:
		var c := (float(al[0]) + float(al[1])) * 0.5
		if c > za and c < zb: ramps.append([c, float(al[1]) - float(al[0])])
	var ws: Array = []
	for w: float in L.wells[sx]:
		if w > za + 0.8 and w < zb - 0.8: ws.append(w)
	ws.sort()
	var cur := za
	var seg := func(a: float, b: float) -> void:
		var rs: Array = []
		for r: Array in ramps:
			if float(r[0]) > a and float(r[0]) < b: rs.append(r)
		RL.strip_z(g, sx * k, sx * P, a, b, rs, "concrete", L.yr, L.yw, 1.0, 0.6)
	for w: float in ws:
		var a := w - 0.75; var b := w + 0.75
		if a > cur: seg.call(cur, a)
		_well(L, g, Vector2(sx * (k + 0.75), w))
		g.rect("concrete", minf(sx * (k + 1.5), sx * P), a, maxf(sx * (k + 1.5), sx * P), b, L.yw)
		g.wall_line("curb", PackedVector2Array([Vector2(sx * k, a), Vector2(sx * k, b)]), L.yr, L.yw, -sx)
		cur = b
	if zb > cur: seg.call(cur, zb)

## round tree well on a z-slope (site.gd tree_well follows only the pilot's x-hill): 1.5 m cell at walk level with a
## 0.6 m round opening down to soil 6 cm below, rim face in kerb concrete
static func _well(L: Dictionary, g: K.Ground, c: Vector2, a := 0.75, r := 0.6) -> void:
	var n := 24
	for k in n:
		var t0 := TAU * k / n; var t1 := TAU * (k + 1) / n
		var d0 := Vector2(cos(t0), sin(t0)); var d1 := Vector2(cos(t1), sin(t1))
		var c0 := c + d0 * r; var c1 := c + d1 * r
		var s0 := c + d0 * (a / maxf(absf(d0.x), absf(d0.y))); var s1 := c + d1 * (a / maxf(absf(d1.x), absf(d1.y)))
		var w := func(p: Vector2) -> float: return _y(L, p.y) + KH
		g.quad("concrete", Vector3(c0.x, w.call(c0), c0.y), Vector3(c1.x, w.call(c1), c1.y), Vector3(s1.x, w.call(s1), s1.y), Vector3(s0.x, w.call(s0), s0.y))
		g.tri("mulch", Vector3(c.x, w.call(c) - 0.06, c.y), Vector3(c0.x, w.call(c0) - 0.06, c0.y), Vector3(c1.x, w.call(c1) - 0.06, c1.y))
		var inward := Vector3(-(d0.x + d1.x), 0, -(d0.y + d1.y))
		g.quad("curb", Vector3(c0.x, w.call(c0) - 0.06, c0.y), Vector3(c1.x, w.call(c1) - 0.06, c1.y), Vector3(c1.x, w.call(c1), c1.y), Vector3(c0.x, w.call(c0), c0.y), inward, true)

## a taper: kerb, parkway and property line blend over the zone with a smoothstep, in 0.5 m slices (exact, no steps)
static func _taper_ground(L: Dictionary, g: K.Ground, zn: Array) -> void:
	var za: float = zn[0]; var zb: float = zn[1]
	var n := maxi(4, ceili((zb - za) / 0.5))
	var kpl := PackedVector2Array(); var kpr := PackedVector2Array()     # kerb lines (packed arrays are values: kept as locals)
	for i in n:
		var a := lerpf(za, zb, float(i) / n); var b := lerpf(za, zb, float(i + 1) / n)
		var xa := _xs(L, a + 1e-3 if i == 0 else a); var xb := _xs(L, b - 1e-3 if i == n - 1 else b)
		var ya := _y(L, a); var yb := _y(L, b)
		var ka: float = xa[0]; var kb: float = xb[0]
		# carriageway: asphalt, with the double yellow when both sections have one
		var cols: Array = [[-1.0, -0.2, "asphalt"], [-0.2, -0.1, "yellow"], [-0.1, 0.1, "asphalt"], [0.1, 0.2, "yellow"], [0.2, 1.0, "asphalt"]] if bool(xa[4]) else [[-1.0, 1.0, "asphalt"]]
		for c: Array in cols:
			var l0 := float(c[0]); var l1 := float(c[1])
			var xa0 := -ka if l0 == -1.0 else l0; var xb0 := -kb if l0 == -1.0 else l0
			var xa1 := ka if l1 == 1.0 else l1; var xb1 := kb if l1 == 1.0 else l1
			g.quad(String(c[2]), Vector3(xa0, ya, a), Vector3(xa1, ya, a), Vector3(xb1, yb, b), Vector3(xb0, yb, b))
		for sx: float in [-1.0, 1.0]:
			var pka: float = xa[1]; var pkb: float = xb[1]
			if pka > ka + 0.01:
				g.quad("grass", Vector3(sx * ka, ya + KH, a), Vector3(sx * pka, ya + KH, a), Vector3(sx * pkb, yb + KH, b), Vector3(sx * kb, yb + KH, b))
			g.quad("concrete", Vector3(sx * pka, ya + KH, a), Vector3(sx * float(xa[2]), ya + KH, a), Vector3(sx * float(xb[2]), yb + KH, b), Vector3(sx * pkb, yb + KH, b))
			if sx < 0:
				if i == 0: kpl.append(Vector2(sx * ka, a))
				kpl.append(Vector2(sx * kb, b))
			else:
				if i == 0: kpr.append(Vector2(sx * ka, a))
				kpr.append(Vector2(sx * kb, b))
	g.wall_line("curb", kpl, L.yr, L.yw, 1.0)
	g.wall_line("curb", kpr, L.yr, L.yw, -1.0)

## ---------------------------------------------------------------------------------------------------- leg furniture
## bus stop on a parkway street (s_apt's design after audit #15): far side of the junction for the departing traffic
## (the -x side drives +z), a 20 m bus zone with red kerb and no stalls, a concrete boarding pad through the parkway at
## the doors (no tree on it), the stop sign at the pad's front end where the front door stops, the bench at the back of
## the walk facing the street, a bin by the bench, a lamp at the back of the zone (people wait after dark), the speed
## sign for the departing traffic 25 m past the stop
static func _bus_stop(L: Dictionary, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, b0: float, b1: float, dress: String) -> void:
	var yw: Callable = L.yw
	var p0 := b0 + 8.0; var p1 := b0 + 15.5
	L.pads.append([-1.0, p0, p1])
	L.nopark.append([-1.0, b0, b1])
	L.red.append([-1.0, b0, b1])
	var bz := p0 + 3.5
	props.add("prop_bench_bus_stop", "dirty" if dress == "grt" else "worn", Vector3(-(9.2 - 0.45), float(yw.call(0.0, bz)), bz), 90.0)
	I.add(props, "prop_bus_stop_sign", "worn", Vector3(-(5.7 + 0.45), float(yw.call(0.0, p1 - 0.6)), p1 - 0.6), 90.0)
	props.add("prop_trash_receptacle", "dirty", Vector3(-(9.2 - 0.5), float(yw.call(0.0, bz + 3.1)), bz + 3.1), 0.0)
	for z: float in [p0, p1, bz]: _take(L, -1.0, z)
	dec.add(14, Vector2(-(7.2 + 1.0), bz), 0.0, 1.8, 4.5, yw, Color(1, 1, 1, 0.6))      # people waiting
	dec.add(14, Vector2(-(5.7 + 0.75), (p0 + p1) * 0.5), 0.0, 1.2, p1 - p0 - 0.6, yw, Color(1, 1, 1, 0.55))   # stepping off
	W.oil(dec, rr, Vector2(-(LANE + 1.2), (b0 + b1) * 0.5), 0.0, L.yr, 0.7)            # buses idle here
	var sz := b1 + 25.0
	while _in_alley(L, sz, 2.0): sz += 3.0
	if sz < float(L.z1) - 4.0 and String(_xs(L, sz)[5]) != "taper":
		props.add("prop_sign_speed25", "worn", Vector3(-(5.7 + 0.35), float(yw.call(0.0, sz)), sz), 90.0)
		_take(L, -1.0, sz)

## city-centre bus stop (no parking lane: the bus stops in the lane): a shelter at the back of the 6.4 m walk (the
## clear path stays 4.5 m), the sign at the kerb at the front door, a bin, worn ground where people wait
static func _bus_shelter(L: Dictionary, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, b0: float, b1: float) -> void:
	var yw: Callable = L.yw
	var bz := b0 + 8.0
	props.add("prop_bus_shelter", "worn", Vector3(-(9.7 - 1.1), float(yw.call(0.0, bz)), bz), 90.0)
	I.add(props, "prop_bus_stop_sign", "worn", Vector3(-(3.3 + 0.45), float(yw.call(0.0, bz + 6.0)), bz + 6.0), 90.0)
	props.add("prop_trash_receptacle", "dirty", Vector3(-(9.7 - 0.5), float(yw.call(0.0, bz + 4.0)), bz + 4.0), 0.0)
	for z: float in [bz - 3.0, bz, bz + 3.0, bz + 6.0]: _take(L, -1.0, z)
	L.red.append([-1.0, b0, b1])     # red kerb: no stopping, the bus pulls in here
	dec.add(14, Vector2(-(3.3 + 2.5), bz + 1.0), 0.0, 3.0, 6.0, yw, Color(1, 1, 1, 0.55))
	W.oil(dec, rr, Vector2(-1.65, bz + 2.0), 0.0, L.yr, 0.7)

## street lamps by section: residential cobras alternating sides every ~44 m (arm over the road; the junction has its
## own corner lamp); apartment globes staggered; civic heritage lamps in pairs opposite each other; gritty cobras on one
## side only (the cheap standard); bay drive pier lamps; downtown / centre heritage lamps every ~24 m staggered with
## the trees; truck street cobras. Lamps stand 0.6 m behind the kerb.
static func _lamps(L: Dictionary, props: K.Props, rr: RandomNumberGenerator) -> void:
	var yw: Callable = L.yw
	var z0: float = L.z0; var z1: float = L.z1
	var put := func(base: String, cond: String, sx: float, z: float, yaw: float) -> void:
		var x: Array = _xs(L, z)
		if String(x[5]) == "taper" or _in_alley(L, z, 2.5) or not _clear(L, sx, z, 2.5): return
		props.add(base, cond, Vector3(sx * (float(x[0]) + 0.6), float(yw.call(0.0, z)), z), yaw)
		_take(L, sx, z)
	var z := z0 + (16.0 if L.start != "seam" else 6.0)
	var side := 1.0 if rr.randf() < 0.5 else -1.0
	while z < z1 - 5.0:
		var x: Array = _xs(L, z)
		var kind: String = x[5]; var dress: String = x[6]
		match kind:
			"res", "resc", "pres":
				put.call("prop_lamp_cobra", "worn", side, z, -90.0 * side)
				side = -side; z += rr.randf_range(40.0, 46.0)
			"std":
				match dress:
					"civ":
						put.call("prop_lamp_victorian", "worn", 1.0, z, 90.0); put.call("prop_lamp_victorian", "worn", -1.0, z, 90.0)
						z += 33.0
					"grt":
						put.call("prop_lamp_cobra", "rusty", 1.0, z, -90.0); z += 39.0
					"wfd":
						put.call("prop_pier_lamp", "worn", side, z, 0.0); side = -side; z += 19.5
					_:
						put.call("prop_lamp_globe", "worn", side, z, 0.0); side = -side; z += 19.5
			"hs", "cc":
				put.call("prop_lamp_victorian", "worn", side, z, 90.0); side = -side; z += 12.0
			"ind":
				put.call("prop_lamp_cobra", "dirty", 1.0, z, -90.0); z += 40.0
			_:
				z += 2.0

## signs: residential and apartment streets are swept weekly (a no-parking-on-sweeping-day sign per side, past the
## alley mouth); gritty legs get tow-away signs at the alley mouth (trucks and the pound cut in there)
static func _signs(L: Dictionary, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator) -> void:
	var yw: Callable = L.yw
	for sx: float in [-1.0, 1.0]:
		var z := float(L.z0) + (46.0 if sx > 0 else 66.0) + rr.randf_range(-2.0, 2.0)
		if L.start == "seam": z = float(L.z0) + rr.randf_range(8.0, 20.0)
		var tries := 0
		while tries < 12 and (z > float(L.z1) - 4.0 or _in_alley(L, z, 2.0) or not _clear(L, sx, z, 2.5) or String(_xs(L, z)[5]) == "taper"):
			z += 3.0; tries += 1
			if z > float(L.z1) - 4.0: z = float(L.z0) + 8.0 + rr.randf_range(0.0, 6.0)
		if tries >= 12: continue
		var x: Array = _xs(L, z)
		var kind: String = x[5]; var dress: String = x[6]
		if kind in ["res", "resc", "pres"] or (kind == "std" and dress in ["apt", "grt"]):
			props.add("prop_sign_no_parking", "rusty" if dress == "grt" else "worn", Vector3(sx * (float(x[0]) + 0.35), float(yw.call(0.0, z)), z), -90.0 * sx)
			_take(L, sx, z)

## street trees. Parkway sections: residential and apartment streets are planted tree by tree over decades (road_lib
## RES_MIX: runs of one species, young to mature, irregular 11-14 m rhythm, ~8 % died and were never replaced); civic
## avenues are one species planted at once in matched pairs (the spec's "trees" list); the gritty edge kept only some
## of its hardy trees (stumps where the rest died); the bay drive has palms. Downtown and centre sidewalks: round wells,
## jacarandas alternating with queen palms (audit #12: the jacaranda's low crown hides sign bands; palms keep them
## readable). Never in the stop / signal sight triangle (the first ~8 m of a leg off a junction), never on an alley
## apron, a bus pad, a taper, or within 3 m of a lamp, sign or hydrant.
static func _trees(L: Dictionary, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sp: Dictionary) -> void:
	var yw: Callable = L.yw
	var z0: float = L.z0; var z1: float = L.z1
	var start := z0 + (8.0 if L.start != "seam" else 3.0)
	var formal: Array = sp.get("trees", ["tree_magnolia_a", "tree_magnolia_b"])
	var st := {"grp": RL._pick_group(rr)}
	var ok := func(sx: float, z: float) -> bool:
		if z < start or z > z1 - 3.0: return false
		if _in_alley(L, z, 3.5): return false
		for pd: Array in L.pads:
			if float(pd[0]) == sx and z > float(pd[1]) - 2.5 and z < float(pd[2]) + 2.5: return false
		var x: Array = _xs(L, z)
		if String(x[5]) in ["taper", "ind"]: return false
		var zn: Array = _zone(L, z)
		if z < float(zn[0]) + 1.0 or z > float(zn[1]) - 1.0: return false     # a well never straddles a section change
		var x2: Array = _xs(L, minf(z + 1.5, z1 - 0.01)); var x3: Array = _xs(L, maxf(z - 1.5, z0))
		if String(x2[5]) == "taper" or String(x3[5]) == "taper": return false
		return _clear(L, sx, z, 3.0)
	var mix_pick := func() -> Array:
		if rr.randf() < 0.45: st.grp = RL._pick_group(rr)
		var gp: Array = RL.RES_MIX[int(st.grp)]
		return [String((gp[0] as Array)[rr.randi() % (gp[0] as Array).size()]), rr.randf_range(float(gp[2]), float(gp[3]))]
	var k := 0
	for sx: float in [-1.0, 1.0]:
		var tz := start + (rr.randf_range(3.0, 7.0) if sx > 0 else rr.randf_range(0.0, 2.0))
		var wi := 0
		while tz < z1 - 3.0:
			var x: Array = _xs(L, tz)
			var kind: String = x[5]; var dress: String = x[6]
			var kx: float = x[0]
			if kind == "std" and dress == "civ":
				# formal: placed by the pair loop below
				tz += 1.0; continue
			var placed := false
			if kind in ["res", "resc", "pres"] or (kind == "std" and dress == "apt") or (kind == "std" and dress == "wfd"):
				if kind != "std" and rr.randf() < 0.08 and ok.call(sx, tz):     # a tree that died: an empty, worn patch
					dec.add(14, Vector2(sx * (kx + 0.75), tz), rr.randf_range(0, 180), 1.1, 1.1, yw, Color(0.75, 0.68, 0.55, 0.55))
					tz += rr.randf_range(11.0, 14.0); continue
				for shift: float in [0.0, 1.0, 2.0, 3.0, 4.0]:
					var z := tz + shift
					if not ok.call(sx, z): continue
					var xs2: Array = _xs(L, z)
					var pkw_c := (float(xs2[0]) + float(xs2[1])) * 0.5
					var model := ""; var scl := 1.0
					if dress == "wfd":
						model = ["palm_mexican_fan_a", "palm_queen_a", "palm_mexican_fan_b", "palm_queen_b", "palm_mexican_fan_c"][rr.randi() % 5]; scl = rr.randf_range(0.85, 1.1)
					else:
						var pk: Array = mix_pick.call(); model = pk[0]; scl = pk[1]
					props.add(model, "normal", Vector3(sx * pkw_c, float(yw.call(0.0, z)) - 0.06, z), rr.randf_range(0.0, 360.0), true, scl)
					_take(L, sx, z); placed = true
					# roots lift the sidewalk beside most trees: a crack, and slabs the city replaced (tinted grey)
					if rr.randf() < 0.6: dec.add(rr.randi() % 2, Vector2(sx * (float(xs2[1]) + 0.8), z + rr.randf_range(-0.8, 0.8)), rr.randf_range(60, 120), 1.9, 0.9, yw, Color(0.3, 0.29, 0.28, 0.8))
					if rr.randf() < 0.3: W.pale_patch(dec, rr, Vector2(sx * (float(xs2[1]) + 1.0), z + rr.randf_range(-1.0, 1.0)), 0.0, 1.9, 1.6, yw, 0.6)
					k += 1
					break
				tz += rr.randf_range(11.0, 14.0)
			elif kind == "std" and dress == "grt":
				if ok.call(sx, tz):
					if rr.randf() < 0.45:
						var gm: String = ["tree_coral_a", "palm_mexican_fan_c", "tree_torrey_pine_b", "palm_mexican_fan_a"][rr.randi() % 4]
						props.add(gm, "normal", Vector3(sx * (kx + 0.75), float(yw.call(0.0, tz)) - 0.06, tz), rr.randf_range(0, 360), true, rr.randf_range(0.8, 1.05))
						_take(L, sx, tz)
					else:     # where a tree died: a stump hole in the worn parkway
						dec.add(14, Vector2(sx * (kx + 0.75), tz), rr.randf_range(0, 180), 1.2, 1.2, yw, Color(0.55, 0.5, 0.45, 0.6))
					tz += 9.5
				else:
					tz += 1.0
			elif kind == "hs" or kind == "cc":
				var z2 := tz
				if ok.call(sx, z2) and _clear(L, sx, z2, 4.0):
					var model2 := ("tree_jacaranda_a" if wi % 2 == 0 else "palm_queen_a") if sx > 0 else ("palm_queen_b" if wi % 2 == 0 else "tree_jacaranda_b")
					props.add(model2, "normal", Vector3(sx * (kx + 0.75), float(yw.call(0.0, z2)) - 0.06, z2), rr.randf_range(0, 360), true, rr.randf_range(0.9, 1.1))
					(L.wells[sx] as Array).append(z2); _take(L, sx, z2); wi += 1
					tz += 12.0 if kind == "hs" else 10.0
				else:
					tz += 1.0
			else:
				tz += 1.0
	# civic avenue pairs
	var cz := start + 2.0
	while cz < z1 - 3.0:
		var x: Array = _xs(L, cz)
		if String(x[5]) == "std" and String(x[6]) == "civ" and ok.call(-1.0, cz) and ok.call(1.0, cz):
			for sx: float in [-1.0, 1.0]:
				# one species planted in one go, but every tree grew its own way: its own model of the pair, turn and size
				var sp2: String = formal[rr.randi() % formal.size()]
				props.add(sp2, "normal", Vector3(sx * (float(x[0]) + 0.75), float(yw.call(0.0, cz)) - 0.06, cz), rr.randf_range(0.0, 360.0), true, rr.randf_range(0.88, 1.1))
				_take(L, sx, cz)
				if rr.randf() < 0.35: dec.add(rr.randi() % 2, Vector2(sx * (float(x[1]) + 0.7), cz + rr.randf_range(-0.8, 0.8)), rr.randf_range(60, 120), 1.9, 0.9, yw, Color(0.3, 0.29, 0.28, 0.8))
			k += 1
			cz += 10.0
		else:
			cz += 1.0

## parking: every parking section, both sides, clear of the alley mouths, 7 m clear of the crosswalk at a junction,
## the hydrant, the bus zone and any taper; recorded for the parked-car layer [x, z, yaw, y, grade along z]
static func _stalls(L: Dictionary, rr: RandomNumberGenerator) -> void:
	var z0: float = L.z0; var z1: float = L.z1
	for sx: float in [-1.0, 1.0]:
		var d := z0 + (7.0 if L.start == "j" else (4.0 if L.start != "seam" else 0.0))
		while d < z1:
			var x: Array = _xs(L, d)
			var sl := HS_STALL if String(x[5]) == "hs" else STALL
			if d + sl > z1 + 1e-3: break
			var ok := bool(x[3]) and bool(_xs(L, d + sl - 0.01)[3]) and String(_xs(L, d + sl * 0.5)[5]) == String(x[5])
			if ok and _in_alley(L, d + sl * 0.5, sl * 0.5 + 1.5): ok = false
			if ok:
				for r: Array in L.nopark:
					if float(r[0]) == sx and d + sl > float(r[1]) and d < float(r[2]): ok = false
			if not ok:
				d += 0.5; continue
			var cz := d + sl * 0.5; var cx := sx * (LANE + 1.2)
			L.stalls.append([cx, cz, 180.0 if sx > 0 else 0.0, _y(L, cz), _grade(L, cz)])
			d += sl

## per-section life
static func _extras(L: Dictionary, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator) -> void:
	var yw: Callable = L.yw
	var z0: float = L.z0; var z1: float = L.z1
	for sx: float in [-1.0, 1.0]:
		var z := z0 + 4.0
		while z < z1 - 3.0:
			var x: Array = _xs(L, z)
			var kind: String = x[5]; var dress: String = x[6]
			var kx: float = x[0]
			if kind == "hs" or kind == "cc":
				# the furniture zone between the wells: a bin near each end of the sidewalk run (people leaving the
				# shops), a bike rack PARALLEL to the kerb (never across the walk), a newspaper box by the corner,
				# in the centre a bench facing the street (people watch the street, not a wall)
				if _clear(L, sx, z, 3.2) and not _in_alley(L, z, 2.5):
					var pick := rr.randi() % 5
					var p := Vector3(sx * (kx + 0.8), float(yw.call(0.0, z)), z)
					match pick:
						0: props.add("prop_trash_receptacle", "worn", p, 0.0)
						1: props.add("prop_bike_rack", "worn", Vector3(sx * (kx + 0.75), p.y, z), 90.0)
						2: props.add("prop_newspaper_box_red" if rr.randf() < 0.5 else "prop_newspaper_box_blue", "worn", Vector3(sx * (kx + 0.7), p.y, z), 90.0 * sx)   # faces the walk
						3:
							if kind == "cc": props.add("prop_park_bench", "worn", Vector3(sx * (kx + 1.1), p.y, z), -90.0 * sx)
							else: props.add("prop_recycling_receptacle", "worn", p, 0.0)
						_: pass
					if pick != 4: _take(L, sx, z)
					z += rr.randf_range(7.0, 11.0)
				else:
					z += 1.0
			elif kind == "std" and dress == "civ" and _clear(L, sx, z, 3.0) and not _in_alley(L, z, 2.0) and rr.randf() < 0.05:
				# visitors' 2 h parking: a pay station at the back of the parkway
				props.add("prop_pay_station", "worn", Vector3(sx * (float(x[1]) + 0.35), float(yw.call(0.0, z)), z), -90.0 * sx)
				_take(L, sx, z); z += 40.0
			elif kind == "std" and dress == "grt" and rr.randf() < 0.012 and _clear(L, sx, z, 3.0):
				# an abandoned shopping cart from the market up the street, on the walk
				props.add("prop_shopping_cart", "worn", Vector3(sx * rr.randf_range(7.8, 8.6), float(yw.call(0.0, z)), z), rr.randf_range(0, 360))
				_take(L, sx, z); z += 50.0
			else:
				z += 1.0

## ------------------------------------------------------------------------------------------------------- leg wear
static func _wear(L: Dictionary, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator) -> void:
	var yr: Callable = L.yr; var yw: Callable = L.yw
	var z0: float = L.z0; var z1: float = L.z1
	var flat := absf(_y(L, z1) - _y(L, z0)) < 0.05 and absf(_grade(L, (z0 + z1) * 0.5)) < 0.002
	for zn: Array in L.zones:
		var za: float = zn[0]; var zb: float = zn[1]; var kind: String = zn[2]
		var x: Array = _xs(L, (za + zb) * 0.5)
		var dress: String = x[6]
		var lane_c := LANE * 0.5
		for sx: float in [-1.0, 1.0]:
			if kind == "ind": lane_c = 2.1
			RL.lane_wear_y(dec, rr, sx * lane_c, za, zb, yr, 0.42 if kind in ["std", "cc", "hs", "ind"] else 0.35)
			var nc := int((zb - za) / (6.0 if dress == "grt" or kind == "ind" else (12.0 if dress == "civ" else 9.0)))
			W.cracks(dec, rr, minf(sx * 0.3, sx * (LANE - 0.3)), za + 1.0, maxf(sx * 0.3, sx * (LANE - 0.3)), zb - 1.0, nc, yr, 0.6 if dress == "civ" else 0.45)
			if kind == "taper": continue
			var k: float = x[0]
			# gutter: leaves from the street trees and grime carried to the kerb; on a slope long streaks run downhill;
			# sand blown up from the beach on the bay drive
			var gz := za + 1.0
			while gz < zb - 1.5:
				var Lg := rr.randf_range(1.5, 2.6) if flat else rr.randf_range(2.8, 3.6)
				var gc := Color(0.86, 0.79, 0.64, rr.randf_range(0.45, 0.65)) if dress == "wfd" else Color(0.95, 0.9, 0.82, rr.randf_range(0.45, 0.7) + (0.15 if dress == "grt" or kind == "ind" else 0.0))
				dec.add(14, Vector2(sx * (k - 0.28), gz + Lg * 0.5), 0.0, 0.5, Lg, yr, gc)
				gz += Lg + (rr.randf_range(2.0, 5.0) if flat else rr.randf_range(0.4, 1.5))
			# the walking line: dirt where people walk (busier downtown / centre, light on quiet streets)
			var P: float = x[2]; var inner: float = x[1] if float(x[1]) > k + 0.01 else k + 1.6
			var wa: Array = {"res": [0.2, 0.4], "resc": [0.22, 0.42], "pres": [0.2, 0.4], "std": [0.3, 0.55], "hs": [0.35, 0.6], "cc": [0.4, 0.65], "ind": [0.45, 0.7]}[kind]
			var wz := za + 0.5
			while wz < zb - 1.0:
				var Lw := rr.randf_range(2.0, 4.5)
				if not _in_alley(L, wz, 1.0):
					dec.add(14, Vector2(sx * rr.randf_range(inner + 0.5, P - 0.5), wz + Lw * 0.5), 0.0, 1.2, Lw, yw, Color(1, 1, 1, rr.randf_range(float(wa[0]), float(wa[1]))))
				wz += Lw + (rr.randf_range(1.0, 3.5) if kind in ["hs", "cc", "ind"] else rr.randf_range(2.0, 6.0))
			if kind in ["hs", "cc"]:      # gum and drip stains, settlement cracks on a busy walk
				for i in int((zb - za) / 8.0):
					dec.add(0, Vector2(sx * rr.randf_range(k + 1.8, P - 0.5), rr.randf_range(za + 1.0, zb - 1.0)), rr.randf_range(0, 180), rr.randf_range(1.2, 2.0), 0.8, yw, Color(0.3, 0.29, 0.28, 0.7))
			if dress == "grt" or kind == "ind":       # broken slabs replaced over the years (grey, never white)
				for i in int((zb - za) / 14.0):
					W.pale_patch(dec, rr, Vector2(sx * rr.randf_range(inner + 0.3, P - 0.3), rr.randf_range(za + 2.0, zb - 2.0)), rr.randf_range(0, 90), rr.randf_range(1.0, 1.7), rr.randf_range(1.0, 1.7), yw, 0.7)
			if dress == "wfd":
				for i in int((zb - za) / 12.0):
					dec.add(4 + i % 2, Vector2(sx * rr.randf_range(inner + 0.3, P - 0.3), rr.randf_range(za + 2.0, zb - 2.0)), rr.randf_range(0, 180), rr.randf_range(1.2, 2.6), rr.randf_range(0.6, 1.2), yw, Color(0.86, 0.79, 0.64, 0.5))
		if not flat and kind != "taper":
			# silt fan where the runoff of a slope stops (the low end of this leg, if it is not the far seam)
			var low := za + 2.5 if _y(L, za) < _y(L, zb) else zb - 2.5
			if low < z1 - 3.0 and low > z0 + 1.0:
				for sx: float in [-1.0, 1.0]:
					dec.add(4 + rr.randi() % 2, Vector2(sx * (float(x[0]) - 0.6), low), 0.0, 1.2, 3.0, yr, Color(0.4, 0.36, 0.3, 0.5))     # dark silt (a pale tile tinted light read as a white smear)
	# oil under parked engines (most stalls are used overnight)
	for st: Array in L.stalls:
		if rr.randf() < 0.6: W.oil(dec, rr, Vector2(float(st[0]), float(st[1]) + (1.2 if float(st[0]) > 0 else -1.2)), 0.0, yr, rr.randf_range(0.35, 0.7))
	# drainage: a flat leg needs a mid-block kerb inlet each side; on a slope the water runs to the lower junction
	if flat:
		for sx: float in [-1.0, 1.0]:
			var iz := minf(float(z0) + 30.5, z1 - 4.0)
			while (_in_alley(L, iz, 2.0) or not _clear(L, sx, iz, 2.0) or String(_xs(L, iz)[5]) == "taper") and iz < z1 - 4.0: iz += 2.5
			if iz < z1 - 4.0:
				props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * float(_xs(L, iz)[0]), float(yr.call(0.0, iz)), iz), -90.0 * sx, false)
				_take(L, sx, iz)
	# utility cuts: water services patched across half the road, a sewer manhole every ~60 m with its old trench patch
	var uz := z0 + rr.randf_range(12.0, 20.0)
	var us := -1.0
	while uz < z1 - 4.0:
		if not _in_alley(L, uz, 2.0) and String(_xs(L, uz)[5]) != "taper":
			dec.add(3, Vector2(us * LANE * 0.5, uz), 90.0, 0.8, LANE - 0.4, yr, Color(1, 1, 1, 0.45))     # faint: a dark tile alone reads as a shadow
		uz += rr.randf_range(22.0, 34.0); us = -us
	var mz := z0 + rr.randf_range(20.0, 28.0)
	while mz < z1 - 4.0:
		var mx := -1.6 if rr.randf() < 0.5 else 1.6
		props.add("prop_manhole_cover", "worn", Vector3(mx, float(yr.call(0.0, mz)) + 0.002, mz), 0.0, false)
		dec.add(2, Vector2(mx, mz), 0.0, 2.2, 2.0, yr, Color(1, 1, 1, 0.75))
		mz += rr.randf_range(55.0, 65.0)
	# tyres cutting into each alley, dirt carried out across the walk
	for al: Array in L.alleys:
		var ac := (float(al[0]) + float(al[1])) * 0.5; var aw := float(al[1]) - float(al[0])
		for sx: float in [-1.0, 1.0]:
			var x: Array = _xs(L, ac)
			dec.add(8, Vector2(sx * 2.4, float(al[0]) - 2.0), sx * 35.0, 0.6, 4.0, yr, Color(1, 1, 1, 0.4))
			dec.add(14, Vector2(sx * (float(x[0]) + 2.2), ac), 0.0, 2.0, aw, yw, Color(1, 1, 1, 0.5))
	# braking marks before the stop bar of the junction this leg leaves from are in the junction piece; here the marks
	# of cars accelerating away (light) at the start of a leg off a junction
	if L.start != "seam":
		for sx: float in [-1.0, 1.0]:
			dec.add(8, Vector2(-sx * LANE * 0.5 + 0.8 * sx, z0 + 3.0), 0.0, 0.45, 3.5, yr, Color(1, 1, 1, 0.25))


## ========================================================================================================== junctions
## pat: four characters for the legs N (-z), E (+x), S (+z), W (-x): 'L' a lined leg (std / resc: double yellow stub,
## continental crosswalk), 'r' a plain residential leg (no stub, two-line crosswalk), '-' closed (a T).
## opts: "lamp" corner [sx, sz] (default picked), "hyd" corner, "box" "usps" / "news" / "" , "bins" bool.
const XW := [12.6, 15.6]
const STOP := [16.6, 17.1]
const J := 20.0

static func junction(name: String, pat: String, opts := {}) -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var ry := S.road_y
	var KB := A.KERB; var RR := A.R; var PK := A.PKW; var PR := A.PROP
	var open := {"N": pat[0] != "-", "E": pat[1] != "-", "S": pat[2] != "-", "W": pat[3] != "-"}
	var mark := {"N": pat[0], "E": pat[1], "S": pat[2], "W": pat[3]}
	var xc: float = (float(XW[0]) + float(XW[1])) * 0.5
	# ---- crosswalk paint across a leg: lines across the leg at |s| in XW
	var xwalk := func(along_x: bool, sg: float, m: String) -> Array:
		var out: Array = []
		if m == "L":      # continental bars, 0.6 m every 1.2 m, lined up with the wheel paths left clear
			var t := -KB + 0.3
			while t + 0.6 <= KB - 0.3 + 1e-3:
				if along_x: out.append([minf(sg * XW[0], sg * XW[1]), t, maxf(sg * XW[0], sg * XW[1]), t + 0.6, "white"])
				else: out.append([t, minf(sg * XW[0], sg * XW[1]), t + 0.6, maxf(sg * XW[0], sg * XW[1]), "white"])
				t += 1.2
		else:             # a quiet corner: two lines
			for e: float in [float(XW[0]), float(XW[1]) - 0.3]:
				if along_x: out.append([minf(sg * e, sg * (e + 0.3)), -KB + 0.15, maxf(sg * e, sg * (e + 0.3)), KB - 0.15, "white"])
				else: out.append([-KB + 0.15, minf(sg * e, sg * (e + 0.3)), KB - 0.15, maxf(sg * e, sg * (e + 0.3)), "white"])
		return out
	# ---- the E-W band (|z| <= KB) from the W mouth to the E mouth (or the kerb of a closed side)
	var pa: Array = []
	for sd: Array in [["E", 1.0], ["W", -1.0]]:
		var sx: float = sd[1]
		if not open[sd[0]]: continue
		pa.append_array(xwalk.call(true, sx, mark[sd[0]]))
		if sx > 0: pa.append([STOP[0], -LANE, STOP[1], 0.0, "white"])      # westbound arrives on z < 0
		else: pa.append([-STOP[1], 0.0, -STOP[0], LANE, "white"])
		if mark[sd[0]] == "L":
			var a0 := minf(sx * STOP[1], sx * J); var a1 := maxf(sx * STOP[1], sx * J)
			pa.append([a0, -0.2, a1, -0.1, "yellow"]); pa.append([a0, 0.1, a1, 0.2, "yellow"])
	var xa := -J if open.W else -KB; var xb := J if open.E else KB
	K.painted_rect(g, xa, -KB, xb, KB, pa, ry)
	for sd: Array in [["S", 1.0], ["N", -1.0]]:
		var sz: float = sd[1]
		if not open[sd[0]]: continue
		var ps: Array = xwalk.call(false, sz, mark[sd[0]])
		if sz < 0: ps.append([-LANE, -STOP[1], 0.0, -STOP[0], "white"])     # southbound arrives on x < 0
		else: ps.append([0.0, STOP[0], LANE, STOP[1], "white"])
		if mark[sd[0]] == "L":
			var b0 := minf(sz * STOP[1], sz * J); var b1 := maxf(sz * STOP[1], sz * J)
			ps.append([-0.2, b0, -0.1, b1, "yellow"]); ps.append([0.1, b0, 0.2, b1, "yellow"])
		K.painted_rect(g, -KB, minf(sz * KB, sz * J), KB, maxf(sz * KB, sz * J), ps, ry)
	# ---- corners where both legs are open: 12-segment kerb return, asphalt fillet, corner sidewalk to the lot corner,
	# parkway (grass, concrete ramp at the crosswalk) and sidewalk along both legs out to the tile edge
	var corners: Array = []
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var ns := "S" if sz > 0 else "N"; var ew := "E" if sx > 0 else "W"
			if not (open[ns] and open[ew]): continue
			corners.append([sx, sz])
			var c := Vector2(sx * (KB + RR), sz * (KB + RR))
			var a0 := atan2(0.0, -sx); var a1 := atan2(-sz, 0.0)
			if a1 - a0 > PI: a1 -= TAU
			if a0 - a1 > PI: a1 += TAU
			var arc := K.arc(c, RR, a0, a1, 12)
			var fil := arc.duplicate(); fil.append(Vector2(sx * KB, sz * KB)); g.poly("asphalt", fil, ry)
			var dd := (arc[1] - arc[0]).normalized(); var left := Vector2(dd.y, -dd.x)
			g.wall_line("curb", arc, ry, S.walk_y, signf(left.dot((arc[0] - c).normalized())))
			var patch := arc.duplicate()
			patch.append(Vector2(sx * (KB + RR), sz * PR)); patch.append(Vector2(sx * PR, sz * PR)); patch.append(Vector2(sx * PR, sz * (KB + RR)))
			g.poly("concrete", patch, S.walk_y)
			var t := KB + RR
			RL._pkw_ramp(g, "x", sz * KB, sz * PK, sx * t, sx * J, sx * xc)
			g.rect("concrete", minf(sx * t, sx * J), minf(sz * PK, sz * PR), maxf(sx * t, sx * J), maxf(sz * PK, sz * PR), S.walk_y)
			RL._pkw_ramp(g, "z", sx * KB, sx * PK, sz * t, sz * J, sz * xc)
			g.rect("concrete", minf(sx * PK, sx * PR), minf(sz * t, sz * J), maxf(sx * PK, sx * PR), maxf(sz * t, sz * J), S.walk_y)
			# people wait at the ramps; the corner gets the dirt of every walker; leaves blown into the corner gutter
			dec.add(14, Vector2(sx * xc, sz * (KB + 1.6)), 0.0, 3.0, 2.2, S.walk_y, Color(1, 1, 1, rr.randf_range(0.3, 0.5)))
			dec.add(14, Vector2(sx * (KB + 1.6), sz * xc), 90.0, 3.0, 2.2, S.walk_y, Color(1, 1, 1, rr.randf_range(0.3, 0.5)))
			dec.add(14, c + Vector2(-sx, -sz).normalized() * (RR - 1.0), 45.0, 2.6, 2.6, S.walk_y, Color(1, 1, 1, 0.4))
			dec.add(14, c + Vector2(-sx, -sz).normalized() * (RR + 0.3), 45.0 * sx * sz, 2.4, 0.6, ry, Color(0.95, 0.9, 0.82, 0.6))
	# ---- a closed side (T): the kerb, parkway and sidewalk run straight across the whole tile; ramps where the two
	# crosswalks of the through street land
	var closed := ""
	for sd: String in ["N", "E", "S", "W"]:
		if not open[sd]: closed = sd
	if closed != "":
		var sgn := 1.0 if closed in ["E", "S"] else -1.0
		var along := "z" if closed in ["E", "W"] else "x"
		var cur := -J
		for c2: float in [-xc, xc]:
			var r0 := c2 - 1.5; var r1 := c2 + 1.5
			S.sidewalk_strip(g, along, sgn * KB, sgn * PK, cur, r0, [], "grass")
			S.sidewalk_strip(g, along, sgn * KB, sgn * PK, r0, r1, [[c2, 3.0]], "concrete", 1.4, 0.0, 0.6)
			cur = r1
		S.sidewalk_strip(g, along, sgn * KB, sgn * PK, cur, J, [], "grass")
		if along == "z": g.rect("concrete", minf(sgn * PK, sgn * PR), -J, maxf(sgn * PK, sgn * PR), J, S.walk_y)
		else: g.rect("concrete", -J, minf(sgn * PK, sgn * PR), J, maxf(sgn * PK, sgn * PR), S.walk_y)
		for c2: float in [-xc, xc]:
			var wp := Vector2(sgn * (KB + 1.6), c2) if along == "z" else Vector2(c2, sgn * (KB + 1.6))
			dec.add(14, wp, 90.0 if along == "z" else 0.0, 3.0, 2.2, S.walk_y, Color(1, 1, 1, 0.4))
		# the T's head: headlights of the stem traffic sweep this kerb, a lamp stands opposite the stem to light it
		var lp := Vector2(sgn * (KB + 0.6), 0.0) if along == "z" else Vector2(0.0, sgn * (KB + 0.6))
		var lyaw := rad_to_deg(atan2(-lp.x, -lp.y))
		props.add("prop_lamp_cobra", "worn", Vector3(lp.x, S.walk_y(0.0), lp.y), lyaw)
		# the kerb of the T head gets the gutter grime of the whole street's runoff
		for k in 4:
			var s := rr.randf_range(-J + 2.0, J - 2.0)
			var gp := Vector2(sgn * (KB - 0.28), s) if along == "z" else Vector2(s, sgn * (KB - 0.28))
			dec.add(14, gp, 0.0 if along == "z" else 90.0, 0.5, 2.6, ry, Color(0.95, 0.9, 0.82, 0.55))
	# ---- stop signs at the right-hand side of every approach, facing the arriving traffic; stop bars painted above
	if open.N: props.add("prop_sign_stop", "worn", Vector3(-(KB + 0.6), S.walk_y(0.0), -(STOP[1] + 0.3)), 180.0)
	if open.S: props.add("prop_sign_stop", "worn", Vector3(KB + 0.6, S.walk_y(0.0), STOP[1] + 0.3), 0.0)
	if open.E: props.add("prop_sign_stop", "worn", Vector3(STOP[1] + 0.3, S.walk_y(0.0), -(KB + 0.6)), 90.0)
	if open.W: props.add("prop_sign_stop", "worn", Vector3(-(STOP[1] + 0.3), S.walk_y(0.0), KB + 0.6), -90.0)
	# ---- corner furniture at r - 1 from the kerb return's centre (on the walk behind the kerb, never on the fillet):
	# the lamp on one corner (if the junction is not a T, whose lamp lights its head), street names on two others
	var order: Array = corners.duplicate()
	for i in order.size():
		var j2 := rr.randi() % order.size(); var tmp: Variant = order[i]; order[i] = order[j2]; order[j2] = tmp
	var cpos := func(cn: Array, back: float) -> Vector2:
		var c := Vector2(float(cn[0]) * (KB + RR), float(cn[1]) * (KB + RR))
		return c + Vector2(-float(cn[0]), -float(cn[1])).normalized() * (RR - back)
	var used: Array = []
	if closed == "" and order.size() > 0:
		var lc: Array = opts.get("lamp", order[0])
		var lp2: Vector2 = cpos.call(lc, 1.0)
		props.add("prop_lamp_cobra", "worn", Vector3(lp2.x, S.walk_y(0.0), lp2.y), rad_to_deg(atan2(-float(lc[0]), -float(lc[1]))))
		used.append(lc)
	var nn := 0
	for cn: Array in order:
		if nn >= 2 or cn in used: continue
		var np: Vector2 = cpos.call(cn, 0.9)
		props.add("prop_sign_street_names", "worn", Vector3(np.x, S.walk_y(0.0), np.y), 45.0)
		used.append(cn); nn += 1
	# ---- a hydrant on a leg's parkway (fire trucks reach every corner of two blocks), red kerb to the kerb return
	# on the side of the leg AWAY from that approach's stop sign, beyond the crosswalk ramp (|z| 12.6-15.6)
	var hcands: Array = []
	if open.N: hcands.append(Vector2(1, -1))
	if open.S: hcands.append(Vector2(-1, 1))
	if not hcands.is_empty():
		var hv: Vector2 = opts.get("hyd", hcands[rr.randi() % hcands.size()])
		I.add(props, "prop_hydrant_red", "worn", Vector3(hv.x * (KB + 0.7), S.walk_y(0.0), hv.y * 17.6), -90.0 * hv.x)
		W.red_kerb(dec, Vector2(hv.x * KB, hv.y * J), Vector2(hv.x * KB, hv.y * 15.8), Vector2(-hv.x, 0.0))
	# ---- a mail box or newspaper boxes at the back of a corner walk (where people pass on foot)
	var box: String = opts.get("box", ["usps", "news", ""][rr.randi() % 3])
	if box != "" and order.size() > 0:
		var bc: Array = order[order.size() - 1]
		var bx := float(bc[0]); var bz := float(bc[1])
		if box == "usps": I.add(props, "prop_usps_collection_box", "worn", Vector3(bx * (PR - 0.6), S.walk_y(0.0), bz * 18.6), 90.0 * -bx)
		else:
			props.add("prop_newspaper_box_blue", "worn", Vector3(bx * (PR - 0.45), S.walk_y(0.0), bz * 18.0), -90.0 * bx)
			props.add("prop_newspaper_box_red", "worn", Vector3(bx * (PR - 0.45), S.walk_y(0.0), bz * 18.8), -90.0 * bx)
	# a bin at the corner of a lined (bus) street where people wait to cross
	if opts.get("bins", pat.count("L") >= 2) and order.size() > 1:
		var tc: Array = order[1]
		props.add("prop_trash_receptacle", "worn", Vector3(float(tc[0]) * (PR - 0.5), S.walk_y(0.0), float(tc[1]) * 13.0), 0.0)
	# ---- kerb inlets just upstream of each crosswalk (the low point of every approach), manhole in the crossing
	for e: Array in [["E", 19.4, -KB, 180.0], ["W", -19.4, KB, 0.0], ["S", KB, 19.4, -90.0], ["N", -KB, -19.4, 90.0]]:
		if open[e[0]]: props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(float(e[1]), ry.call(0.0), float(e[2])), float(e[3]), false)
	var mh := Vector2(rr.randf_range(-2.0, 2.0), rr.randf_range(-2.0, 2.0))
	props.add("prop_manhole_cover", "worn", Vector3(mh.x, ry.call(0.0) + 0.002, mh.y), 0.0, false)
	# ---- wear: braking and oil before every stop bar, a trench patch across the crossing, cracks, crosswalk paint
	# worn in the wheel paths
	for e: Array in [["E", 18.5, -LANE * 0.5, 90.0], ["W", -18.5, LANE * 0.5, 90.0], ["S", LANE * 0.5, 18.5, 0.0], ["N", -LANE * 0.5, -18.5, 0.0]]:
		if not open[e[0]]: continue
		for wp: float in [-0.8, 0.8]:
			var o := Vector2(wp, 0.0) if float(e[3]) == 0.0 else Vector2(0.0, wp)
			dec.add(8, Vector2(float(e[1]), float(e[2])) + o, float(e[3]), 0.45, rr.randf_range(3.0, 4.2), ry, Color(1, 1, 1, rr.randf_range(0.3, 0.45)))
		if rr.randf() < 0.75: W.oil(dec, rr, Vector2(float(e[1]), float(e[2])), float(e[3]), ry, rr.randf_range(0.45, 0.7))
	if rr.randf() < 0.6: dec.add(3, Vector2(rr.randf_range(-2.0, 2.0), 0.0), 0.0 if rr.randf() < 0.5 else 90.0, 0.9, 2.0 * KB, ry, Color(1, 1, 1, 0.5))     # a water-service trench across the crossing, sealed long ago (faint: a dark tile alone reads as a shadow)
	W.cracks(dec, rr, -KB, -KB, KB, KB, 6 + rr.randi() % 5, ry, 0.45)
	for sd: Array in [["E", 1.0, true], ["W", -1.0, true], ["S", 1.0, false], ["N", -1.0, false]]:
		if not open[sd[0]] or mark[sd[0]] != "L": continue
		for k in 2:
			var s := rr.randf_range(-KB + 0.8, KB - 0.8)
			if sd[2]: dec.add(14, Vector2(float(sd[1]) * xc, s), 0.0, 3.0, 0.9, ry, Color(1, 1, 1, 0.35))
			else: dec.add(14, Vector2(s, float(sd[1]) * xc), 90.0, 3.0, 0.9, ry, Color(1, 1, 1, 0.35))
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s (%s): ground tris %d, props %d" % [name, pat, g.tri_count(), props.count()])
	K.save_piece(root, name)


## =============================================================================================== review ground (preview)
## PREVIEW ONLY: grass under the family's review area so shots do not look into a void. Each lattice cell (and a 60 m
## margin round the area) gets a Coons patch reaching 0.6 m under its streets' walks (inset 8.6 m from a street centre
## line; none where no street runs, e.g. the superblock edges), 3 cm under the walk at the edge heights: our blocks
## use their own profile (resstd_sites.json prof_a), the others a smoothstep between the pads. Review frame: (u, y, v)
## + (0, 0, -3000). Never placed in the game.
static func review_ground(name: String) -> void:
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new()
	var sites: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/review/sites.json"))
	var mine: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/review/resstd_sites.json"))
	var pad := {}
	for n: Dictionary in sites.nodes: pad["%d,%d" % [roundi(float(n.u)), roundi(float(n.v))]] = float(n.pad)
	var prof := {}
	for b: Dictionary in mine.blocks: prof[String(b.id)] = b.prof_a
	var segs: Array = []      # every straight street of the skeleton: [a, b, padA, prof]
	for b: Dictionary in sites.blocks:
		if String(b.kind) != "lattice": continue
		var a := Vector2(float(b.a[0]), float(b.a[1])); var c := Vector2(float(b.b[0]), float(b.b[1]))
		var pa: float = pad.get("%d,%d" % [roundi(a.x), roundi(a.y)], 6.0); var pb: float = pad.get("%d,%d" % [roundi(c.x), roundi(c.y)], 6.0)
		var L := a.distance_to(c)
		segs.append([a, c, pa, prof.get(String(b.id), [[20.0, L - 20.0, pb - pa]] if absf(pb - pa) > 1e-4 else [])])
	var U: Array = [-860.0, -800.0, -600.0, -400.0, -200.0, 0.0, 250.0, 500.0, 560.0]
	var V: Array = [-1460.0, -1400.0, -1200.0, -1000.0, -800.0, -600.0, -400.0, -200.0, 0.0, 200.0, 260.0]
	# the street a point lies on (collinear with a skeleton street and inside its length), or -1
	var on_street := func(p: Vector2) -> int:
		for k in segs.size():
			var a: Vector2 = segs[k][0]; var c: Vector2 = segs[k][1]
			if absf(a.x - c.x) < 0.5 and absf(p.x - a.x) < 0.5 and p.y >= minf(a.y, c.y) - 0.5 and p.y <= maxf(a.y, c.y) + 0.5: return k
			if absf(a.y - c.y) < 0.5 and absf(p.y - a.y) < 0.5 and p.x >= minf(a.x, c.x) - 0.5 and p.x <= maxf(a.x, c.x) + 0.5: return k
		return -1
	var street_y := func(k: int, p: Vector2) -> float:
		var sg: Array = segs[k]
		var s := (p - (sg[0] as Vector2)).length()
		var y := float(sg[2])
		for pp: Array in sg[3]: y += float(pp[2]) * ss((s - float(pp[0])) / (float(pp[1]) - float(pp[0])))
		return y
	var point_y := func(p: Vector2) -> float:
		var k: int = on_street.call(p)
		if k >= 0: return float(street_y.call(k, p))
		var best := 6.0; var bd := 1e9
		for key: String in pad:
			var q := Vector2(float(key.get_slice(",", 0)), float(key.get_slice(",", 1)))
			if q.distance_to(p) < bd: bd = q.distance_to(p); best = float(pad[key])
		return best
	# a cell side p -> q: [street index or -1 for the side's middle]
	var side_k := func(p: Vector2, q: Vector2) -> int: return on_street.call((p + q) * 0.5)
	var side_y := func(p: Vector2, q: Vector2, k: int, t: Vector2) -> float:
		if k >= 0: return float(street_y.call(k, t))
		var f := (t - p).length() / maxf(p.distance_to(q), 0.01)
		return lerpf(float(point_y.call(p)), float(point_y.call(q)), ss(f))
	for i in U.size() - 1:
		for j in V.size() - 1:
			var u0: float = U[i]; var u1: float = U[i + 1]; var v0: float = V[j]; var v1: float = V[j + 1]
			var P00 := Vector2(u0, v0); var P10 := Vector2(u1, v0); var P01 := Vector2(u0, v1); var P11 := Vector2(u1, v1)
			var kb: int = side_k.call(P00, P10); var kt: int = side_k.call(P01, P11)
			var kl: int = side_k.call(P00, P01); var kr: int = side_k.call(P10, P11)
			var ia := u0 + (8.6 if kl >= 0 else 0.0); var ib := u1 - (8.6 if kr >= 0 else 0.0)
			var ja := v0 + (8.6 if kb >= 0 else 0.0); var jb := v1 - (8.6 if kt >= 0 else 0.0)
			var bot := func(u: float) -> float: return float(side_y.call(P00, P10, kb, Vector2(u, v0)))
			var top := func(u: float) -> float: return float(side_y.call(P01, P11, kt, Vector2(u, v1)))
			var lef := func(v: float) -> float: return float(side_y.call(P00, P01, kl, Vector2(u0, v)))
			var rig := func(v: float) -> float: return float(side_y.call(P10, P11, kr, Vector2(u1, v)))
			var c00: float = (float(bot.call(ia)) + float(lef.call(ja))) * 0.5; var c10: float = (float(bot.call(ib)) + float(rig.call(ja))) * 0.5
			var c01: float = (float(top.call(ia)) + float(lef.call(jb))) * 0.5; var c11: float = (float(top.call(ib)) + float(rig.call(jb))) * 0.5
			var yf := func(u: float, v: float) -> float:
				var a := (u - ia) / (ib - ia); var b := (v - ja) / (jb - ja)
				var y := (1.0 - b) * float(bot.call(u)) + b * float(top.call(u)) + (1.0 - a) * float(lef.call(v)) + a * float(rig.call(v)) \
					- ((1.0 - a) * (1.0 - b) * c00 + a * (1.0 - b) * c10 + (1.0 - a) * b * c01 + a * b * c11)
				return y + KH - 0.03
			var nu := maxi(1, ceili((ib - ia) / 8.0)); var nv := maxi(1, ceili((jb - ja) / 8.0))
			for a2 in nu:
				for b2 in nv:
					var ua := lerpf(ia, ib, float(a2) / nu); var ub := lerpf(ia, ib, float(a2 + 1) / nu)
					var va := lerpf(ja, jb, float(b2) / nv); var vb := lerpf(ja, jb, float(b2 + 1) / nv)
					g.quad("grass", Vector3(ua, yf.call(ua, va), va - 3000.0), Vector3(ub, yf.call(ub, va), va - 3000.0), Vector3(ub, yf.call(ub, vb), vb - 3000.0), Vector3(ua, yf.call(ua, vb), vb - 3000.0))
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	print("%s: ground tris %d" % [name, g.tri_count()])
	K.save_piece(root, name)

static func _ekey(a: Vector2, c: Vector2) -> String:
	var p := a if (a.x < c.x or (a.x == c.x and a.y < c.y)) else c
	var q := c if p == a else a
	return "%d,%d|%d,%d" % [roundi(p.x), roundi(p.y), roundi(q.x), roundi(q.y)]
