extends SceneTree
## Piece b_se: downtown block east of Amber, south of 10th (x 16..50, z 9.7..97.5). Run once; never when locked.
## Post office on the corner, set back 4 m behind a paved forecourt (benches, bike rack, planters either side of the
## door, the entrance axis kept clear); boutique row; department store (the block's anchor, loading dock to the
## alley); seaside cafe. A news kiosk faces 10th. Behind: parking, dumpsters behind the cafe and the store dock.
const B := preload("res://tools/city/pilot/pieces/block_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var root := Node3D.new(); root.name = "b_se"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	B.begin(root.name)
	var g := K.Ground.new(); var props := K.Props.new()
	# post office: front 4 m behind the building line, starting 4 m back from the 10th building line
	var po := B.on_amber(bl, "civic/civ_post_office", 1.0, S.A_BLD + 4.0, S.T_BLD + 4.0)
	var zpo := S.T_BLD + 4.0 + float(po[1]) * 0.5       # entrance axis
	var z := S.T_BLD + 4.0 + float(po[1])
	for f: String in ["commercial/com_boutique_row", "urban/urb_dept_store", "commercial/com_cafe_seaside"]:
		var r := B.on_amber(bl, f, 1.0, S.A_BLD, z)
		if f.ends_with("cafe_seaside"): B.door_pots(props, r[0], f)
		z += float(r[1])
	B.on_tenth(bl, "commercial/com_kiosk", -1.0, S.T_BLD, 39.5)
	# forecourt paving: along Amber in front of the post office, and along 10th beside it
	g.rect("paving", S.A_BLD, S.T_BLD, S.A_BLD + 4.0, S.T_BLD + 4.0 + float(po[1]), S.walk_y)
	g.rect("paving", S.A_BLD + 4.0, S.T_BLD, S.A_BLD + 4.0 + float(po[2]), S.T_BLD + 4.0, S.walk_y)
	B.rear_lot(g, S.A_BLD + 4.0 + float(po[2]), S.ALLEY_E[0], S.T_BLD, S.T_BLD + 4.0 + float(po[1]), false)
	B.rear_lot(g, S.A_BLD, S.ALLEY_E[0], S.T_BLD + 4.0 + float(po[1]), 97.5)
	B.alley(g, S.ALLEY_E[0], S.ALLEY_E[1], S.T_BLD, 97.5)
	# forecourt: planters flank the door, benches face Amber off the axis, a bike rack by the 10th side
	props.add("plant_potted_leafy", "normal", Vector3(S.A_BLD + 3.2, S.walk_y(0.0), zpo - 2.2), 0.0)
	props.add("plant_potted_leafy", "normal", Vector3(S.A_BLD + 3.2, S.walk_y(0.0), zpo + 2.2), 0.0)
	props.add("prop_park_bench", "worn", Vector3(S.A_BLD + 3.3, S.walk_y(0.0), zpo - 6.5), -90.0)
	props.add("prop_park_bench", "worn", Vector3(S.A_BLD + 3.3, S.walk_y(0.0), zpo + 6.5), -90.0)
	props.add("prop_bike_rack", "worn", Vector3(S.A_BLD + 6.0, S.walk_y(0.0), S.T_BLD + 2.0), 0.0)
	props.add("prop_trash_receptacle", "worn", Vector3(S.A_BLD + 3.3, S.walk_y(0.0), zpo + 9.0), 0.0)
	props.add("hedge_boxwood_low_2m", "normal", Vector3(S.A_BLD + 0.4, S.walk_y(0.0), S.T_BLD + 5.5), 90.0)
	props.add("hedge_boxwood_low_2m", "normal", Vector3(S.A_BLD + 0.4, S.walk_y(0.0), S.T_BLD + 4.0 + float(po[1]) - 1.5), 90.0)
	# back of house
	props.add("prop_dumpster_rolloff_20yd", "worn", Vector3(42.0, S.walk_y(42.0), 70.0), 0.0)     # store loading dock
	props.add("prop_dumpster_3yd_green", "worn", Vector3(32.0, S.walk_y(32.0), 92.5), 90.0)        # cafe
	props.add("prop_ac_condenser", "worn", Vector3(36.0, S.walk_y(36.0), 30.0), 90.0)   # behind the post office
	for zp: float in [20.0, 53.0, 86.0]:
		props.add("prop_utility_pole_transformer" if zp == 53.0 else "prop_utility_pole", "worn", Vector3(S.ALLEY_E[0] + 0.4, S.walk_y(S.ALLEY_E[0]), zp), 0.0)
	B.finish(root, g, props, "b_se")
	quit()
