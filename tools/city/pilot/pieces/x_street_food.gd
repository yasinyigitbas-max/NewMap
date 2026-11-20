extends SceneTree
## x_street_food (20 Nov, Yasin: "THERE ARE NEW ASSETS THERE, ONE PASSENGER FERRY, AND STREET FOOD KIOSKS, ADD THEM INTO
## THE GAME, RANDOMLY PLACED AROUND THE MAP AT THE LOGICAL LOCATIONS, LIKE SEA SIDE, CORNER OF SOME STREETS, NEAR CAMPUS
## ETC."): the street-food kiosks (assets/coronado_kit/props/kiosks) and the passenger ferry (vehicles/ferry) as an
## overlay piece in the grid frame, so no locked piece changes. Every spot is chosen by hand, with its reason, in
## map_dc/coronado/city_kit/zoning/street_food.json ({"items": [{"kind", "pos": [x, y, z], "yaw", "why"}]}; y = the
## paved ground under it, or the waterline for the ferry; yaw turns the model's front (+Z) to face the customers).
## Tiers as the kit's props (near 0-62 m, mid 58-222 m, far 218 m on); the ferry keeps its near model to 120 m and its
## mid one to 900 m (it is seen across the bay). Collision: each model's _col.glb as it is (true shape, both sides).
## Placed at [0, 0, 0] in the grid frame (integrate.py lists it). Rebuild after editing the list:
##   godot --headless --path . -s res://tools/city/pilot/pieces/x_street_food.gd
const K := preload("res://tools/city/pilot/kit_lib.gd")
const KIOSK := "res://assets/coronado_kit/props/kiosks/prop_kiosk_%s_%s.glb"
const FERRY := "res://assets/coronado_kit/vehicles/ferry/veh_ferry_passenger_%s.glb"
const KINDS := ["hotdog_cart", "paleta_cart", "taco_stand", "shaveice_shack", "lemonade_stand", "ferry"]

func _init() -> void: _run.call_deferred()

func _file(kind: String, tier: String) -> String:
	return FERRY % tier if kind == "ferry" else KIOSK % [kind, tier]

func _run() -> void:
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/zoning/street_food.json"))
	var by := {}
	for it: Dictionary in j.items:
		var kind := String(it.kind)
		assert(KINDS.has(kind), "unknown kind " + kind)
		if not by.has(kind): by[kind] = []
		var p: Array = it.pos
		by[kind].append(Transform3D(Basis(Vector3.UP, deg_to_rad(float(it.yaw))), Vector3(float(p[0]), float(p[1]), float(p[2]))))
	var root := Node3D.new(); root.name = "x_street_food"
	var props := Node3D.new(); props.name = "Props"; root.add_child(props)
	var body := StaticBody3D.new(); body.name = "PropCol"; props.add_child(body)
	var n := 0
	for kind: String in by:
		var ferry := kind == "ferry"
		var ranges := {"near": [0.0, 120.0 if ferry else 62.0], "mid": [115.0 if ferry else 58.0, 900.0 if ferry else 222.0], "far": [218.0, 1500.0]}
		for tier: String in (["near", "mid"] if ferry else ["near", "mid", "far"]):
			var inst: Node = (load(_file(kind, tier)) as PackedScene).instantiate()
			var src: MeshInstance3D = K._first_mesh(inst)
			var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = src.mesh
			var ts: Array = by[kind]; mm.instance_count = ts.size()
			for i in ts.size(): mm.set_instance_transform(i, (ts[i] as Transform3D) * src.transform)
			var mmi := MultiMeshInstance3D.new(); mmi.multimesh = mm
			mmi.name = ("veh_ferry_passenger_%s" if ferry else "prop_kiosk_" + kind + "_%s") % tier
			mmi.visibility_range_begin = ranges[tier][0]; mmi.visibility_range_end = ranges[tier][1]; mmi.visibility_range_end_margin = 2.0
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if tier == "near" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			props.add_child(mmi)
			inst.free()
		var ci: Node = (load(_file(kind, "col")) as PackedScene).instantiate()
		var cm: MeshInstance3D = K._first_mesh(ci)
		var sh: ConcavePolygonShape3D = cm.mesh.create_trimesh_shape(); sh.backface_collision = true
		for t: Transform3D in by[kind]:
			var cs := CollisionShape3D.new(); cs.shape = sh; cs.transform = t * cm.transform; body.add_child(cs); n += 1
		ci.free()
	print("x_street_food items=%d kinds=%s" % [n, str(by.keys())])
	K.save_piece(root, "x_street_food")
	quit()
