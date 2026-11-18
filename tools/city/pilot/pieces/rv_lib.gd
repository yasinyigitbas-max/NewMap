extends RefCounted
## Residential VARIANTS (18 Nov, zone growth): one residential QUADRANT of a lattice junction (the 100 x 100 m corner
## between two residential legs), built on the hill exactly where it stands. The locked sample is the pilot's hill rows
## (r_n / r_s: 15 m lots, level terraces at their frontage height, low retaining walls, back-lot power line); these
## variants carry its rules onto the 200 m lattice. Never used by a locked piece; prefix r_ (residential).
##
## THE PLAN (as a planner would lay out a Coronado village block on the lattice):
##   The residential legs (s_res_*, s_rs_*) have NO driveway cuts and an alley apron at 54-60 m on every leg, so every
##   quadrant is cut by two alleys (v 54-60 running along u, u 54-60 running along v) into four sub-blocks:
##     A [9.2..54 x 9.2..54]   the corner: lots facing the avenue (-v); the corner lot sees the side street too
##     B [60..100 x 9.2..54]   lots facing the avenue (-v)
##     C [9.2..54 x 60..100]   lots facing the side street (-u)
##     D [60..100 x 60..100]   inside the alleys: alley cottages (houses fronting the alley with their own garage) or a
##                             pocket park / neighbourhood green (fenced, ONE gate off the alley)
##   Street lots are 44.8 m deep: 6 m front yard, the house, the back yard, then an 8 m garage strip on the ALLEY (the
##   garage door faces the alley, a second car on the pad beside it, the bins inside the back gate: Coronado's alley
##   pattern; the street keeps its kerb parking and its trees).
## THE HILL: the quadrant's ground follows the SAME surface as the streets around it. A 200 m block between four
##   junction pads p00 (this junction), pu (200 m along u), pv (along v), puv rises with the kit's smoothstep between
##   the junction tiles (20..180 m), as every leg does; inside the block the four edges are blended (a Coons patch):
##     h(u, v) = (pu - p00) S(u) + (pv - p00) S(v) + (puv - pu - pv + p00) S(u) S(v),  S(t) = ss((t - 20) / 160)
##   so it equals each leg's sidewalk at the property line, and the four quadrants of a block meet without a seam.
##   Every lot is a LEVEL terrace at its frontage height (the sample's rule: nothing stands on a slope); low retaining
##   faces along the property line (steps on the path), between terraces, and between the yard and the garage strip
##   (steps at the back gate). The garage strip follows the alley (cars drive straight in). Alleys and the park lawn
##   follow the surface; play and picnic pads are level with a low edge.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")

const PROP := 9.2
const AL0 := 54.0
const AL1 := 60.0
## quadrant depth along u / v (half the block: 100 m, or 125 m in the 250 m blocks east of Amber) and the block
## lengths the street profiles span (the legs rise between the junction tiles: 20 .. L - 20)
var LU := 100.0
var LV := 100.0
var BU := 200.0
var BV := 200.0
const KERB_H := 0.15
const SET := 6.0          # front yard
const GS := 8.0           # garage strip at the back of a street lot (on the alley)
const FORE := 2.5         # corner shop forecourt

var name := ""
var sx := 1.0
var sz := 1.0
var p0 := 0.0
var pu := 0.0
var pv := 0.0
var puv := 0.0
var rr: RandomNumberGenerator
var g: K.Ground
var props: K.Props
var dec: K.Decals
var root: Node3D
var bl: Node3D
var paints: Array = []
var surfs: Array = []     # [u0, v0, u1, v1, kind, y]  kind: "level" | "field" | "strip_u" (y = fh(u, y)) | "strip_v"
var stalls: Array = []
var poles: Array = []
var blds: Array = []      # {node, w, d, folder, house}
var occ: Array = []       # [u, v, r] taken spots (quadrant coordinates)
var fences: Array = []    # [Vector2 a, Vector2 b] fence lines (quadrant coordinates)
var doorpts: Array = []   # Vector2 points 0.8 m in front of every ground door (keep 1.6 m clear)
var used: Dictionary = {} # house folder -> count in this piece
var shops: Array = []     # [label, folder, kind] walk-in shops of this piece (rooms: interiors/assignment_res.json)
var design: Dictionary = {}

## ------------------------------------------------------------------------------------------------ the surface
static func ss(t: float) -> float:
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func Su(t: float) -> float: return ss((t - 20.0) / (BU - 40.0))
func Sv(t: float) -> float: return ss((t - 20.0) / (BV - 40.0))

## walking height (street surface + kerb) of the block surface at quadrant (u, v), relative to this junction's pad
func fh(u: float, v: float) -> float:
	var a := Su(u); var b := Sv(v)
	return (pu - p0) * a + (pv - p0) * b + (puv - pu - pv + p0) * a * b + KERB_H

## ground height under quadrant (u, v): the last surface that holds the point, else the block surface
func gy(u: float, v: float) -> float:
	for i in range(surfs.size() - 1, -1, -1):
		var s: Array = surfs[i]
		if u >= float(s[0]) - 1e-3 and u <= float(s[2]) + 1e-3 and v >= float(s[1]) - 1e-3 and v <= float(s[3]) + 1e-3:
			match String(s[4]):
				"level": return float(s[5])
				"strip_u": return fh(u, float(s[5]))
				"strip_v": return fh(float(s[5]), v)
			return fh(u, v)
	return fh(u, v)

func L(u: float, v: float, y: float) -> Vector3: return Vector3(sx * u, y, sz * v)
func L2(u: float, v: float) -> Vector2: return Vector2(sx * u, sz * v)
func Q2(p: Vector3) -> Vector2: return Vector2(p.x * sx, p.z * sz)
func gyl(x: float, z: float) -> float: return gy(x * sx, z * sz)

## a paint rectangle in quadrant coordinates -> local [x0, z0, x1, z1, mat]
func prect(u0: float, v0: float, u1: float, v1: float, mat: String) -> void:
	var a := L2(u0, v0); var b := L2(u1, v1)
	paints.append([minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), mat])

## world yaw of a facing given as a quadrant direction
func yaw_of(du: float, dv: float) -> float: return rad_to_deg(atan2(sx * du, sz * dv))

## ------------------------------------------------------------------------------------------------ setup
func begin(piece: String, site: Dictionary, des: Dictionary) -> void:
	name = piece; design = des
	sx = float(site.sx); sz = float(site.sz)
	p0 = float(site.p0); pu = float(site.pu); pv = float(site.pv); puv = float(site.puv)
	BU = float(site.get("Lu", 200.0)); BV = float(site.get("Lv", 200.0)); LU = BU * 0.5; LV = BV * 0.5
	rr = W.rng_for(piece)
	g = K.Ground.new(); props = K.Props.new(); dec = K.Decals.new()
	root = Node3D.new(); root.name = piece
	bl = Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	root.set_meta("site", site); root.set_meta("design", String(des.get("name", "")))

## ------------------------------------------------------------------------------------------------ props
func free_at(u: float, v: float, r: float) -> bool:
	if u - r < PROP or v - r < PROP or u + r > LU or v + r > LV: return false
	for o: Array in occ:
		if Vector2(u, v).distance_to(Vector2(float(o[0]), float(o[1]))) < r + float(o[2]): return false
	for dp: Vector2 in doorpts:
		if Vector2(u, v).distance_to(dp) < r + 1.3: return false
	for b: Dictionary in blds:
		var lp: Vector3 = (b.node as Node3D).transform.affine_inverse() * L(u, v, 0.0)
		if absf(lp.x) < float(b.w) * 0.5 + r and absf(lp.z) < float(b.d) * 0.5 + r: return false
	return true

func near_fence(u: float, v: float, d: float) -> bool:
	for f: Array in fences:
		var a: Vector2 = f[0]; var b: Vector2 = f[1]
		var p := Vector2(u, v)
		var t := clampf((p - a).dot(b - a) / maxf((b - a).length_squared(), 1e-6), 0.0, 1.0)
		if p.distance_to(a.lerp(b, t)) < d: return true
	return false

## place a ground prop at quadrant (u, v) on the ground under it (y lift for wall-mounted items)
func add(base: String, cond: String, u: float, v: float, yaw: float, lift := 0.0, collide := true, scale := 1.0, r := 0.0) -> void:
	props.add(base, cond, L(u, v, gy(u, v) + lift), yaw, collide, scale)
	if r > 0.0: occ.append([u, v, fp_r(base, r)])

## try a spot; true when placed
func fp_r(base: String, r: float) -> float:
	if base.begins_with("tree_") or base.begins_with("palm_"): return r      # trees: the trunk counts (validator rule)
	var e := K.manifest(base)
	var fw := float(e.get("footprint_w", 0.5)); var fd := float(e.get("footprint_d", 0.5))
	return maxf(r, 0.5 * sqrt(fw * fw + fd * fd) + 0.05)       # half the diagonal: items stand at any angle

func try_add(base: String, cond: String, u: float, v: float, yaw: float, r: float, scale := 1.0) -> bool:
	r = fp_r(base, r)
	if not free_at(u, v, r): return false
	if not (base.begins_with("tree_") or base.begins_with("palm_")) and near_fence(u, v, r): return false
	if (base.begins_with("tree_") or base.begins_with("palm_")) and near_fence(u, v, 1.2): return false
	add(base, cond, u, v, yaw, 0.0, true, scale, r)
	return true

## a run of fence panels with a post at every joint (panels never stretched: n = ceil(L / pw), spacing <= pw).
## y < -100: each panel / post on the ground under it; else at y.
func fence_run(a: Vector2, b: Vector2, panel: String, post: String, pw: float, y := -1000.0, cond := "worn") -> void:
	var Lr := a.distance_to(b)
	if Lr < 0.3: return
	fences.append([a, b])
	var la := L2(a.x, a.y); var lb := L2(b.x, b.y)
	var yaw := rad_to_deg(atan2(lb.x - la.x, lb.y - la.y)) + 90.0
	var dir := (b - a) / Lr
	var gyf := func(q: Vector2) -> float: return gy(q.x, q.y) if y < -100.0 else y
	var joints: Array = [a, b]
	if Lr < pw:
		# shorter than one panel: one shortened panel (never stretched), flush with both ends
		var m := (a + b) * 0.5
		var bs := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis().scaled(Vector3(Lr / pw, 1.0, 1.0))
		var k := panel + "|" + cond
		if not props.items.has(k): props.items[k] = []
		(props.items[k] as Array).append(Transform3D(bs, L(m.x, m.y, float(gyf.call(m)))))
	else:
		# whole panels, the end ones flush with the run's ends (posts there), the overlap shared out in the middle
		var n := maxi(1, int(ceil(Lr / pw - 0.02)))
		for i in n:
			var c := a + dir * (pw * 0.5) if n == 1 else a.lerp(b - dir * pw, float(i) / float(n - 1)) + dir * (pw * 0.5)
			if n == 1: c = (a + b) * 0.5
			props.add(panel, cond, L(c.x, c.y, float(gyf.call(c))), yaw)
			if i > 0: joints.append(c - dir * (pw * 0.5))
	if post != "":
		for e: Vector2 in joints: props.add(post, cond, L(e.x, e.y, float(gyf.call(e))), yaw)

## the same run with gaps [s, width] (gates or openings) along it; a gate model goes in each gap if gate != ""
func fence_line(a: Vector2, b: Vector2, gaps: Array, panel: String, post: String, pw: float, gate := "", y := -1000.0) -> void:
	var Lr := a.distance_to(b)
	var dir := (b - a) / maxf(Lr, 1e-6)
	var cur := 0.0
	var gs: Array = gaps.duplicate(); gs.sort_custom(func(p: Array, q: Array) -> bool: return float(p[0]) < float(q[0]))
	for gp: Array in gs:
		var g0 := float(gp[0]) - float(gp[1]) * 0.5; var g1 := float(gp[0]) + float(gp[1]) * 0.5
		if g0 > cur + 0.3: fence_run(a + dir * cur, a + dir * g0, panel, post, pw, y)
		if gate != "":
			var m := a + dir * float(gp[0])
			var la := L2(a.x, a.y); var lb := L2(b.x, b.y)
			props.add(gate, "worn", L(m.x, m.y, gy(m.x, m.y) if y < -100.0 else y), rad_to_deg(atan2(lb.x - la.x, lb.y - la.y)) + 90.0)
		cur = g1
	if Lr > cur + 0.3: fence_run(a + dir * cur, b, panel, post, pw, y)

const FENCE := {
	"picket": ["fence_picket_white", "fence_post_picket", 2.0, "fence_gate_picket"],
	"iron": ["fence_wrought_iron", "fence_post_wrought_iron", 1.98, "fence_gate_wrought_iron"],
	"vinyl": ["fence_vinyl_canal_rail", "fence_post_vinyl", 2.015, ""],
	"privacy": ["fence_wood_privacy", "fence_post_privacy", 2.01, "fence_gate_privacy"],
	"board": ["fence_weathered_board", "fence_post_privacy", 2.0, "fence_gate_privacy"],
	"stucco": ["fence_stucco_wall", "", 2.03, ""],
	"brick": ["fence_brick_wall", "", 2.03, ""],
	"chain": ["fence_chainlink", "fence_chainlink_post", 2.0, ""],
}

## ------------------------------------------------------------------------------------------------ ground walls
## vertical face along a-b (local) between two surfaces (ya0/yb0 one side, ya1/yb1 the other), visible both ways
func wall2(a: Vector2, b: Vector2, ya0: float, yb0: float, ya1: float, yb1: float) -> void:
	if absf(ya0 - ya1) < 0.01 and absf(yb0 - yb1) < 0.01: return
	var A0 := Vector3(a.x, minf(ya0, ya1), a.y); var A1 := Vector3(a.x, maxf(ya0, ya1), a.y)
	var B0 := Vector3(b.x, minf(yb0, yb1), b.y); var B1 := Vector3(b.x, maxf(yb0, yb1), b.y)
	var n := Vector3(b.y - a.y, 0.0, -(b.x - a.x))
	g.quad("wall", A0, B0, B1, A1, n, true)
	g.quad("wall", A0, B0, B1, A1, -n, true)

## retaining face along the quadrant segment a-b between height functions fa(u, v) and fb(u, v), in 2 m pieces
func seam(a: Vector2, b: Vector2, fa: Callable, fb: Callable) -> void:
	var Lr := a.distance_to(b)
	if Lr < 0.02: return
	var n := maxi(1, int(ceil(Lr / 2.0)))
	for k in n:
		var p := a.lerp(b, float(k) / n); var q := a.lerp(b, float(k + 1) / n)
		wall2(L2(p.x, p.y), L2(q.x, q.y), float(fa.call(p.x, p.y)), float(fa.call(q.x, q.y)), float(fb.call(p.x, p.y)), float(fb.call(q.x, q.y)))

func c_field() -> Callable: return func(u: float, v: float) -> float: return fh(u, v)
func c_const(y: float) -> Callable: return func(_u: float, _v: float) -> float: return y

## steps into a level region from a line: the region (height H) lies on the `side` of the line (along the axis), the
## outside surface at the line has height fo(u, v). Treads 0.3 m, risers <= 0.17; a hole in the region's paint, cheek
## walls. axis "v": the line is v = t (steps run along v); "u": u = t. c = centre along the line, width w.
func steps(axis: String, c: float, t: float, side: float, H: float, fo: Callable, w := 1.2) -> void:
	var pt := func(s: float, tt: float) -> Vector2: return Vector2(s, tt) if axis == "v" else Vector2(tt, s)
	var y0 := float(fo.call((pt.call(c, t) as Vector2).x, (pt.call(c, t) as Vector2).y))
	var dh := H - y0
	if absf(dh) < 0.06:
		return
	var n := int(ceil(absf(dh) / 0.17))
	var a0: Vector2 = pt.call(c - w * 0.5, t); var a1: Vector2 = pt.call(c + w * 0.5, t + side * 0.3 * n)
	prect(minf(a0.x, a1.x), minf(a0.y, a1.y), maxf(a0.x, a1.x), maxf(a0.y, a1.y), "-")
	for k in n:
		var ya := y0 + dh * float(k) / n; var yb := y0 + dh * float(k + 1) / n
		var ta := t + side * 0.3 * k; var tb := t + side * 0.3 * (k + 1)
		var q0: Vector2 = pt.call(c - w * 0.5, ta); var q1: Vector2 = pt.call(c + w * 0.5, ta)
		var q2: Vector2 = pt.call(c + w * 0.5, tb); var q3: Vector2 = pt.call(c - w * 0.5, tb)
		g.quad("concrete", L(q0.x, q0.y, yb), L(q1.x, q1.y, yb), L(q2.x, q2.y, yb), L(q3.x, q3.y, yb))
		wall2(L2(q0.x, q0.y), L2(q1.x, q1.y), ya, ya, yb, yb)
		for e: float in [c - w * 0.5, c + w * 0.5]:
			var r0: Vector2 = pt.call(e, ta); var r1: Vector2 = pt.call(e, tb)
			wall2(L2(r0.x, r0.y), L2(r1.x, r1.y), yb, yb, H, H)
	# the last riser up to the region if the treads stop short (rounding)
	var tl := t + side * 0.3 * n
	var e0: Vector2 = pt.call(c - w * 0.5, tl); var e1: Vector2 = pt.call(c + w * 0.5, tl)
	wall2(L2(e0.x, e0.y), L2(e1.x, e1.y), H, H, H, H)

## ------------------------------------------------------------------------------------------------ buildings
func building(folder: String, u: float, v: float, y: float, yaw: float, house: bool, label := "", wear := 0.65) -> Dictionary:
	var n := K.building(bl, folder, L(u, v, y), yaw, label, wear)
	var st := K.building_stats(folder)
	var b := {"node": n, "w": float(st.footprint_wd[0]), "d": float(st.footprint_wd[1]), "folder": folder, "house": house, "st": st, "y": y}
	blds.append(b)
	for e: Array in st.get("doors_front", []):
		var p: Vector3 = n.transform * Vector3(float(e[1]), 0.0, float(st.footprint_wd[1]) * 0.5 + 0.8)
		doorpts.append(Q2(p))
	return b

## quadrant point of a building-local point (x along the front, z toward the front)
func bq(b: Dictionary, lx: float, lz: float) -> Vector2:
	return Q2((b.node as Node3D).transform * Vector3(lx, 0.0, lz))

func byaw(b: Dictionary) -> float: return rad_to_deg((b.node as Node3D).rotation.y)

## a prop on a building's wall: lx along the front, lz toward the front (d/2 = front face), height h over its floor
func on_wall(b: Dictionary, base: String, cond: String, lx: float, lz: float, h: float, yaw: float) -> void:
	var p := bq(b, lx, lz)
	props.add(base, cond, L(p.x, p.y, float(b.y) + h), yaw, false)

## ------------------------------------------------------------------------------------------------ lots
## A row of lots in one sub-block. axis "v": lots side by side along u from s0 to s1, depth along v from f (front, the
## street or alley they face, toward -v) to b; "u": side by side along v, depth along u (they face -u).
## specs: Array of {w (lot width), house, garage ("" none, "own" = the house's own door), front (fence kind / "hedge" /
## "privet" / ""), back (fence kind), gs (garage strip depth, 0 = none), shop (bool)}.
func pt(axis: String, s: float, t: float) -> Vector2: return Vector2(s, t) if axis == "v" else Vector2(t, s)

func row(axis: String, s0: float, f: float, b: float, specs: Array) -> Array:
	var lots: Array = []
	var s := s0
	for sp: Dictionary in specs:
		var w := float(sp.w)
		var lot := sp.duplicate()
		lot.axis = axis; lot.s0 = s; lot.s1 = s + w; lot.f = f; lot.b = b
		var fc: Vector2 = pt(axis, s + w * 0.5, f)
		lot.Ht = snappedf(fh(fc.x, fc.y), 0.01)
		lots.append(lot)
		s += w
	# surfaces: terrace (level) and the garage strip (follows the alley along it)
	for lot: Dictionary in lots:
		var gs := float(lot.get("gs", 0.0))
		var tb := float(lot.b) - gs
		var a: Vector2 = pt(axis, float(lot.s0), f); var c: Vector2 = pt(axis, float(lot.s1), tb)
		surfs.append([minf(a.x, c.x), minf(a.y, c.y), maxf(a.x, c.x), maxf(a.y, c.y), "level", float(lot.Ht)])
		if gs > 0.0:
			var a2: Vector2 = pt(axis, float(lot.s0), tb); var c2: Vector2 = pt(axis, float(lot.s1), float(lot.b))
			surfs.append([minf(a2.x, c2.x), minf(a2.y, c2.y), maxf(a2.x, c2.x), maxf(a2.y, c2.y), "strip_u" if axis == "v" else "strip_v", float(lot.b)])
	# retaining faces
	for i in lots.size():
		var lot: Dictionary = lots[i]
		var H := float(lot.Ht); var gs := float(lot.get("gs", 0.0)); var tb := float(lot.b) - gs
		var sa := float(lot.s0); var sb := float(lot.s1)
		var cH := c_const(H)
		var cF := c_field()
		var cS := (func(u: float, v: float) -> float: return fh(u, float(lot.b))) if axis == "v" else (func(u: float, v: float) -> float: return fh(float(lot.b), v))
		# back of the terrace: the garage strip (or the alley / the mid-block line when there is no strip)
		seam(pt(axis, sa, tb), pt(axis, sb, tb), cH, cS if gs > 0.0 else cF)
		# sides: the neighbour lot's terrace, or the surface outside the row
		if i == 0:
			seam(pt(axis, sa, f), pt(axis, sa, tb), cH, cF)
			if gs > 0.0: seam(pt(axis, sa, tb), pt(axis, sa, float(lot.b)), cS, cF)
		if i + 1 < lots.size():
			seam(pt(axis, sb, f), pt(axis, sb, tb), cH, c_const(float(lots[i + 1].Ht)))
		else:
			seam(pt(axis, sb, f), pt(axis, sb, tb), cH, cF)
			if gs > 0.0: seam(pt(axis, sb, tb), pt(axis, sb, float(lot.b)), cS, cF)
	return lots

## ------------------------------------------------------------------------------------------------ one house lot
func house_lot(lot: Dictionary) -> void:
	var axis := String(lot.axis)
	var s0 := float(lot.s0); var s1 := float(lot.s1); var f := float(lot.f); var bk := float(lot.b)
	var H := float(lot.Ht); var gs := float(lot.get("gs", 0.0)); var tb := bk - gs
	var w := s1 - s0
	var fdu := 0.0 if axis == "v" else -1.0; var fdv := -1.0 if axis == "v" else 0.0
	var yaw := yaw_of(fdu, fdv)                    # front faces the street / alley
	var folder := String(lot.house)
	var st := K.building_stats(folder)
	var hw: float = st.footprint_wd[0]; var hd: float = st.footprint_wd[1]
	used[folder] = int(used.get(folder, 0)) + 1
	# the house sits off-centre, leaving the wider side yard on the side of the garage / the side gate
	var side := 1.0 if int(lot.get("i", 0)) % 2 == 0 else -1.0
	var slack := w - hw
	var off := side * clampf(slack * 0.5 - 1.4, 0.0, 1.6)
	var hs := (s0 + s1) * 0.5 + off
	var set := SET + float(lot.get("set_extra", 0.0))
	var ht := f + set + hd * 0.5
	var hp: Vector2 = pt(axis, hs, ht)
	var b := building(folder, hp.x, hp.y, H, yaw, true, "", float(design.get("wear", 0.65)))
	lot.bld = b
	# the front door (first door*) along the lot
	var door_s := hs
	var garage_door_s := -1000.0
	for e: Array in st.get("doors_front", []):
		var dp := bq(b, float(e[1]), hd * 0.5)
		var ds := dp.x if axis == "v" else dp.y
		if String(e[0]).begins_with("door") and door_s == hs: door_s = ds
		if String(e[0]).begins_with("garage"): garage_door_s = ds
	var house_front := f + set
	# ---------------------------------------------------------------- front yard
	var own_garage := garage_door_s > -999.0
	var fo := c_field()
	steps(axis, door_s, f, 1.0, H, fo)
	var nst := int(ceil(absf(H - fh(pt(axis, door_s, f).x, pt(axis, door_s, f).y)) / 0.17)) if absf(H - fh(pt(axis, door_s, f).x, pt(axis, door_s, f).y)) >= 0.06 else 0
	var ps0: Vector2 = pt(axis, door_s - 0.6, f + 0.3 * nst); var ps1: Vector2 = pt(axis, door_s + 0.6, house_front)
	prect(minf(ps0.x, ps1.x), minf(ps0.y, ps1.y), maxf(ps0.x, ps1.x), maxf(ps0.y, ps1.y), "concrete")
	if own_garage:
		# driveway from the alley / street edge to the house's own garage door: a ramp over the front yard
		_driveway(axis, garage_door_s, f, house_front, H)
	# planting bed along the house front (the path and the driveway cut through it)
	var bed0 := house_front - 1.8
	var gap_s := [door_s]
	if own_garage: gap_s.append(garage_door_s)
	var bs := hs - hw * 0.5
	while bs < hs + hw * 0.5 - 0.5:
		var be := minf(bs + 1.0, hs + hw * 0.5)
		var clear := true
		for gsx: float in gap_s:
			if absf((bs + be) * 0.5 - gsx) < 1.6: clear = false
		if clear:
			var m0: Vector2 = pt(axis, bs, bed0); var m1: Vector2 = pt(axis, be, house_front)
			prect(minf(m0.x, m1.x), minf(m0.y, m1.y), maxf(m0.x, m1.x), maxf(m0.y, m1.y), "mulch")
		bs = be
	var plants: Array = design.get("plants", ["plant_bird_of_paradise", "plant_agave_americana_small"])
	for k in 5:
		var ps := hs + rr.randf_range(-hw * 0.45, hw * 0.45)
		var pp: Vector2 = pt(axis, ps, house_front - 1.05)
		var okp := true
		for gsx: float in gap_s:
			if absf(ps - gsx) < 1.8: okp = false
		if okp: try_add(String(plants[rr.randi() % plants.size()]), "normal", pp.x, pp.y, rr.randf_range(0, 360), 0.6)
	# front fence / hedge on the terrace edge, open at the path (a gate) and the driveway
	var front := String(lot.get("front", ""))
	var fa: Vector2 = pt(axis, s0, f + 0.35); var fb: Vector2 = pt(axis, s1, f + 0.35)
	var gaps: Array = [[door_s - s0, 1.2]]
	if own_garage: gaps.append([garage_door_s - s0, 4.6])
	var t_r := f + set + hd + 0.55                    # where the back yard is closed off: from the house's back corners (clear of the downspouts)
	lot.t_r = t_r
	if FENCE.has(front):
		var fd: Array = FENCE[front]
		fence_line(fa, fb, gaps, String(fd[0]), String(fd[1]), float(fd[2]), String(fd[3]) if not own_garage else "", H)
		# the front fence turns back along the lot lines to the back-yard fence (each shared line drawn once)
		var sides_f: Array = [s0]
		if bool(lot.get("last", false)) or not FENCE.has(String(lot.get("next_front", ""))): sides_f.append(s1)
		for e9: float in sides_f:
			fence_run(pt(axis, e9, f + 0.35), pt(axis, e9, t_r), String(fd[0]), String(fd[1]), float(fd[2]), maxf(H, float(lot.get("Hprev", H))) if e9 == s0 else H)
		if rr.randf() < 0.7:
			var mb: Vector2 = pt(axis, door_s + 1.0, f + 1.0)
			if free_at(mb.x, mb.y, 0.3): add("prop_mailbox_post_wood" if rr.randf() < 0.5 else "prop_mailbox_post_metal", "worn", mb.x, mb.y, yaw, 0.0, true, 1.0, 0.3)
	elif front == "hedge" or front == "privet":
		var hk := "hedge_boxwood_low_2m" if front == "hedge" else "hedge_privet_2m"
		var x := s0 + 0.5
		while x + 2.0 <= s1 - 0.4:
			var mid := x + 1.0
			var blocked := absf(mid - door_s) < 2.0 or (own_garage and absf(mid - garage_door_s) < 3.4)
			if not blocked:
				var hp2: Vector2 = pt(axis, mid, f + 0.55)
				props.add(hk, "normal", L(hp2.x, hp2.y, H), yaw + 0.0 if axis == "v" else yaw)
				occ.append([hp2.x, hp2.y, 0.5])
				x += 2.0
			else:
				x += 0.5
	# planting along the inside of the front edge (owners soften the fence / hedge line), clear of the gate and drive
	for k5 in 3:
		var es := rr.randf_range(s0 + 1.2, s1 - 1.2)
		if absf(es - door_s) < 1.8 or (own_garage and absf(es - garage_door_s) < 3.0): continue
		var ep: Vector2 = pt(axis, es, f + 1.8)
		try_add(String(plants[rr.randi() % plants.size()]), "normal", ep.x, ep.y, rr.randf_range(0, 360), 0.7)
	if H - fh(pt(axis, (s0 + s1) * 0.5, f).x, pt(axis, (s0 + s1) * 0.5, f).y) > 0.35:
		for k8 in 2:
			var ip: Vector2 = pt(axis, rr.randf_range(s0 + 1.5, s1 - 1.5), f + 1.4)
			if absf(ip.x + ip.y - (pt(axis, door_s, f).x + pt(axis, door_s, f).y)) > 2.0: try_add("plant_iceplant_patch", "normal", ip.x, ip.y, rr.randf_range(0, 360), 1.0)
	# a yard tree in some front yards (owners plant one; never in front of the door or the windows' middle)
	if rr.randf() < float(design.get("front_tree", 0.4)):
		var trees: Array = design.get("front_trees", ["tree_magnolia_a", "tree_jacaranda_a", "palm_queen_a"])
		var tsx := s0 + 2.6 if door_s > (s0 + s1) * 0.5 else s1 - 2.6
		var tp: Vector2 = pt(axis, tsx, f + 3.0)
		try_add(String(trees[rr.randi() % trees.size()]), "normal", tp.x, tp.y, rr.randf_range(0, 360), 1.0, rr.randf_range(0.8, 1.05))
	# lawn care: a sprinkler head in the lawn (most owners), or a dry, patchy lawn (some do not water)
	var Hc := func(x: float, z: float) -> float: return gyl(x, z)
	if rr.randf() < float(design.get("dry", 0.25)):
		for k in 4:
			var dp2: Vector2 = pt(axis, rr.randf_range(s0 + 1.0, s1 - 1.0), f + rr.randf_range(1.5, set - 1.6))
			var dl := L2(dp2.x, dp2.y)
			dec.add(14, dl, rr.randf_range(0, 360), rr.randf_range(1.8, 3.2), rr.randf_range(1.4, 2.4), Hc, Color(0.8, 0.72, 0.46, 0.6))
	else:
		var sp2: Vector2 = pt(axis, s0 + 2.0 if door_s > (s0 + s1) * 0.5 else s1 - 2.0, f + 4.6)
		if free_at(sp2.x, sp2.y, 0.2): add("prop_sprinkler_popup" if rr.randf() < 0.5 else "prop_sprinkler_impact", "worn", sp2.x, sp2.y, 0.0, 0.0, false, 1.0, 0.2)
	# worn grass: the postman's shortcut from the path across the lawn to the neighbour
	var wp: Vector2 = pt(axis, (door_s + (s1 if side > 0 else s0)) * 0.5, f + 1.4)
	dec.add(14, L2(wp.x, wp.y), yaw + 90.0, 0.9, absf(door_s - (s1 if side > 0 else s0)) * 0.8, Hc, Color(1, 1, 1, 0.45))
	# ---------------------------------------------------------------- on the house
	var porch: String = ["prop_porch_light_coach", "prop_porch_light_coach_bronze", "prop_porch_light_barn"][rr.randi() % 3]
	var dl_x := 0.0
	for e: Array in st.get("doors_front", []):
		if String(e[0]).begins_with("door"): dl_x = float(e[1]); break
	on_wall(b, porch, "worn", dl_x - 0.85, hd * 0.5 + 0.05, 2.1, yaw)
	on_wall(b, "prop_house_numbers_tile" if rr.randf() < 0.5 else "prop_house_numbers_wood", "worn", dl_x + 0.85, hd * 0.5 + 0.03, 1.75, yaw)
	if not FENCE.has(front): on_wall(b, "prop_mailbox_wall_black" if rr.randf() < 0.5 else "prop_mailbox_wall_brass", "worn", dl_x + 1.25, hd * 0.5 + 0.05, 1.2, yaw)
	var pot: Vector2 = bq(b, dl_x - 1.3, hd * 0.5 + 0.4)
	if free_at(pot.x, pot.y, 0.3): add("plant_potted_succulent", "normal", pot.x, pot.y, 0.0, 0.0, true, 1.0, 0.3)
	var pot2: Vector2 = bq(b, dl_x + 1.35, hd * 0.5 + 0.45)
	if rr.randf() < 0.6: try_add("plant_potted_leafy" if rr.randf() < 0.5 else "plant_potted_succulent", "normal", pot2.x, pot2.y, 0.0, 0.3)
	# people sit out front in the evening: a chair or two on the lawn by the door, facing the street
	if rr.randf() < float(design.get("front_chairs", 0.35)):
		var ch2: Vector2 = bq(b, dl_x + (2.4 if rr.randf() < 0.5 else -2.4), hd * 0.5 + 2.0)
		try_add(String(design.get("front_chair", "prop_adirondack_white")), "worn", ch2.x, ch2.y, yaw + rr.randf_range(-20, 20), 0.6)
	for c: Vector2 in [Vector2(-1, 1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1)]:
		on_wall(b, "prop_downspout_3m", "worn", c.x * (hw * 0.5 - 0.2), c.y * (hd * 0.5 + 0.04), 0.0, yaw + (0.0 if c.y > 0 else 180.0))
		var dsp := bq(b, c.x * (hw * 0.5 - 0.2), c.y * (hd * 0.5 + 0.3)); occ.append([dsp.x, dsp.y, 0.45])
	# services on the side wall facing the wider side yard: meters, AC on the ground beside it, hose reel
	var ws := side                                   # +1: the house's +x side in its own frame? use the lot side
	var lx := (hw * 0.5 + 0.02) * (1.0 if bq(b, 1.0, 0.0).distance_to(pt(axis, s1, ht)) < bq(b, -1.0, 0.0).distance_to(pt(axis, s1, ht)) else -1.0) * ws
	var wyaw := yaw + (90.0 if lx > 0 else -90.0)
	on_wall(b, "prop_meter_electric", "worn", lx, -hd * 0.1, 1.05, wyaw)
	on_wall(b, "prop_meter_gas", "rusty" if rr.randf() < 0.4 else "worn", lx, -hd * 0.1 - 0.8, 0.2, wyaw)
	var acp := bq(b, lx + signf(lx) * 0.75, -hd * 0.25)
	if free_at(acp.x, acp.y, 0.55): add("prop_ac_condenser" if rr.randf() < 0.6 else "prop_ac_condenser_compact", "worn", acp.x, acp.y, wyaw, 0.0, true, 1.0, 0.55)
	else:
		var acb := bq(b, -hw * 0.3, -hd * 0.5 - 0.8)
		if free_at(acb.x, acb.y, 0.55): add("prop_ac_condenser_compact", "worn", acb.x, acb.y, yaw + 180.0, 0.0, true, 1.0, 0.55)
	on_wall(b, "prop_hose_reel_wall", "worn", lx, hd * 0.25, 0.0, wyaw)
	if rr.randf() < 0.3: on_wall(b, "prop_satellite_dish_round" if rr.randf() < 0.5 else "prop_satellite_dish", "worn", -lx, -hd * 0.3, 2.7, yaw + (90.0 if -lx > 0 else -90.0))
	if rr.randf() < 0.35: on_wall(b, "prop_ac_window", "worn", -lx, hd * 0.15, 1.3, yaw + (90.0 if -lx > 0 else -90.0))
	var wall_plants: bool = design.get("wall_plants", false)
	if wall_plants:
		on_wall(b, "plant_bougainvillea_wall", "normal", hw * 0.25, hd * 0.5 + 0.3, 0.0, yaw)
		for kb: float in [-1.5, 0.0, 1.5]:
			var bwp := bq(b, hw * 0.25 + kb, hd * 0.5 + 0.4); occ.append([bwp.x, bwp.y, 0.55])
	# ---------------------------------------------------------------- back yard and garage strip
	var back := String(lot.get("back", "privacy"))
	var bf: Array = FENCE.get(back, FENCE["privacy"])
	var rear := f + set + hd                          # the house's back wall
	var sf: Array = FENCE.get(String(design.get("side", "privacy")), FENCE["privacy"])
	# side fences from the back corners of the house to the back line (on the higher terrace of the two)
	for e2: float in [s0, s1]:
		if e2 == s1 and not bool(lot.get("last", false)): continue     # each shared line once (the lot to the right draws it)
		var a3: Vector2 = pt(axis, e2, minf(t_r, float(lot.get("t_r_prev", t_r))) if e2 == s0 else t_r)   # a shared line starts where the first of the two yards closes
		var b3: Vector2 = pt(axis, e2, tb - 0.25)
		var yy := maxf(H, float(lot.get("Hprev", H)) if e2 == s0 else H)
		fence_run(a3, b3, String(sf[0]), String(sf[1]), float(sf[2]), yy)
	# the returns: from each side wall of the house to the lot line, touching both; the side gate on the wider side
	for sd: float in [-1.0, 1.0]:
		var wall_s := hs + sd * (hw * 0.5 - 0.05)       # from the back corner of the house (just behind its rear wall)
		var line_s := s1 if sd > 0 else s0
		var Lr := absf(line_s - wall_s)
		if Lr < 0.3: continue
		var ra: Vector2 = pt(axis, wall_s, t_r); var rb: Vector2 = pt(axis, line_s, t_r)
		if Lr >= 2.6 and sd == side:
			fence_line(ra, rb, [[Lr * 0.5, 1.15]], String(sf[0]), String(sf[1]), float(sf[2]), "fence_gate_privacy", H)
		else:
			fence_run(ra, rb, String(sf[0]), String(sf[1]), float(sf[2]), H)
	if gs > 0.0:
		# the yard's back fence along the strip edge, with a gate (steps if the strip is lower / higher)
		var gate_s := (s0 + s1) * 0.5 - side * (w * 0.5 - 2.0)
		var ba: Vector2 = pt(axis, s0, tb - 0.25); var bb: Vector2 = pt(axis, s1, tb - 0.25)
		fence_line(ba, bb, [[gate_s - s0, 1.2]], String(bf[0]), String(bf[1]), float(bf[2]), String(bf[3]), H)
		var cS := (func(u: float, v: float) -> float: return fh(u, bk)) if axis == "v" else (func(u: float, v: float) -> float: return fh(bk, v))
		steps(axis, gate_s, tb, -1.0, H, cS)
		# garage at the alley edge, its door to the alley; a second car on the pad beside it; bins by the gate
		var gar := String(lot.get("garage", ""))
		var gar_s := (s0 + s1) * 0.5 + side * (w * 0.5 - 2.4 - (3.0 if gar.contains("double") else 1.75))
		if gar != "" and gar != "own":
			var gst := K.building_stats(gar)
			var gw: float = gst.footprint_wd[0]; var gd: float = gst.footprint_wd[1]
			gar_s = clampf(gar_s, s0 + gw * 0.5 + 0.4, s1 - gw * 0.5 - 0.4)
			var gt := bk - 1.2 - gd * 0.5
			var gp: Vector2 = pt(axis, gar_s, gt)
			# the garage stands at the lowest point under its footprint (the strip follows the alley)
			var gy0 := minf(gy(pt(axis, gar_s - gw * 0.5, gt).x, pt(axis, gar_s - gw * 0.5, gt).y), gy(pt(axis, gar_s + gw * 0.5, gt).x, pt(axis, gar_s + gw * 0.5, gt).y))
			var gb := building(gar, gp.x, gp.y, gy0, yaw_of(-fdu, -fdv), false, "", float(design.get("wear", 0.65)) + 0.1)
			used[gar] = int(used.get(gar, 0)) + 1
			if not gar.contains("carport"):
				on_wall(gb, "prop_porch_light_barn", "worn", gw * 0.5 - 0.3, gd * 0.5 + 0.05, 2.35, yaw_of(-fdu, -fdv))
				if wall_plants: on_wall(gb, "plant_bougainvillea_wall", "normal", 0.0, -gd * 0.5 - 0.3, 0.0, yaw_of(fdu, fdv))
			var ap0: Vector2 = pt(axis, gar_s - gw * 0.5, bk - 1.2); var ap1: Vector2 = pt(axis, gar_s + gw * 0.5, bk)
			prect(minf(ap0.x, ap1.x), minf(ap0.y, ap1.y), maxf(ap0.x, ap1.x), maxf(ap0.y, ap1.y), "concrete")
			var oc: Vector2 = pt(axis, gar_s, bk - 0.8)
			W.oil(dec, rr, L2(oc.x, oc.y), yaw, Hc, 0.5)
			# roof items only where the roof stands clearly above the junction pad (the validator reads "on a roof" by
			# height over the piece origin; on the downhill side a garage roof can sit lower than that)
			var roof_ok := gy0 + float(gst.get("height", 2.8)) > 1.5
			if roof_ok and gar.contains("flat") and rr.randf() < 0.8:
				on_wall(gb, "prop_solar_panel_x3", "clean", 0.0, 0.0, float(gst.get("height", 2.8)) + 0.02, yaw_of(-fdu, -fdv))
			elif roof_ok and rr.randf() < 0.25:
				on_wall(gb, "prop_vent_turbine", "rusty", 0.6, -0.8, float(gst.get("height", 3.0)) - 0.1, 0.0)
			# the pad beside the garage: a car, a boat trailer or a golf cart
			var pad_s := gar_s - side * (gw * 0.5 + 1.7)
			if pad_s > s0 + 1.6 and pad_s < s1 - 1.6 and absf(pad_s - gate_s) > 2.4:
				var q0: Vector2 = pt(axis, pad_s - 1.4, bk - 6.0); var q1: Vector2 = pt(axis, pad_s + 1.4, bk)
				prect(minf(q0.x, q1.x), minf(q0.y, q1.y), maxf(q0.x, q1.x), maxf(q0.y, q1.y), "concrete")
				var pc: Vector2 = pt(axis, pad_s, bk - 3.0)
				var extra: Array = design.get("pad_extras", [])
				var roll := rr.randf()
				if roll < 0.55:
					stalls.append([L(pc.x, pc.y, 0.0).x, L(pc.x, pc.y, 0.0).z, yaw_of(fdu, fdv), gy(pc.x, pc.y), 0.0])
				elif roll < 0.8 and not extra.is_empty():
					add(String(extra[rr.randi() % extra.size()]), "worn", pc.x, pc.y, yaw_of(fdu, fdv), 0.0, true, 1.0, 1.3)
				W.oil(dec, rr, L2(pc.x, pc.y), yaw, Hc, 0.6)
		# now and then a house is being redone: the roll-off on the pad, a temporary fence round the yard's end, cones
		if rr.randf() < float(design.get("reno", 0.05)):
			var rs := (s0 + s1) * 0.5 - side * (w * 0.5 - 4.6)
			var rp: Vector2 = pt(axis, rs, bk - 3.4)
			if free_at(rp.x, rp.y, 1.8):
				add("prop_dumpster_rolloff_20yd", "dirty", rp.x, rp.y, yaw_of(0.0 if axis == "v" else 1.0, 1.0 if axis == "v" else 0.0), 0.0, true, 1.0, 1.8)
				for k6 in 2:
					var cn: Vector2 = pt(axis, rs + (k6 * 2.0 - 1.0) * 2.0, bk + 0.6)
					add("prop_cone_28in" if k6 == 0 else "prop_cone_18in", "dirty", cn.x, cn.y, rr.randf_range(0, 360), 0.0, false)
				var t0: Vector2 = pt(axis, s0 + 0.8, rear + 1.5); var t1: Vector2 = pt(axis, s1 - 0.8, rear + 1.5)
				fence_run(t0, t1, "fence_temp_fence_panel_screen", "", 3.3, H, "dirty")
				dec.add(14, L2(rp.x, rp.y), yaw, 3.5, 7.0, Hc, Color(0.85, 0.8, 0.7, 0.6))
		# three carts inside the back gate, against the fence (not collection day)
		for k3 in 3:
			var cp: Vector2 = pt(axis, gate_s + (1.25 + k3 * 0.9) * (1.0 if gate_s < (s0 + s1) * 0.5 else -1.0), tb + 0.8)
			if free_at(cp.x, cp.y, 0.38): add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k3], "worn", cp.x, cp.y, yaw_of(fdu, fdv) + rr.randf_range(-4, 4), 0.0, true, 1.0, 0.38)
		var gc: Vector2 = pt(axis, gate_s, tb + 1.0)
		dec.add(14, L2(gc.x, gc.y), yaw, 2.2, 1.6, Hc, Color(1, 1, 1, 0.55))
	# the yard: one shade tree in a back corner, and what this household does out there
	var bt: Array = design.get("back_trees", ["tree_ficus_a", "tree_coral_a", "tree_jacaranda_b", "tree_magnolia_b"])
	var tcs := s0 + 3.2 if side > 0 else s1 - 3.2
	var tcp: Vector2 = pt(axis, tcs, tb - 3.4)
	try_add(String(bt[rr.randi() % bt.size()]), "normal", tcp.x, tcp.y, rr.randf_range(0, 360), 1.2, rr.randf_range(0.8, 1.1))
	var yard: Array = design.get("yard", ["patio", "bbq", "chairs", "arbor", "line", "kayak"])
	var by := rear + 3.4
	var pick := String(yard[rr.randi() % yard.size()])
	var yc: Vector2 = pt(axis, hs, by)
	match pick:
		"patio":
			if try_add("prop_patio_set_4", "worn", yc.x, yc.y, rr.randf_range(-20, 20), 1.3):
				var pp3: Vector2 = pt(axis, hs - 1.9, by - 1.2)
				try_add("plant_potted_leafy", "normal", pp3.x, pp3.y, 0.0, 0.7)
				var bq2: Vector2 = pt(axis, hs + 2.6, by - 1.0)
				try_add("prop_bbq_kettle" if rr.randf() < 0.5 else "prop_bbq_gas_cart", "worn", bq2.x, bq2.y, yaw + 180.0, 0.7)
				dec.add(14, L2(yc.x, yc.y), yaw, 3.4, 3.0, Hc, Color(1, 1, 1, 0.5))
		"bbq":
			try_add("prop_bbq_gas_cart", "worn", yc.x - 0.0, yc.y, yaw, 0.9)
			var ch: Vector2 = pt(axis, hs - 2.2, by + 1.0)
			try_add("prop_adirondack_wood", "worn", ch.x, ch.y, yaw + 160.0, 0.7)
			var tank: Vector2 = pt(axis, hs + 1.4, rear + 0.5)
			try_add("prop_propane_cylinder_100lb", "rusty", tank.x, tank.y, 0.0, 0.3)
		"chairs":
			for k4 in 2:
				var cc: Vector2 = pt(axis, hs - 1.0 + k4 * 1.8, by + 0.6)
				try_add("prop_adirondack_white", "worn", cc.x, cc.y, yaw + 180.0 + rr.randf_range(-15, 15), 0.6)
		"arbor":
			var ac2: Vector2 = pt(axis, hs, by + 1.5)
			try_add("prop_garden_arbor", "worn", ac2.x, ac2.y, yaw, 1.0)
			var pl: Vector2 = pt(axis, hs + 2.0, by + 1.5)
			try_add("plant_potted_leafy", "normal", pl.x, pl.y, 0.0, 0.7)
		"line":
			var lc: Vector2 = pt(axis, hs, by + 1.8)
			if free_at(lc.x, lc.y, 2.8): add("prop_clothesline", "worn", lc.x, lc.y, yaw + 90.0, 0.0, true, 1.0, 2.8)
		"kayak":
			var kc: Vector2 = pt(axis, s0 + 1.2 if side < 0 else s1 - 1.2, rear + 2.5)
			try_add("prop_kayak_rack", "worn", kc.x, kc.y, yaw + 90.0, 1.0)
			var icp: Vector2 = pt(axis, hs + 1.5, rear + 1.0)
			try_add("prop_ice_chest", "worn", icp.x, icp.y, yaw, 0.5)
			var uc: Vector2 = pt(axis, hs, by)
			try_add("prop_beach_umbrella_closed", "worn", uc.x, uc.y, 0.0, 0.4)
	var pick2 := String(yard[(yard.find(pick) + 1 + rr.randi() % maxi(1, yard.size() - 1)) % yard.size()])
	var y2: Vector2 = pt(axis, hs + side * 3.5, by + 4.5)
	match pick2:
		"patio": try_add("prop_patio_set_4", "worn", y2.x, y2.y, rr.randf_range(-20, 20), 1.3)
		"bbq": try_add("prop_bbq_kettle", "worn", y2.x, y2.y, yaw, 0.5)
		"chairs": try_add("prop_adirondack_wood", "worn", y2.x, y2.y, yaw + 180.0 + rr.randf_range(-20, 20), 0.6)
		"arbor": try_add("prop_garden_arbor", "worn", y2.x, y2.y, yaw, 1.0)
		"line": if free_at(y2.x, y2.y, 2.8): add("prop_clothesline", "worn", y2.x, y2.y, yaw + 90.0, 0.0, true, 1.0, 2.8)
		"kayak": try_add("prop_beach_umbrella_closed", "worn", y2.x, y2.y, 0.0, 0.4)
	if rr.randf() < float(design.get("swing", 0.15)):
		var sw: Vector2 = pt(axis, (s0 + s1) * 0.5, tb - 5.5)
		try_add("prop_swing_set", "worn", sw.x, sw.y, yaw + 90.0, 2.6)
	var fr: Array = design.get("fruit", ["tree_coral_b", "tree_magnolia_a", "tree_jacaranda_a"])
	if rr.randf() < 0.55:
		var ft: Vector2 = pt(axis, s1 - 3.0 if side > 0 else s0 + 3.0, rear + rr.randf_range(5.0, 9.0))
		try_add(String(fr[rr.randi() % fr.size()]), "normal", ft.x, ft.y, rr.randf_range(0, 360), 1.0, rr.randf_range(0.55, 0.75))
	for k7 in 3:
		var bp: Vector2 = pt(axis, rr.randf_range(s0 + 1.2, s1 - 1.2), tb - 1.2)
		try_add(String(plants[rr.randi() % plants.size()]), "normal", bp.x, bp.y, rr.randf_range(0, 360), 0.6)
	var hr: Vector2 = pt(axis, hs - hw * 0.5 + 0.8, rear + 0.6)
	if rr.randf() < 0.5: try_add("prop_hose_reel_cart", "worn", hr.x, hr.y, yaw, 0.45)
	# wear: grime at the foot of the house front, the path to the back gate worn into the grass
	var g0: Vector2 = bq(b, -hw * 0.5, hd * 0.5 + 0.4); var g1: Vector2 = bq(b, hw * 0.5, hd * 0.5 + 0.4)
	dec.add(14, L2((g0.x + g1.x) * 0.5, (g0.y + g1.y) * 0.5), yaw + 90.0, 0.6, hw, Hc, Color(1, 1, 1, 0.4))
	if gs > 0.0:
		var gate_s2 := (s0 + s1) * 0.5 - side * (w * 0.5 - 2.0)
		var m2: Vector2 = pt(axis, (gate_s2 + hs) * 0.5, (rear + tb) * 0.5)
		dec.add(14, L2(m2.x, m2.y), yaw + rad_to_deg(atan2(gate_s2 - hs, tb - rear)) * (1.0 if axis == "v" else -1.0), 1.0, (tb - rear), Hc, Color(1, 1, 1, 0.5))

## the house's own driveway: a ramp from the edge it faces (field) up / down to the terrace at the house front
func _driveway(axis: String, s: float, f: float, t1: float, H: float) -> void:
	var a: Vector2 = pt(axis, s - 1.6, f); var b: Vector2 = pt(axis, s + 1.6, t1)
	prect(minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), "-")
	var nseg := 6
	for k in nseg:
		var ta := lerpf(f, t1, float(k) / nseg); var tb := lerpf(f, t1, float(k + 1) / nseg)
		var y0: float = fh(pt(axis, s, f).x, pt(axis, s, f).y)
		var ya := lerpf(y0, H, float(k) / nseg); var yb := lerpf(y0, H, float(k + 1) / nseg)
		var q0: Vector2 = pt(axis, s - 1.6, ta); var q1: Vector2 = pt(axis, s + 1.6, ta)
		var q2: Vector2 = pt(axis, s + 1.6, tb); var q3: Vector2 = pt(axis, s - 1.6, tb)
		g.quad("concrete", L(q0.x, q0.y, ya), L(q1.x, q1.y, ya), L(q2.x, q2.y, yb), L(q3.x, q3.y, yb))
		for e: float in [s - 1.6, s + 1.6]:
			var r0: Vector2 = pt(axis, e, ta); var r1: Vector2 = pt(axis, e, tb)
			wall2(L2(r0.x, r0.y), L2(r1.x, r1.y), ya, yb, H, H)
	var oc: Vector2 = pt(axis, s, (f + t1) * 0.5)
	W.oil(dec, rr, L2(oc.x, oc.y), 0.0, func(x: float, z: float) -> float: return gyl(x, z) + 0.0, 0.5)

## ------------------------------------------------------------------------------------------------ the corner shop
## A neighbourhood shop on the corner lot of A (the corner where both streets meet, flat: inside the junction's level
## margin): its front on the avenue behind a 2.5 m paved forecourt, its side on the side street, staff parking and the
## bins off the alley. Its room is made by the room tool (interiors/assignment_res.json).
func corner_shop(lot: Dictionary, folder: String, label: String, kind: String) -> void:
	var H := float(lot.Ht)
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var s0 := float(lot.s0); var s1 := float(lot.s1)
	var su := s0 + 1.4 + w * 0.5
	var tv := PROP + FORE + d * 0.5
	var b := building(folder, su, tv, H, yaw_of(0.0, -1.0), false, label, 0.7)
	lot.bld = b
	used[folder] = int(used.get(folder, 0)) + 1
	shops.append([label, folder, kind])
	prect(s0, PROP, s1, PROP + FORE, "concrete")
	# the forecourt: what this shop puts out (never in front of the door), a bench facing the street, a bike rack along
	# the front, a newspaper box; a sandwich-board style menu is the kit's menu board for cafes
	var door_s := su
	for e: Array in st.get("doors_front", []):
		door_s = bq(b, float(e[1]), d * 0.5).x; break
	var spots: Array = [s0 + 1.2, s1 - 1.0, s0 + 3.0, s1 - 3.0]
	var things: Array = []
	match kind:
		"cafe": things = [["prop_park_bench", 0.0], ["prop_bike_rack", 0.0], ["plant_potted_leafy", 0.0], ["prop_newspaper_box_blue", 0.0]]
		"cleaners": things = [["prop_bench_bus_stop", 0.0], ["prop_vending_soda", 0.0], ["prop_recycling_receptacle", 0.0], ["plant_potted_succulent", 0.0]]
		_: things = [["prop_bike_rack", 0.0], ["prop_ice_chest", 0.0], ["prop_newspaper_box_red", 0.0], ["prop_trash_receptacle", 0.0]]
	var k := 0
	for sp: float in spots:
		if k >= things.size(): break
		if absf(sp - door_s) < 2.2: continue
		var t: Array = things[k]
		var yy := yaw_of(0.0, -1.0) + (0.0 if String(t[0]) != "prop_bike_rack" else 0.0)
		if String(t[0]).begins_with("prop_vending") or String(t[0]) == "prop_ice_chest": yy = yaw_of(0.0, -1.0)
		if try_add(String(t[0]), "worn", sp, PROP + 1.2, yy, 0.5): k += 1
	dec.add(14, L2(door_s, PROP + 1.4), 0.0, 2.0, 2.4, func(x: float, z: float) -> float: return gyl(x, z), Color(1, 1, 1, 0.55))
	# the corner: the neighbourhood's mailbox and a paper box where people pass; pots either side of the door; a lamp
	try_add("prop_usps_collection_box", "worn", s1 - 0.8, PROP + 0.6, yaw_of(0.0, -1.0), 0.5)
	for sd2: float in [-1.0, 1.0]:
		try_add("plant_potted_leafy" if kind == "cafe" else "plant_potted_succulent", "normal", door_s + sd2 * 1.1, PROP + FORE - 0.35, 0.0, 0.3)
	on_wall(b, "prop_porch_light_coach_bronze", "worn", -w * 0.35, d * 0.5 + 0.05, 2.4, yaw_of(0.0, -1.0))
	on_wall(b, "prop_porch_light_coach_bronze", "worn", w * 0.35, d * 0.5 + 0.05, 2.4, yaw_of(0.0, -1.0))
	if kind == "sport":       # boards and kayaks out front in the morning (the shop rents them)
		try_add("prop_kayak_rack", "worn", s0 + 2.0, PROP + 1.0, yaw_of(1.0, 0.0), 0.9)
		try_add("prop_beach_umbrella_closed", "worn", s0 + 3.2, PROP + 0.8, 0.0, 0.3)
	if kind == "cafe":        # two small tables outside on the forecourt, chairs pushed in
		try_add("prop_patio_set_4", "worn", s1 - 2.6, PROP + 1.25, 0.0, 1.0)
	# back of house: meters, AC, the bins in an enclosure off the alley, two staff stalls
	on_wall(b, "prop_meter_electric", "worn", -w * 0.3, -d * 0.5 - 0.02, 1.05, yaw_of(0.0, 1.0))
	on_wall(b, "prop_meter_gas", "rusty", -w * 0.3 + 0.9, -d * 0.5 - 0.02, 0.2, yaw_of(0.0, 1.0))
	var acp := bq(b, w * 0.25, -d * 0.5 - 0.9)
	try_add("prop_ac_condenser", "dirty", acp.x, acp.y, yaw_of(0.0, 1.0), 0.6)
	var bins := Vector2(s0 + 2.0, float(lot.b) - 2.0)
	add("prop_dumpster_3yd_green", "dirty", bins.x, bins.y, yaw_of(0.0, -1.0), 0.0, true, 1.0, 1.2)
	var rc := Vector2(s0 + 4.0, float(lot.b) - 1.5)
	try_add("prop_recycling_receptacle", "worn", rc.x, rc.y, yaw_of(0.0, -1.0), 0.4)
	prect(s0, float(lot.b) - 13.0, s1, float(lot.b), "asphalt")
	for k2 in 2:
		var sc := Vector2(s1 - 2.0 - k2 * 2.8, float(lot.b) - 6.5)
		stalls.append([L(sc.x, sc.y, 0.0).x, L(sc.x, sc.y, 0.0).z, yaw_of(0.0, -1.0), gy(sc.x, sc.y), 0.0])
		W.oil(dec, rr, L2(sc.x, sc.y), 0.0, func(x: float, z: float) -> float: return gyl(x, z), 0.7)
	W.cracks(dec, rr, minf(L2(s0, float(lot.b) - 13.0).x, L2(s1, float(lot.b)).x), minf(L2(s0, float(lot.b) - 13.0).y, L2(s1, float(lot.b)).y), maxf(L2(s0, float(lot.b) - 13.0).x, L2(s1, float(lot.b)).x), maxf(L2(s0, float(lot.b) - 13.0).y, L2(s1, float(lot.b)).y), 6, func(x: float, z: float) -> float: return gyl(x, z), 0.5)
	# a low hedge on the side-street edge (the side yard), the rest is lawn
	var x := float(lot.f) + FORE + d + 0.6           # the side yard behind the shop
	while x + 2.0 < float(lot.b) - 14.0:
		props.add("hedge_boxwood_low_2m", "normal", L(s0 + 0.5, x + 1.0, H), yaw_of(1.0, 0.0))
		occ.append([s0 + 0.5, x + 1.0, 0.5])
		x += 2.0

## ------------------------------------------------------------------------------------------------ alleys
## the two alleys of the quadrant: asphalt following the surface, a concrete centre gutter, poles along one edge (the
## overhead line runs down the alley; positions go to meta "poles" for the wires piece), cracks, patches, oil, grime
func alleys() -> void:
	var c := (AL0 + AL1) * 0.5
	# gutter first (the first matching paint wins)
	prect(PROP, c - 0.4, LU, c + 0.4, "concrete")
	prect(PROP, AL0, LU, AL1, "asphalt")
	prect(c - 0.4, PROP, c + 0.4, AL0, "concrete"); prect(c - 0.4, AL1, c + 0.4, LV, "concrete")
	prect(AL0, PROP, AL1, AL0, "asphalt"); prect(AL0, AL1, AL1, LV, "asphalt")
	surfs.append([PROP, AL0, LU, AL1, "field", 0.0])
	surfs.append([AL0, PROP, AL1, AL0, "field", 0.0])
	surfs.append([AL0, AL1, AL1, LV, "field", 0.0])
	var Hc := func(x: float, z: float) -> float: return gyl(x, z)
	for along_u: bool in [true, false]:
		var a := L2(PROP, AL0) if along_u else L2(AL0, PROP)
		var b := L2(LU, AL1) if along_u else L2(AL1, LV)
		var LL := LU if along_u else LV
		W.cracks(dec, rr, minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), 18, Hc, 0.4)
		var k := PROP + 3.0
		while k < LL - 3.0:
			var o := Vector2(k, c + rr.randf_range(-1.6, 1.6)) if along_u else Vector2(c + rr.randf_range(-1.6, 1.6), k)
			W.oil(dec, rr, L2(o.x, o.y), 90.0 if along_u else 0.0, Hc, rr.randf_range(0.45, 0.8))
			for e: float in [AL0 + 0.3, AL1 - 0.3]:
				var gp := Vector2(k + 1.5, e) if along_u else Vector2(e, k + 1.5)
				dec.add(14, L2(gp.x, gp.y), 90.0 if along_u else 0.0, 0.7, 3.0, Hc, Color(1, 1, 1, rr.randf_range(0.4, 0.65)))
			k += rr.randf_range(6.0, 10.0)
		for t in 2:
			var tp := rr.randf_range(PROP + 6.0, LL - 6.0)
			var pv2 := Vector2(tp, c) if along_u else Vector2(c, tp)
			dec.add(2 + t, L2(pv2.x, pv2.y), 90.0 if along_u else 0.0, 2.4, 6.0, Hc, Color(1, 1, 1, 0.9))
		var ps := rr.randf_range(30.0, 90.0)
		var pq := Vector2(ps, c - 1.2) if along_u else Vector2(c - 1.2, ps)
		W.pale_patch(dec, rr, L2(pq.x, pq.y), 90.0 if along_u else 0.0, 1.6, 2.4, Hc)     # a utility cut, patched

## the alley poles (after the lots): every ~30 m on one alley edge, each slid along the alley until it is clear of
## every garage door and gate (a pole never stands in front of a garage)
func alley_poles() -> void:
	var c := (AL0 + AL1) * 0.5
	for along_u: bool in [true, false]:
		var s := 18.0 if along_u else 24.0
		var LL2 := LU if along_u else LV
		while s < LL2 - 4.0:
			var placed := false
			for dk: float in [0.0, 2.0, -2.0, 4.0, -4.0, 6.0, -6.0, 8.0, -8.0]:
				var ss2 := s + dk
				if absf(ss2 - c) < 5.0 or ss2 < PROP + 4.0 or ss2 > LL2 - 2.0: continue
				var pu2 := Vector2(ss2, AL0 - 0.45) if along_u else Vector2(AL0 - 0.45, ss2)      # in the rear easement, off the asphalt
				var ok := true
				for dp: Vector2 in doorpts:
					if pu2.distance_to(dp) < 2.2: ok = false; break
				if ok and not free_at(pu2.x, pu2.y, 0.3): ok = false
				if ok:
					var lp2 := L2(pu2.x, pu2.y)
					for pr: Array in paints:     # never on a paved lot (the corner shops' staff parking)
						if String(pr[4]) == "asphalt" and lp2.x > float(pr[0]) - 0.3 and lp2.x < float(pr[2]) + 0.3 and lp2.y > float(pr[1]) - 0.3 and lp2.y < float(pr[3]) + 0.3 and not (absf(pu2.y - (AL0 + AL1) * 0.5) < 3.0 or absf(pu2.x - (AL0 + AL1) * 0.5) < 3.0): ok = false; break
				if not ok: continue
				var pyaw := 90.0 if along_u else 0.0
				props.add("prop_utility_pole_transformer" if poles.size() % 3 == 1 else "prop_utility_pole", "worn", L(pu2.x, pu2.y, fh(pu2.x, pu2.y) - KERB_H + 0.02), pyaw)
				occ.append([pu2.x, pu2.y, 0.4])
				poles.append([L(pu2.x, pu2.y, fh(pu2.x, pu2.y)), pyaw, "u" if along_u else "v"])
				placed = true; break
			s += 30.0

## ------------------------------------------------------------------------------------------------ sub-block D
## pocket park (the block's kids play here; parents watch from the benches): iron fence round it, ONE gate off the
## alley, a level play pad of bark with a low edge, swings, slide, picnic under a sail, fountain, bins, shade trees, a
## lamp at the gate; the lawn follows the hill.
func park_d(kind: String) -> void:
	var u0 := AL1; var v0 := AL1; var u1 := LU; var v1 := LV
	surfs.append([u0, v0, u1, v1, "field", 0.0])
	var Hc := func(x: float, z: float) -> float: return gyl(x, z)
	var gate_v := 76.0
	# fence (on the lawn, following it), a gate off the alley that runs along v (u 54-60)
	fence_line(Vector2(u0 + 0.6, v0 + 0.6), Vector2(u1 - 0.6, v0 + 0.6), [], "fence_wrought_iron", "fence_post_wrought_iron", 1.98)
	fence_line(Vector2(u1 - 0.6, v0 + 0.6), Vector2(u1 - 0.6, v1 - 0.6), [], "fence_wrought_iron", "fence_post_wrought_iron", 1.98)
	fence_line(Vector2(u1 - 0.6, v1 - 0.6), Vector2(u0 + 0.6, v1 - 0.6), [], "fence_wrought_iron", "fence_post_wrought_iron", 1.98)
	fence_line(Vector2(u0 + 0.6, v1 - 0.6), Vector2(u0 + 0.6, v0 + 0.6), [[(v1 - 0.6) - gate_v, 1.3]], "fence_wrought_iron", "fence_post_wrought_iron", 1.98, "fence_gate_wrought_iron")
	prect(u0, gate_v - 1.0, u0 + 8.0, gate_v + 1.0, "concrete")
	add("prop_lamp_globe", "worn", u0 + 1.6, gate_v + 2.4, 0.0, 0.0, true, 1.0, 0.4)
	if kind == "park":
		# the play area: a level bark pad with a low edge, three things to play on, a shade sail over the parents'
		# bench, benches round it facing the play (parents watch the kids, not a wall)
		var pu0 := 68.0; var pv0 := 63.5; var pu1 := 91.0; var pv1 := 80.5
		var Hp := snappedf(fh((pu0 + pu1) * 0.5, (pv0 + pv1) * 0.5), 0.01)
		surfs.append([pu0, pv0, pu1, pv1, "level", Hp])
		prect(pu0, pv0, pu1, pv1, "mulch")
		var cP := c_const(Hp); var cF := c_field()
		seam(Vector2(pu0, pv0), Vector2(pu1, pv0), cP, cF); seam(Vector2(pu1, pv0), Vector2(pu1, pv1), cP, cF)
		seam(Vector2(pu1, pv1), Vector2(pu0, pv1), cP, cF); seam(Vector2(pu0, pv1), Vector2(pu0, pv0), cP, cF)
		add("prop_play_structure", "worn", 80.5, 71.5, yaw_of(-1.0, 0.0), 0.0, true, 1.0, 4.0)
		add("prop_swing_set", "worn", 72.5, 67.8, 90.0, 0.0, true, 1.0, 2.6)
		add("prop_slide", "worn", 87.5, 66.5, yaw_of(0.0, 1.0), 0.0, true, 1.0, 1.6)
		add("prop_swing_set", "dirty", 87.5, 77.0, 0.0, 0.0, true, 1.0, 2.6)
		dec.add(14, L2(72.5, 67.8), 0.0, 3.0, 2.0, Hc, Color(1, 1, 1, 0.6))
		dec.add(14, L2(87.5, 77.0), 90.0, 3.0, 2.0, Hc, Color(1, 1, 1, 0.6))
		dec.add(14, L2(80.5, 75.5), 0.0, 4.0, 2.4, Hc, Color(1, 1, 1, 0.45))
		for e: Array in [[66.3, 69.0, 1.0, 0.0], [66.3, 73.5, 1.0, 0.0], [76.0, 82.3, 0.0, -1.0], [83.0, 82.3, 0.0, -1.0]]:
			add("prop_park_bench", "worn", float(e[0]), float(e[1]), yaw_of(float(e[2]), float(e[3])), 0.0, true, 1.0, 1.0)
		props.add("prop_shade_sail", "worn", L(66.3, 71.2, gy(66.3, 71.2)), 90.0)
		# the gate: path, a bin and the fountain beside it (never on it), a lamp
		add("prop_trash_receptacle", "worn", 64.0, 79.2, 0.0, 0.0, true, 1.0, 0.4)
		add("prop_recycling_receptacle", "worn", 65.0, 79.2, 0.0, 0.0, true, 1.0, 0.4)
		add("prop_drinking_fountain", "worn", 64.0, 72.6, yaw_of(1.0, 0.0), 0.0, true, 1.0, 0.5)
		# the picnic lawn at the back: two tables, each under its own sail, a grill, a bin at the lawn's edge
		for k in 2:
			var tu := 72.0 + k * 10.0
			add("prop_picnic_table", "worn", tu, 91.0, 0.0, 0.0, true, 1.0, 1.4)
			props.add("prop_shade_sail", "worn", L(tu, 91.0, gy(tu, 91.0)), 0.0)
			dec.add(14, L2(tu, 91.0), 0.0, 3.4, 3.0, Hc, Color(1, 1, 1, 0.45))
		add("prop_bbq_kettle", "dirty", 77.0, 95.5, 0.0, 0.0, true, 1.0, 0.5)
		add("prop_trash_receptacle", "dirty", 88.5, 96.5, 0.0, 0.0, true, 1.0, 0.4)
		# planting: beds along the fence, trees in the corners and the lawn
		for t: Array in [["tree_coral_b", 95.5, 64.5], ["tree_jacaranda_a", 64.5, 95.0], ["tree_magnolia_a", 96.0, 96.0], ["tree_torrey_pine_a", 95.5, 84.0], ["tree_jacaranda_b", 64.5, 86.0]]:
			try_add(String(t[0]), "normal", float(t[1]), float(t[2]), rr.randf_range(0, 360), 1.0)
		for bed: Array in [[62.0, 64.0, 0.0], [70.0, 62.0, 90.0], [97.8, 72.0, 0.0], [92.0, 97.8, 90.0], [62.0, 90.0, 0.0]]:
			var pb: String = ["plant_bird_of_paradise", "plant_agave_americana", "plant_iceplant_patch", "plant_bougainvillea_mound"][rr.randi() % 4]
			try_add(pb, "normal", float(bed[0]), float(bed[1]), float(bed[2]), 1.0)
		for hb in 4:
			var hu := 74.0 + hb * 4.0
			props.add("hedge_boxwood_low_2m", "normal", L(hu, 98.6, gy(hu, 98.6)), yaw_of(1.0, 0.0))
		add("prop_lamp_globe", "worn", 91.5, 86.5, 0.0, 0.0, true, 1.0, 0.4)
		dec.add(14, L2(66.0, 76.0), 90.0, 1.4, 6.0, Hc, Color(1, 1, 1, 0.5))
	else:
		# a quiet green: the block's old trees (a Norfolk pine and a Torrey pine), a small memorial with a bench each
		# side facing it, picnic tables under sails, beds along the fence, the dog walkers' bin and sign at the gate,
		# the diagonal shortcut worn into the grass
		try_add("tree_norfolk_pine_c", "normal", 88.0, 88.0, 30.0, 1.5)
		try_add("tree_torrey_pine_b", "normal", 68.0, 92.0, 110.0, 1.5)
		try_add("tree_coral_a", "normal", 93.0, 66.0, 200.0, 1.2)
		try_add("tree_magnolia_b", "normal", 70.0, 66.0, 60.0, 1.2)
		var mc := Vector2(80.0, 79.0)
		var Hm := snappedf(fh(mc.x, mc.y), 0.01)
		surfs.append([mc.x - 4.0, mc.y - 4.0, mc.x + 4.0, mc.y + 4.0, "level", Hm])
		prect(mc.x - 4.0, mc.y - 4.0, mc.x + 4.0, mc.y + 4.0, "paving")
		var cM := c_const(Hm); var cF2 := c_field()
		seam(Vector2(mc.x - 4.0, mc.y - 4.0), Vector2(mc.x + 4.0, mc.y - 4.0), cM, cF2); seam(Vector2(mc.x + 4.0, mc.y - 4.0), Vector2(mc.x + 4.0, mc.y + 4.0), cM, cF2)
		seam(Vector2(mc.x + 4.0, mc.y + 4.0), Vector2(mc.x - 4.0, mc.y + 4.0), cM, cF2); seam(Vector2(mc.x - 4.0, mc.y + 4.0), Vector2(mc.x - 4.0, mc.y - 4.0), cM, cF2)
		add("prop_obelisk_monument", "worn", mc.x, mc.y, 0.0, 0.0, true, 1.0, 1.2)
		for e: Array in [[mc.x - 3.0, mc.y, 1.0, 0.0], [mc.x + 3.0, mc.y, -1.0, 0.0]]:
			add("prop_park_bench", "worn", float(e[0]), float(e[1]), yaw_of(float(e[2]), float(e[3])), 0.0, true, 1.0, 1.0)
		for k2 in 4: props.add("plant_potted_succulent", "normal", L(mc.x + [-1.2, 1.2, -1.2, 1.2][k2], mc.y + [-1.2, -1.2, 1.2, 1.2][k2], Hm), 0.0)
		for k in 2:
			var tu2 := 70.0 + k * 10.0
			add("prop_picnic_table", "worn", tu2, 67.5, 0.0, 0.0, true, 1.0, 1.4)
			props.add("prop_shade_sail", "worn", L(tu2, 67.5, gy(tu2, 67.5)), 0.0)
		add("prop_park_bench", "worn", 92.0, 95.0, yaw_of(-1.0, -1.0), 0.0, true, 1.0, 1.0)
		add("prop_trash_receptacle", "worn", 64.0, 79.2, 0.0, 0.0, true, 1.0, 0.4)
		add("prop_beach_sign_dog", "worn", 63.6, 72.8, yaw_of(1.0, 0.0), 0.0, true, 1.0, 0.3)
		for bed2: Array in [[97.6, 74.0], [97.6, 80.0], [62.2, 86.0], [75.0, 97.8], [84.0, 62.2]]:
			var pb2: String = ["plant_agave_americana", "plant_iceplant_patch", "plant_bird_of_paradise", "plant_bougainvillea_mound"][rr.randi() % 4]
			try_add(pb2, "normal", float(bed2[0]), float(bed2[1]), 0.0, 1.0)
		add("prop_lamp_globe", "worn", 74.0, 74.0, 0.0, 0.0, true, 1.0, 0.4)
		dec.add(14, L2(72.0, 77.5), yaw_of(1.0, 0.3), 1.2, 16.0, Hc, Color(1, 1, 1, 0.55))

## ------------------------------------------------------------------------------------------------ finish
## after everything is placed: drop any small ground item a fence line or a wall-mounted bush crosses (the yard
## fences are drawn after the planting and the services, so they can cut through them), and items on top of each other
func clear_fences() -> void:
	var walls: Array = []
	for k: String in props.items:
		if k.begins_with("prop_downspout") or k.begins_with("plant_bougainvillea_wall"):
			for t: Transform3D in props.items[k]: walls.append(Q2(t.origin))
	var kept_pts: Array = []
	for k: String in props.items.keys():
		var base := k.get_slice("|", 0)
		if base.begins_with("fence_") or base.begins_with("tree_") or base.begins_with("palm_") or base.begins_with("prop_utility_pole") or base.begins_with("prop_shade_sail"): continue
		var e := K.manifest(base)
		if String(e.get("mount", "ground")) != "ground": continue
		var fw2 := float(e.get("footprint_w", 0.5)); var fd2 := float(e.get("footprint_d", 0.5))
		var r := 0.5 * sqrt(fw2 * fw2 + fd2 * fd2)
		var keep: Array = []
		for t: Transform3D in props.items[k]:
			var q := Q2(t.origin)
			var ok := not near_fence(q.x, q.y, r + 0.05)
			if ok:
				for wq: Vector2 in walls:
					if q.distance_to(wq) < r + 0.35: ok = false; break
			if ok: keep.append(t)
		props.items[k] = keep

func finish() -> void:
	clear_fences()
	# the ground: every surface with the paints (holes "-" where steps / ramps are built)
	for s: Array in surfs:
		var a := L2(float(s[0]), float(s[1])); var b := L2(float(s[2]), float(s[3]))
		var kind := String(s[4]); var y := float(s[5])
		var yfn: Callable
		match kind:
			"level": yfn = func(_x: float, _z: float) -> float: return y
			"strip_u": yfn = func(x: float, _z: float) -> float: return fh(x * sx, y)
			"strip_v": yfn = func(_x: float, z: float) -> float: return fh(y, z * sz)
			_: yfn = func(x: float, z: float) -> float: return fh(x * sx, z * sz)
		K.painted_rect(g, minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), paints, yfn, "grass")
	# no tree hugging a fence or a wall top
	root.set_meta("stalls", stalls)
	root.set_meta("poles", poles)
	root.set_meta("shops", shops)
	root.set_meta("houses", used)
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: ground tris %d, props %d, buildings %d, stalls %d, shops %d" % [name, g.tri_count(), props.count(), bl.get_child_count(), stalls.size(), shops.size()])
	K.save_piece(root, name)

## ------------------------------------------------------------------------------------------------ the whole quadrant
## site: {sx, sz, p0, pu, pv, puv, shop: [folder, label, kind] or []}. design: the variant (rv_designs.gd).
func build(piece: String, site: Dictionary, des: Dictionary) -> void:
	begin(piece, site, des)
	alleys()
	var houses: Array = (des.houses as Array).duplicate()
	var garages: Array = des.garages
	var bag: Array = []
	var pick := func() -> String:
		if bag.is_empty():
			bag = houses.duplicate()
			for i in range(bag.size() - 1, 0, -1):
				var j := rr.randi_range(0, i); var tv: Variant = bag[i]; bag[i] = bag[j]; bag[j] = tv
		return String(bag.pop_back())
	var fronts: Array = des.fronts
	var mk := func(w: float, i: int, maxw: float) -> Dictionary:
		var h := ""
		var fits := false
		for tries in 12:
			h = String(pick.call())
			if float(K.building_stats(h).footprint_wd[0]) <= maxw: fits = true; break
		if not fits:      # nothing narrow enough came up: the narrowest house of the design that fits (never one too wide)
			var best_w := 1e9
			for hh: String in houses:
				var ww := float(K.building_stats(hh).footprint_wd[0])
				if ww <= maxw and ww < best_w: best_w = ww; h = hh
		return {"w": w, "house": h, "garage": String(garages[rr.randi() % garages.size()]), "front": String(fronts[rr.randi() % fronts.size()]),
			"back": String(des.get("back", "privacy")), "gs": GS, "i": i}
	var shop: Array = site.get("shop", [])
	for sub: String in ["A", "B", "C"]:
		var n: int = int(des.get(sub, 3))
		var axis := "u" if sub == "C" else "v"
		var s0 := PROP if sub != "B" else AL1
		var s1 := AL0 if sub == "A" else LU
		if sub == "C": s0 = AL1; s1 = LV
		if sub != "A": n = maxi(1, roundi(float(n) * (s1 - s0) / 40.0))      # the design's count is for a 40 m frontage
		var specs: Array = []
		var lw := (s1 - s0) / n
		for i in n:
			specs.append(mk.call(lw, i, lw - 2.0))
		if sub == "A" and not shop.is_empty():
			specs[0] = {"w": lw, "house": "", "garage": "", "front": "", "back": "", "gs": 0.0, "i": 0, "shop": true}
		var lots := row(axis, s0, PROP, AL0, specs)
		var prevH := -1000.0
		for i in lots.size():
			var lot: Dictionary = lots[i]
			lot.last = i == lots.size() - 1
			lot.next_front = String(lots[i + 1].get("front", "")) if i + 1 < lots.size() else ""
			lot.Hprev = prevH if prevH > -999.0 else float(lot.Ht)
			if i > 0 and (lots[i - 1] as Dictionary).has("t_r"): lot.t_r_prev = float(lots[i - 1].t_r)
			prevH = float(lot.Ht)
			if bool(lot.get("shop", false)): corner_shop(lot, String(shop[0]), String(shop[1]), String(shop[2]))
			else: house_lot(lot)
	match String(des.get("D", "park")):
		"cottages":
			var dh: Array = des.d_houses
			var nd: int = maxi(1, roundi(float(des.get("D_n", 2)) * (LU - AL1) / 40.0))
			var specs2: Array = []
			var lw2 := (LU - AL1) / nd
			for i in nd:
				var h2 := String(dh[(rr.randi() + i) % dh.size()])
				specs2.append({"w": lw2, "house": h2, "garage": "own", "front": String(des.get("d_front", "")), "back": String(des.get("back", "privacy")), "gs": 0.0, "i": i, "set_extra": -2.0})
			var lots2 := row("v", AL1, AL1, LV, specs2)
			var prev2 := -1000.0
			for i in lots2.size():
				var lot2: Dictionary = lots2[i]
				lot2.last = i == lots2.size() - 1
				lot2.next_front = String(lots2[i + 1].get("front", "")) if i + 1 < lots2.size() else ""
				lot2.Hprev = prev2 if prev2 > -999.0 else float(lot2.Ht)
				if i > 0 and (lots2[i - 1] as Dictionary).has("t_r"): lot2.t_r_prev = float(lots2[i - 1].t_r)
				prev2 = float(lot2.Ht)
				house_lot(lot2)
				# the back line (mid-block): a privacy fence on the terrace
				var bf: Array = FENCE.get(String(des.get("back", "privacy")), FENCE["privacy"])
				fence_run(Vector2(float(lot2.s0) + 0.2, LV - 0.3), Vector2(float(lot2.s1) - 0.2, LV - 0.3), String(bf[0]), String(bf[1]), float(bf[2]), float(lot2.Ht))
		"green": park_d("green")
		_: park_d("park")
	alley_poles()
	finish()
