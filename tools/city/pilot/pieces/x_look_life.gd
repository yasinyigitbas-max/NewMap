extends SceneTree
## x_look_life (look uplift, 28 Nov; Yasin: "go for both 15 and 16"): the junctions' own wear and the empty lots' life as an
## overlay piece in the grid frame, so no locked piece changes. Every line is chosen by hand, with its reason, in
## map_dc/coronado/city_kit/zoning/look_life.json: {"kind": "prop", "model": "<folder>/<prop>_<variant>", "pos", "yaw",
## "why"} (assets/coronado_kit/props/<model>_near.glb, collision <prop>_col.glb) or {"kind": "decal", "tile", "pos",
## "yaw", "w", "l", "alpha", "why"} (kit_lib Decals, the photo atlas the pieces' wear uses). Not a generator: it decides
## nothing, it builds the list. Placed at [0, 0, 0] (a layout row). Rebuild after editing the list:
##   godot --headless --path . -s res://tools/city/pilot/pieces/x_look_life.gd
const K := preload("res://tools/city/pilot/kit_lib.gd")
const P := "res://assets/coronado_kit/props/"

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/zoning/look_life.json"))
	var root := Node3D.new(); root.name = "x_look_life"
	var props := Node3D.new(); props.name = "Props"; root.add_child(props)
	var body := StaticBody3D.new(); body.name = "PropCol"; props.add_child(body)
	var by := {}
	var dec := K.Decals.new(); var nd := 0
	for it: Dictionary in j.items:
		var p: Array = it.pos
		if String(it.kind) == "decal":
			var y := float(p[1])
			dec.add(int(it.tile), Vector2(float(p[0]), float(p[2])), float(it.yaw), float(it.w), float(it.l), func(_x: float, _z: float) -> float: return y, Color(1, 1, 1, float(it.alpha)))
			nd += 1
		else:
			var m := String(it.model)
			if not by.has(m): by[m] = []
			by[m].append(Transform3D(Basis(Vector3.UP, deg_to_rad(float(it.yaw))), Vector3(float(p[0]), float(p[1]), float(p[2]))))
	var np := 0
	for m: String in by:
		var inst: Node = (load(P + m + "_near.glb") as PackedScene).instantiate()
		var src: MeshInstance3D = K._first_mesh(inst)
		var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = src.mesh
		var ts: Array = by[m]; mm.instance_count = ts.size()
		for i in ts.size(): mm.set_instance_transform(i, (ts[i] as Transform3D) * src.transform)
		var mmi := MultiMeshInstance3D.new(); mmi.multimesh = mm; mmi.name = m.get_file() + "_near"
		mmi.visibility_range_end = 80.0; mmi.visibility_range_end_margin = 2.0
		props.add_child(mmi); inst.free()
		var base := m.get_base_dir() + "/" + m.get_file().rsplit("_", true, 1)[0]      # (the variant off: one collision per prop)
		if ResourceLoader.exists(P + base + "_col.glb"):
			var ci: Node = (load(P + base + "_col.glb") as PackedScene).instantiate()
			var cm: MeshInstance3D = K._first_mesh(ci)
			var sh: ConcavePolygonShape3D = cm.mesh.create_trimesh_shape(); sh.backface_collision = true
			for t: Transform3D in ts:
				var cs := CollisionShape3D.new(); cs.shape = sh; cs.transform = t * cm.transform; body.add_child(cs)
			ci.free()
		np += ts.size()
	if nd > 0:
		var dm := dec.build(); dm.name = "Wear"; root.add_child(dm)
	print("x_look_life props=%d decals=%d" % [np, nd])
	K.save_piece(root, "x_look_life")
	quit()
