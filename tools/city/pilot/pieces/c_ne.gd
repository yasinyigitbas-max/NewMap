extends SceneTree
## Piece c_ne (city centre sample, NE corner). The corner is a public plaza in front of the glass tower: the tower faces
## the plaza, not the traffic. Plaza: an obelisk as the focal point on the axis of the tower door, ficus trees in
## wells for shade, shade sails over the seating, planters, benches facing the obelisk, bike racks, globe lamps,
## steel bollards on the street edges (keeps cars off a big paved space), news boxes where office workers pass.
## Then the hotel (its kitchen court behind), and a brick corner block with apartments over the alley.
## Run once; never when locked.
const C := preload("res://tools/city/pilot/pieces/cc_lib.gd")
const B := preload("res://tools/city/pilot/pieces/block_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const PZ := 23.7      # plaza depth along Amber (from the 10th building line)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "c_ne"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	B.begin("c_ne"); var g := K.Ground.new(); var props := K.Props.new()
	C.floor(g, 1.0, -1.0, [[S.A_BLD, -PZ, S.ALLEY_E[0], -S.T_BLD, "paving"]])
	# the glass tower stands north of the plaza and faces it (front toward +z, the junction), 24 x 24, west side on Amber
	B.on_tenth(bl, "urban/twr_glass", 1.0, -PZ, S.A_BLD + 12.0)
	var z := -PZ - 24.0
	for f: String in ["urban/twr_hotel", "urban/urb_brick_corner"]:
		var r := B.on_amber(bl, f, 1.0, S.A_BLD, z); z -= float(r[1])
		if not f.contains("brick"): C.back_of_house(props, r[0], f)   # the brick corner's back wall touches the alley apartments
	# a cafe in the tower's ground floor puts its tables out on the plaza, west of the door
	for tx: float in [20.0, 23.0]:   # under the west shade sail
		props.add("prop_patio_set_4", "worn", Vector3(tx, S.walk_y(0.0), -PZ + 3.4), 0.0)
	props.add("plant_potted_succulent", "normal", Vector3(25.0, S.walk_y(0.0), -PZ + 0.5), 0.0)
	var apt := K.building(bl, "modular/examples/mod_apt_row", Vector3(38.0, S.walk_y(0.0), -86.7), 90.0)
	C.back_of_house(props, apt, "modular/examples/mod_apt_row", true, true)
	# ---- plaza (x 16..44, z -23.7..-9.7): centre on the tower door axis
	var cx := S.A_BLD + 12.0; var cz := (-PZ - S.T_BLD) * 0.5
	props.add("prop_obelisk_monument", "worn", Vector3(cx, S.walk_y(0.0), cz), 0.0)
	for q: Vector2 in [Vector2(cx - 7.0, cz), Vector2(cx + 7.0, cz)]:
		S.tree_well(g, q, 0.9, 0.75)
		props.add("tree_ficus_a" if q.x < cx else "tree_ficus_b", "normal", Vector3(q.x, S.walk_y(0.0) - 0.06, q.y), q.x * 9.0)
	for q2: Vector2 in [Vector2(cx - 6.5, cz - 3.6), Vector2(cx + 6.5, cz - 3.6)]:
		props.add("prop_shade_sail", "worn", Vector3(q2.x, S.walk_y(0.0), q2.y), 0.0)
	for k in 4:   # benches round the obelisk, facing it, under the sails
		var a := TAU * (k + 0.5) / 4.0
		var p := Vector2(cx, cz) + Vector2(cos(a), sin(a)) * 3.6
		props.add("prop_park_bench", "worn", Vector3(p.x, S.walk_y(0.0), p.y), rad_to_deg(atan2(cx - p.x, cz - p.y)))
	for px: float in [S.A_BLD + 2.0, S.ALLEY_E[0] - 2.0]:
		for pz: float in [-S.T_BLD - 2.0, -PZ + 2.0]:
			props.add("plant_potted_leafy", "normal", Vector3(px, S.walk_y(0.0), pz), 0.0)
	for lx: float in [cx - 10.5, cx + 10.5]:
		props.add("prop_lamp_globe", "worn", Vector3(lx, S.walk_y(0.0), cz + 4.0), 0.0)
	# bollards on the two street edges, a gap every few metres for people, none at the corner ramps
	var bz := -S.T_BLD - 3.0
	while bz > -PZ + 1.0:
		props.add("prop_bollard_steel", "worn", Vector3(S.A_BLD + 0.4, S.walk_y(0.0), bz), 0.0); bz -= 2.4
	var bx := S.A_BLD + 3.5
	while bx < S.ALLEY_E[0] - 1.0:
		props.add("prop_bollard_steel", "worn", Vector3(bx, S.walk_y(0.0), -S.T_BLD - 0.4), 0.0); bx += 2.4
	props.add("prop_bike_rack", "worn", Vector3(S.ALLEY_E[0] - 7.5, S.walk_y(0.0), cz - 4.5), 0.0)
	props.add("prop_bike_rack", "worn", Vector3(S.ALLEY_E[0] - 7.5, S.walk_y(0.0), cz - 2.5), 0.0)
	props.add("prop_newspaper_box_red", "worn", Vector3(cx - 2.2, S.walk_y(0.0), -PZ + 0.6), 0.0)
	props.add("prop_newspaper_box_blue", "worn", Vector3(cx + 2.2, S.walk_y(0.0), -PZ + 0.6), 0.0)
	props.add("prop_trash_receptacle", "worn", Vector3(cx - 4.0, S.walk_y(0.0), -PZ + 0.9), 0.0)
	props.add("prop_recycling_receptacle", "worn", Vector3(cx + 4.0, S.walk_y(0.0), -PZ + 0.9), 0.0)
	for k in 6: B.dec.add(14, Vector2(cx + randf_range(-9, 9), cz + randf_range(-4, 4)), randf_range(0, 360), 2.4, 1.8, S.walk_y, Color(1, 1, 1, 0.35))
	# hotel kitchen court and the block's substation
	props.add("prop_dumpster_3yd_green", "worn", Vector3(41.0, S.walk_y(0.0), -55.0), 90.0)
	props.add("prop_dumpster_3yd_green", "worn", Vector3(41.0, S.walk_y(0.0), -58.0), 90.0)
	props.add("prop_propane_cylinder_100lb", "worn", Vector3(36.0, S.walk_y(0.0), -62.0), 0.0)
	props.add("prop_transformer_substation", "worn", Vector3(40.0, S.walk_y(0.0), -70.0), 90.0)
	props.add("prop_ac_condenser", "worn", Vector3(35.6, S.walk_y(0.0), -50.0), 90.0)
	props.add("prop_ac_condenser", "worn", Vector3(35.6, S.walk_y(0.0), -51.4), 90.0)
	B.finish(root, g, props, "c_ne")
	quit()
