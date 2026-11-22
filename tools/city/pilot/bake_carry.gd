extends SceneTree
## Carry props (page J, Yasin 22 Nov): bake each kit carry prop (assets/coronado_kit/props/indoor/carry, export-excluded
## like every kit source glb) into a runtime scene the game ships: map_dc/coronado/city_kit/carry/scenes/<name>.scn.
## A scene = Node3D <name> > MeshInstance3D "mesh" (mesh embedded, the kit prop shader at the indoor "clean" wear,
## materials/pw_props_j_color_clean_20.tres as page-I props get pw_props_i_*), Marker3D "grip_r" / "grip_l" (hand attach
## points: +X along the handle bar, +Y up; boxes and crates: grip_l on the -X face, grip_r on +X). Meta: hold
## ("one_hand_hang" / "two_hand_sides"), tris, col (AABB of the kit col box). Plus carry/scenes/carry_props.json (index).
## Run: godot --headless --path . -s res://tools/city/pilot/bake_carry.gd
const K := preload("res://tools/city/pilot/kit_lib.gd")
const SRC := "res://assets/coronado_kit/props/indoor/carry/"
const MAN := "res://assets/coronado_kit/props/manifest_incarry.json"
const OUT := "res://map_dc/coronado/city_kit/carry/scenes/"
const WEAR := 0.2     # room_lib PROP_WEAR: the kit's "clean" condition
func _init() -> void: _run.call_deferred()
func _find(n: Node, nm: String) -> Node:
	if n.name == nm: return n
	for c in n.get_children():
		var r := _find(c, nm)
		if r: return r
	return null
func _xf(n: Node3D, root: Node) -> Transform3D:
	var t := n.transform; var p := n.get_parent()
	while p and p != root:
		if p is Node3D: t = (p as Node3D).transform * t
		p = p.get_parent()
	return t
func _run() -> void:
	var man: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAN))
	DirAccess.make_dir_recursive_absolute(OUT)
	var index := {}; var bad := 0
	var names: Array = man.keys(); names.sort()
	for name: String in names:
		var e: Dictionary = man[name]
		var near := SRC + "prop_%s_clean_near.glb" % name
		if not ResourceLoader.exists(near): print("CARRY missing ", near); bad += 1; continue
		var inst: Node = (load(near) as PackedScene).instantiate()
		var src: MeshInstance3D = K._first_mesh(inst)
		var root := Node3D.new(); root.name = name
		var mi := MeshInstance3D.new(); mi.name = "mesh"; root.add_child(mi); mi.owner = root
		var mesh: ArrayMesh = src.mesh.duplicate(true)    # embedded: the kit glb is not exported
		mesh.resource_path = ""
		mi.mesh = mesh; mi.transform = _xf(src, inst)
		var wm: Material = K.prop_wear_mat(mesh.surface_get_material(0), WEAR)
		mi.material_override = wm
		var grips := {}
		for g: String in ["grip_r", "grip_l"]:
			var gn: Node3D = _find(inst, g)
			if gn == null: print("CARRY no ", g, " on ", name); bad += 1; continue
			var mk := Marker3D.new(); mk.name = g; mk.transform = _xf(gn, inst); root.add_child(mk); mk.owner = root
			grips[g] = [mk.position.x, mk.position.y, mk.position.z]
		var aabb := mesh.get_aabb()
		var col := SRC + "prop_%s_col.glb" % name
		if ResourceLoader.exists(col):
			var ci: Node = (load(col) as PackedScene).instantiate()
			var cm: MeshInstance3D = K._first_mesh(ci)
			if cm: aabb = _xf(cm, ci) * cm.mesh.get_aabb()
			ci.free()
		var tris := 0
		for s in mesh.get_surface_count():
			var a := mesh.surface_get_arrays(s)
			tris += (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if a[Mesh.ARRAY_INDEX] != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		var hold: String = (e.get("grips", {}) as Dictionary).get("hold", "one_hand_hang")
		root.set_meta(&"hold", hold); root.set_meta(&"tris", tris); root.set_meta(&"col", aabb)
		var ps := PackedScene.new(); ps.pack(root)
		var path := OUT + name + ".scn"
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		var err := ResourceSaver.save(ps, path, ResourceSaver.FLAG_COMPRESS)
		if err != OK: print("CARRY save failed ", path, " ", err); bad += 1
		index[name] = {"scene": path, "hold": hold, "tris": tris, "budget": e.get("budget", 0), "grips": grips,
			"col": [aabb.position.x, aabb.position.y, aabb.position.z, aabb.size.x, aabb.size.y, aabb.size.z]}
		print("CARRY %s tris %d hold %s grips %s" % [name, tris, hold, str(grips)])
		root.free(); inst.free()
	var jp := OUT + "carry_props.json"
	if FileAccess.file_exists(jp): DirAccess.remove_absolute(ProjectSettings.globalize_path(jp))
	var f := FileAccess.open(jp, FileAccess.WRITE); f.store_string(JSON.stringify(index, " ", true)); f.close()
	print("CARRY baked %d, problems %d" % [index.size(), bad])
	quit(1 if bad else 0)
