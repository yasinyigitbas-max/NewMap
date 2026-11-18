extends RefCounted
## "Life" overlay for the two oldest samples (17 Nov, Yasin: "elevate the props of city center and pilot to the other
## zones average, about 1500 ... props must be placed logically, they must exist for reasons"). The locked pieces are
## NOT re-run or touched: an overlay piece (d_pilot / d_cc) reads their finished scenes - buildings (kit stats, doors,
## the real roof surface by raycast), ground (height by raycast), every existing prop - and adds only what each
## building would really have and is still missing, each item checked against existing props, doors and walls:
## - flat commercial roofs: the HVAC plant (condensers), exhaust vent boxes over kitchens and restrooms, plumbing
##   vents, turbine vents on the older brick blocks (pitched roofs get none: the raycast normal decides);
## - every building: its service side (meter bank, gas meter, condensers, the bin carts for homes) if absent;
## - houses: downspouts at the corners (rain off the roof), house numbers by the front door, a hose reel on a side wall;
## - shops: a potted plant either side of the door (owners put them there), cafe / bakery / bar tables on a wide walk
##   in front (people sit out), a bike rack parallel to the shopfront, paper boxes at the block corners;
## - wear where the new things are used: grime under cafe tables and at doors.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const DIR := "res://map_dc/coronado/city_kit/pieces/"

var props := K.Props.new()
var dec := K.Decals.new()
var rr: RandomNumberGenerator
var taken: Array = []          # [Vector3, radius]
var blds: Array = []           # {node xf, inv, tm, folder, st, w, d, house}
var grounds: Array = []        # TriangleMesh
var folders := {}              # basename -> kit folder
var added := 0
var _gcache := {}
var _grid := {}                # Vector2i(4 m cell) -> Array of [Vector3, r]
var why := {}

func _init(name: String) -> void:
	rr = W.rng_for(name)
	for cat in DirAccess.get_directories_at("res://assets/coronado_kit/buildings/"):
		for b in DirAccess.get_directories_at("res://assets/coronado_kit/buildings/" + cat):
			folders[b] = cat + "/" + b
	for b2 in DirAccess.get_directories_at("res://map_dc/coronado/city_kit/buildings/"): folders[b2] = "ck/" + b2
	for b3 in DirAccess.get_directories_at("res://assets/coronado_kit/modular/examples/"): folders[b3] = "modular/examples/" + b3

## every layout row at this sample position (the sample's own pieces with their yaws; wires and overlays excluded)
func load_sample(pos: Array) -> void:
	var L: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/city_layout.json"))
	for r: Dictionary in L.instances:
		var p: Array = r.pos
		var pc := String(r.piece)
		if pc.begins_with("w_") or pc.begins_with("d_"): continue
		if float(p[0]) == float(pos[0]) and float(p[2]) == float(pos[2]): _load_piece(pc, float(r.get("yaw", 0.0)))

func _load_piece(nm: String, yaw: float) -> void:
		var rot := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), Vector3.ZERO)
		var root: Node = (load(DIR + nm + ".scn") as PackedScene).instantiate()
		var g := root.get_node_or_null("ground") as MeshInstance3D
		if g and g.mesh:
			var faces := g.mesh.get_faces()
			for fi in faces.size(): faces[fi] = rot * faces[fi]
			var tmg := TriangleMesh.new(); tmg.create_from_faces(faces); grounds.append(tmg)
		for mmi: MultiMeshInstance3D in root.find_children("*", "MultiMeshInstance3D", true, false):
			var base := String(mmi.name); base = base.substr(0, base.rfind("_")); base = base.substr(0, base.rfind("_"))
			var e: Dictionary = K.manifest(base)
			var r := clampf(Vector2(float(e.get("footprint_w", 0.6)), float(e.get("footprint_d", 0.6))).length() * 0.5, 0.3, 3.0)
			var px: Transform3D = rot
			var par: Node = mmi.get_parent()
			var chain := Transform3D.IDENTITY
			while par and par != root:
				if par is Node3D: chain = (par as Node3D).transform * chain
				par = par.get_parent()
			px = rot * chain
			for i in mmi.multimesh.instance_count:
				var t := px * mmi.transform * mmi.multimesh.get_instance_transform(i)
				taken.append([t.origin, r])
		var bn := root.get_node_or_null("Buildings")
		if bn:
			for b: Node3D in bn.get_children():
				var near := b.get_node_or_null("near") as MeshInstance3D
				if near == null or near.mesh == null: continue
				var key := String(b.get_meta(&"kit", ""))
				if key == "":
					var bname := String(b.name)
					key = String(folders.get(bname, ""))
				var st: Dictionary = K.building_stats(key) if key != "" else {}
				var ab := near.mesh.get_aabb()
				var w: float = float(st.footprint_wd[0]) if st.has("footprint_wd") else ab.size.x
				var d: float = float(st.footprint_wd[1]) if st.has("footprint_wd") else ab.size.z
				var bt := rot * b.transform
				var xf := bt * near.transform
				blds.append({"xf": bt, "mxf": xf, "inv": xf.affine_inverse(), "tm": near.mesh.generate_triangle_mesh(), "folder": key, "st": st, "w": w, "d": d,
					"house": key.begins_with("houses/") or key.begins_with("garages/"), "top": ab.end.y, "recorded": b.has_meta(&"kit")})
		root.free()

## ground height under (x, z): the highest ground triangle of the loaded pieces (handles the pilot's hill)
func gy(x: float, z: float) -> float:
	var ck := Vector2i(roundi(x * 4.0), roundi(z * 4.0))
	if _gcache.has(ck): return float(_gcache[ck])
	var best := -INF
	for tm: TriangleMesh in grounds:
		var h: Dictionary = tm.intersect_ray(Vector3(x, 300.0, z), Vector3.DOWN)
		if not h.is_empty(): best = maxf(best, (h.position as Vector3).y)
	_gcache[ck] = best
	return best

func _inside_bld(p: Vector3, pad: float) -> bool:
	for b: Dictionary in blds:
		var lp: Vector3 = (b.xf as Transform3D).affine_inverse() * p
		if absf(lp.x) < float(b.w) * 0.5 + pad and absf(lp.z) < float(b.d) * 0.5 + pad: return true
	return false

func _cell(p: Vector3) -> Vector2i: return Vector2i(floori(p.x / 4.0), floori(p.z / 4.0))

func _index() -> void:
	_grid.clear()
	for t: Array in taken: _addgrid(t)

func _addgrid(t: Array) -> void:
	var c := _cell(t[0])
	if not _grid.has(c): _grid[c] = []
	(_grid[c] as Array).append(t)

func _clear(p: Vector3, r: float) -> bool:
	if _grid.is_empty(): _index()
	var c0 := _cell(p)
	var near: Array = []
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			near.append_array(_grid.get(c0 + Vector2i(dx, dz), []))
	for t: Array in near:
		var q: Vector3 = t[0]
		if absf(q.y - p.y) > 1.6: continue
		if Vector2(q.x - p.x, q.z - p.z).length() < r + float(t[1]): return false
	return true

## place a prop if it is clear; reason key for the report
func put(base: String, cond: String, p: Vector3, yaw: float, r: float, reason: String, wall := false) -> bool:
	if not wall and not _clear(p, r): return false
	if not wall and p.y - gy(p.x, p.z) < 2.0 and _inside_bld(p, r * 0.5 + 0.15): return false     # never inside a building
	props.add(base, cond, p, yaw, not wall)
	taken.append([p, r])
	if not _grid.is_empty(): _addgrid([p, r])
	added += 1; why[reason] = int(why.get(reason, 0)) + 1
	return true

## ---------------------------------------------------------------- roofs
func roofs(step := 5.0) -> void:
	for b: Dictionary in blds:
		if bool(b.house): continue
		var w: float = b.w; var d: float = b.d
		var inv: Transform3D = b.inv; var mxf: Transform3D = b.mxf; var tm: TriangleMesh = b.tm
		var bxf: Transform3D = b.xf
		var yaw := rad_to_deg(bxf.basis.get_euler().y)
		var brick := String(b.folder).contains("brk") or String(b.folder).contains("brick")
		var lx := -w * 0.5 + 2.2
		var n_here := 0
		while lx <= w * 0.5 - 2.2:
			var lz := -d * 0.5 + 2.2
			while lz <= d * 0.5 - 2.2:
				var wp := bxf * Vector3(lx + rr.randf_range(-0.8, 0.8), 0.0, lz + rr.randf_range(-0.8, 0.8))
				var hit := _roof_at(tm, inv, mxf, wp)
				if hit != Vector3.INF and _roof_at(tm, inv, mxf, wp + Vector3(1.2, 0, 0)).y == hit.y and _roof_at(tm, inv, mxf, wp + Vector3(-1.2, 0, 0)).y == hit.y and _roof_at(tm, inv, mxf, wp + Vector3(0, 0, 1.2)).y == hit.y and _roof_at(tm, inv, mxf, wp + Vector3(0, 0, -1.2)).y == hit.y:
					var roll := rr.randf()
					var base := "prop_ac_condenser"
					if n_here > 0:
						if roll < 0.32: base = "prop_ac_condenser"
						elif roll < 0.55: base = "prop_vent_box"
						elif roll < 0.78: base = "prop_vent_plumbing"
						elif roll < 0.9 and brick: base = "prop_vent_turbine"
						elif roll < 0.94 and String(b.folder).contains("apt"): base = "prop_tv_antenna"     # flats: one aerial each
						else: base = "prop_ac_condenser_compact"
					if put(base, "rusty" if rr.randf() < 0.3 else "worn", hit, yaw + 90.0 * float(rr.randi() % 4), 0.7, "roof plant (HVAC / vents) on flat roofs"): n_here += 1
				lz += step
			lx += step

func _roof_at(tm: TriangleMesh, inv: Transform3D, mxf: Transform3D, wp: Vector3) -> Vector3:
	var o := inv * Vector3(wp.x, 300.0, wp.z)
	var dv := (inv.basis * Vector3.DOWN).normalized()
	var h: Dictionary = tm.intersect_ray(o, dv)
	if h.is_empty(): return Vector3.INF
	var nrm: Vector3 = (mxf.basis * (h.normal as Vector3)).normalized()
	if nrm.y < 0.97: return Vector3.INF
	var p: Vector3 = mxf * (h.position as Vector3)
	if p.y - gy(wp.x, wp.z) < 2.6: return Vector3.INF      # an awning or a canopy, not a roof
	return Vector3(snappedf(p.x, 0.001), snappedf(p.y, 0.01), snappedf(p.z, 0.001))

## residents' roof terraces on condo / hotel / apartment towers: table sets under a sail, chairs, pots, a grill -
## the amenity deck every downtown residential tower sells itself with (placed before the roof plant)
func roof_terraces() -> void:
	for b: Dictionary in blds:
		var f := String(b.folder)
		if not (f.contains("condo") or f.contains("hotel") or f.contains("apt")) or bool(b.house): continue
		var w: float = b.w; var d: float = b.d
		var bxf: Transform3D = b.xf; var inv: Transform3D = b.inv; var mxf: Transform3D = b.mxf; var tm: TriangleMesh = b.tm
		var yaw := rad_to_deg(bxf.basis.get_euler().y)
		var n_c := 0
		for c: Vector2 in [Vector2(-0.3, 0.25), Vector2(0.3, 0.25), Vector2(-0.3, -0.2), Vector2(0.3, -0.2)]:
			var wp := bxf * Vector3(c.x * w, 0, c.y * d)
			var hit := _roof_at(tm, inv, mxf, wp)
			if hit == Vector3.INF: continue
			if _roof_at(tm, inv, mxf, wp + Vector3(2.5, 0, 0)).y != hit.y or _roof_at(tm, inv, mxf, wp + Vector3(-2.5, 0, 0)).y != hit.y or _roof_at(tm, inv, mxf, wp + Vector3(0, 0, 2.5)).y != hit.y or _roof_at(tm, inv, mxf, wp + Vector3(0, 0, -2.5)).y != hit.y: continue
			if not put("prop_patio_set_4", "worn", hit, yaw, 1.2, "towers: residents' roof terrace"): continue
			props.add("prop_shade_sail", "worn", hit, yaw, false); added += 1; why["towers: residents' roof terrace"] = int(why["towers: residents' roof terrace"]) + 1
			var bb := Basis(Vector3.UP, deg_to_rad(yaw))
			for it: Array in [["plant_potted_leafy", 2.2, 0.0, 0.4], ["plant_potted_succulent", -2.2, 0.6, 0.4], ["prop_adirondack_white", 1.4, -2.2, 0.6], ["prop_adirondack_wood", -1.4, -2.2, 0.6], ["prop_bbq_gas_cart", 2.6, 1.8, 0.6]]:
				put(String(it[0]), "normal" if String(it[0]).begins_with("plant") else "worn", hit + bb * Vector3(float(it[1]), 0, float(it[2])), yaw + 180.0 * float(int(it[2] < 0)), float(it[3]), "towers: residents' roof terrace")
			n_c += 1

## ---------------------------------------------------------------- service sides
func services() -> void:
	for b: Dictionary in blds:
		var w: float = b.w; var d: float = b.d
		var bxf: Transform3D = b.xf
		var back := bxf * Vector3(0, 0, -d * 0.5 - 0.5)
		var has := false
		for t: Array in taken:
			if Vector2((t[0] as Vector3).x - back.x, (t[0] as Vector3).z - back.z).length() < w * 0.5 + 2.0 and absf((t[0] as Vector3).y - back.y) < 3.0:
				has = true; break
		if has: continue          # already has a service side (or something stands there)
		var yaw := rad_to_deg(bxf.basis.get_euler().y) + 180.0
		var x0 := -w * 0.5 + 1.6
		var ok_wall := true
		for k in 3:
			var mp := bxf * Vector3(x0 + k * 0.42, 0, -d * 0.5 - 0.02)
			var g := gy(mp.x, mp.z)
			if g == -INF: ok_wall = false; break
		if not ok_wall: continue
		for k2 in 3:
			var mp2 := bxf * Vector3(x0 + k2 * 0.42, 0, -d * 0.5 - 0.02)
			put("prop_meter_electric", "worn", Vector3(mp2.x, gy(mp2.x, mp2.z) + 1.05, mp2.z), yaw, 0.2, "service side: meters", true)
		var gp := bxf * Vector3(x0 + 1.7, 0, -d * 0.5 - 0.02)
		put("prop_meter_gas", "rusty", Vector3(gp.x, gy(gp.x, gp.z) + 0.2, gp.z), yaw, 0.2, "service side: meters", true)
		var ap := bxf * Vector3(x0 + 3.4, 0, -d * 0.5 - 0.75)
		if not _inside_bld(ap, 0.1): put("prop_ac_condenser", "worn", Vector3(ap.x, gy(ap.x, ap.z), ap.z), yaw, 0.7, "service side: condenser")
		if bool(b.house) or String(b.folder).begins_with("apartments/"):
			for k3 in 3:
				var cp := bxf * Vector3(w * 0.5 - 1.5 - k3 * 0.8, 0, -d * 0.5 - 0.75)
				if not _inside_bld(cp, 0.1): put(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k3], "worn", Vector3(cp.x, gy(cp.x, cp.z), cp.z), yaw + rr.randf_range(-15, 15), 0.45, "service side: bin carts (homes)")

## ---------------------------------------------------------------- houses
func houses() -> void:
	for b: Dictionary in blds:
		if not bool(b.house) or String(b.folder).begins_with("garages/"): continue
		var w: float = b.w; var d: float = b.d
		var bxf: Transform3D = b.xf
		var yaw := rad_to_deg(bxf.basis.get_euler().y)
		for c: Vector2 in [Vector2(-1, 1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1)]:
			var p := bxf * Vector3(c.x * (w * 0.5 - 0.2), 0, c.y * (d * 0.5 + 0.04))
			var g := gy(p.x, p.z)
			if g == -INF: continue
			if _clear(Vector3(p.x, g, p.z), 0.45): put("prop_downspout_3m", "worn", Vector3(p.x, g, p.z), yaw + (0.0 if c.y > 0 else 180.0), 0.2, "houses: downspouts at the corners", true)
		var doors: Array = (b.st as Dictionary).get("doors_front", [])
		for e: Array in doors:
			if not String(e[0]).begins_with("door") and String(e[0]) != "apt_door": continue     # house kits name doors by style
			var np := bxf * Vector3(float(e[1]) + 0.85, 0, d * 0.5 + 0.03)
			var g2 := gy(np.x, np.z)
			if g2 != -INF: put("prop_house_numbers_tile" if rr.randf() < 0.5 else "prop_house_numbers_wood", "worn", Vector3(np.x, g2 + 1.75, np.z), yaw, 0.1, "houses: numbers by the door", true)
			break
		var hp := bxf * Vector3(w * 0.5 + 0.03, 0, -d * 0.2)
		var g3 := gy(hp.x, hp.z)
		if g3 != -INF and not _inside_bld(hp + bxf.basis.x * 0.6, 0.0) and _clear(Vector3(hp.x, g3, hp.z), 0.6): put("prop_hose_reel_wall", "worn", Vector3(hp.x, g3, hp.z), yaw + 90.0, 0.3, "houses: hose reel on the side wall", true)

## golf carts in front of garages (Coronado runs on golf carts), one house in two that has a garage
func golf_carts() -> void:
	for b: Dictionary in blds:
		if not bool(b.house): continue
		for e: Array in (b.st as Dictionary).get("doors_front", []):
			if String(e[0]) != "garage" or rr.randf() < 0.5: continue
			var bxf: Transform3D = b.xf
			var p := bxf * Vector3(float(e[1]), 0, float(b.d) * 0.5 + 3.4)
			var g := gy(p.x, p.z)
			if g != -INF: put("prop_golf_cart_blue" if rr.randf() < 0.5 else "prop_golf_cart_white", "worn", Vector3(p.x, g, p.z), rad_to_deg(bxf.basis.get_euler().y) + 180.0, 1.4, "houses: golf cart in the driveway")

## window AC units on the old 2-4 storey brick / stucco blocks (built before central air): back and side walls, one in
## roughly every other window bay per floor; the raycast puts each unit on the real wall surface
func window_acs() -> void:
	for b: Dictionary in blds:
		if bool(b.house): continue
		var f := String(b.folder)
		if not (f.contains("brick") or f.contains("brk") or f.contains("apt") or f.contains("arcade") or f.contains("orange") or f.contains("bakery") or f.contains("books") or f.contains("boutique")): continue
		var top: float = b.top
		if top > (20.0 if f.contains("apt") else 15.0) or top < 5.0: continue
		var w: float = b.w; var d: float = b.d
		var bxf: Transform3D = b.xf; var inv: Transform3D = b.inv; var mxf: Transform3D = b.mxf; var tm: TriangleMesh = b.tm
		var yaw := rad_to_deg(bxf.basis.get_euler().y)
		var floors := int(floor((top - 1.0) / 3.0))
		for side: Array in [[Vector3(0, 0, -1), d * 0.5, w, 180.0], [Vector3(1, 0, 0), w * 0.5, d, 90.0], [Vector3(-1, 0, 0), w * 0.5, d, -90.0]]:
			var nrm: Vector3 = side[0]; var off: float = side[1]; var span: float = side[2]
			var s := -span * 0.5 + 2.0
			while s < span * 0.5 - 1.5:
				for fl in range(1, floors + 1):
					if rr.randf() > 0.45: continue
					var lp := nrm * (off + 3.0) + (Vector3(nrm.z, 0, -nrm.x) * s)
					var wpo := bxf * lp
					var gyv := gy(wpo.x, wpo.z)
					if gyv == -INF: continue
					var yy := gyv + 3.0 * float(fl) - 0.9
					var o := inv * Vector3(wpo.x, yy, wpo.z)
					var dv := (inv.basis * (bxf.basis * -nrm)).normalized()
					var h: Dictionary = tm.intersect_ray(o, dv)
					if h.is_empty(): continue
					var hp: Vector3 = mxf * (h.position as Vector3)
					if hp.distance_to(wpo + Vector3(0, yy - wpo.y, 0)) > 3.8: continue
					var out := (bxf.basis * nrm).normalized()
					put("prop_ac_window", "rusty" if rr.randf() < 0.35 else "worn", hp + out * 0.12, yaw + float(side[3]), 0.3, "old blocks: window AC units", true)
				s += 3.0

## solar: rows of panels on the big flat roofs (malls, big stores, arcades - California does this), and panels laid on
## the south-facing slope of some house roofs
func solar() -> void:
	for b: Dictionary in blds:
		var w: float = b.w; var d: float = b.d
		var bxf: Transform3D = b.xf; var inv: Transform3D = b.inv; var mxf: Transform3D = b.mxf; var tm: TriangleMesh = b.tm
		var yaw := rad_to_deg(bxf.basis.get_euler().y)
		if not bool(b.house) and w * d > 500.0 and float(b.top) < 20.0:
			var lx := -w * 0.3
			while lx < w * 0.3:
				var lz := -d * 0.3
				while lz < d * 0.3:
					var wp := bxf * Vector3(lx, 0, lz)
					var hit := _roof_at(tm, inv, mxf, wp)
					if hit != Vector3.INF and _roof_at(tm, inv, mxf, wp + Vector3(1.8, 0, 0)).y == hit.y and _roof_at(tm, inv, mxf, wp + Vector3(-1.8, 0, 0)).y == hit.y:
						put("prop_solar_panel_x3", "worn", hit, yaw, 1.5, "big flat roofs: solar array")
					lz += 2.5
				lx += 3.4
		elif bool(b.house) and not String(b.folder).begins_with("garages/") and rr.randf() < 0.45:
			var n_p := 0
			var lx2 := -w * 0.35
			while lx2 < w * 0.35 and n_p < 8:
				var lz2 := -d * 0.4
				while lz2 < d * 0.4 and n_p < 8:
					var wp2 := bxf * Vector3(lx2, 0, lz2)
					var o := inv * Vector3(wp2.x, 300.0, wp2.z)
					var h: Dictionary = tm.intersect_ray(o, (inv.basis * Vector3.DOWN).normalized())
					if not h.is_empty():
						var n: Vector3 = (mxf.basis * (h.normal as Vector3)).normalized()
						if n.y > 0.55 and n.y < 0.95 and n.z > 0.3:          # the south-facing slope
							var zh := Vector3(n.x, 0, n.z).normalized()
							var zz := (zh - n * zh.dot(n)).normalized()
							var bas := Basis(n.cross(zz), n, zz)
							var hp2: Vector3 = mxf * (h.position as Vector3)
							props.add("prop_solar_panel", "worn", hp2 + n * 0.04, 0.0, false)
							# re-set the last transform's basis to lie on the roof plane
							var key := "prop_solar_panel|worn"
							var arr: Array = props.items[key]
							arr[arr.size() - 1] = Transform3D(bas, hp2 + n * 0.04)
							added += 1; why["houses: solar panels on the south roof"] = int(why.get("houses: solar panels on the south roof", 0)) + 1
							n_p += 1
					lz2 += 1.8
				lx2 += 1.1

## ---------------------------------------------------------------- shopfronts
func shopfronts(cafe_tables: bool) -> void:
	for b: Dictionary in blds:
		if bool(b.house): continue
		var st: Dictionary = b.st
		var doors: Array = []
		for e: Array in st.get("doors_front", []):
			if String(e[0]) == "shopdoor" or String(e[0]) == "civic_door": doors.append(float(e[1]))
		if doors.is_empty(): continue
		var w: float = b.w; var d: float = b.d
		var bxf: Transform3D = b.xf
		var yaw := rad_to_deg(bxf.basis.get_euler().y)
		var free_x := func(x: float, half: float) -> bool:
			for dx: float in doors:
				if absf(x - dx) < 1.95 + half: return false
			return absf(x) < w * 0.5 - half - 0.3
		var at := func(lx: float, lz: float) -> Vector3:
			var p: Vector3 = bxf * Vector3(lx, 0, d * 0.5 + lz)
			return Vector3(p.x, gy(p.x, p.z), p.z)
		for dx2: float in doors:
			for s: float in [-1.6, 1.6]:
				var pp: Vector3 = at.call(dx2 + s, 0.75)
				if pp.y != -INF and not _near_door_other(doors, dx2 + s, dx2) and _door_clear(pp, 1.55): put("plant_potted_leafy" if rr.randf() < 0.6 else "plant_potted_succulent", "normal", pp, 0.0, 0.35, "shops: a pot either side of the door")
		var f := String(b.folder)
		if cafe_tables and (f.contains("cafe") or f.contains("bistro") or f.contains("bakery") or f.contains("bar")):
			for tx: float in [-3.6, 3.6, -7.4, 7.4]:
				var x: float = float(doors[0]) + tx
				if not free_x.call(x, 1.0): continue
				var tp: Vector3 = at.call(x, 2.0)
				if tp.y != -INF and put("prop_patio_set_4", "worn", tp, rr.randf_range(-10, 10), 1.0, "cafes: tables out on the walk"):
					dec.add(14, Vector2(tp.x, tp.z), 0.0, 2.2, 2.2, gy, Color(1, 1, 1, 0.45))
		for bx: float in [-w * 0.5 + 2.0, w * 0.5 - 2.0]:
			if free_x.call(bx, 1.25):
				var rp: Vector3 = at.call(bx, 1.0)
				if rp.y != -INF and _door_clear(rp, 2.6) and put("prop_bike_rack", "worn", rp, yaw, 1.6, "shops: bike rack parallel to the front"): break
		for dx3: float in doors:
			var dp: Vector3 = at.call(dx3, 0.6)
			if dp.y != -INF: dec.add(14, Vector2(dp.x, dp.z), yaw, 1.6, 1.2, gy, Color(1, 1, 1, 0.5))    # the doorstep is where everyone steps

## distance from p to every ground-floor front door of every loaded building (a neighbour's door counts too)
func _door_clear(p: Vector3, r: float) -> bool:
	for b: Dictionary in blds:
		var bxf: Transform3D = b.xf
		for e: Array in (b.st as Dictionary).get("doors_front", []):
			var dp := bxf * Vector3(float(e[1]), 0, float(b.d) * 0.5)
			if Vector2(dp.x - p.x, dp.z - p.z).length() < r: return false
	return true

func _near_door_other(doors: Array, x: float, own: float) -> bool:
	for dx: float in doors:
		if dx != own and absf(x - dx) < 1.0: return true
	return false

func save(root_name: String) -> void:
	var root := Node3D.new(); root.name = root_name
	root.set_meta("stalls", [])
	var wm := dec.build()
	if wm: root.add_child(wm)
	props.build(root, K)
	print("%s: added %d props %s" % [root_name, added, why])
	K.save_piece(root, root_name)
