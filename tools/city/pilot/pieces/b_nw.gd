extends SceneTree
## Piece b_nw: downtown block west of Amber, north of 10th (x -50..-16, z -97.5..-9.7). Run once; never when locked.
## Street wall on Amber (zero setback): brick corner (4 storeys), Orange row, bakery, Crown bar, brick row (3), surf
## shop, realty. On 10th: corner building's side, then a small cafe. Behind: customer parking off the alley,
## dumpsters only behind the food places (bakery, bar, cafe), alley utility poles (wires stay off the main street).
const B := preload("res://tools/city/pilot/pieces/block_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var root := Node3D.new(); root.name = "b_nw"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	B.begin(root.name)
	var g := K.Ground.new(); var props := K.Props.new()
	var z := -S.T_BLD
	var backs: Array = []
	for f: String in ["urban/urb_brick_corner", "commercial/com_orange_row", "commercial/com_bakery", "commercial/com_bar_crown", "urban/urb_brick_row", "commercial/com_surf_shop", "commercial/com_realty"]:
		var r := B.on_amber(bl, f, -1.0, -S.A_BLD, z)
		if f.ends_with("bakery") or f.ends_with("bar_crown"): B.door_pots(props, r[0], f)
		backs.append([z, z - float(r[1]), -S.A_BLD - float(r[2]), f])
		z -= float(r[1])
	var cafe := B.on_tenth(bl, "commercial/com_shallow_cafe", 1.0, -S.T_BLD, -37.75)
	B.door_pots(props, cafe[0], "commercial/com_shallow_cafe")
	props.add("prop_park_bench", "worn", Vector3(-39.8, S.walk_y(0.0), -S.T_BLD + 0.35), 0.0)   # against the cafe wall beside its door
	# ground: one service lot behind the frontage (stalls along the alley), the alley itself
	B.rear_lot(g, -S.A_BLD, S.ALLEY_W[1], -S.T_BLD, -97.5)
	B.alley(g, S.ALLEY_W[0], S.ALLEY_W[1], -S.T_BLD, -97.5)
	# back of house: a dumpster behind each food place, against its back wall, lid toward the lot
	for b: Array in backs:
		var f: String = b[3]
		if f.ends_with("bakery") or f.ends_with("bar_crown"):
			var zc := (float(b[0]) + float(b[1])) * 0.5
			props.add("prop_dumpster_3yd_green", "worn", Vector3(float(b[2]) - 1.0, S.walk_y(0.0), zc), -90.0)
	props.add("prop_dumpster_3yd_blue", "worn", Vector3(-38.0, S.walk_y(0.0), -18.5), 180.0)       # behind the cafe
	for k in 2: props.add("fence_graffiti_cmu_panel", "worn", Vector3(-41.0 + k * 2.0, S.walk_y(0.0), -20.3), 0.0)   # bin enclosure wall, tagged
	props.add("prop_recycling_receptacle", "worn", Vector3(-36.2, S.walk_y(0.0), -18.6), 180.0)
	# AC condensers on the ground behind the brick buildings (rooftop units are in the models)
	props.add("prop_ac_condenser", "worn", Vector3(-33.2, S.walk_y(0.0), -24.0), -90.0)
	props.add("prop_ac_condenser", "worn", Vector3(-31.2, S.walk_y(0.0), -70.0), -90.0)
	# utility poles on the block side of the alley, every 33 m, one with the transformer that feeds the row
	for zp: float in [-20.0, -53.0, -86.0]:
		props.add("prop_utility_pole_transformer" if zp == -53.0 else "prop_utility_pole", "worn", Vector3(S.ALLEY_W[1] - 0.4, S.walk_y(0.0), zp), 0.0)
	props.add("prop_lot_light_pole", "worn", Vector3(-38.0, S.walk_y(0.0), -60.0), 0.0)          # lights the rear lot at night
	B.finish(root, g, props, "b_nw")
	quit()
