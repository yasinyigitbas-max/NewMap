extends SceneTree
## Piece i_ne (industrial sample, NE): Harbor Steel works, as a perimeter block (density pass, Yasin 16 Nov).
## Cross-street frontage: a workers' diner on the corner (lunch for the whole district), the steel stockhouse, the
## company's old brick office. Side-street frontage: a machine shop, a fabrication shed, a truck repair shop.
## Back rows facing the yard: the mill (factory, tall chimney, landmark with the water tower) and a finished-goods
## warehouse. The shared yard between them: steel shipping containers, scrap rolloffs, the works' own transformer,
## k-rails guarding the mill doors, lot lights. Trucks come in at both standard driveways.
## Run once; never when locked.
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := 1.0; var sz := -1.0
	var root := Node3D.new(); root.name = "i_ne"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("i_ne")
	# gravel behind the warehouse around the tanks
	I.quad_floor(g, sx, sz, [[60.0, -99.8, 99.8, -78.0, "gravel"]])
	var B: Array = []   # [result, folder]
	var f := I.FRONT
	B.append([I.put(bl, props, sx, sz, "x", 22.5, f, "commercial/com_bistro", "harbor_diner"), "commercial/com_bistro"])
	B.append([I.put(bl, props, sx, sz, "x", 45.5, f, "industrial/ind_warehouse", "steel_stockhouse"), "industrial/ind_warehouse"])
	B.append([I.put(bl, props, sx, sz, "x", 79.0, f, "modular/examples/mod_brk_row", "harbor_steel_office"), "modular/examples/mod_brk_row"])
	B.append([I.put(bl, props, sx, sz, "z", 23.5, f, "ck/ck_svc_trade", "machine_shop"), "ck/ck_svc_trade"])  # audit fix 17 Nov (#9): was mod_svc_row, whose pharmacy + laundromat fronts repeated 13 times
	B.append([I.put(bl, props, sx, sz, "z", 45.5, f, "modular/examples/mod_wh_shed", "fabrication_shed"), "modular/examples/mod_wh_shed"])
	B.append([I.put(bl, props, sx, sz, "z", 79.0, f, "industrial/ind_repair", "truck_repair"), "industrial/ind_repair"])
	B.append([I.put_back(bl, props, sx, sz, "z", 40.0, "industrial/ind_factory", "harbor_steel_mill"), "industrial/ind_factory"])
	B.append([I.put_back(bl, props, sx, sz, "x", 36.0, "industrial/ind_warehouse", "finished_goods"), "industrial/ind_warehouse"])
	I.street_fence(props, sx, sz, "x", [[22.5, 34.5], [45.5, 69.5], [79.0, 97.0]], I.APRONS)
	I.street_fence(props, sx, sz, "z", [[23.5, 35.5], [45.5, 69.5], [79.0, 97.0]], I.APRONS)
	I.lot_fence(props, Vector2(99.8, -I.PROP), Vector2(99.8, -99.8)); I.lot_fence(props, Vector2(I.PROP, -99.8), Vector2(99.8, -99.8))
	# ---- the yard (u 34-72, v 34-72)
	I.containers(props, sx, sz, 38.0, 40.0, 4, true, rr, 0.7)        # coil boxes waiting for export
	I.containers(props, sx, sz, 38.0, 52.0, 3, true, rr, 0.5)
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", I.q(sx, sz, 56.0, 40.0), 0.0)   # offcuts / scrap
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", I.q(sx, sz, 62.0, 40.0), 8.0)
	for k in 4: I.add(props, "prop_k_rail", "dirty", I.q(sx, sz, 70.0, 44.0 + k * 4.2), 90.0)   # guards the mill wall from forklifts
	I.add(props, "prop_transformer_substation", "dirty", I.q(sx, sz, 52.0, 66.0), 0.0)
	I.add(props, "prop_switch_rack", "worn", I.q(sx, sz, 57.0, 68.0), 0.0)
	I.add(props, "prop_utility_pole_transformer", "dirty", I.q(sx, sz, 46.0, 70.0), 0.0)
	for p: Vector2 in [Vector2(36.0, 36.0), Vector2(70.0, 36.0), Vector2(36.0, 70.0)]:
		I.add(props, "prop_lot_light_pole", "dirty", I.q(sx, sz, p.x, p.y), 45.0)
	for k in 6: I.add(props, "prop_cone_28in", "dirty", I.q(sx, sz, 48.0 + k * 1.1, 58.0), k * 37.0)   # marked-off spill
	I.add(props, "prop_water_barrier_orange", "dirty", I.q(sx, sz, 48.0, 61.0), 0.0)
	I.add(props, "prop_water_barrier_white", "dirty", I.q(sx, sz, 50.5, 61.2), 12.0)
	# ---- back corner: tanks and the water tower (seen from the whole district)
	I.add(props, "prop_tank_vertical", "dirty", I.q(sx, sz, 66.0, 83.0), 0.0)
	I.add(props, "prop_tank_vertical", "worn", I.q(sx, sz, 66.0, 93.5), 0.0)
	I.add(props, "prop_tank_horizontal_propane", "rusty", I.q(sx, sz, 76.0, 81.0), 90.0)
	I.add(props, "prop_water_tower", "dirty", I.q(sx, sz, 88.0, 88.0), 15.0)
	# ---- by the doors: the diner's bins and gas, the office's dumpster, the repair shop's tyre-and-drum mess
	I.back_door_clutter(props, rr, I.q(sx, sz, 28.0, 26.5), 0.0, "gas")
	I.back_door_clutter(props, rr, I.q(sx, sz, 31.5, 28.5), 0.0, "shop")
	I.back_door_clutter(props, rr, I.q(sx, sz, 92.0, 27.0), 0.0, "shop")
	I.back_door_clutter(props, rr, I.q(sx, sz, 30.0, 92.0), -90.0, "yard")
	for k in 3: I.add(props, "prop_channelizer_drum", "dirty", I.q(sx, sz, 27.5, 80.0 + k * 0.8), 0.0)
	# ---- the diner's sidewalk: papers, a bin, a bike rack for the shift workers who ride in
	I.walk_prop(props, sx, sz, "x", 24.5, "prop_newspaper_box_blue"); I.walk_prop(props, sx, sz, "x", 25.4, "prop_newspaper_box_red")
	I.walk_prop(props, sx, sz, "x", 36.0, "prop_trash_receptacle", "dirty"); I.walk_prop(props, sx, sz, "z", 30.0, "prop_bike_rack")
	# ---- wear: every building's feet, truck paths, the yard
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	I.truck_path(dec, rr, Vector2(40.0, -I.PROP), Vector2(40.0, -46.0))
	I.truck_path(dec, rr, Vector2(75.0, -I.PROP), Vector2(75.0, -36.0))
	I.truck_path(dec, rr, Vector2(I.PROP, -40.0), Vector2(56.0, -40.0))
	I.truck_path(dec, rr, Vector2(I.PROP, -75.0), Vector2(34.0, -75.0))
	I.yard_wear(dec, rr, sx, sz, 34.0, 34.0, 72.0, 72.0, 1.6)
	I.yard_wear(dec, rr, sx, sz, 10.0, 34.0, 34.0, 99.0, 0.8)
	I.yard_wear(dec, rr, sx, sz, 34.0, 10.0, 99.0, 34.0, 0.8)
	I.yard_wear(dec, rr, sx, sz, 60.0, 76.0, 99.0, 99.0, 0.7)
	I.finish(root, g, props, dec, "i_ne")
	quit()
