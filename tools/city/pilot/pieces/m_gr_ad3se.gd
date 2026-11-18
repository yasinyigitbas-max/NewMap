extends SceneTree
## Piece m_gr_ad3se (commercial strip growth, VARIANT E "motel and gym", 19 Nov): the block between 3rd St and the strip
## sample's NE quarter (m_ne), from Adela Ave to Glorietta Blvd (grid u 508.7-645.7, v -1385.7 to -1300), placed at the
## Adela x 3rd junction (500, 2, -1400). On the slope up from 3rd St (pad 2) toward the sample (4).
## Why this use (city planner): across 3rd St is the hospital, behind is the bridge mouth. Families of patients and
## travellers off the bridge need a cheap bed close by: a motor court in two wings with its rooms facing the parking
## court (the office in the west wing, the guest laundry in the east one); a 24-hour gym in an old warehouse at the back
## (shift workers from the hospital train at odd hours); a walk-up coffee kiosk on the 3rd St corner for staff who walk
## across. 3rd St (palm parkway, a bus pad) and the ring give no driveway: everything enters from Adela's two aprons;
## the back of the block leads through a gate into the boat and RV storage on the ring (m_gr_e4n). A billboard on the
## ring corner faces the bridge traffic.
## Variant differences: two motel wings facing a court, the gym in a warehouse, the walk-up kiosk with its patio,
## jacarandas and corals in the court's planters, a guest laundry, a boat on its trailer in a stall.
## Run once (tools/city/run/build.sh m_gr_ad3se); never when locked.
const G := preload("res://tools/city/pilot/pieces/strip_grow_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const PALMS := ["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c", "palm_queen_a"]
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := G.new("m_gr_ad3se", "E motel and gym")
	var tries := func(base: String, cond: String, x: float, z: float, yaw: float) -> void:
		if b.free_at(x, z, b.half(base)): b.add(base, cond, x, z, yaw)
	# ---------------------------------------------------------------- the motor court: two wings, backs to 3rd St, rooms on the court
	var w1 := b.bld("extras/motel_inn_court", 52.0, 24.0, 0.0, "harbor_view_motel", 0.75)
	var w2 := b.bld("extras/motel_inn_court", 98.0, 24.0, 0.0, "harbor_view_motel_east", 0.75)
	b.paints.append(b.rect(34.0, 29.0, 116.0, 31.0, "concrete"))              # the walk along the room doors
	b.paints.append(b.rect(34.0, 31.0, 116.0, 35.6, "grass"))                 # planters between the walk and the cars
	for k in 6:
		var tx := 38.0 + k * 14.0
		if absf(tx - 75.0) > 4.0: b.add(["tree_jacaranda_a", "tree_coral_a", "palm_queen_b"][k % 3], "normal", tx, 33.3, k * 53.0)
	b.stalls_x(35.0, 13, 41.5, -1.0); b.stalls_x(81.0, 13, 41.5, -1.0)       # guests park at their own doors
	b.roof(w1, ["prop_ac_condenser", "prop_satellite_dish_round", "prop_ac_condenser"])
	b.roof(w2, ["prop_ac_condenser", "prop_vent_plumbing", "prop_ac_condenser"])
	tries.call("prop_ice_chest", "worn", 71.6, 30.0, 90.0)                    # ice and soda at the gap between the wings
	tries.call("prop_vending_soda", "worn", 73.2, 30.2, 0.0)
	tries.call("prop_vending_snack", "worn", 76.8, 30.2, 0.0)
	tries.call("prop_golf_cart_white", "worn", 78.6, 25.0, 0.0)               # housekeeping's cart, parked in the gap
	# ---------------------------------------------------------------- the walk-up coffee kiosk on the 3rd St corner
	var ki := b.bld("commercial/com_kiosk", 20.0, 22.0, 180.0, "crosswalk_coffee", 0.8)
	b.paints.append(b.rect(11.0, 25.5, 29.0, 34.0, "concrete"))               # its patio
	b.paints.append(b.rect(11.0, 14.3, 29.0, 19.0, "concrete"))               # its forecourt on the 3rd St walk (staff come across on foot)
	for k in 2: b.add("prop_picnic_table", "worn", 15.0 + k * 9.0, 30.0, 0.0)
	tries.call("prop_trash_receptacle", "worn", 19.5, 33.4, 0.0)
	tries.call("prop_bike_rack", "worn", 20.0, 26.2, 0.0)
	# ---------------------------------------------------------------- the 24-hour gym in the old warehouse at the back
	var gym := b.bld("industrial/ind_warehouse", 116.0, 82.0, -90.0, "iron_tide_gym", 0.8)
	b.paints.append(b.rect(102.0, 70.0, 104.0, 94.0, "concrete"))
	b.roof(gym, ["prop_vent_turbine", "prop_vent_turbine", "prop_ac_condenser", "prop_ac_condenser", "prop_solar_panel_x3"])
	# ---------------------------------------------------------------- the lot (Adela's aprons at 45 and 80), rows across the slope
	b.stalls_x(12.0, 13, 48.5, 1.0); b.stalls_x(51.0, 14, 48.5, 1.0)
	b.stalls_x(12.0, 13, 59.5, -1.0); b.stalls_x(51.0, 14, 59.5, -1.0)
	b.stalls_x(12.0, 13, 66.5, 1.0); b.stalls_x(51.0, 14, 66.5, 1.0)
	b.stalls_x(12.0, 13, 77.5, -1.0); b.stalls_x(51.0, 14, 77.5, -1.0)
	b.stalls_x(12.0, 13, 84.5, 1.0); b.stalls_x(51.0, 14, 84.5, 1.0)
	for iz: Array in [[48.6, 59.4], [66.6, 77.4]]:
		b.island(47.2, float(iz[0]), 50.9, float(iz[1]), 1, ["tree_coral_b", "tree_jacaranda_b"])
		b.island(89.0, float(iz[0]), 91.8, float(iz[1]), 0, PALMS)
	b.island(47.2, 84.6, 50.9, 90.0, 0, PALMS)
	for p: Vector2 in [Vector2(49.0, 52.0), Vector2(49.0, 70.0), Vector2(90.4, 63.0), Vector2(24.0, 37.0), Vector2(100.0, 93.0)]:
		tries.call("prop_lot_light_pole", "worn", p.x, p.y, 0.0)
	# a boat on its trailer in a back stall: someone off to the storage yard next door
	tries.call("prop_boat_trailer", "worn", 30.0, 87.5, 0.0)
	tries.call("prop_boat_skiff", "worn", 30.0, 87.8, 0.0)
	# ---------------------------------------------------------------- the back strip, the gate to the storage yard, the ring corner
	b.paints.append(b.rect(10.0, 90.2, 100.0, 99.5, "grass"))
	for k in 5: b.add(["tree_torrey_pine_b", "tree_eucalyptus_a", "tree_torrey_pine_a"][k % 3], "normal", 18.0 + k * 18.0, 95.0, k * 41.0)
	b.pole_line(14.0, 98.6, 96.0, 98.6, 27.0)
	# (the storage yard's fence and gate are built by m_gr_e4n on its own edge: one fence, one owner)
	b.island(118.0, 14.6, 142.6, 17.3, 2, PALMS)
	b.island(142.9, 17.3, 145.5, 99.4, 6, PALMS)
	b.add("prop_billboard", "worn", 134.0, 30.0, 90.0)                        # facing the ring and the bridge traffic
	b.add("prop_pylon_sign", "worn", 12.0, 15.95, 180.0)                      # HARBOR VIEW MOTEL - VACANCY, facing 3rd St
	# ---------------------------------------------------------------- polish
	b.door_life()
	b.enclosure(80.0, 95.0, 180.0)
	b.add("prop_dumpster_rolloff_20yd", "rusty", 132.0, 88.0, 0.0)          # the gym's old equipment and cardboard
	for m: Vector2 in [Vector2(30.0, 63.0), Vector2(70.0, 63.0), Vector2(95.0, 81.0)]:
		b.add("prop_manhole_cover", "dirty", m.x, m.y, 0.0, false, 0.002)
	for d: Vector2 in [Vector2(30.0, 45.0), Vector2(70.0, 81.0), Vector2(95.5, 52.0)]:
		b.add("prop_storm_drain_grate", "dirty", d.x, d.y, 0.0, false, 0.002)
	tries.call("prop_park_bench", "worn", 101.4, 72.0, -90.0)                 # outside the gym door, facing the lot
	tries.call("prop_bike_rack", "worn", 101.4, 90.0, 90.0)
	tries.call("prop_newspaper_box_red", "worn", 66.0, 30.0, 0.0)
	# polish 19 Nov (whole-zone pass): a chair set between the kiosk's picnic tables, a table in the wings' gap, carts at the motel
	tries.call("prop_patio_set_4", "worn", 19.5, 29.6, 0.0)
	tries.call("prop_patio_set_4", "worn", 73.8, 26.4, 0.0)
	for x: float in [32.6, 117.4]: tries.call("prop_trash_cart_green", "dirty", x, 27.0, 0.0)
	tries.call("prop_hydrant_red", "worn", 75.0, 32.6, 0.0)
	tries.call("prop_drinking_fountain", "worn", 101.4, 67.6, -90.0)           # at the gym door
	# ---------------------------------------------------------------- wear
	b.building_wear()
	b.stall_wear(0.7)
	b.tyre_path(8.7, 45.0, 95.0, 45.0); b.tyre_path(8.7, 80.0, 95.0, 81.0); b.tyre_path(95.5, 45.0, 95.5, 96.0)
	b.tyre_path(110.0, 96.0, 133.0, 99.0)
	b.yard_wear(9.0, 34.0, 142.0, 99.5, 1.0)
	b.finish("prop_wheel_stop_concrete")
	quit()
