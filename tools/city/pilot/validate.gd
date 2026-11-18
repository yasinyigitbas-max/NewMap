extends SceneTree
## Block-kit piece checks (city1). Loads every piece in map_dc/coronado/city_kit/pieces/ (all together, in the shared
## pilot frame, so problems where two pieces meet are caught too) and reports, per prop / building:
##   overlap   two props' footprints overlap (trees: trunk only; fences may touch end to end)
##   inside    a prop stands inside a building footprint
##   door      something stands in the 1.4 x 1.5 m space in front of a building door
##   road      a prop other than a manhole or kerb inlet stands in a traffic or parking lane
##   street    (17 Nov, after the audit found signal poles on the asphalt past the kerb return) a ground prop stands on
##             the road surface (asphalt / paint) of ANY street or junction piece (j_*, s_*), in every zone
## Prints one line per problem, then "CHECKS n problems". Exit code 1 if any.
## Run: godot --path <preview project> -s res://tools/city/pilot/validate.gd   (real renderer: MultiMesh data)

const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const KIT := "res://assets/coronado_kit/buildings/"
var problems := 0

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var props: Array = []       # [piece, base, center Vector2, half Vector2, angle]
	var blds: Array = []        # [piece, name, center Vector2, half Vector2, angle, doors]
	var world := Node3D.new(); root.add_child(world)
	var road_tris := {}      # 8 m grid cell -> Array of [a, b, c: Vector2, y: float] (road surfaces of street pieces)
	for n: Node3D in K.place_layout(world, ["w_power"]):
		var piece := String(n.name)
		var pname := String(n.get_meta(&"piece", piece))
		if pname.begins_with("j_") or pname.begins_with("s_"):
			for gm: MeshInstance3D in n.find_children("ground", "MeshInstance3D", true, false):
				_road_tris(gm, road_tris)
		for mmi: MultiMeshInstance3D in n.find_children("*_near", "MultiMeshInstance3D", true, false):
			var nm := String(mmi.name).trim_suffix("_near")
			var base := nm.substr(0, nm.rfind("_"))
			if base.begins_with("plant_lawn_patch") or base.begins_with("plant_iceplant"): continue   # ground cover: walked over
			var e := K.manifest(base)
			var fw := float(e.get("footprint_w", 0.5)); var fd := float(e.get("footprint_d", 0.5))
			if base.begins_with("tree_") or base.begins_with("palm_"): fw = 0.6; fd = 0.6
			if base.begins_with("prop_utility_pole") or base.begins_with("prop_lot_light") or base.begins_with("prop_billboard") or base.begins_with("prop_lamp_cobra"): fw = 0.45; fd = 0.45   # overhead parts: only the posts stand on the ground
			if base.begins_with("prop_shade_sail"): continue   # canvas overhead on thin corner posts: things go UNDER it
			var mounted := String(e.get("mount", "ground")) != "ground"     # wall / roof props: not on the ground
			var mm := mmi.multimesh
			for i in mm.instance_count:
				var t := mmi.global_transform * mm.get_instance_transform(i)
				var ang := atan2(t.basis.z.x, t.basis.z.z)
				var up := mounted or (t.origin.y - n.global_position.y) > 1.2      # lifted: on a wall, a roof, a stack
				var o2 := Vector2(t.origin.x, t.origin.z)
				if base == "prop_marina_finger":      # origin at the float-side root, the finger runs 7.5 m along local +z
					var zz := t.basis.z.normalized() * 3.75; o2 += Vector2(zz.x, zz.z)
				props.append([piece, base, o2, Vector2(fw, fd) * 0.5, ang, t.origin.y, up])
		var bn := n.get_node_or_null("Buildings")
		if bn:
			for b: Node3D in bn.get_children():
				var st: Dictionary = K.building_stats(String(b.get_meta(&"kit"))) if b.has_meta(&"kit") else _stats(String(b.name))
				if st.is_empty():
					# a building placed under a business label (older pieces, no "kit" meta): its near mesh still comes
					# from the kit file, whose folder holds the stats
					var nm2 := b.get_node_or_null("near") as MeshInstance3D
					var rp := nm2.mesh.resource_path if nm2 and nm2.mesh else ""
					if rp.contains("::"): rp = rp.get_slice("::", 0)
					if rp != "" and FileAccess.file_exists(rp.get_base_dir() + "/stats.json"):
						st = JSON.parse_string(FileAccess.get_file_as_string(rp.get_base_dir() + "/stats.json"))
					if st.is_empty() and nm2 and nm2.mesh: st = _match(nm2.mesh)
					if st.is_empty():
						print("CHECK-NOTE %s %s: no stats found (mesh %s), not checked" % [piece, b.name, rp])
						continue
				var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
				var gb := b.global_transform.basis
				var ang2 := atan2(gb.z.x, gb.z.z)      # world yaw (17 Nov: the local rotation.y ignored a rotated piece's own yaw -> 146 false 'inside' at the waterfront in the assembled city)
				var doors: Array = []
				for e2: Array in st.get("doors_front", []):
					var p3: Vector3 = b.global_transform * Vector3(float(e2[1]), 0.0, d * 0.5 + 0.75)
					doors.append([String(e2[0]), Vector2(p3.x, p3.z)])
				blds.append([piece, String(b.name), Vector2(b.global_position.x, b.global_position.z), Vector2(w, d) * 0.5, ang2, doors])
	print("CHECKS loaded %d props, %d buildings" % [props.size(), blds.size()])
	# overlaps between props
	for i in props.size():
		var a: Array = props[i]
		for j in range(i + 1, props.size()):
			var b2: Array = props[j]
			if (a[2] as Vector2).distance_to(b2[2]) > (a[3] as Vector2).length() + (b2[3] as Vector2).length(): continue
			if String(a[1]).begins_with("fence_") and String(b2[1]).begins_with("fence_"): continue
			if _wf_joined(String(a[1]), String(b2[1])): continue   # waterfront assemblies bolt together / stand on decks
			if absf(float(a[5]) - float(b2[5])) > 1.5: continue   # stacked (containers): one stands on the other
			if a[6] and b2[6] and absf(float(a[5]) - float(b2[5])) > 0.6: continue   # wall props at different heights (buzzer under a door light, balcony above it)
			if _hit(a[2], a[3] * 0.95, a[4], b2[2], b2[3] * 0.95, b2[4]):
				_report("overlap", "%s %s at %s  x  %s %s at %s" % [a[0], a[1], _p(a[2]), b2[0], b2[1], _p(b2[2])])
	# buildings overlapping each other (walls through walls)
	for i in blds.size():
		for j in range(i + 1, blds.size()):
			var a1: Array = blds[i]; var b1: Array = blds[j]
			if (a1[2] as Vector2).distance_to(b1[2]) > (a1[3] as Vector2).length() + (b1[3] as Vector2).length(): continue
			if _hit(a1[2], (a1[3] as Vector2) - Vector2(0.1, 0.1), a1[4], b1[2], (b1[3] as Vector2) - Vector2(0.1, 0.1), b1[4]):
				_report("bldg", "%s %s at %s  x  %s %s at %s" % [a1[0], a1[1], _p(a1[2]), b1[0], b1[1], _p(b1[2])])
	# props inside buildings, door spaces
	for a: Array in props:
		if a[6]: continue     # mounted / lifted props stand on walls and roofs, not in rooms or doorways
		for b: Array in blds:
			if (a[2] as Vector2).distance_to(b[2]) > (a[3] as Vector2).length() + (b[3] as Vector2).length(): continue
			if _hit(a[2], a[3], a[4], b[2], (b[3] as Vector2) - Vector2(0.15, 0.15), b[4]):
				_report("inside", "%s %s at %s inside %s %s" % [a[0], a[1], _p(a[2]), b[0], b[1]])
		for b: Array in blds:
			for dr: Array in b[5]:
				if _hit(a[2], a[3], a[4], dr[1], Vector2(0.7, 0.75), b[4]):
					_report("door", "%s %s at %s blocks the %s of %s" % [a[0], a[1], _p(a[2]), dr[0], b[1]])
	# props in lanes
	# (the pilot's own lanes by coordinates: only for the pilot's pieces; every other street is covered by the
	#  road-surface check below, which reads each street piece's asphalt wherever it is placed)
	const PILOT := ["j_amber_10th", "s_amber_n", "s_amber_s", "s_10th_w", "s_10th_e", "b_nw", "b_ne", "b_se", "b_sw", "r_n", "r_s", "d_pilot"]
	for a: Array in props:
		var p: Vector2 = a[2]; var base: String = a[1]
		var pc := String(a[0]); var us := pc.rfind("_")
		if not (pc.substr(0, us) in PILOT): continue
		if base.contains("manhole") or base.contains("storm_drain"): continue
		var on_amber := absf(p.x) > S.A_MED + 0.05 and absf(p.x) < S.A_KERB - 0.1 and absf(p.y) < 97.5
		var on_tenth := absf(p.y) < S.T_KERB - 0.1 and absf(p.x) > S.A_KERB and absf(p.x) < 150.0
		if on_amber or on_tenth: _report("road", "%s %s at %s stands in the street" % [a[0], base, _p(p)])
	# props on the road surface of any street / junction piece (all zones)
	for a: Array in props:
		if a[6]: continue
		var base2: String = a[1]
		if base2.contains("manhole") or base2.contains("storm_drain"): continue
		var p2: Vector2 = a[2]
		var cell := Vector2i(floori(p2.x / 8.0), floori(p2.y / 8.0))
		for t: Array in road_tris.get(cell, []):
			if absf(float(a[5]) - float(t[3])) < 0.3 and Geometry2D.point_is_inside_triangle(p2, t[0], t[1], t[2]):
				_report("street", "%s %s at %s stands on the road surface" % [a[0], base2, _p(p2)])
				break
	print("CHECKS %d problems" % problems)
	quit(1 if problems else 0)

## collect the road-surface triangles (asphalt / white / yellow) of a street piece's ground mesh into an 8 m grid
func _road_tris(gm: MeshInstance3D, grid: Dictionary) -> void:
	var m := gm.mesh as ArrayMesh
	if m == null: return
	var xf := gm.global_transform
	for si in m.get_surface_count():
		if not (m.surface_get_name(si) in ["asphalt", "white", "yellow"]): continue
		var arr := m.surface_get_arrays(si)
		var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var n := ix.size() if ix.size() > 0 else vv.size()
		for k in range(0, n, 3):
			var p0 := xf * vv[ix[k] if ix.size() > 0 else k]
			var p1 := xf * vv[ix[k + 1] if ix.size() > 0 else k + 1]
			var p2 := xf * vv[ix[k + 2] if ix.size() > 0 else k + 2]
			var a := Vector2(p0.x, p0.z); var b := Vector2(p1.x, p1.z); var c := Vector2(p2.x, p2.z)
			var y := (p0.y + p1.y + p2.y) / 3.0
			var lo := Vector2i(floori(minf(a.x, minf(b.x, c.x)) / 8.0), floori(minf(a.y, minf(b.y, c.y)) / 8.0))
			var hi := Vector2i(floori(maxf(a.x, maxf(b.x, c.x)) / 8.0), floori(maxf(a.y, maxf(b.y, c.y)) / 8.0))
			for cx in range(lo.x, hi.x + 1):
				for cz in range(lo.y, hi.y + 1):
					var key := Vector2i(cx, cz)
					if not grid.has(key): grid[key] = []
					(grid[key] as Array).append([a, b, c, y])

func _report(kind: String, msg: String) -> void:
	problems += 1
	print("CHECK %-8s %s" % [kind, msg])

func _p(v: Vector2) -> String:
	return "(%.1f, %.1f)" % [v.x, v.y]

## oriented rectangles overlap (separating axis test); ang = yaw about Y, half = half extents in local x / z
func _hit(ca: Vector2, ha: Vector2, aa: float, cb: Vector2, hb: Vector2, ab: float) -> bool:
	var axes := [Vector2(cos(aa), -sin(aa)), Vector2(sin(aa), cos(aa)), Vector2(cos(ab), -sin(ab)), Vector2(sin(ab), cos(ab))]
	var d := cb - ca
	for ax: Vector2 in axes:
		var ra := ha.x * absf(Vector2(cos(aa), -sin(aa)).dot(ax)) + ha.y * absf(Vector2(sin(aa), cos(aa)).dot(ax))
		var rb := hb.x * absf(Vector2(cos(ab), -sin(ab)).dot(ax)) + hb.y * absf(Vector2(sin(ab), cos(ab)).dot(ax))
		if absf(d.dot(ax)) > ra + rb: return false
	return true

var _stat_cache := {}
func _stats(name: String) -> Dictionary:
	if _stat_cache.has(name): return _stat_cache[name]
	var out := {}
	for cat in DirAccess.get_directories_at(KIT):
		var p := KIT + cat + "/" + name + "/stats.json"
		if FileAccess.file_exists(p):
			out = JSON.parse_string(FileAccess.get_file_as_string(p)); break
	var pm := "res://assets/coronado_kit/modular/examples/" + name + "/stats.json"
	if out.is_empty() and FileAccess.file_exists(pm): out = JSON.parse_string(FileAccess.get_file_as_string(pm))
	var pc := "res://map_dc/coronado/city_kit/buildings/" + name + "/stats.json"
	if out.is_empty() and FileAccess.file_exists(pc): out = JSON.parse_string(FileAccess.get_file_as_string(pc))
	_stat_cache[name] = out
	return out

## a building mesh embedded in a saved piece: find its kit building by shape (vertex count + bounds of the near mesh)
var _shapes := {}
func _key(m: Mesh) -> String:
	var ab := m.get_aabb()
	return "%d_%.1f_%.1f_%.1f" % [m.surface_get_array_len(0), ab.size.x, ab.size.y, ab.size.z]
func _match(m: Mesh) -> Dictionary:
	if _shapes.is_empty():
		var dirs: Array = []
		for cat in DirAccess.get_directories_at(KIT):
			for b in DirAccess.get_directories_at(KIT + cat): dirs.append(KIT + cat + "/" + b)
		for b in DirAccess.get_directories_at("res://assets/coronado_kit/modular/examples/"): dirs.append("res://assets/coronado_kit/modular/examples/" + b)
		for b in DirAccess.get_directories_at("res://map_dc/coronado/city_kit/buildings/"): dirs.append("res://map_dc/coronado/city_kit/buildings/" + b)
		for d: String in dirs:
			if not FileAccess.file_exists(d + "/stats.json"): continue
			var f := K._tier_file(d, "near")
			if f == "": continue
			var inst: Node = (load(f) as PackedScene).instantiate()
			var mi := K._first_mesh(inst)
			if mi and mi.mesh: _shapes[_key(mi.mesh)] = JSON.parse_string(FileAccess.get_file_as_string(d + "/stats.json"))
			inst.free()
	return _shapes.get(_key(m), {})

## waterfront kit parts that are DESIGNED to touch (kit README snap rules): quay modules, pier sections, floats, fingers,
## piles and gangways join each other; dock boxes, shore-power pedestals, fuel pumps, pier lamps, life rings and the
## seaside railing stand ON those decks. Boats are still checked against all of them.
const WF_STRUCT := ["prop_quay_", "prop_pier_straight", "prop_pier_thead", "prop_pier_rail_end", "prop_marina_float", "prop_marina_finger", "prop_marina_pile", "prop_gangway"]
const WF_DECK := ["prop_dock_box", "prop_marina_pedestal", "prop_fuel_pump", "prop_pier_lamp", "prop_lifering_stand", "prop_prom_rail"]
static func _wf_joined(a: String, b: String) -> bool:
	var sa := WF_STRUCT.any(func(p: String) -> bool: return a.begins_with(p))
	var sb := WF_STRUCT.any(func(p: String) -> bool: return b.begins_with(p))
	var da := WF_DECK.any(func(p: String) -> bool: return a.begins_with(p))
	var db := WF_DECK.any(func(p: String) -> bool: return b.begins_with(p))
	return (sa and sb) or (sa and db) or (da and sb)
