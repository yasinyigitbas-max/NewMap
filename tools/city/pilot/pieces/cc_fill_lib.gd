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

func yf(_x: float, _z: float) -> float: return y0

## ---------------------------------------------------------------- ground
func pad(x0: float, z0: float, x1: float, z1: float) -> void:
	floors.append([minf(x0, x1), minf(z0, z1), maxf(x0, x1), maxf(z0, z1)])

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
	var wy := y0; var sy := y0 - 0.06
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
func edge_poly(mat: String, pts: PackedVector2Array) -> void:
	polys.append([mat, pts])

## the outline's four edges, each facing out (for build_floor's skirt)
static func rect_edges(x0: float, z0: float, x1: float, z1: float, mat := "wall") -> Array:
	return [[Vector2(x0, z0), Vector2(x1, z0), 1.0, mat], [Vector2(x1, z0), Vector2(x1, z1), 1.0, mat], [Vector2(x1, z1), Vector2(x0, z1), 1.0, mat], [Vector2(x0, z1), Vector2(x0, z0), 1.0, mat]]

## the floor: every pad cut with the paints (first matching paint wins), cells never merged (no T-joints), then a
## 0.3 m skirt in the edge's material down the outer edges given (so a residual gap shows a face, not grass)
func build_floor(skirt_edges: Array) -> void:
	for f: Array in floors:
		K.painted_rect(g, f[0], f[1], f[2], f[3], paints, yf, "asphalt", false)
	for w: Array in wells: _draw_well(w[0], float(w[1]), float(w[2]))
	for pg: Array in polys: g.poly(String(pg[0]), pg[1], yf)
	for e: Array in skirt_edges:     # [Vector2 a, Vector2 b, out_side, mat]
		g.wall_line(String(e[3]), PackedVector2Array([e[0], e[1]]), func(_x: float, _z: float) -> float: return y0 - 0.3, yf, float(e[2]))

## ---------------------------------------------------------------- buildings
static func _near_aabb(folder: String) -> AABB:
	var f := K._tier_file(K._bdir(folder), "near")
	var inst: Node = (load(f) as PackedScene).instantiate()
	var mi := K._first_mesh(inst)
	var ab := mi.transform * mi.mesh.get_aabb()
	inst.free()
	return ab

const FACE := {"s": 0.0, "n": 180.0, "e": 90.0, "w": -90.0}

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
	var r := {"node": node, "folder": folder, "rect": [xs.min(), zs.min(), xs.max(), zs.max()], "doors": doors, "yaw": yaw, "c": c, "b": b, "ab": ab, "st": st}
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
	return Vector3(p.x, y0 + ly, p.z)

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
	props.add(base, cond, Vector3(p.x, y0 + h, p.z), yaw, false)
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
	return put(base, cond, Vector3(p.x, y0, p.z), yaw + yaw_add, reason)

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
	return Vector3(p.x, y0 + lp.y, p.z)

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
