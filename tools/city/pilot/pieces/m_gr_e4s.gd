extends SceneTree
## Piece m_gr_e4s (commercial strip growth, VARIANT B "bridge-mouth pad", 18 Nov): the narrow lot between the strip
## sample's grocery lot and Glorietta Blvd, south of 4th St (grid u 600-645.7, v -1185.7 to -1100), placed at the strip
## junction (500, 4, -1200). Flat (pad 4).
## Why this use (city planner): every car coming off the bridge passes this corner at the 4th St signal - the most
## seen frontage on the island, and too narrow (45 m) and too hard to reach for a store: neither 4th St (palm parkway)
## nor the ring (a bus stop at its only paved gap) gives it a driveway. A used-car lot is exactly that strip use: it
## WANTS to be seen, not reached by passing trade; its cars are driven in through the grocery lot next door (the sample
## m_se's two aisles end open at this edge, a shared access every strip has), test drives leave the same way.
## Layout: a front line of cars nose to the ring behind a white rail, two display rows back to back, the test-drive
## aisles, the sales office in the middle row with a hedge and a bench, the dealer's own service / detail garage at
## the back, the pylon on the corner, lot lights brighter than anywhere else (cars sell at night).
## Variant differences: no customer parking at all, iron bollards along the rail, vinyl rail, privet hedge, a golf
## cart (the lot porter), a hose reel cart and a wash bay at the garage, rubber wheel stops.
## Run once (tools/city/run/build.sh m_gr_e4s); never when locked.
const G := preload("res://tools/city/pilot/pieces/strip_grow_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const PALMS := ["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"]
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := G.new("m_gr_e4s", "B bridge-mouth pad")
	# ---------------------------------------------------------------- the sales office in the middle row
	var off := b.bld("commercial/com_shallow_books", 125.0, 50.0, 90.0, "bridge_motors_office", 0.75)   # faces the ring aisle (+x)
	b.paints.append(b.rect(121.5, 45.0, 131.5, 55.0, "concrete"))
	b.add("prop_park_bench", "worn", 129.8, 54.3, 90.0)                       # buyers wait for the paperwork, facing the cars
	b.add("plant_potted_succulent", "normal", 129.8, 45.8); b.add("prop_trash_receptacle", "worn", 129.9, 47.0, 0.0)
	for k in 4: b.add("hedge_privet_2m", "normal", 122.0 + k * 2.0, 44.5, 0.0)   # a low hedge on the office pad's north edge
	b.roof(off, ["prop_ac_condenser_compact", "prop_vent_plumbing"])
	# ---------------------------------------------------------------- display rows (all sale cars: no customer parking)
	b.stalls_z(18.0, 10, 136.5, 1.0)                                           # front line, nose to the ring
	b.stalls_z(57.0, 7, 136.5, 1.0)
	b.stalls_z(18.0, 9, 125.0, -1.0); b.stalls_z(18.0, 9, 125.0, 1.0)         # the double row ...
	b.stalls_z(57.0, 7, 125.0, -1.0); b.stalls_z(57.0, 7, 125.0, 1.0)         # ... broken by the office
	b.stalls_z(18.0, 9, 107.0, 1.0); b.stalls_z(48.0, 10, 107.0, 1.0)         # back row on the shared aisle
	b.island(107.0, 42.4, 112.5, 47.6, 1, ["tree_jacaranda_b"])
	# ---------------------------------------------------------------- frontage: rail, bollards, landscape, pylon
	b.island(100.5, 14.6, 145.4, 17.3, 4, PALMS)
	b.island(142.9, 17.3, 145.5, 78.0, 4, PALMS + ["palm_queen_a"])
	for k in 28: b.add("prop_bollard_iron", "worn", 142.3, 19.0 + k * 2.1, 0.0)    # a bollard line: no sale car rolls into the planting
	for k in 19: b.add("prop_bollard_iron", "worn", 102.0 + k * 2.1, 17.8, 0.0)
	b.add("prop_pylon_sign", "worn", 141.0, 15.9, 180.0)                      # BRIDGE MOTORS, facing 4th St and the bridge traffic
	b.island(136.6, 45.3, 142.4, 56.7, 1, ["palm_queen_b"])                    # the gap in the front line: a planted island
	for p: Vector2 in [Vector2(139.5, 49.0), Vector2(104.0, 78.5), Vector2(139.5, 79.0), Vector2(131.0, 46.0)]:
		b.add("prop_lot_light_pole", "worn", p.x, p.y, 0.0)
	# ---------------------------------------------------------------- the service / detail garage at the back
	var gar := b.bld("industrial/ind_repair", 112.0, 89.0, 180.0, "bridge_motors_service", 0.85, true, false)   # bays face the lot (north)
	b.paints.append(b.rect(103.0, 76.0, 121.0, 81.0, "concrete"))            # bay apron, the wash spot
	b.add("prop_hose_reel_cart", "worn", 122.5, 79.0, 0.0); b.add("prop_golf_cart_blue", "worn", 125.0, 86.0, 90.0)
	b.add("prop_channelizer_drum", "dirty", 122.0, 93.0, 0.0); b.add("prop_channelizer_drum", "dirty", 122.0, 94.0, 0.0)
	b.add("prop_dumpster_3yd_green", "rusty", 127.0, 95.5, 0.0)
	b.stalls_z(82.0, 5, 136.5, 1.0)                                            # cars waiting for detailing
	b.add("prop_sign_no_parking", "worn", 101.0, 77.0, 0.0)
	b.roof(gar, ["prop_vent_turbine", "prop_ac_condenser", "prop_solar_panel_x3"])
	# ---------------------------------------------------------------- polish pass (lots of props, fitting a used-car lot)
	var tries := func(base: String, cond: String, x: float, z: float, yaw: float) -> void:
		if b.free_at(x, z, b.half(base)): b.add(base, cond, x, z, yaw)
	b.door_life()
	b.pole_line(102.0, 99.3, 141.0, 99.3)
	for m: Vector2 in [Vector2(103.5, 60.0), Vector2(116.0, 50.0), Vector2(133.5, 62.0)]:
		b.add("prop_manhole_cover", "dirty", m.x, m.y, 0.0, false, 0.002)
	tries.call("prop_vending_soda", "worn", 123.0, 46.0, 90.0)              # buyers wait for the paperwork with a soda
	tries.call("prop_ice_chest", "worn", 123.0, 54.0, 90.0)
	tries.call("prop_cone_28in", "dirty", 104.5, 76.0, 0.0); tries.call("prop_cone_28in", "dirty", 120.0, 76.2, 0.0)   # the detail bay's wet floor
	tries.call("prop_water_barrier_white", "dirty", 101.5, 72.0, 0.0)      # keeps test drives off the bay apron
	tries.call("prop_recycling_receptacle", "worn", 121.8, 81.6, 0.0)
	tries.call("prop_channelizer_drum", "dirty", 120.6, 95.0, 0.0)
	tries.call("prop_trash_cart_black", "worn", 102.0, 96.5, 0.0)
	# ---------------------------------------------------------------- wear: polished aisles, water from the detail bay
	b.building_wear()
	b.stall_wear(0.25)                                                         # sale cars sit: little oil
	b.tyre_path(100.0, 26.0, 116.0, 26.0); b.tyre_path(100.0, 38.0, 116.0, 38.0)
	b.tyre_path(116.0, 20.0, 116.0, 74.0); b.tyre_path(133.5, 20.0, 133.5, 74.0)
	for k in 8: b.dec.add(14, Vector2(b.rr.randf_range(104.0, 120.0), b.rr.randf_range(76.0, 82.0)), b.rr.randf_range(0, 180), 3.0, 3.0, b.yfn, Color(1, 1, 1, 0.55))
	b.yard_wear(100.0, 17.5, 142.5, 99.5, 0.8)
	b.finish("prop_wheel_stop_rubber")
	quit()
