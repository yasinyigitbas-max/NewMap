extends SceneTree
## Piece c_se (city centre sample, SE corner). The corner lot is a construction site (centres always have one):
## screened temporary fence along both streets with a rolling gate on 10th (trucks never use the main street), the
## site office as two stacked containers, a 20 yd rolloff, k-rails and water barriers lined up, cones, propane, a
## "coming soon" billboard high over the fence corner. Then the condo tower with its residents' garden court behind,
## a small office block, and a corner cafe. Run once; never when locked.
const C := preload("res://tools/city/pilot/pieces/cc_lib.gd")
const B := preload("res://tools/city/pilot/pieces/block_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const SZ := 37.7      # construction lot runs from the 10th building line to here along Amber
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "c_se"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	B.begin("c_se"); var g := K.Ground.new(); var props := K.Props.new()
	C.floor(g, 1.0, 1.0, [[S.A_BLD, S.T_BLD, S.ALLEY_E[0], SZ, "mulch"], [32.0, SZ, S.ALLEY_E[0], SZ + 36.0, "grass"]])
	var z := SZ
	for f: String in ["urban/twr_condo_shores", "modular/examples/mod_twr_office", "commercial/com_shallow_cafe"]:
		var r := B.on_amber(bl, f, 1.0, S.A_BLD, z); z += float(r[1])
		if not f.contains("condo"): C.back_of_house(props, r[0], f)   # the condo's back is its garden court
	# ---- construction site
	C.site_fence(props, Vector2(S.A_BLD + 0.3, S.T_BLD + 0.3), Vector2(S.A_BLD + 0.3, SZ - 0.3))           # Amber side
	C.site_fence(props, Vector2(S.A_BLD + 0.3, S.T_BLD + 0.3), Vector2(30.0, S.T_BLD + 0.3))               # 10th side up to the gate
	props.add("fence_gate_rolling_chainlink", "worn", Vector3(33.2, S.walk_y(0.0), S.T_BLD + 0.3), 0.0)
	C.site_fence(props, Vector2(36.4, S.T_BLD + 0.3), Vector2(S.ALLEY_E[0] - 0.3, S.T_BLD + 0.3))
	C.site_fence(props, Vector2(S.ALLEY_E[0] - 0.3, S.T_BLD + 0.3), Vector2(S.ALLEY_E[0] - 0.3, SZ - 0.3))   # alley side
	props.add("prop_container_20ft_white", "worn", Vector3(40.5, S.walk_y(0.0), 30.0), 0.0)                 # site office, two high
	props.add("prop_container_20ft_white", "dirty", Vector3(40.5, S.walk_y(0.0) + 2.59, 30.0), 0.0)
	props.add("prop_container_20ft_blue", "worn", Vector3(37.4, S.walk_y(0.0), 30.0), 0.0)                  # tool store
	props.add("prop_dumpster_rolloff_20yd", "rusty", Vector3(22.0, S.walk_y(0.0), 28.0), 0.0)
	for k in 2: props.add("prop_k_rail", "worn", Vector3(29.0 + k * 4.0, S.walk_y(0.0), 23.0), 0.0)
	for k in 3: props.add("prop_water_barrier_orange" if k % 2 == 0 else "prop_water_barrier_white", "worn", Vector3(19.0 + k * 2.0, S.walk_y(0.0), 35.6), 0.0)
	for k in 5: props.add("prop_cone_28in", "worn", Vector3(30.0 + k * 0.8, S.walk_y(0.0), 13.0), k * 30.0)
	props.add("prop_propane_cylinder_100lb", "worn", Vector3(35.0, S.walk_y(0.0), 34.0), 0.0)
	props.add("prop_tank_horizontal_propane", "worn", Vector3(42.4, S.walk_y(0.0), 13.6), 90.0)           # heaters / torches
	props.add("prop_container_20ft_green", "worn", Vector3(41.3, S.walk_y(0.0), 20.5), 0.0)               # materials store
	for k in 4: props.add("prop_temp_fence_stand", "worn", Vector3(19.0 + k * 0.7, S.walk_y(0.0), 32.0), 90.0)   # spare fence feet
	props.add("prop_dumpster_3yd_green", "rusty", Vector3(28.5, S.walk_y(0.0), 34.6), 0.0)                # site waste
	props.add("prop_propane_cylinder_100lb", "worn", Vector3(35.5, S.walk_y(0.0), 34.3), 0.0)
	props.add("prop_barricade_type3", "worn", Vector3(33.2, S.walk_y(0.0), S.T_BLD - 1.6), 0.0)              # in front of the gate when shut
	props.add("prop_billboard", "worn", Vector3(24.0, S.walk_y(0.0), 17.5), -135.0)   # faces the junction, over the fence corner
	for k in 8: B.dec.add(8, Vector2(33.2 + randf_range(-1.5, 1.5), S.T_BLD + 2.0 + k * 2.5), randf_range(-10, 10), 0.6, 4.0, S.walk_y, Color(0.9, 0.85, 0.75, 0.5))   # truck tracks
	# ---- condo garden court (residents only: hedge round it, benches, palms, a gas barbecue)
	for k in 6: props.add("hedge_boxwood_low_2m", "normal", Vector3(33.0, S.walk_y(0.0), SZ + 3.0 + k * 2.2), 90.0)
	for q: Vector2 in [Vector2(38.0, SZ + 6.0), Vector2(38.0, SZ + 26.0)]:
		props.add("palm_queen_a", "normal", Vector3(q.x, S.walk_y(0.0), q.y), q.y * 11.0)
	props.add("prop_patio_set_4", "worn", Vector3(39.0, S.walk_y(0.0), SZ + 14.0), 20.0)
	props.add("prop_bbq_gas_cart", "worn", Vector3(42.0, S.walk_y(0.0), SZ + 18.0), -90.0)
	props.add("prop_park_bench", "worn", Vector3(42.6, S.walk_y(0.0), SZ + 10.0), -90.0)
	props.add("prop_transformer_substation", "worn", Vector3(40.0, S.walk_y(0.0), 84.0), 90.0)
	props.add("prop_dumpster_3yd_green", "worn", Vector3(41.0, S.walk_y(0.0), 93.0), 90.0)                # cafe
	B.finish(root, g, props, "c_se")
	quit()
