extends RefCounted
## City-centre FILL helpers (claude/fill-city-centre, 19 Nov). A copy of the ideas in cc_lib.gd / block_lib.gd with the
## behaviour the fill needs (the shared libraries are not edited): buildings placed by their REAL near-mesh outline
## facing any of the four directions, every prop placed with a reason and checked against buildings, doors and other
## props (a refused prop is PRINTED, never silently dropped), ground at a given height per rectangle (level pads),
## a 0.3 m skirt under every outer edge, and a ground-only stage (CCF_STAGE=ground) so the ground can be checked
## against the land before anything stands on it. This file DECIDES NOTHING: every position comes from a piece script.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")

var name := ""
var root: Node3D
var bl: Node3D
var g := K.Ground.new()
var props := K.Props.new()
var dec := K.Decals.new()
var rr: RandomNumberGenerator
var y0 := 0.15                 # the level of this piece's pad (piece-local)
var paints: Array = []         # [x0, z0, x1, z1, mat] cut into the floor
var floors: Array = []         # [x0, z0, x1, z1, y]  pads
var blds: Array = []           # {node, folder, rect [x0, z0, x1, z1], doors [[kind, Vector3, Vector3 out]], yaw}
var items: Array = []          # [Vector2, r, base]
var why := {}
var refused: Array = []
var stalls: Array = []
var stage := ""

func _init(piece: String, level := 0.15) -> void:
	name = piece; y0 = level
	rr = W.rng_for(piece)
	stage = OS.get_environment("CCF_STAGE")
	root = Node3D.new(); root.name = piece
	bl = Node3D.new(); bl.name = "Buildings"; root.add_child(bl)

var hfn := Callable()          # the piece's floor height (x, z) -> y when it is not flat (set by the piece script)
func yf(x: float, z: float) -> float: return float(hfn.call(x, z)) if hfn.is_valid() else y0

## ---------------------------------------------------------------- ground
func pad(x0: float, z0: float, x1: float, z1: float, fn := Callable()) -> void:
	floors.append([minf(x0, x1), minf(z0, z1), maxf(x0, x1), maxf(z0, z1), fn])

## a retaining face along a - b where two levels meet: from ybot(x, z) up to ytop(x, z), facing out_side (as wall_line);
## 0.3 m deeper than the lower level so no gap shows at its foot
func retain(a: Vector2, b: Vector2, ybot: Callable, ytop: Callable, out_side: float, mat := "wall") -> void:
	var n := maxi(1, int(ceil(a.distance_to(b) / 2.0)))
	var pts := PackedVector2Array()
	for i in n + 1: pts.append(a.lerp(b, float(i) / n))
	g.wall_line(mat, pts, func(x: float, z: float) -> float: return float(ybot.call(x, z)) - 0.3, ytop, out_side)

func paint(mat: String, x0: float, z0: float, x1: float, z1: float) -> void:
	paints.append([minf(x0, x1), minf(z0, z1), maxf(x0, x1), maxf(z0, z1), mat])

## a tree well in paved ground: a hole in the floor (first paint wins) and the well cell drawn on its own, so the slab
## never hides the well's soil (16 Nov: "trees grow out of the cement")
var wells: Array = []
func well(x: float, z: float, a := 0.9, r := 0.75) -> void:
	paints.push_front([x - a, z - a, x + a, z + a, "-"])
	wells.append([Vector2(x, z), a, r])

func _draw_well(c: Vector2, a: float, r: float) -> void:
	var n := 24
	var wy := yf(c.x, c.y); var sy := wy - 0.06
	for k in n:
		var t0 := TAU * k / n; var t1 := TAU * (k + 1) / n
		var d0 := Vector2(cos(t0), sin(t0)); var d1 := Vector2(cos(t1), sin(t1))
		var c0 := c + d0 * r; var c1 := c + d1 * r
		var s0 := c + d0 * (a / maxf(absf(d0.x), absf(d0.y))); var s1 := c + d1 * (a / maxf(absf(d1.x), absf(d1.y)))
		g.quad("concrete", Vector3(c0.x, wy, c0.y), Vector3(c1.x, wy, c1.y), Vector3(s1.x, wy, s1.y), Vector3(s0.x, wy, s0.y))
		g.tri("mulch", Vector3(c.x, sy, c.y), Vector3(c0.x, sy, c0.y), Vector3(c1.x, sy, c1.y))
		var inward := Vector3(-(d0.x + d1.x), 0, -(d0.y + d1.y))
		g.quad("curb", Vector3(c0.x, sy, c0.y), Vector3(c1.x, sy, c1.y), Vector3(c1.x, wy, c1.y), Vector3(c0.x, wy, c0.y), inward, true)

## extra ground that follows a street's real edge where it is not straight (a polygon in x, z at the pad level)
var polys: Array = []
func edge_poly(mat: String, pts: PackedVector2Array, fn := Callable()) -> void:
	polys.append([mat, pts, fn])

## the same as a band of quads: from each street edge vertex straight across to a base line (z = base, or x = base when
## along_x is false), so a SLOPING edge gets a height at every vertex (a polygon's long triangles would sag between them)
var bands: Array = []
func edge_band(mat: String, pts: PackedVector2Array, base: float, fn: Callable, along_x := true) -> void:
	bands.append([mat, pts, base, fn, along_x])

## skirt edges round an outline given as a closed ring of points in the same winding as rect_edges (x0 z0, x1 z0, x1 z1,
## x0 z1): a curved or chamfered street edge gets its skirt where the ground really ends
static func ring_edges(pts: Array, mat := "wall") -> Array:
	var out: Array = []
	for i in pts.size():
		var a: Vector2 = pts[i]; var b: Vector2 = pts[(i + 1) % pts.size()]
		if a.distance_to(b) > 1e-3: out.append([a, b, 1.0, mat])
	return out

## the deepest of these buildings front to back (m), to know where the lots behind a row may start
static func depth_of(folders: Array) -> float:
	var d := 0.0
	for f in folders: d = maxf(d, _near_aabb(String(f)).size.z)
	return d

## the outline's four edges, each facing out (for build_floor's skirt)
static func rect_edges(x0: float, z0: float, x1: float, z1: float, mat := "wall") -> Array:
	return [[Vector2(x0, z0), Vector2(x1, z0), 1.0, mat], [Vector2(x1, z0), Vector2(x1, z1), 1.0, mat], [Vector2(x1, z1), Vector2(x0, z1), 1.0, mat], [Vector2(x0, z1), Vector2(x0, z0), 1.0, mat]]

## the floor: every pad cut with the paints (first matching paint wins), cells never merged (no T-joints), then a
## 0.3 m skirt in the edge's material down the outer edges given (so a residual gap shows a face, not grass)
var skirt_depth := 0.3         # a slope piece sets it deeper so a plinth face at an edge reaches under the street
func build_floor(skirt_edges: Array) -> void:
	for f: Array in floors:
		var fn: Callable = f[4] if (f[4] as Callable).is_valid() else yf
		K.painted_rect(g, f[0], f[1], f[2], f[3], paints, fn, "asphalt", false)
	for w: Array in wells: _draw_well(w[0], float(w[1]), float(w[2]))
	for pg: Array in polys: g.poly(String(pg[0]), pg[1], pg[2] if (pg[2] as Callable).is_valid() else yf)
	for bd: Array in bands:
		var bp: PackedVector2Array = bd[1]; var bf: Callable = bd[3]; var bb: float = bd[2]
		for k in bp.size() - 1:
			var p0 := bp[k]; var p1 := bp[k + 1]
			var q0 := Vector2(p0.x, bb) if bd[4] else Vector2(bb, p0.y); var q1 := Vector2(p1.x, bb) if bd[4] else Vector2(bb, p1.y)
			if p0.distance_to(q0) < 1e-4 and p1.distance_to(q1) < 1e-4: continue
			g.quad(String(bd[0]), Vector3(q0.x, bf.call(q0.x, q0.y), q0.y), Vector3(q1.x, bf.call(q1.x, q1.y), q1.y), Vector3(p1.x, bf.call(p1.x, p1.y), p1.y), Vector3(p0.x, bf.call(p0.x, p0.y), p0.y))
	for e: Array in skirt_edges:     # [Vector2 a, Vector2 b, out_side, mat]
		var a2: Vector2 = e[0]; var b2: Vector2 = e[1]
		var n2 := maxi(1, int(ceil(a2.distance_to(b2) / 2.0)))
		var pts2 := PackedVector2Array()
		for i2 in n2 + 1: pts2.append(a2.lerp(b2, float(i2) / n2))
		g.wall_line(String(e[3]), pts2, func(x: float, z: float) -> float: return yf(x, z) - skirt_depth, yf, float(e[2]))

## ---------------------------------------------------------------- buildings
static func _near_aabb(folder: String) -> AABB:
	var f := K._tier_file(K._bdir(folder), "near")
	var inst: Node = (load(f) as PackedScene).instantiate()
	var mi := K._first_mesh(inst)
	var ab := mi.transform * mi.mesh.get_aabb()
	inst.free()
	return ab

const FACE := {"s": 0.0, "n": 180.0, "e": 90.0, "w": -90.0}

## how far a building's wall line stands behind its real front (awning, steps): the depth of the frontage strip that
## can follow a sloping walk in front of it without the facade floating over it
static func setback(folder: String) -> float:
	var ab := _near_aabb(folder)
	var st := K.building_stats(folder)
	var fz: float = minf(ab.end.z, float(st.footprint_wd[1]) * 0.5) if st.has("footprint_wd") else ab.end.z
	return maxf(0.0, ab.end.z - fz)

## a building whose REAL front (near mesh, awnings and steps included) lies on the point `front` (x, z), facing `face`
## (s = +z, n = -z, e = +x, w = -x). along: shift along the frontage. Returns the record.
## nominal = true: the stats facade (footprint depth / 2) on the point instead, awnings and cornices over the walk (as the
## approved c_* blocks stand on Amber)
func bld(folder: String, front: Vector2, face: String, nominal := false, label := "", wear := 0.65) -> Dictionary:
	var ab := _near_aabb(folder)
	var yaw: float = FACE[face]
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var fdir := b * Vector3(0, 0, 1)
	var st0 := K.building_stats(folder)
	var fz: float = float(st0.footprint_wd[1]) * 0.5 if nominal else ab.end.z
	var c := Vector3(front.x, y0, front.y) - fdir * fz
	fz = minf(ab.end.z, float(st0.footprint_wd[1]) * 0.5) if st0.has("footprint_wd") else ab.end.z     # the wall line
	var node := K.building(bl, folder, c, yaw, label, wear)
	var xs: Array[float] = []; var zs: Array[float] = []
	for lx: float in [ab.position.x, ab.end.x]:
		for lz: float in [ab.position.z, minf(ab.end.z, fz)]:     # the walls; an awning over the walk is not a wall
			var p := c + b * Vector3(lx, 0, lz); xs.append(p.x); zs.append(p.z)
	var st := K.building_stats(folder)
	var d: float = st.footprint_wd[1]; var w: float = st.footprint_wd[0]
	var doors: Array = []
	# every ground-floor door of the model, all four sides, as MEASURED for the rooms (interiors/room_contracts.json):
	# the kit stats list front doors only and the modular examples none; back doors need their space as much
	var con: Dictionary = _contracts().get(folder, {})
	if not con.is_empty():
		for e: Dictionary in con.entrances:
			if int(e.floor) != 0: continue
			var a := float(e.along); var kind := "rollup" if String(e.kind) == "service_bay" else String(e.kind)
			match String(e.facade):
				"front": doors.append([kind, c + b * Vector3(a, 0, d * 0.5), fdir])
				"back": doors.append([kind, c + b * Vector3(a, 0, -d * 0.5), -fdir])
				"left": doors.append([kind, c + b * Vector3(-w * 0.5, 0, a), b * Vector3(-1, 0, 0)])
				"right": doors.append([kind, c + b * Vector3(w * 0.5, 0, a), b * Vector3(1, 0, 0)])
	else:
		for e: Array in st.get("doors_front", []):
			doors.append([String(e[0]), c + b * Vector3(float(e[1]), 0, d * 0.5), fdir])
	var r := {"node": node, "folder": folder, "rect": [xs.min(), zs.min(), xs.max(), zs.max()], "doors": doors, "yaw": yaw, "c": c, "b": b, "ab": ab, "st": st, "y": y0}
	blds.append(r)
	return r

static var _con := {}
static func _contracts() -> Dictionary:
	if _con.is_empty():
		for f: String in ["room_contracts.json", "room_contracts_cc.json"]:
			var p := "res://map_dc/coronado/city_kit/interiors/" + f
			if FileAccess.file_exists(p): _con.merge((JSON.parse_string(FileAccess.get_file_as_string(p)) as Dictionary).models)
	return _con

## the shop doors on a building's FRONT (from the measured contract, or the stats for models without one)
func front_shops(r: Dictionary) -> Array:
	var out: Array = []
	var f: Vector3 = (r.b as Basis) * Vector3(0, 0, 1)
	for dr: Array in r.doors:
		if String(dr[0]) in ["shop", "shopdoor", "civic", "civic_door"] and (dr[2] as Vector3).dot(f) > 0.9: out.append(dr)
	return out

## piece point at a building's local offset (x across the front, z: + toward the front), on the pad
func at(r: Dictionary, lx: float, lz: float, ly := 0.0) -> Vector3:
	var p: Vector3 = r.c + (r.b as Basis) * Vector3(lx, 0, lz)
	return Vector3(p.x, float(r.y) + ly, p.z)

## ---------------------------------------------------------------- props
static func _radius(base: String) -> float:
	if base.begins_with("tree_") or base.begins_with("palm_"): return 0.6     # the trunk; the crown is overhead
	var e := K.manifest(base)
	return clampf(Vector2(float(e.get("footprint_w", 0.6)), float(e.get("footprint_d", 0.6))).length() * 0.5, 0.15, 6.0)

func _in_bld(p: Vector2, pad_m: float) -> String:
	for r: Dictionary in blds:
		var q: Array = r.rect
		if p.x > float(q[0]) - pad_m and p.x < float(q[2]) + pad_m and p.y > float(q[1]) - pad_m and p.y < float(q[3]) + pad_m: return String(r.folder)
	return ""

func _door_hit(p: Vector2, r: float) -> String:
	for b: Dictionary in blds:
		for d: Array in b.doors:
			var dp: Vector3 = d[1]; var o: Vector3 = d[2]
			var rel := Vector2(p.x - dp.x, p.y - dp.z)
			var ahead := rel.dot(Vector2(o.x, o.z))
			var side := absf(rel.dot(Vector2(o.z, -o.x)))
			var half := 3.4 if String(d[0]) == "rollup" else 0.9
			if ahead > -0.5 and ahead < 2.2 + r and side < half + r: return "%s door of %s" % [d[0], b.folder]
	return ""

## place one ground prop with its reason; checked against buildings (real outline), doors (a 2.2 m deep, 2.2 m wide
## space in front of every door), other props. check = false for fences / lines / items placed on purpose touching.
func put(base: String, cond: String, p: Vector3, yaw: float, reason: String, check := true, scale := 1.0) -> bool:
	var r := _radius(base) * 0.8
	var q := Vector2(p.x, p.z)
	if check:
		var hb := _in_bld(q, -0.05)
		var hd := _door_hit(q, r * 0.6)
		var hp := ""
		for it: Array in items:
			if (it[0] as Vector2).distance_to(q) < r + float(it[1]): hp = String(it[2]); break
		if hb != "" or hd != "" or hp != "":
			refused.append("%s at (%.1f, %.1f): %s" % [base, p.x, p.z, "inside " + hb if hb != "" else (hd if hd != "" else "on top of " + hp)])
			return false
	props.add(base, cond, p, yaw, true, scale)
	items.append([q, r, base])
	why[reason] = int(why.get(reason, 0)) + 1
	return true

## a wall-hung item on a building face. side: "back" / "front" / "left" / "right" (seen from the front), along = offset
## along that face from its middle, h = height of its base, out = distance off the real wall
func wall(r: Dictionary, base: String, cond: String, side: String, along: float, h: float, reason: String, out := 0.03) -> void:
	var ab: AABB = r.ab
	var lp := Vector3.ZERO; var yaw: float = r.yaw
	match side:
		"back": lp = Vector3(-along, h, ab.position.z - out); yaw += 180.0
		"front": lp = Vector3(along, h, ab.end.z + out)
		"left": lp = Vector3(ab.position.x - out, h, along); yaw -= 90.0
		"right": lp = Vector3(ab.end.x + out, h, -along); yaw += 90.0
	var p: Vector3 = r.c + (r.b as Basis) * Vector3(lp.x, 0, lp.z)
	for dr: Array in r.doors:
		var dp: Vector3 = dr[1]
		if Vector2(dp.x - p.x, dp.z - p.z).length() < (3.4 if String(dr[0]) == "rollup" else 1.25):
			refused.append("%s on the %s wall of %s at (%.1f, %.1f): over / beside its %s door" % [base, side, r.folder, p.x, p.z, dr[0]]); return
	props.add(base, cond, Vector3(p.x, float(r.y) + h, p.z), yaw, false)
	why[reason] = int(why.get(reason, 0)) + 1

## a ground prop standing just off a building face (condensers, bins, gas meters), same sides as wall()
func by_wall(r: Dictionary, base: String, cond: String, side: String, along: float, off: float, reason: String, yaw_add := 0.0) -> bool:
	var ab: AABB = r.ab
	var lp := Vector3.ZERO; var yaw: float = r.yaw
	match side:
		"back": lp = Vector3(-along, 0, ab.position.z - off); yaw += 180.0
		"front": lp = Vector3(along, 0, ab.end.z + off)
		"left": lp = Vector3(ab.position.x - off, 0, along); yaw -= 90.0
		"right": lp = Vector3(ab.end.x + off, 0, -along); yaw += 90.0
	var p: Vector3 = r.c + (r.b as Basis) * lp
	return put(base, cond, Vector3(p.x, yf(p.x, p.z), p.z), yaw + yaw_add, reason)

## the service side every downtown building has: meter bank + gas meter on the back wall, condensers on the ground
## behind, bin carts where people live. along0: where along the back the bank starts (clear of the back door)
func services(r: Dictionary, along0: float, n_ac: int, homes: bool, side := "back") -> void:
	for k in 3: wall(r, "prop_meter_electric", "worn", side, along0 + k * 0.42, 1.05, "service side: meter bank")
	wall(r, "prop_meter_gas", "rusty", side, along0 + 1.7, 0.2, "service side: gas meter")
	for k in n_ac: by_wall(r, "prop_ac_condenser", "worn", side, along0 + 3.4 + k * 1.3, 0.75, "service side: condensers")
	if homes:
		for k in 3: by_wall(r, ["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", side, along0 - 1.6 - k * 0.95, 0.6, "homes: bin carts by the back door", rr.randf_range(-8, 8))

## a door the kit stats do not list (modular examples carry no doors_front): local x on the front
func add_door(r: Dictionary, lx: float, kind := "door") -> void:
	var st: Dictionary = r.st
	var fz: float = float(st.footprint_wd[1]) * 0.5 if st.has("footprint_wd") else (r.ab as AABB).end.z
	(r.doors as Array).append([kind, at(r, lx, fz), (r.b as Basis) * Vector3(0, 0, 1)])

## the neighbours' props (street pieces, locked samples) so nothing is put on top of them. rows: [piece, pos, yaw];
## origin: this piece's layout position (all in the grid frame)
func neighbours(rows: Array, origin: Vector3) -> void:
	for row: Array in rows:
		var path := "res://map_dc/coronado/city_kit/pieces/%s.scn" % String(row[0])
		var n: Node = (load(path) as PackedScene).instantiate()
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(float(row[2]))), (row[1] as Vector3) - origin)
		var cnt := 0
		for mmi: MultiMeshInstance3D in n.find_children("*", "MultiMeshInstance3D", true, false):
			if not String(mmi.name).ends_with("_near") and not String(mmi.name).contains("_near"): continue
			var base := String(mmi.name); base = base.substr(0, base.rfind("_")); base = base.substr(0, base.rfind("_"))
			var chain := Transform3D.IDENTITY
			var par: Node = mmi.get_parent()
			while par and par != n:
				if par is Node3D: chain = (par as Node3D).transform * chain
				par = par.get_parent()
			for i in mmi.multimesh.instance_count:
				var t := xf * chain * mmi.transform * mmi.multimesh.get_instance_transform(i)
				items.append([Vector2(t.origin.x, t.origin.z), _radius(base) * 0.8, "%s (%s)" % [base, row[0]]]); cnt += 1
		n.free()
		print("%s: %d neighbour props from %s" % [name, cnt, row[0]])

## the flat roof under (lx, lz) of a building (raycast on its near mesh), INF if not a flat roof there
var _tm := {}
func roof(r: Dictionary, lx: float, lz: float) -> Vector3:
	var f: String = r.folder
	if not _tm.has(f):
		var inst: Node = (load(K._tier_file(K._bdir(f), "near")) as PackedScene).instantiate()
		var mi := K._first_mesh(inst)
		_tm[f] = [mi.mesh.generate_triangle_mesh(), mi.transform]
		inst.free()
	var e: Array = _tm[f]
	var tm: TriangleMesh = e[0]; var mt: Transform3D = e[1]
	var o := mt.affine_inverse() * Vector3(lx, 200.0, lz)
	var h: Dictionary = tm.intersect_ray(o, (mt.basis.inverse() * Vector3.DOWN).normalized())
	if h.is_empty(): return Vector3.INF
	var n: Vector3 = (mt.basis * (h.normal as Vector3)).normalized()
	if absf(n.y) < 0.97: return Vector3.INF
	var lp: Vector3 = mt * (h.position as Vector3)
	if lp.y < 3.0: return Vector3.INF
	var p: Vector3 = r.c + (r.b as Basis) * Vector3(lx, 0, lz)
	return Vector3(p.x, float(r.y) + lp.y, p.z)

## roof plant on a flat roof: each [lx, lz, base] goes to the nearest spot within 2.5 m that is level 0.6 m round it
## (bulkheads, parapets and pitched roofs refuse) and 1.6 m from the units already up there; refused spots printed
var _roofed: Array = []
func _flat(r: Dictionary, x: float, z: float) -> Vector3:
	var p := roof(r, x, z)
	if p == Vector3.INF: return p
	for d: Vector2 in [Vector2(0.6, 0), Vector2(-0.6, 0), Vector2(0, 0.6), Vector2(0, -0.6), Vector2(0.6, 0.6), Vector2(-0.6, -0.6)]:
		var q := roof(r, x + d.x, z + d.y)
		if q == Vector3.INF or absf(q.y - p.y) > 0.02: return Vector3.INF
	return p

func roof_plant(r: Dictionary, spots: Array, reason: String) -> void:
	for s: Array in spots:
		var best := Vector3.INF; var bd := INF
		for ix in range(-5, 6):
			for iz in range(-5, 6):
				var dd := Vector2(ix, iz) * 0.5
				if dd.length() > 2.5 or dd.length() >= bd: continue
				var p := _flat(r, float(s[0]) + dd.x, float(s[1]) + dd.y)
				if p == Vector3.INF: continue
				var clash := false
				for q: Vector3 in _roofed:
					if Vector2(q.x - p.x, q.z - p.z).length() < 1.6 and absf(q.y - p.y) < 1.0: clash = true
				if clash: continue
				best = p; bd = dd.length()
		if best == Vector3.INF: refused.append("%s roof (%.1f, %.1f) of %s: no level spot within 2.5 m" % [s[2], s[0], s[1], r.folder]); continue
		_roofed.append(best)
		props.add(String(s[2]), "worn" if rr.randf() < 0.7 else "rusty", best, float(r.yaw) + 90.0 * float(rr.randi() % 4), false)
		why[reason] = int(why.get(reason, 0)) + 1

## ---------------------------------------------------------------- wear
func grime(c: Vector2, yaw: float, sx: float, sz: float, a := 0.45) -> void:
	dec.add(14, c, yaw, sx, sz, yf, Color(1, 1, 1, a))

func oil(c: Vector2, yaw := 0.0, s := 0.75) -> void:
	W.oil(dec, rr, c, yaw, yf, s)

func cracks(x0: float, z0: float, x1: float, z1: float, n: int, sealed := 0.4) -> void:
	W.cracks(dec, rr, x0, z0, x1, z1, n, yf, sealed)

func tyre(c: Vector2, yaw: float, len_m := 6.0, a := 0.35) -> void:
	dec.add(8, c, yaw, 0.5, len_m, yf, Color(1, 1, 1, a))

## ---------------------------------------------------------------- finish
func finish() -> void:
	root.set_meta("stalls", stalls)
	if stage != "ground":
		for k: String in props.items:     # grime and drips under every dumpster and bin cart
			if k.contains("dumpster") or k.contains("recycling") or k.contains("trash_cart"):
				for t: Transform3D in props.items[k]:
					dec.add(14, Vector2(t.origin.x, t.origin.z), rad_to_deg(t.basis.get_euler().y), 3.0 if k.contains("dumpster") else 1.3, 2.4 if k.contains("dumpster") else 1.1, yf, Color(1, 1, 1, 0.65))
		var wm := dec.build()
		if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	if stage == "ground":
		for c in bl.get_children(): c.free()
	else:
		props.build(root, K)
	print("%s: stage %s, ground tris %d, props %d, buildings %d, decals %d" % [name, stage if stage != "" else "full", g.tri_count(), props.count() if stage != "ground" else 0, bl.get_child_count(), dec.count])
	print("%s WHY %s" % [name, why])
	for s in refused: print("%s REFUSED %s" % [name, s])
	K.save_piece(root, name)

## ---------------------------------------------------------------- placement arithmetic (decides nothing)
## a frontage row: the listed buildings side by side (0.1 m apart, by their REAL widths) along a line, starting at
## `start` and running in direction `run` (+1 / -1 along the line's axis). face: which way the fronts look. line: the
## property line (x for "e"/"w" faces, z for "n"/"s"). labels: one per folder. Returns the records, and where the row
## ended in `row_end`.
var row_end := 0.0
## the same arithmetic without placing anything: per building [low end, high end, centre] along the line (to lay the
## ground lots under a row before the row is built)
func row_plan(folders: Array, start: float, run: float, face: String) -> Array:
	var out: Array = []
	var s := start
	for i in folders.size():
		var ab := _near_aabb(String(folders[i]))
		var b := Basis(Vector3.UP, deg_to_rad(float(FACE[face])))
		var along := Vector3(0, 0, 1) if face in ["e", "w"] else Vector3(1, 0, 0)
		var sgn := signf((b * Vector3(1, 0, 0)).dot(along))
		var lo := ab.position.x if sgn > 0 else -ab.end.x
		var hi := ab.end.x if sgn > 0 else -ab.position.x
		var c := (s - lo) if run > 0 else (s - hi)
		out.append([c + lo, c + hi, c])
		s = (c + hi + 0.1) if run > 0 else (c + lo - 0.1)
	return out

## ylev: optional (centre along the line) -> the level the building stands on (a row on a slope steps with it)
func row(folders: Array, labels: Array, start: float, run: float, face: String, line: float, nominal := false, ylev := Callable()) -> Array:
	var out: Array = []
	var s := start
	var y_keep := y0
	for i in folders.size():
		var f := String(folders[i])
		var ab := _near_aabb(f)
		var b := Basis(Vector3.UP, deg_to_rad(float(FACE[face])))
		# the building's local x axis in the piece, and how far its real outline reaches each way along the line
		var ax: Vector3 = b * Vector3(1, 0, 0)
		var along := Vector3(0, 0, 1) if face in ["e", "w"] else Vector3(1, 0, 0)
		var sgn := signf(ax.dot(along))      # +1: local +x runs with +along
		var lo := ab.position.x if sgn > 0 else -ab.end.x       # extent toward -along
		var hi := ab.end.x if sgn > 0 else -ab.position.x       # extent toward +along
		var c := (s - lo) if run > 0 else (s - hi)
		var front := Vector2(line, c) if face in ["e", "w"] else Vector2(c, line)
		if ylev.is_valid(): y0 = float(ylev.call(c))
		out.append(bld(f, front, face, nominal, String(labels[i])))
		y0 = y_keep
		s = (c + hi + 0.1) if run > 0 else (c + lo - 0.1)
	row_end = s
	return out

## wrought iron run from a to b: whole 1.98 m panels (never stretched), the overlap shared, a post at both ends and at
## every joint
func iron(a: Vector2, b: Vector2, reason: String) -> void:
	var L2 := a.distance_to(b); var n := maxi(1, int(ceil(L2 / 1.98)))
	var dir := (b - a).normalized()
	var yaw := rad_to_deg(atan2(dir.x, dir.y)) + 90.0
	var cs: Array[Vector2] = []
	for i in n:
		cs.append(a + dir * (0.99 + (L2 - 1.98) * float(i) / float(n - 1)) if n > 1 else a.lerp(b, 0.5))
	for m: Vector2 in cs: put("fence_wrought_iron", "worn", Vector3(m.x, _low(m, dir, 0.99), m.y), yaw, reason, false)
	var posts: Array[Vector2] = [a, b]
	for i in n - 1: posts.append((cs[i] + cs[i + 1]) * 0.5)
	for pp: Vector2 in posts: put("fence_post_wrought_iron", "worn", Vector3(pp.x, yf(pp.x, pp.y), pp.y), yaw, "fence post at every joint", false)

## CMU block wall from a to b: 2.03 m panels, the overlap shared; every fifth panel tagged
func cmu(a: Vector2, b: Vector2, reason: String) -> void:
	var L2 := a.distance_to(b); var n := maxi(1, int(ceil(L2 / 2.03)))
	var dir := (b - a).normalized()
	var yaw := rad_to_deg(atan2(dir.x, dir.y)) + 90.0
	for i in n:
		var m: Vector2 = a + dir * (1.015 + (L2 - 2.03) * float(i) / float(n - 1)) if n > 1 else a.lerp(b, 0.5)
		put("fence_graffiti_cmu_panel" if i % 5 == 2 else "fence_cmu_wall", "worn", Vector3(m.x, _low(m, dir, 1.015), m.y), yaw, reason, false)

## the lowest floor along a panel centred at m running along dir, half length hl (a panel on a slope stands at its
## lowest ground, -3 cm on a slope, or its downhill end floats)
func _low(m: Vector2, dir: Vector2, hl: float) -> float:
	var a := yf(m.x - dir.x * hl, m.y - dir.y * hl); var b := yf(m.x + dir.x * hl, m.y + dir.y * hl); var c := yf(m.x, m.y)
	var lo := minf(minf(a, b), c)
	return lo - 0.03 if maxf(maxf(a, b), c) - lo > 0.01 else lo

## alley wear along an alley (along z if along_z): cracks, the oil stripe down the middle, grime at the walls, a trench
## patch; the caller adds tyre arcs where vehicles turn (mouths, crossings) and oil where they stand
func alley_wear(x0: float, z0: float, x1: float, z1: float, along_z: bool) -> void:
	cracks(x0 + 0.4, z0 + 0.4, x1 - 0.4, z1 - 0.4, int(maxf(absf(x1 - x0), absf(z1 - z0)) / 5.0), 0.5)
	var c := (x0 + x1) * 0.5 if along_z else (z0 + z1) * 0.5
	var a := z0 if along_z else x0; var e := z1 if along_z else x1
	var s := a + 2.0
	while s < e - 2.0:
		var p := Vector2(c + rr.randf_range(-0.3, 0.3), s) if along_z else Vector2(s, c + rr.randf_range(-0.3, 0.3))
		dec.add(6, p, 0.0 if along_z else 90.0, 0.9, rr.randf_range(4.0, 6.5), yf, Color(1, 1, 1, rr.randf_range(0.35, 0.55)))
		s += rr.randf_range(7.0, 11.0)
	var m := (a + e) * 0.5
	dec.add(2, Vector2(c, m) if along_z else Vector2(m, c), 90.0 if along_z else 0.0, 1.4, 5.5, yf, Color(1, 1, 1, 0.85))

## ---------------------------------------------------------------- terraces on a slope (geometry, decides nothing)
## linear interpolation in a measured profile [[t, h], ...] (sorted by t)
static func prof(tab: Array, t: float) -> float:
	if t <= float(tab[0][0]): return float(tab[0][1])
	for i in tab.size() - 1:
		var a: Array = tab[i]; var b: Array = tab[i + 1]
		if t <= float(b[0]): return lerpf(float(a[1]), float(b[1]), (t - float(a[0])) / (float(b[0]) - float(a[0])))
	return float(tab[tab.size() - 1][1])

## the piece's ground as lots: [x0, z0, x1, z1, fn] (fn(x, z) -> y: a level pad or a slope that follows a street),
## tiling the piece without overlaps. Every lot becomes a floor with its own heights; the floor height field (hfn)
## looks the lot up; and wherever two lots meet at heights more than 2 cm apart, a RETAINING face is built on their
## shared edge, from 0.3 m under the lower side up to the higher side, facing the lower side.
var lots: Array = []
func _lot_at(x: float, z: float) -> Array:
	for l: Array in lots:
		if x >= float(l[0]) - 1e-4 and x <= float(l[2]) + 1e-4 and z >= float(l[1]) - 1e-4 and z <= float(l[3]) + 1e-4: return l
	return []

func terrain(ls: Array) -> void:
	# every lot's height is taken INSIDE the lot (1 mm in): a function that steps exactly on the lot's edge (a seam
	# segment, a lane end) would otherwise ramp the lot's last cell up to its neighbour's value
	lots = []
	for l0: Array in ls:
		var f0: Callable = l0[4]; var ax := float(l0[0]) + 1e-3; var bx := float(l0[2]) - 1e-3; var az := float(l0[1]) + 1e-3; var bz := float(l0[3]) - 1e-3
		lots.append([l0[0], l0[1], l0[2], l0[3], func(x: float, z: float) -> float: return float(f0.call(clampf(x, ax, maxf(ax, bx)), clampf(z, az, maxf(az, bz))))])
	for l: Array in lots: pad(float(l[0]), float(l[1]), float(l[2]), float(l[3]), l[4])
	hfn = func(x: float, z: float) -> float:
		var l2 := _lot_at(x, z)
		return float((l2[4] as Callable).call(x, z)) if not l2.is_empty() else y0
	var faces := 0
	for i in lots.size():
		for j in lots.size():
			if i == j: continue
			var A: Array = lots[i]; var B: Array = lots[j]
			# A's east edge against B's west edge, and A's south edge against B's north edge (each pair once)
			for axis: int in [0, 1]:
				var shared := absf(float(A[2 if axis == 0 else 3]) - float(B[0 if axis == 0 else 1])) < 1e-3
				if not shared: continue
				var e := float(A[2 if axis == 0 else 3])
				var s0 := maxf(float(A[1 if axis == 0 else 0]), float(B[1 if axis == 0 else 0]))
				var s1 := minf(float(A[3 if axis == 0 else 2]), float(B[3 if axis == 0 else 2]))
				if s1 - s0 < 0.05: continue
				var n := maxi(1, int(ceil((s1 - s0) / 0.5)))
				for k in n:
					var sa := lerpf(s0, s1, float(k) / n); var sb := lerpf(s0, s1, float(k + 1) / n)
					var pa := Vector2(e, sa) if axis == 0 else Vector2(sa, e); var pb := Vector2(e, sb) if axis == 0 else Vector2(sb, e)
					var ha := float((A[4] as Callable).call(pa.x, pa.y)); var hb := float((B[4] as Callable).call(pa.x, pa.y))
					var ha2 := float((A[4] as Callable).call(pb.x, pb.y)); var hb2 := float((B[4] as Callable).call(pb.x, pb.y))
					if absf(ha - hb) < 0.02 and absf(ha2 - hb2) < 0.02: continue
					var a_hi := ha + ha2 > hb + hb2
					var top0 := maxf(ha, hb); var top1 := maxf(ha2, hb2); var bot0 := minf(ha, hb) - 0.3; var bot1 := minf(ha2, hb2) - 0.3
					var out := (Vector3(1, 0, 0) if axis == 0 else Vector3(0, 0, 1)) * (1.0 if a_hi else -1.0)
					g.quad("wall", Vector3(pa.x, bot0, pa.y), Vector3(pb.x, bot1, pb.y), Vector3(pb.x, top1, pb.y), Vector3(pa.x, top0, pa.y), out, true)
					faces += 1
	print("%s: terrain %d lots, %d retaining face segments" % [name, lots.size(), faces])

## ---------------------------------------------------------------- slope helpers (blocks 4-6, 19 Nov)
## the land as read on 19 Nov (zoning/terrain_grid.npz, 4 m grid, piece frame, metres over the 6.0 datum), embedded in
## the piece script as {x0, z0, step, nx, nz, h: [...] row-major by z}: bilinear, so open ground can follow it
static func land_at(LD: Dictionary, x: float, z: float) -> float:
	var s := float(LD.step); var nx := int(LD.nx); var nz := int(LD.nz)
	var fx := clampf((x - float(LD.x0)) / s, 0.0, nx - 1.001); var fz := clampf((z - float(LD.z0)) / s, 0.0, nz - 1.001)
	var i := int(fx); var j := int(fz); fx -= i; fz -= j
	var h: Array = LD.h
	return lerpf(lerpf(float(h[j * nx + i]), float(h[j * nx + i + 1]), fx), lerpf(float(h[(j + 1) * nx + i]), float(h[(j + 1) * nx + i + 1]), fx), fz)

## open ground: `base` (x, z) eased to fixed heights near the given edges. edges: [[Vector2 a, Vector2 b, Callable
## h(x, z) on the edge]]; within R m of the nearest edge the ground runs smoothly (smoothstep) from that edge's height
## to the base, so an open lot meets a street walk, an alley or a neighbour flush and has no jump inside it
static func eased(base: Callable, edges: Array, R := 8.0) -> Callable:
	return func(x: float, z: float) -> float:
		var p := Vector2(x, z); var best := 1e9; var hb := 0.0; var q := Vector2.ZERO
		for e: Array in edges:
			var a: Vector2 = e[0]; var b: Vector2 = e[1]
			var c := Geometry2D.get_closest_point_to_segment(p, a, b)
			var d := p.distance_to(c)
			if d < best: best = d; q = c; hb = float((e[2] as Callable).call(c.x, c.y))
		var t := smoothstep(0.0, R, best)
		var b0 := float(base.call(x, z))
		return lerpf(hb, b0, t) if best < R else b0

## a row of buildings on a sloping street: per building a level pad at the walk's HIGHEST point along its lot (never under
## the walk) and, in front of its wall line, a frontage strip that follows the walk exactly (flush; the plinth between
## strip and pad is the retaining face). walk: along -> height. back: the across coordinate where the lots end behind.
## limit: the along coordinate the row may not pass. Appends the lots; returns {plan, pads, folders, n, end}.
func front_lots(lots: Array, folders: Array, start: float, run: float, face: String, line: float, walk: Callable, back: float, limit: float, min_pad := -1e9, kerb := 0.0) -> Dictionary:
	var plan := row_plan(folders, start, run, face)
	var n := 0
	for p: Array in plan:
		if (run > 0 and float(p[1]) > limit) or (run < 0 and float(p[0]) < limit): break
		n += 1
	plan = plan.slice(0, n)
	var pads: Array[float] = []
	var a := start
	for i in n:
		var b: float
		if run > 0: b = (float(plan[i][1]) + float(plan[i + 1][0])) * 0.5 if i < n - 1 else float(plan[i][1]) + 0.05
		else: b = (float(plan[i][0]) + float(plan[i + 1][1])) * 0.5 if i < n - 1 else float(plan[i][0]) - 0.05
		var hi := -1e9
		for k in 9: hi = maxf(hi, float(walk.call(lerpf(a, b, k / 8.0))))
		hi = maxf(hi, min_pad)
		pads.append(hi)
		var sb := setback(String(folders[i]))
		var lo_al := minf(a, b); var hi_al := maxf(a, b)
		var fw := func(_x: float, _z: float) -> float: return 0.0
		var hpad := hi
		var wf := walk
		# kerb: the buildings' fronts stand this far back from the street edge, so even a building whose wall is its
		# front gets a strip flush with the walk in front and its plinth face at its own wall
		if face in ["s", "n"]:
			var zf := line - sb if face == "s" else line + sb
			var ze := line + kerb if face == "s" else line - kerb
			lots.append([lo_al, minf(back, zf), hi_al, maxf(back, zf), func(_x: float, _z: float) -> float: return hpad])
			if sb + kerb > 0.02:
				lots.append([lo_al, minf(zf, ze), hi_al, maxf(zf, ze), func(x: float, _z: float) -> float: return float(wf.call(x))])
				paint("concrete", lo_al, minf(zf, ze), hi_al, maxf(zf, ze))     # the strip is pavement, one with the walk
		else:
			var xf := line - sb if face == "e" else line + sb
			var xe := line + kerb if face == "e" else line - kerb
			lots.append([minf(back, xf), lo_al, maxf(back, xf), hi_al, func(_x: float, _z: float) -> float: return hpad])
			if sb + kerb > 0.02:
				lots.append([minf(xf, xe), lo_al, maxf(xf, xe), hi_al, func(_x: float, z: float) -> float: return float(wf.call(z))])
				paint("concrete", minf(xf, xe), lo_al, maxf(xf, xe), hi_al)     # the strip is pavement, one with the walk
		a = b
	return {"plan": plan, "pads": pads, "folders": folders.slice(0, n), "n": n, "end": a}

## place the row front_lots laid out, each building at its pad
func front_row(fl: Dictionary, labels: Array, start: float, run: float, face: String, line: float) -> Array:
	var plan: Array = fl.plan; var pads: Array = fl.pads
	return row(fl.folders, labels.slice(0, int(fl.n)), start, run, face, line, false, func(cx: float) -> float:
		var best := 0
		for i in plan.size():
			if absf(float(plan[i][2]) - cx) < absf(float(plan[best][2]) - cx): best = i
		return float(pads[best]))
