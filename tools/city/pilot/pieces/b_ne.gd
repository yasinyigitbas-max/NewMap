extends SceneTree
## Piece b_ne: downtown block east of Amber, north of 10th (x 16..50, z -97.5..-9.7). Run once; never when locked.
## Spanish arcade (corner), the village theatre mid-block (the street's landmark, bus stop in front), Orange arcade,
## brick row. On 10th: the corner's side, then a small bookshop. Behind: parking, dumpster behind the arcade's cafe,
## the theatre's stage door side kept clear, alley poles.
const B := preload("res://tools/city/pilot/pieces/block_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var root := Node3D.new(); root.name = "b_ne"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	B.begin(root.name)
	var g := K.Ground.new(); var props := K.Props.new()
	var z := -S.T_BLD
	for f: String in ["commercial/com_spanish_arcade_block", "landmarks/lmk_village_theatre", "commercial/com_orange_arcade_block", "urban/urb_brick_row"]:
		var r := B.on_amber(bl, f, 1.0, S.A_BLD, z)
		if f.ends_with("spanish_arcade_block"): B.door_pots(props, r[0], f)
		z -= float(r[1])
	B.on_tenth(bl, "commercial/com_shallow_books", 1.0, -S.T_BLD, 37.0)
	props.add("prop_park_bench", "worn", Vector3(S.A_BLD - 0.35, S.walk_y(0.0), -62.7), -90.0)   # Orange arcade, between its doors (frontage furniture lives with the block)
	B.rear_lot(g, S.A_BLD, S.ALLEY_E[0], -S.T_BLD, -97.5)
	B.alley(g, S.ALLEY_E[0], S.ALLEY_E[1], -S.T_BLD, -97.5)
	props.add("prop_dumpster_3yd_green", "worn", Vector3(34.0, S.walk_y(34.0), -22.0), 90.0)     # arcade cafe
	props.add("prop_dumpster_3yd_blue", "worn", Vector3(35.0, S.walk_y(35.0), -64.0), 90.0)      # Orange arcade shops
	props.add("prop_recycling_receptacle", "worn", Vector3(35.0, S.walk_y(35.0), -66.0), 90.0)
	props.add("prop_ac_condenser", "worn", Vector3(32.8, S.walk_y(32.8), -30.0), 90.0)
	for zp: float in [-20.0, -53.0, -86.0]:
		props.add("prop_utility_pole_transformer" if zp == -86.0 else "prop_utility_pole", "worn", Vector3(S.ALLEY_E[0] + 0.4, S.walk_y(S.ALLEY_E[0]), zp), 0.0)
	props.add("prop_lot_light_pole", "worn", Vector3(38.0, S.walk_y(38.0), -78.0), 0.0)
	# a utility crew is working on the transformer pole: cones round its foot, a barricade toward the alley traffic
	for k in 6:
		var a := TAU * k / 6.0
		props.add("prop_cone_28in", "worn", Vector3(S.ALLEY_E[0] + 0.4 + cos(a) * 1.7, S.walk_y(44.0), -86.0 + sin(a) * 1.7), k * 40.0)
	props.add("prop_barricade_type1", "worn", Vector3(S.ALLEY_E[0] + 3.4, S.walk_y(46.0), -86.0), 90.0)
	B.finish(root, g, props, "b_ne")
	quit()
