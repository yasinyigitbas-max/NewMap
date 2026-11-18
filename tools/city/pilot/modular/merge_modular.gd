extends SceneTree
## Merge a modular assembly (layout.json: kit pieces from assets/coronado_kit/modular/pieces placed on the 0.5 m grid)
## into ONE city-kit building: <name>_{near,mid,far,col}.scn + stats.json in map_dc/coronado/city_kit/buildings/<name>/.
## Same idea as the kit's merge_assembly.py (one mesh, one material per tier: 1 draw per tier), done in Godot because
## the kit's Python build tools are not in this repository. The far tier merges the pieces' own far tiers (no
## stretched hull texture). Collision: one box over the outline.
## Run: godot --path PV -s res://tools/city/pilot/modular/merge_modular.gd -- res://tools/city/pilot/modular/<name>.json
const PIECES := "res://assets/coronado_kit/modular/pieces/"
const OUT := "res://map_dc/coronado/city_kit/buildings/"

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var path := ""
	for a in OS.get_cmdline_user_args(): path = a
	var L: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var name := String(L.name); var g := String(L.group)
	var dir := OUT + name + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var tris := {}
	for tier: String in ["near", "mid", "far"]:
		var st := SurfaceTool.new(); var mat: Material = null; var n_ok := 0
		var items: Array = L.pieces
		if tier == "far" and L.has("far_tiles"):
			# far: a grid of an existing example's far hull (a few dozen triangles) instead of every piece's far tier
			var ft: Dictionary = L.far_tiles; items = []
			var sz := float(ft.size)
			for ix in int(ft.nx):
				for iz in int(ft.nz):
					items.append({"piece": (String(ft.example) if String(ft.example).begins_with("@") else "@" + String(ft.example)), "x": (ix - (int(ft.nx) - 1) * 0.5) * sz, "z": (iz - (int(ft.nz) - 1) * 0.5) * sz, "rot_y": 0})
		for it: Dictionary in items:
			var pn := String(it.piece); var grp := String(it.get("group", g))
			var f := PIECES + grp + "/" + pn + "/mod_" + pn + "_" + tier + ".glb"
			if pn.begins_with("@map:"): f = "res://assets/coronado_kit/modular/examples_map/%s/mod_%s_%s.glb" % [pn.substr(5), pn.substr(5), tier]
			elif pn.begins_with("@"): f = "res://assets/coronado_kit/modular/examples/%s/mod_%s_%s.glb" % [pn.substr(1), pn.substr(1), tier]
			if not ResourceLoader.exists(f): continue
			var inst: Node = (load(f) as PackedScene).instantiate()
			var mi := _first_mesh(inst)
			if mi and mi.mesh:
				var t := Transform3D(Basis(Vector3.UP, deg_to_rad(float(it.rot_y))), Vector3(float(it.x), float(it.get("y", 0.0)), float(it.z))) * mi.transform
				for s in mi.mesh.get_surface_count():
					if mat == null: mat = mi.mesh.surface_get_material(s)
					st.append_from(mi.mesh, s, t)
				n_ok += 1
			inst.free()
		if n_ok == 0: continue
		var m := st.commit()
		if mat: m.surface_set_material(0, mat)
		tris[tier] = m.surface_get_array_index_len(0) / 3 if m.get_surface_count() > 0 else 0
		_save_mesh(m, dir + name + "_" + tier + ".scn")
	var W := float(L.outline.W); var D := float(L.outline.D)
	var H := float(L.outline.get("floor", 0.0)) + float(L.outline.get("storey", 6.6)) * float(L.outline.get("storeys", 1)) + float(L.outline.get("parapet", 0.8))
	var box := BoxMesh.new(); box.size = Vector3(W, H, D)
	var cm := MeshInstance3D.new(); cm.mesh = box; cm.position = Vector3(0, H * 0.5, 0)
	var holder := Node3D.new(); holder.name = name + "_col"; holder.add_child(cm); cm.owner = holder
	var ps := PackedScene.new(); ps.pack(holder); ResourceSaver.save(ps, dir + name + "_col.scn"); holder.free()
	# doors on the front (pieces at rot 0): from each piece's own openings (door kinds only), unless the layout says
	var doors: Array = L.get("doors_front", [])
	if doors.is_empty():
		for it: Dictionary in L.pieces:
			if int(it.rot_y) != 0: continue
			var sp := PIECES + String(it.get("group", g)) + "/" + String(it.piece) + "/stats.json"
			if not FileAccess.file_exists(sp): continue
			var pst: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sp))
			for o: Dictionary in pst.get("openings", []):
				if String(o.k) in ["apt_door", "shopdoor", "civic_door", "rollup"] and float(it.z) > 0.0 and float(o.get("t0", 0.0)) < 0.8:   # ground floor only
					doors.append([String(o.k), float(it.x) + float(o.c)])
	var stats := {"name": name, "cat": "mod", "footprint_wd": [W, D], "height": H, "tris": tris,
		"doors_front": doors, "merged_from": path.get_file()}
	var fo := FileAccess.open(dir + "stats.json", FileAccess.WRITE); fo.store_string(JSON.stringify(stats, " ")); fo.close()
	print("merge_modular %s: tris %s" % [name, tris])
	quit()

func _save_mesh(m: Mesh, p: String) -> void:
	var mi := MeshInstance3D.new(); mi.name = p.get_file().get_basename(); mi.mesh = m
	var ps := PackedScene.new(); ps.pack(mi); ResourceSaver.save(ps, p); mi.free()

func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _first_mesh(c)
		if r: return r
	return null
