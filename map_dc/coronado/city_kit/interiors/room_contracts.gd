extends SceneTree
## Room contracts for zero-loading interiors (17 Nov, interiors session). Read-only on the city kit.
##
## For every kit building model the LOCKED samples use, this reads the model's near mesh and finds its real openings
## from the atlas: each door and window is a quad mapped onto one opening region of assets/coronado_kit/textures/
## city_layout.json (O_shopdoor, O_apt_door, O_civic_door, O_patio, O_rollup, O_apt_slider, O_storefront, O_win_*,
## O_glass_plain, O_civic_win, O_lancet, O_ribbon, O_small_*). Triangles are grouped per region and facade into
## opening rectangles (along the facade, bottom, top) in the model's own frame (front = +Z, origin = footprint
## bottom centre). From those it derives the floors, the inside volume per floor, the entrances and the room types
## that fit (the shop layout sets' size limits in map_dc/coronado/shops/interior/layouts).
##
## Writes (res://map_dc/coronado/city_kit/interiors/):
##   room_contracts.json   one contract per model
##   sample_buildings.json every building placed in the 8 locked samples (+ stadium): piece, label, model, world
##                         transform, and each real door in world coordinates (for the shop assignment)
## Run: godot --headless --path <preview project> -s res://map_dc/coronado/city_kit/interiors/room_contracts.gd
const K := preload("res://tools/city/pilot/kit_lib.gd")
const OUT := "res://map_dc/coronado/city_kit/interiors/"
const LAYOUTS := "res://map_dc/coronado/shops/interior/layouts/"
## the 8 locked samples (piece origin in city_layout.json) + the stadium site
const SAMPLES := {"0,0": "pilot_high_street", "0,400": "city_centre", "0,-400": "industrial", "-400,0": "commercial_strip",
	"400,0": "apartment_band", "400,400": "civic_band", "400,-400": "gritty_edge", "-400,400": "waterfront", "400,600": "civic_band"}
const DOORS := {"O_shopdoor": "shop", "O_civic_door": "civic", "O_apt_door": "residential", "O_patio": "patio", "O_rollup": "service_bay", "O_apt_slider": "slider"}
const WIN_PREFIX := ["O_win_", "O_storefront", "O_glass_plain", "O_civic_win", "O_lancet", "O_ribbon", "O_small_"]
const WALL := 0.30          # wall thickness assumed inside the shell (kit slabs 0.30-0.45)
const FRONT_WALL := 0.45

var regs := {}              # opening regions: name -> [u0, v0, u1, v1]
var sregs := {}             # sign regions: SG_* (a name painted in the atlas) and S_signbg (a blank board)
var stext := {}             # SG_* -> the name painted on it
var sets: Array = []        # shop layout sets: [set, types, min_w, max_w, min_d, max_d]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var L: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/coronado_kit/textures/city_layout.json"))
	for r: String in L.regions:
		var e: Dictionary = L.regions[r]
		if r.begins_with("O_") and e.has("uv"): regs[r] = e.uv
		if r.begins_with("SG_") and e.has("uv"): sregs[r] = e.uv
		if r == "S_signbg" or r == "T_dark":     # T_dark: the blank dark sign boards of the generic models (filtered by size below)
			var sz: Array = L.size if L.size is Array else [L.size, L.size]
			if e.has("uv") and (e.uv as Array).size() == 4: sregs[r] = e.uv
			else:
				var px: Array = e.px
				sregs[r] = [float(px[0]) / float(sz[0]), float(px[1]) / float(sz[1]), float(px[2]) / float(sz[0]), float(px[3]) / float(sz[1])]
	stext = L.get("signs", {})
	for f in DirAccess.get_files_at(LAYOUTS):
		if not f.ends_with(".json"): continue
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUTS + f))
		var rm: Dictionary = d.get("room", {})
		sets.append([String(d.set), d.get("types", []), float(rm.get("min_w", 3)), float(rm.get("max_w", 9)), float(rm.get("min_d", 4)), float(rm.get("max_d", 10))])
	# ---- every building in the samples
	var world := Node3D.new(); root.add_child(world)
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(K.LAYOUT)).instances
	var blds: Array = []
	var models := {}
	for r: Dictionary in rows:
		var p: Array = r.pos
		var key := "%d,%d" % [int(p[0]), int(p[2])]
		if not SAMPLES.has(key): continue
		var path := "res://map_dc/coronado/city_kit/pieces/%s.scn" % r.piece
		if not ResourceLoader.exists(path): continue
		var n: Node3D = (load(path) as PackedScene).instantiate()
		n.position = Vector3(float(p[0]), float(p[1]), float(p[2])); n.rotation_degrees.y = float(r.get("yaw", 0))
		world.add_child(n)
		var bn := n.get_node_or_null("Buildings")
		if bn == null: continue
		for b: Node3D in bn.get_children():
			var folder := _folder(b)
			if folder == "": print("RC skip %s/%s: model not found" % [r.piece, b.name]); continue
			if not models.has(folder): models[folder] = _contract(folder)
			blds.append({"sample": SAMPLES[key], "piece": String(r.piece), "label": String(b.name), "model": folder, "xf": b.global_transform})
	# ---- world doors per building
	var out_b: Array = []
	for e: Dictionary in blds:
		var c: Dictionary = models[e.model]
		var xf: Transform3D = e.xf
		var doors: Array = []
		for o: Dictionary in c.get("openings", []):
			if not DOORS.has(o.region): continue
			var lp := _facade_point(o, c)
			var wp := xf * lp
			var nrm := (xf.basis * _facade_normal(String(o.facade))).normalized()
			doors.append({"kind": DOORS[o.region], "facade": o.facade, "floor": o.floor, "w": o.w, "local": [snappedf(lp.x, 0.01), snappedf(lp.y, 0.01), snappedf(lp.z, 0.01)],
				"world": [snappedf(wp.x, 0.01), snappedf(wp.y, 0.01), snappedf(wp.z, 0.01)], "out": [snappedf(nrm.x, 0.001), snappedf(nrm.z, 0.001)]})
		var yaw := rad_to_deg(xf.basis.get_euler().y)
		out_b.append({"sample": e.sample, "piece": e.piece, "label": e.label, "model": e.model,
			"pos": [snappedf(xf.origin.x, 0.01), snappedf(xf.origin.y, 0.01), snappedf(xf.origin.z, 0.01)], "yaw": snappedf(yaw, 0.1), "doors": doors})
	_save("room_contracts.json", {"_doc": "Generated by room_contracts.gd from the kit near meshes + stats. Model frame: origin = footprint bottom centre, front = +Z, metres. Openings are found from the atlas regions they are mapped to; floor heights and inside volumes are derived (see each field's note). Not measured in game.", "models": models})
	_save("sample_buildings.json", {"_doc": "Every building in the 8 locked samples (+ stadium): its model and each real door in world coordinates (city_layout frame, x east, -z north). 'out' = the door's outward direction.", "buildings": out_b})
	var nd := 0
	for b2: Dictionary in out_b: nd += (b2.doors as Array).size()
	print("RC models=%d buildings=%d doors=%d" % [models.size(), out_b.size(), nd])
	quit()

## the kit folder of a placed building ("commercial/com_bakery", "ck/ck_brk3_row2", "modular/examples/mod_svc_row")
func _folder(b: Node3D) -> String:
	if b.has_meta(&"kit"): return String(b.get_meta(&"kit"))
	var nm := b.get_node_or_null("near") as MeshInstance3D
	if nm == null or nm.mesh == null: return ""
	var rp := nm.mesh.resource_path
	if rp.contains("::"): rp = rp.get_slice("::", 0)
	var dir := rp.get_base_dir()
	if dir.begins_with("res://assets/coronado_kit/buildings/"): return dir.trim_prefix("res://assets/coronado_kit/buildings/")
	if dir.begins_with("res://map_dc/coronado/city_kit/buildings/"): return "ck/" + dir.get_file()
	if dir.begins_with("res://assets/coronado_kit/modular/examples/"): return "modular/examples/" + dir.get_file()
	return ""

func _facade_normal(f: String) -> Vector3:
	match f:
		"front": return Vector3(0, 0, 1)
		"back": return Vector3(0, 0, -1)
		"right": return Vector3(1, 0, 0)
		_: return Vector3(-1, 0, 0)

## a door's centre at its sill, on the facade plane, in the model frame
func _facade_point(o: Dictionary, c: Dictionary) -> Vector3:
	var a := float(o.along); var pl := float(o.plane)
	match String(o.facade):
		"front", "back": return Vector3(a, float(o.y0), pl)
		_: return Vector3(pl, float(o.y0), a)

func _contract(folder: String) -> Dictionary:
	var st: Dictionary = K.building_stats(folder)
	var dir := K._bdir(folder)
	var f := K._tier_file(dir, "near")
	var c := {"model": folder, "cat": String(st.get("cat", "")), "footprint_wd": st.get("footprint_wd", []), "height": st.get("height", 0.0),
		"storeys": int(st.get("storeys", 0)), "stats_doors_front": st.get("doors_front", [])}
	if f == "" or st.is_empty():
		c["error"] = "no near mesh or stats"; return c
	var inst: Node = (load(f) as PackedScene).instantiate()
	var mi := K._first_mesh(inst)
	var groups := {}       # region|facade|plane -> Array of rects [a0, a1, y0, y1]
	var walls_out: Array = []   # facade-facing faces (any region): [facade, plane, a0, a1, y0, y1] - what stands in front of a door
	var m: Mesh = mi.mesh
	for si in m.get_surface_count():
		var arr := m.surface_get_arrays(si)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]; var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var nt := idx.size() / 3 if idx.size() > 0 else v.size() / 3
		for t in nt:
			var i0 := idx[t * 3] if idx.size() > 0 else t * 3
			var i1 := idx[t * 3 + 1] if idx.size() > 0 else t * 3 + 1
			var i2 := idx[t * 3 + 2] if idx.size() > 0 else t * 3 + 2
			var cu := (uv[i0] + uv[i1] + uv[i2]) / 3.0
			cu.x = fposmod(cu.x, 1.0)
			var reg := ""
			for r: String in regs:
				var u: Array = regs[r]
				if cu.x >= float(u[0]) and cu.x <= float(u[2]) and cu.y >= float(u[1]) and cu.y <= float(u[3]): reg = r; break
			if reg == "":
				for r3: String in sregs:
					var u3: Array = sregs[r3]
					if cu.x >= float(u3[0]) and cu.x <= float(u3[2]) and cu.y >= float(u3[1]) and cu.y <= float(u3[3]): reg = r3; break
			var p0 := mi.transform * v[i0]; var p1 := mi.transform * v[i1]; var p2 := mi.transform * v[i2]
			if not (DOORS.has(reg) or WIN_PREFIX.any(func(p: String) -> bool: return reg.begins_with(p))):
				var nn := -((p1 - p0).cross(p2 - p0)).normalized()
				if absf(nn.y) < 0.3:
					var ff := ""
					if absf(nn.z) >= absf(nn.x): ff = "front" if nn.z > 0 else "back"
					else: ff = "right" if nn.x > 0 else "left"
					var ax := ff == "front" or ff == "back"
					walls_out.append([ff, (p0.z + p1.z + p2.z) / 3.0 if ax else (p0.x + p1.x + p2.x) / 3.0,
						minf(minf(p0.x, p1.x), p2.x) if ax else minf(minf(p0.z, p1.z), p2.z), maxf(maxf(p0.x, p1.x), p2.x) if ax else maxf(maxf(p0.z, p1.z), p2.z),
						minf(minf(p0.y, p1.y), p2.y), maxf(maxf(p0.y, p1.y), p2.y)])
			if reg == "" or not (DOORS.has(reg) or sregs.has(reg) or WIN_PREFIX.any(func(p: String) -> bool: return reg.begins_with(p))): continue
			var n := (p1 - p0).cross(p2 - p0)
			if n.length() < 1e-6: continue
			n = -n.normalized()        # Godot front faces wind clockwise: the cross product points inward
			if absf(n.y) > 0.5: continue      # horizontal faces (sills, lintel undersides) are not the opening
			var fac := ""
			if absf(n.z) >= absf(n.x): fac = "front" if n.z > 0 else "back"
			else: fac = "right" if n.x > 0 else "left"
			var along_x := fac == "front" or fac == "back"
			var a0 := minf(minf(p0.x, p1.x), p2.x) if along_x else minf(minf(p0.z, p1.z), p2.z)
			var a1 := maxf(maxf(p0.x, p1.x), p2.x) if along_x else maxf(maxf(p0.z, p1.z), p2.z)
			var plane := (p0.z + p1.z + p2.z) / 3.0 if along_x else (p0.x + p1.x + p2.x) / 3.0
			var gk := "%s|%s|%.1f" % [reg, fac, plane]
			if not groups.has(gk): groups[gk] = []
			(groups[gk] as Array).append([a0, a1, minf(minf(p0.y, p1.y), p2.y), maxf(maxf(p0.y, p1.y), p2.y), plane])
	inst.free()
	# merge triangles that touch into opening rectangles (sign boards the same way, kept apart in "signs")
	var ops: Array = []
	var signs: Array = []
	for gk: String in groups:
		var rects: Array = groups[gk]
		var merged := true
		while merged:
			merged = false
			for i in rects.size():
				for j in range(i + 1, rects.size()):
					var a: Array = rects[i]; var b: Array = rects[j]
					if float(a[0]) <= float(b[1]) + 0.05 and float(b[0]) <= float(a[1]) + 0.05 and float(a[2]) <= float(b[3]) + 0.05 and float(b[2]) <= float(a[3]) + 0.05:
						rects[i] = [minf(a[0], b[0]), maxf(a[1], b[1]), minf(a[2], b[2]), maxf(a[3], b[3]), a[4]]
						rects.remove_at(j); merged = true; break
				if merged: break
		var parts := gk.split("|")
		for r2: Array in rects:
			var w := float(r2[1]) - float(r2[0]); var h := float(r2[3]) - float(r2[2])
			if w < 0.25 or h < 0.25: continue        # frame slivers
			if sregs.has(parts[0]):
				# a dark trim quad is a blank sign board only at sign size in the shop band (1.2 m+ wide, 0.3-1 m high)
				if parts[0] == "T_dark" and (w < 1.2 or h < 0.3 or h > 1.0 or float(r2[2]) < 2.6 or float(r2[3]) > 5.2): continue
				signs.append({"region": "blank" if parts[0] == "T_dark" else parts[0], "text": String(stext.get(parts[0], "")), "facade": parts[1], "plane": snappedf(float(r2[4]), 0.01),
					"along": snappedf((float(r2[0]) + float(r2[1])) * 0.5, 0.01), "w": snappedf(w, 0.01), "y0": snappedf(float(r2[2]), 0.01), "y1": snappedf(float(r2[3]), 0.01)})
				continue
			ops.append({"region": parts[0], "facade": parts[1], "plane": snappedf(float(r2[4]), 0.01), "along": snappedf((float(r2[0]) + float(r2[1])) * 0.5, 0.01),
				"w": snappedf(w, 0.01), "y0": snappedf(float(r2[2]), 0.01), "y1": snappedf(float(r2[3]), 0.01)})
	# floors: the ground floor is the sill of the lowest door; upper floors from the window sills above it
	var door_y := INF
	for o: Dictionary in ops:
		if DOORS.has(o.region) and String(o.region) != "O_apt_slider": door_y = minf(door_y, float(o.y0))
	if door_y == INF: door_y = 0.0
	var sills: Array = []
	for o2: Dictionary in ops:
		if not DOORS.has(o2.region) and float(o2.y0) > door_y + 2.4: sills.append(snappedf(float(o2.y0) - 0.9, 0.5))
	for o3: Dictionary in ops:
		if String(o3.region) == "O_apt_slider" or (String(o3.region) == "O_apt_door" and float(o3.y0) > door_y + 2.0): sills.append(snappedf(float(o3.y0), 0.5))
	var floors: Array = [snappedf(door_y, 0.01)]
	sills.sort()
	for s in sills:
		if float(s) > float(floors[floors.size() - 1]) + 2.4: floors.append(float(s))
	var top := float(st.get("height", 3.0)) - 0.6
	for o4: Dictionary in ops:
		var fl := 0
		for k in floors.size():
			if float(o4.y0) >= float(floors[k]) - 0.3: fl = k
		o4["floor"] = fl
	var fw: Array = st.footprint_wd
	var iw := float(fw[0]) - 2.0 * WALL; var idp := float(fw[1]) - WALL - FRONT_WALL
	var vols: Array = []
	for k2 in floors.size():
		var ceil_y := float(floors[k2 + 1]) - 0.3 if k2 + 1 < floors.size() else top
		vols.append({"floor": k2, "y": floors[k2], "clear_h": snappedf(ceil_y - float(floors[k2]), 0.01), "inner_wd": [snappedf(iw, 0.01), snappedf(idp, 0.01)],
			"box_min": [snappedf(-iw * 0.5, 0.01), floors[k2], snappedf(-float(fw[1]) * 0.5 + WALL, 0.01)], "box_max": [snappedf(iw * 0.5, 0.01), snappedf(ceil_y, 0.01), snappedf(float(fw[1]) * 0.5 - FRONT_WALL, 0.01)]})
	# a door the building's own pier / pilaster stands in front of (18 Nov: the Heave Ho cafe's corner pier covers the right
	# 0.55 m of its painted door): the part of the doorway nothing stands in front of within 0.6 m of the door, at body
	# height, is recorded as "clear" [s0, s1] - the room builds its door there and closes the rest
	for od: Dictionary in ops:
		if not DOORS.has(od.region): continue
		var f0 := String(od.facade); var outs := 1.0 if (f0 == "front" or f0 == "right") else -1.0
		var lo := float(od.along) - float(od.w) * 0.5; var hi := float(od.along) + float(od.w) * 0.5
		var spans: Array = [[lo, hi]]
		for wq: Array in walls_out:
			if String(wq[0]) != f0: continue
			var d := (float(wq[1]) - float(od.plane)) * outs
			if d < 0.05 or d > 0.6: continue
			if float(wq[5]) < float(od.y0) + 0.2 or float(wq[4]) > float(od.y0) + 2.0: continue
			var b0 := float(wq[2]); var b1 := float(wq[3])
			var nxt: Array = []
			for sp: Array in spans:
				if b1 <= float(sp[0]) + 0.05 or b0 >= float(sp[1]) - 0.05: nxt.append(sp); continue
				if b0 > float(sp[0]): nxt.append([float(sp[0]), b0])
				if b1 < float(sp[1]): nxt.append([b1, float(sp[1])])
			spans = nxt
		var best: Array = []
		for sp2: Array in spans:
			if best.is_empty() or float(sp2[1]) - float(sp2[0]) > float(best[1]) - float(best[0]): best = sp2
		# mouldings round a door stand a few cm into it: only a real obstruction (0.2 m+ of the doorway) counts
		if not best.is_empty() and (hi - lo) - (float(best[1]) - float(best[0])) >= 0.2:
			od["clear"] = [snappedf(float(best[0]), 0.01), snappedf(float(best[1]), 0.01)]
	c["openings"] = ops
	c["signs"] = signs
	c["floors"] = vols
	c["floors_note"] = "derived: ground = lowest door sill; upper floors from window sills (-0.9 m) and upper apartment doors / sliders; walls assumed %.2f m (front %.2f m)" % [WALL, FRONT_WALL]
	# entrances and the rooms that fit behind them
	var ents: Array = []
	var front_shop: Array = []
	for o5: Dictionary in ops:
		if (String(o5.region) == "O_shopdoor" or String(o5.region) == "O_civic_door") and int(o5.floor) == 0: front_shop.append(o5)
	for o6: Dictionary in ops:
		if not DOORS.has(o6.region): continue
		var kind: String = DOORS[o6.region]
		var e := {"kind": kind, "facade": o6.facade, "along": o6.along, "w": o6.w, "floor": o6.floor}
		if kind == "shop" or kind == "civic":
			# the bay this door owns: split the facade between neighbouring public doors on the same facade
			var same: Array = front_shop.filter(func(x: Dictionary) -> bool: return x.facade == o6.facade)
			same.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.along) < float(b.along))
			var full := iw if (String(o6.facade) == "front" or String(o6.facade) == "back") else idp
			var lo := -full * 0.5; var hi := full * 0.5
			for s2: Dictionary in same:
				if float(s2.along) < float(o6.along) - 0.5: lo = maxf(lo, (float(s2.along) + float(o6.along)) * 0.5)
				if float(s2.along) > float(o6.along) + 0.5: hi = minf(hi, (float(s2.along) + float(o6.along)) * 0.5)
			var bw := hi - lo
			var bd := idp if (String(o6.facade) == "front" or String(o6.facade) == "back") else iw
			var fits: Array = []
			for sdef: Array in sets:
				if bw >= float(sdef[2]) and bd >= float(sdef[4]): fits.append(sdef[0])
			e["bay_w"] = snappedf(bw, 0.01); e["bay_d"] = snappedf(bd, 0.01); e["fits"] = fits
		ents.append(e)
	c["entrances"] = ents
	return c

func _save(f: String, v: Variant) -> void:
	var fa := FileAccess.open(OUT + f, FileAccess.WRITE); fa.store_string(JSON.stringify(v, " ")); fa.close()
