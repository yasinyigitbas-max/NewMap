extends SceneTree
## The things he holds, made into scenes of the lab from the kit (27 Nov, Yasin: "copy the weapons and carry props here
## ... lets just make sure the look correct in player hand"). The lab is its own project and cannot see the kit's
## folders, so each prop is read from its .glb and saved as traversal/props/<name>.scn: its mesh with one shared
## material a page (the kit's atlas pages G, weapons, and J, carry props), and its hand points as child nodes, from
## the kit's own lists (`manifest_weapons.json`; `carry_props.json`): `grip_r`, `grip_l`, and `muzzle` on a gun.
## Run:  godot --headless --path traversal_lab -s res://tools/build_props.gd      (twice, with --import between: the
## first run writes the atlas pictures, the second the scenes)
const OUT := "res://traversal/props/"
const KIT := "../assets/coronado_kit/"
# the carry props taken (of the kit's 21): one of each kind he was asked to carry
const CARRY := ["briefcase_leather", "briefcase_aluminium", "bag_plastic_thankyou", "bag_paper_grocery", "box_moving", "box_ship_small"]


func _abs(rel: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join(rel).simplify_path()


func _mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var m := _mesh(c)
		if m:
			return m
	return null


func _read(path: String, pictures := false) -> MeshInstance3D:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if not pictures:
		st.handle_binary_image = GLTFState.HANDLE_BINARY_DISCARD_TEXTURES       # (the pictures are read once a page, not for every prop)
	if doc.append_from_file(path, st) != OK:
		print("cannot read ", path)
		return null
	return _mesh(doc.generate_scene(st))


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var weapons: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_abs(KIT + "props/manifest_weapons.json")))
	var carry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_abs("../map_dc/coronado/city_kit/carry/scenes/carry_props.json")))
	var jobs: Array = []        # [name, glb, page, {point: [x, y, z]}, hold]
	for w: String in weapons:
		var d: Dictionary = weapons[w]
		var pts: Dictionary = (d["grips"]["points"] as Dictionary).duplicate()
		if d.has("muzzle"):
			pts["muzzle"] = d["muzzle"]
		jobs.append([w, _abs(KIT + "props/weapons/%s_clean_near.glb" % String(d["file_base"])), "g", pts, String(d["grips"]["hold"])])
	for c: String in CARRY:
		var d2: Dictionary = carry[c]
		jobs.append([c, _abs(KIT + "props/indoor/carry/prop_%s_clean_near.glb" % c), "j", d2["grips"], String(d2["hold"])])
	# 1. the atlas pictures, once a page
	var wrote := false
	var first := {}
	for j: Array in jobs:
		if first.has(j[2]):
			continue
		first[j[2]] = true
		if FileAccess.file_exists(OUT + "props_%s_color.jpg" % j[2]):
			continue
		var mi := _read(j[1], true)
		var mat := mi.mesh.surface_get_material(0) as BaseMaterial3D
		for part: Array in [["color", mat.albedo_texture], ["normal", mat.normal_texture], ["orm", mat.roughness_texture]]:
			if part[1] == null:
				continue
			var img: Image = (part[1] as Texture2D).get_image()
			if img.is_compressed():
				img.decompress()
			if part[0] == "normal":
				img.save_png(OUT + "props_%s_normal.png" % j[2])
			else:
				img.convert(Image.FORMAT_RGB8)
				img.save_jpg(OUT + "props_%s_%s.jpg" % [j[2], part[0]], 0.92)
		wrote = true
	if wrote:
		print("atlas pictures written: run --import, then this tool again")
		quit(0)
		return
	# 2. one material a page, and the scenes
	var mats := {}
	var list := {}
	for j: Array in jobs:
		var mi := _read(j[1])
		if mi == null:
			continue
		if not mats.has(j[2]):
			var m := StandardMaterial3D.new()
			m.albedo_texture = load(OUT + "props_%s_color.jpg" % j[2])
			if FileAccess.file_exists(OUT + "props_%s_normal.png" % j[2]):
				m.normal_enabled = true
				m.normal_texture = load(OUT + "props_%s_normal.png" % j[2])
			if FileAccess.file_exists(OUT + "props_%s_orm.jpg" % j[2]):
				var orm: Texture2D = load(OUT + "props_%s_orm.jpg" % j[2])
				m.ao_enabled = true
				m.ao_texture = orm
				m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
				m.roughness_texture = orm
				m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
				m.metallic = 1.0
				m.metallic_texture = orm
				m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
			ResourceSaver.save(m, OUT + "props_%s.material" % j[2])
			mats[j[2]] = load(OUT + "props_%s.material" % j[2])
		var top := Node3D.new()
		top.name = String(j[0])
		var show := MeshInstance3D.new()
		show.name = "Mesh"
		show.mesh = mi.mesh
		show.transform = mi.transform
		show.mesh.surface_set_material(0, mats[j[2]])
		top.add_child(show)
		show.owner = top
		for p: String in (j[3] as Dictionary):
			if j[3][p] == null:
				continue                # (a one-handed weapon has no second hand point)
			var at := Node3D.new()
			at.name = p
			var v: Array = j[3][p]
			at.position = Vector3(float(v[0]), float(v[1]), float(v[2]))
			top.add_child(at)
			at.owner = top
		top.set_meta(&"hold", j[4])
		var ps := PackedScene.new()
		ps.pack(top)
		var err := ResourceSaver.save(ps, OUT + "%s.scn" % String(j[0]), ResourceSaver.FLAG_COMPRESS)
		var bb := show.mesh.get_aabb()
		list[String(j[0])] = {"hold": j[4], "size": [snappedf(bb.size.x, 0.001), snappedf(bb.size.y, 0.001), snappedf(bb.size.z, 0.001)]}
		print("%-22s %-16s saved %d  size %s  points %s" % [j[0], j[4], err, str(bb.size.snappedf(0.001)), str((j[3] as Dictionary).keys())])
	var f := FileAccess.open(OUT + "props.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(list, "  "))
	quit(0)
