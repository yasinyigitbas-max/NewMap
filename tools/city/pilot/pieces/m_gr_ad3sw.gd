extends SceneTree
## Piece m_gr_ad3sw (commercial strip growth, VARIANT D "hospital side", 19 Nov): the block between 3rd St and the strip
## sample's mall (m_nw), west of Adela Ave (grid u 400-491.3, v -1385.7 to -1300), placed at the Adela x 3rd junction
## (500, 2, -1400). On the slope: 3rd St lies at pad 2, the sample 2 m higher (the ground follows Adela's rise).
## Why this use (city planner): the hospital campus is across 3rd St. Hospitals pull the same things onto the strip
## across the road everywhere: a medical office row (urgent care that takes the walk-ins the ER turns away, a physio
## practice for the discharged), a coffee and flower shop for visitors on the signalised corner, and paid visitor
## parking because the hospital's own fills by nine. Entered from 3rd St's two aprons and Adela's two; the medical row
## stands at the top of the slope with its service lane behind it (Adela's south apron leads in), the parking steps up
## the slope in rows across it, a planted buffer and pines on the west edge toward Crown Hill's houses.
## Variant differences: the visitor parking with its attendant's booth and pay stations, a Spanish arcade block (used
## once before), torrey and Norfolk pines, rubber wheel stops, the coffee / flower corner.
## Run once (tools/city/run/build.sh m_gr_ad3sw); never when locked.
const G := preload("res://tools/city/pilot/pieces/strip_grow_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const PINES := ["tree_torrey_pine_a", "tree_torrey_pine_b", "tree_norfolk_pine_c"]
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := G.new("m_gr_ad3sw", "D hospital side")
	var tries := func(base: String, cond: String, x: float, z: float, yaw: float) -> void:
		if b.free_at(x, z, b.half(base)): b.add(base, cond, x, z, yaw)
	# ---------------------------------------------------------------- the medical row at the top of the slope (faces 3rd St)
	var med := b.bld("commercial/com_spanish_arcade_block", -60.0, 82.5, 180.0, "harbor_medical_plaza", 0.7)
	b.paints.append(b.rect(-75.0, 72.5, -45.0, 74.5, "concrete"))            # the arcade's walk
	b.roof(med, ["prop_ac_condenser", "prop_ac_condenser", "prop_vent_box", "prop_solar_panel_x3"])
	b.paints.append(b.rect(-47.0, 76.5, -8.7, 83.5, "asphalt"))               # the service drive from Adela's south apron ...
	b.paints.append(b.rect(-75.0, 90.5, -8.7, 99.5, "asphalt"))               # ... to the lane behind the row
	b.enclosure(-40.0, 95.0, 180.0)
	b.add("prop_dumpster_3yd_green", "rusty", -78.0, 96.0, 0.0)               # medical waste goes in the locked bin
	b.add("prop_sign_no_parking", "worn", -46.5, 84.2, 0.0)
	# ---------------------------------------------------------------- the coffee + flower corner at the signal (faces 3rd St)
	var cor := b.bld("commercial/com_orange_corner", -24.0, 27.0, 180.0, "visitors_corner", 0.75)
	b.paints.append(b.rect(-31.0, 18.0, -17.0, 20.0, "concrete"))
	b.stalls_z(22.0, 5, -32.0, -1.0)                                           # short-stay row at its side
	b.add("prop_sign_no_parking", "worn", -37.8, 21.4, 0.0)                    # 15 MIN
	b.roof(cor, ["prop_vent_box", "prop_ac_condenser_compact"])
	# ---------------------------------------------------------------- the visitor parking, stepping up the slope
	b.stalls_x(-76.5, 10, 48.5, 1.0); b.stalls_x(-76.5, 10, 59.5, -1.0)       # rows across the slope, between the two drives
	b.stalls_x(-41.5, 11, 48.5, 1.0); b.stalls_x(-41.5, 11, 59.5, -1.0)
	b.stalls_x(-76.5, 9, 66.5, 1.0)                                           # nose-in at the medical row
	b.stalls_x(-76.5, 10, 41.5, -1.0)                                         # and on the low side of the first aisle
	b.stalls_z(16.0, 9, -84.0, -1.0); b.stalls_z(50.0, 7, -84.0, -1.0)       # the west column along the buffer
	b.island(-49.4, 48.6, -41.6, 59.4, 1, ["tree_coral_a"])
	b.island(-11.6, 48.6, -9.0, 59.4, 0, PINES)
	b.island(-92.0, 40.6, -89.6, 49.4, 1, ["tree_torrey_pine_a"])
	# the attendant's booth and pay stations where the drives enter from 3rd St
	var bo := b.bld("commercial/com_kiosk", -66.0, 21.0, 180.0, "visitor_parking_booth", 0.8, true, false)
	for p: Vector2 in [Vector2(-75.0, 26.0), Vector2(-50.5, 26.0), Vector2(-15.0, 50.0)]:
		tries.call("prop_pay_station", "worn", p.x, p.y, 0.0)
	tries.call("prop_sign_no_parking", "worn", -77.5, 15.6, 0.0)              # VISITOR PARKING $5
	for p2: Vector2 in [Vector2(-45.5, 50.5), Vector2(-10.3, 51.0), Vector2(-90.8, 44.0), Vector2(-79.5, 72.5)]:     # on islands and edges, never in a stall
		tries.call("prop_lot_light_pole", "worn", p2.x, p2.y, 0.0)
	# ---------------------------------------------------------------- frontages: 3rd St planting, the west buffer toward the houses
	b.island(-100.0 + 0.6, 14.6, -84.6, 17.3, 2, PINES)
	b.island(-75.4, 14.6, -49.6, 17.3, 2, ["palm_mexican_fan_a", "palm_mexican_fan_c"])
	b.island(-40.4, 14.6, -32.6, 17.3, 1, ["palm_queen_b"])
	b.paints.append(b.rect(-99.4, 17.3, -92.0, 99.4, "grass"))
	for k in 6: b.add(PINES[k % 3], "normal", -96.2, 24.0 + k * 13.0, k * 61.0)
	for k2 in 38: b.add("hedge_privet_2m", "normal", -98.7, 21.0 + k2 * 2.05, 90.0)   # a privet screen toward Crown Hill's back yards
	b.add("prop_pylon_sign", "worn", -16.0, 15.95, 180.0)                     # HARBOR MEDICAL PLAZA - COFFEE - FLOWERS, facing 3rd St
	# ---------------------------------------------------------------- polish (fitting the hospital's side of the street)
	b.door_life()
	b.fire_lane(-75.0, 72.5, -45.0, 72.5, Vector2(0, -1))
	tries.call("prop_park_bench", "worn", -46.6, 73.3, 0.0)                   # waiting for a ride home from the clinic
	tries.call("prop_park_bench", "worn", -17.6, 19.0, 180.0)                 # coffee outside, facing the hospital
	tries.call("prop_bike_rack", "worn", -30.0, 18.8, 0.0)
	tries.call("prop_newspaper_box_blue", "worn", -16.4, 19.0, 180.0)
	tries.call("prop_vending_soda", "worn", -66.0, 18.0, 180.0)              # at the booth: the attendant's and the visitors'
	for m: Vector2 in [Vector2(-60.0, 45.0), Vector2(-25.0, 63.0), Vector2(-80.0, 60.0)]:
		b.add("prop_manhole_cover", "dirty", m.x, m.y, 0.0, false, 0.002)
	for d: Vector2 in [Vector2(-45.5, 30.0), Vector2(-80.5, 40.0), Vector2(-60.0, 63.0)]:
		b.add("prop_storm_drain_grate", "dirty", d.x, d.y, 0.0, false, 0.002)
	b.pole_line(-90.0, 99.3, -76.0, 99.3, 14.0)
	# polish 19 Nov (whole-zone pass): bollards keep the nose-in cars off the clinic walk, a fountain and a hydrant at the row
	for k in 9: tries.call("prop_bollard_concrete", "worn", -74.0 + k * 3.4, 72.8, 0.0)
	tries.call("prop_drinking_fountain", "worn", -62.0, 74.0, 180.0)
	tries.call("prop_hydrant_red", "worn", -44.8, 75.4, 0.0)
	tries.call("prop_recycling_receptacle", "worn", -27.0, 19.0, 180.0)        # cups from the coffee window
	# ---------------------------------------------------------------- wear
	b.building_wear()
	b.stall_wear(0.5)
	b.tyre_path(-80.0, 14.6, -80.0, 66.0); b.tyre_path(-45.0, 14.6, -45.0, 66.0); b.tyre_path(-8.7, 45.0, -45.0, 45.0)
	b.tyre_path(-8.7, 80.0, -40.0, 95.0)
	b.yard_wear(-92.0, 17.5, -9.0, 99.5, 0.9)
	b.finish("prop_wheel_stop_rubber")
	quit()
