extends SceneTree
## x_look_life (look uplift, 28 Nov; Yasin: "go for both 15 and 16"): the junctions' own wear and the empty lots' life as an
## overlay piece in the grid frame, so no locked piece changes. Every line is chosen by hand, with its reason, in
## map_dc/coronado/city_kit/zoning/look_life.json: {"kind": "prop", "model": "<folder>/<prop>_<variant>", "pos", "yaw",
## "why"} (assets/coronado_kit/props/<model>_near.glb, collision <prop>_col.glb) or {"kind": "decal", "tile", "pos",
## "yaw", "w", "l", "alpha", "why"} (kit_lib Decals, the photo atlas the pieces' wear uses). Not a generator: it decides
## nothing, it builds the list. Placed at [0, 0, 0] (a layout row). Rebuild after editing the list:
##   godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/pilot/pieces/x_look_life.gd
## NEVER --headless: its dummy renderer drops every MultiMesh instance transform (all props saved at 0, 0, 0)
const K := preload("res://tools/city/pilot/kit_lib.gd")
const P := "res://assets/coronado_kit/props/"

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/zoning/look_life.json"))
	var root := Node3D.new(); root.name = "x_look_life"
	# (props through kit_lib's own Props: the kit's tiers, its worn material and its colliders, as every piece places
	# them; the first build copied only the meshes and the bake did not take them as kit props)
	var props := K.Props.new()
	var dec := K.Decals.new(); var nd := 0
	for it: Dictionary in j.items:
		var p: Array = it.pos
		if String(it.kind) == "decal":
			var y := float(p[1])
			dec.add(int(it.tile), Vector2(float(p[0]), float(p[2])), float(it.yaw), float(it.w), float(it.l), func(_x: float, _z: float) -> float: return y, Color(1, 1, 1, float(it.alpha)))
			nd += 1
		else:
			var m := String(it.model).get_file()      # <prop>_<condition>
			var cond := m.rsplit("_", true, 1)[1]; var base := m.rsplit("_", true, 1)[0]
			props.add(base, cond, Vector3(float(p[0]), float(p[1]), float(p[2])), float(it.yaw))
	var np := props.count()
	props.build(root, K)
	if nd > 0:
		var dm := dec.build(); dm.name = "Wear"; root.add_child(dm)
	print("x_look_life props=%d decals=%d" % [np, nd])
	K.save_piece(root, "x_look_life")
	quit()
