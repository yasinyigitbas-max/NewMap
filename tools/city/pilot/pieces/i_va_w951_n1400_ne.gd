extends SceneTree
## Piece i_va_w951_n1400_ne (industrial growth, VARIANT A "port", third dressing; 19 Nov, Yasin: "roll out to your
## whole zone"; not locked). Site: the strip between Alameda Blvd (the base fence boulevard) and the sample's i_nw /
## the freight station i_va_w800_n1600_sw, from 3rd St north to 1st St's rounded corner: world u -951..-900,
## v -1590..-1414. Its free area is measured row by row (G.measure_rows): the ring's corner curves across its north end.
## HARBOR FREIGHT STATION'S EMPTIES DEPOT: the empty boxes wait here in long stacks until a ship or a barge takes them.
## The depot is reached only through the freight station's yard, by a new gate in its west wall.
## Planner's reasons:
##  - Alameda and 3rd St have no driveway here, and trucks should not stop on the boulevard: so there are no gates on
##    the streets, and the depot is part of the freight station's yard.
##  - Toward the boulevard (bus stop, palms): a block wall following the street's curve (opaque, tagged near the
##    bus stop), with the stacks showing over it, like any container depot by a port road.
##  - No fence on the east edge: the neighbours' fences (i_nw) and the freight station's wall close it.
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/ind_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const NAME := "i_va_w951_n1400_ne"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := 1.0; var sz := -1.0
	var J := Vector3(-950.889, 2.0, -1400.0)
	var Lu := 50.889
	var mr: Dictionary = await G.measure_rows(self, J, sx, sz, Lu, 192.0, [NAME])
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(NAME)
	G.floor_rows(g, mr, sx, sz, [[16.0, 20.0, 42.0, 172.0, "gravel"]])
	var vf := float(mr.rows[0][0]); var af := float(mr.rows[0][1])
	# ---- walls: 3rd St, then the boulevard following its curve into the corner
	G.wall(props, sx, sz, Vector2(af + 0.4, vf + 0.2), Vector2(Lu - 0.3, vf + 0.2), "fence_cmu_wall", 6, "dirty")
	G.wall_left(props, mr, sx, sz, vf + 1.5, 191.0, "fence_cmu_wall", 7)
	# ---- the stacks: three double columns along the strip, cross aisles every ~40 m, a lane along the east edge
	var cols := [18.5, 21.1, 26.5, 29.1, 34.5, 37.1]
	for v0: float in [20.0, 64.0, 104.0, 148.0]:
		var n := 6 if v0 < 140.0 else 3
		for u: float in cols:
			var hts: Array = []
			for k in n: hts.append(1 + rr.randi() % 3)
			var row := G.row_at(mr, v0 + n * 6.35)
			if row.is_empty() or float(row[1]) > u - 2.0: n = 2; hts = hts.slice(0, 2)
			G.stack_col(props, rr, sx, sz, u, v0 + 3.2, hts)
	var ck := K.building(bl, "commercial/com_kiosk", G.q(sx, sz, 44.5, 133.5), 90.0, "depot_check_in", 0.85)    # its door to the lane
	for p: Vector2 in [Vector2(43.0, 40.0), Vector2(43.0, 82.0), Vector2(43.0, 122.0), Vector2(43.0, 160.0)]:
		I.add(props, "prop_lot_light_pole", "dirty", G.q(sx, sz, p.x, p.y), 0.0)
	# ---- POLISH: each with its reason; placed only where free (G.place)
	var obs := G.obstacles(bl, props, []); var kp := [[40.0, 15.0, 51.0, 186.0], [15.0, 58.0, 42.0, 63.5], [15.0, 98.0, 42.0, 103.5], [15.0, 142.0, 42.0, 147.5]]
	G.place(props, obs, rr, sx, sz, "prop_hydrant_red", "rusty", 39.0, 120.0, 40.5, 130.0, 0.0)
	G.spot(props, obs, rr, sx, sz, [["prop_k_rail", "dirty"], ["prop_k_rail", "dirty"], ["prop_water_barrier_orange", "dirty"]], 40.0, 172.0, 50.0, 182.0, 0.0)   # the lane's end, kept from the corner wall
	G.spot(props, obs, rr, sx, sz, [["prop_cone_28in", "dirty"], ["prop_cone_28in", "dirty"], ["prop_channelizer_drum", "dirty"]], 40.0, 138.0, 43.0, 146.0, 0.0)
	G.spot(props, obs, rr, sx, sz, [["prop_trash_cart_black", "worn"], ["prop_dumpster_3yd_blue", "rusty"]], 45.5, 124.0, 48.8, 130.0, 0.0)   # the check-in hut's bins
	# ---- wear: the reach-stacker's lane is the most worn ground
	I.truck_path(dec, rr, Vector2(sx * 50.8, sz * 140.5), Vector2(sx * 46.0, sz * 140.5))
	I.truck_path(dec, rr, Vector2(sx * 46.0, sz * 22.0), Vector2(sx * 46.0, sz * 178.0))
	for v1: float in [61.0, 101.0, 145.0]: I.truck_path(dec, rr, Vector2(sx * 46.0, sz * v1), Vector2(sx * 17.0, sz * v1))
	G.yard_wear(dec, rr, sx, sz, 16.0, 20.0, 50.0, 175.0, 1.0)
	I.bld_wear(dec, rr, ck, 4.0, 6.0, "commercial/com_kiosk")
	root.set_meta("stalls", [])
	I.finish(root, g, props, dec, NAME)
	quit()
