extends SceneTree
## Piece i_nw (industrial sample, NW): Bayline Logistics distribution centre - the quadrant is ONE big warehouse
## (Yasin 16 Nov: "maybe make one quarter a big warehouse"). The 72 x 48 m shed (merged from the kit's warehouse
## modules: tools/city/pilot/modular/mod_wh_dist.json) stands at the back with its dock face to a 37 m truck court
## that opens straight off the side street's two driveways (semis need the depth to back in). Trailers stand at the
## docks and wait in a row along the north fence. Small buildings hold the cross-street frontage: a dispatch office
## and drivers' cafe on the corner, a brick freight office, a tyre shop. Run once; never when locked.
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := -1.0; var sz := -1.0
	var root := Node3D.new(); root.name = "i_nw"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("i_nw")
	# gravel trailer park along the north fence
	I.quad_floor(g, sx, sz, [[-47.0, -99.8, -I.PROP, -88.0, "gravel"]])
	var B: Array = []
	var f := I.FRONT
	B.append([I.put(bl, props, sx, sz, "z", 25.5, 49.5, "ck/mod_wh_dist", "bayline_dc"), "ck/mod_wh_dist"])
	B.append([I.put(bl, props, sx, sz, "x", 22.5, f, "commercial/com_orange_corner", "drivers_cafe"), "commercial/com_orange_corner"])
	B.append([I.put(bl, props, sx, sz, "x", 44.0, f, "modular/examples/mod_brk_row", "bayline_freight_office"), "modular/examples/mod_brk_row"])
	B.append([I.put(bl, props, sx, sz, "x", 79.0, f, "ck/mod_stg_row_roofed", "tyre_shop"), "ck/mod_stg_row_roofed"])
	B.append([I.put(bl, props, sx, sz, "z", 23.5, f, "ck/ck_svc_trade", "bayline_dispatch"), "ck/ck_svc_trade"])  # audit fix 17 Nov (#9): was mod_svc_row, whose pharmacy + laundromat fronts repeated 13 times
	# cross street: the 40 m driveway leads into the court, the 75 m one only to the staff passage: a closed gate
	I.street_fence(props, sx, sz, "x", [[22.5, 34.5], [44.0, 62.0], [72.0, 78.0], [79.0, 97.0]], [40.0])
	I.add(props, "fence_gate_rolling_chainlink", "worn", I.q(sx, sz, 75.0, I.PROP + 0.15), 0.0)
	# side street: dispatch office, then the court open to both driveways, fenced between
	I.street_fence(props, sx, sz, "z", [[23.5, 35.5]], I.APRONS)
	I.lot_fence(props, Vector2(-99.8, -I.PROP), Vector2(-99.8, -99.8)); I.lot_fence(props, Vector2(-I.PROP, -99.8), Vector2(-99.8, -99.8))
	# guard booth inside the 75 m driveway (trucks check in), a barrier line of k-rails between court and the cafe
	K.building(bl, "commercial/com_kiosk", I.q(sx, sz, 13.0, 66.0), 180.0, "gate_booth")   # door to the driveway, not the fence
	# ---- trailers at the docks: the dock bays sit at local x -6 / +6 of the shed (world v = 61.5 +- 6)
	for v: float in [55.5, 67.5]:
		I.add(props, "prop_container_20ft_white", "dirty", I.q(sx, sz, 43.9, v), 90.0)
		I.add(props, "prop_container_20ft_white", "worn", I.q(sx, sz, 37.8, v), 90.0)    # 40 ft trailer = two 20 ft boxes nose to tail
	# drive-in doors (local x -18 / +18): a box truck's worth of oil, cones keeping the swing clear
	for v: float in [43.5, 79.5]:
		for k in 3: I.add(props, "prop_cone_28in", "dirty", I.q(sx, sz, 45.5, v - 3.5 + k * 3.5), k * 40.0)
	# trailers waiting in a row along the north fence (gravel park), noses to the fence
	for k in 7:
		var u := 14.0 + k * 4.2
		if rr.randf() < 0.85:
			I.add(props, ["prop_container_20ft_white", "prop_container_20ft_blue", "prop_container_20ft_red"][k % 3], "dirty" if k % 2 else "worn", I.q(sx, sz, u, 93.0), 0.0)
			if k % 3 != 1: I.add(props, "prop_container_20ft_white", "dirty", I.q(sx, sz, u, 93.0 - 6.2), 0.0)
	for p: Vector2 in [Vector2(20.0, 50.0), Vector2(20.0, 72.0), Vector2(40.0, 30.0), Vector2(44.0, 80.0)]:
		I.add(props, "prop_lot_light_pole", "dirty", I.q(sx, sz, p.x, p.y), 0.0)
	I.add(props, "prop_k_rail", "worn", I.q(sx, sz, 46.4, 33.5), 0.0)    # one rail by the office corner, clear of its door
	I.add(props, "prop_dumpster_3yd_green", "rusty", I.q(sx, sz, 46.0, 87.0), 90.0)
	I.add(props, "prop_dumpster_3yd_blue", "rusty", I.q(sx, sz, 46.0, 90.0), 90.0)
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", I.q(sx, sz, 13.5, 57.0), 90.0)        # cardboard / pallet wrap
	# ---- the frontage buildings' back doors: cafe bins + gas, freight office dumpster, tyre shop's drums and cones
	I.back_door_clutter(props, rr, I.q(sx, sz, 26.0, 25.8), 180.0, "gas")
	I.back_door_clutter(props, rr, I.q(sx, sz, 47.0, 25.0), 180.0, "shop")
	I.back_door_clutter(props, rr, I.q(sx, sz, 84.5, 23.0), 180.0, "shop")
	for k in 4: I.add(props, "prop_channelizer_drum", "dirty", I.q(sx, sz, 88.0 + k * 0.85, 23.2), 0.0)
	# ---- the drivers' cafe sidewalk: bus stop bench for the drivers' shuttle, a bin, a paper box
	I.walk_prop(props, sx, sz, "x", 26.0, "prop_trash_receptacle", "dirty"); I.walk_prop(props, sx, sz, "x", 31.5, "prop_newspaper_box_red")
	I.walk_prop(props, sx, sz, "z", 30.0, "prop_usps_collection_box")
	# ---- wear: a truck court is the most worn ground in the city
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	for v: float in [55.5, 67.5, 43.5, 79.5]:
		I.truck_path(dec, rr, Vector2(-I.PROP, -40.0 if v < 61.5 else -75.0), Vector2(-46.0, -v))
		for k in 3: W.oil(dec, rr, Vector2(-44.0 + k * 3.0, -v), 90.0, S.walk_y, 0.95)
	I.truck_path(dec, rr, Vector2(-40.0, -I.PROP), Vector2(-30.0, -60.0))
	I.yard_wear(dec, rr, sx, sz, 10.0, 24.0, 47.0, 99.0, 1.8)
	I.yard_wear(dec, rr, sx, sz, 10.0, 10.0, 99.0, 25.0, 0.8)
	I.finish(root, g, props, dec, "i_nw")
	quit()
