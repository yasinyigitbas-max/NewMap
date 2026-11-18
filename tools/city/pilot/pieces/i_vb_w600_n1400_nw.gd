extends SceneTree
## Piece i_vb_w600_n1400_nw (industrial growth, VARIANT B "fleet", second dressing; 18 Nov, not locked).
## Site: NW corner of 3rd St (the arterial, the bridge traffic's way to the base) x G Ave, world
## (-700..-600, -1500..-1400); the sample's i_ne (Harbor Steel) is its west neighbour, the seafood block its north one.
## 3RD STREET TRUCK SERVICES: the trucks of the whole district pass by here on 3rd St. This block feeds them: a
## drivers' diner (walk-in), a truck wash, a tyre store, a truck-parts counter (walk-in), a heavy repair shop and a
## diesel island. Drivers leave their own cars at the back fence while they are out on a run.
## Planner's reasons:
##  - 3rd St narrows to the truck section toward J Ave; the frontage follows the measured property line, and every
##    building stands 0.5 m behind the deepest walk over its width (forecourt where the street narrows).
##  - The wash takes trucks from the yard and lets them out at 3rd St's own apron (38 m); G Ave's two aprons (44, 79 m)
##    are the yard's gates.
##  - The north edge is this block's block wall (opaque, tagged): it is shared with the seafood block, which adds none.
##    The west edge is the sample's chain-link: nothing is added (no double fence).
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/ind_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const NAME := "i_vb_w600_n1400_nw"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := -1.0; var sz := -1.0
	var m: Dictionary = await G.measure(self, Vector3(-600.0, 2.0, -1400.0), sx, sz)
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(NAME)
	var stl: Array = []
	var paints: Array = G.stall_paint(sx, sz, 30.0, 18, 94.6, 1.0)
	paints.append([sx * 61.0, sz * 49.0, sx * 47.0, sz * 45.0, "concrete"])        # the diesel island's slab
	G.floor(g, m, sx, sz, paints)
	var B: Array = []
	B.append([G.put(bl, props, sx, sz, "x", 22.5, G.front_x(m, 22.0, 35.0), "ck/mod_fastfood", "truck_stop_diner"), "ck/mod_fastfood"])   # not ck_grt_row2: the room's storefront band ran across its door (Yasin 18 Nov)
	B.append([G.put(bl, props, sx, sz, "x", 43.0, G.front_x(m, 43.0, 69.2), "services/svc_carwash", "truck_wash"), "services/svc_carwash"])
	B.append([G.put(bl, props, sx, sz, "x", 72.0, G.front_x(m, 72.0, 90.0), "ck/mod_stg_row_roofed", "tyre_store"), "ck/mod_stg_row_roofed"])
	var fz := G.front_z(m, 22.0, 100.0)
	B.append([G.put(bl, props, sx, sz, "z", 28.5, fz, "ck/ck_svc_trade_1d", "truck_parts"), "ck/ck_svc_trade_1d"])
	B.append([G.put(bl, props, sx, sz, "z", 50.0, fz, "industrial/ind_repair", "heavy_repair"), "industrial/ind_repair"])
	G.frontage(props, m, sx, sz, "x", [[22.5, 34.5], [43.0, 69.2], [72.0, 90.0]], [38.0], "chain", 34.5, 99.8, [], [38.0])
	G.frontage(props, m, sx, sz, "z", [[28.5, 40.5], [50.0, 68.0]], [44.0, 79.0], "chain", 40.5, 99.8)
	G.wall(props, sx, sz, Vector2(G.ev(m, 99.8) + 0.2, 99.8), Vector2(99.6, 99.8), "fence_cmu_wall", 6)
	# ---- the diesel island: two pumps on their slab, iron bollards round it, the tank behind a k-rail
	for k in 2: I.add(props, "prop_fuel_pump", "clean", G.q(sx, sz, 51.0 + k * 6.0, 47.0), 90.0)
	for bu: float in [47.6, 54.0, 60.4]:
		for bv: float in [45.4, 48.6]: I.add(props, "prop_bollard_iron", "rusty", G.q(sx, sz, bu, bv), 0.0)
	I.add(props, "prop_tank_vertical", "dirty", G.q(sx, sz, 70.0, 56.0), 0.0)
	for k in 2: I.add(props, "prop_k_rail", "dirty", G.q(sx, sz, 64.4, 54.0 + k * 4.2), 90.0)    # the tank is 9 m across
	# ---- the tyre store's back: rolloff of scrap tyres, the heavy repair shop's drums, the wash's soap drums
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", G.q(sx, sz, 60.0, 86.0), 90.0)
	for k in 6: I.add(props, "prop_channelizer_drum", "dirty", G.q(sx, sz, 27.5 + (k / 3) * 0.85, 70.0 + (k % 3) * 0.85), 0.0)
	for k in 3: I.add(props, "prop_channelizer_drum", "worn", G.q(sx, sz, 40.0 + k * 0.85, 33.0), 0.0)
	I.add(props, "prop_propane_tank_250gal", "rusty", G.q(sx, sz, 28.0, 48.5), 0.0)
	I.back_door_clutter(props, rr, G.q(sx, sz, 28.5, 29.5), 0.0, "gas")      # the diner's fryer gas and bins
	I.back_door_clutter(props, rr, G.q(sx, sz, 25.5, 34.0), 90.0, "shop")    # the parts counter's cardboard
	for p: Vector2 in [Vector2(40.0, 60.0), Vector2(75.0, 70.0), Vector2(50.0, 86.0), Vector2(85.0, 45.0)]:
		I.add(props, "prop_lot_light_pole", "dirty", G.q(sx, sz, p.x, p.y), 0.0)
	I.add(props, "prop_utility_pole_transformer", "dirty", G.q(sx, sz, 97.0, 60.0), 0.0)
	# a billboard over the tyre store, faced to the 3rd St traffic (the arterial is where they pay)
	I.add(props, "prop_billboard", "worn", G.q(sx, sz, 91.0, 30.0), 0.0)
	# concrete bollards between the diner's side wall and the wash's exit: trucks cut that corner
	for bv: float in [17.0, 20.0, 23.0, 26.0]: I.add(props, "prop_bollard_concrete", "dirty", G.q(sx, sz, 35.1, bv), 0.0)
	# ---- drivers' own cars along the back wall
	stl.append_array(G.stalls(props, sx, sz, 30.0, 18, 94.6, 1.0, "prop_wheel_stop_concrete", [7]))
	# ---- the diner's sidewalk: a bench facing 3rd St (drivers wait for a lift), bin, paper box; the parts counter's rack
	# one bin at the diner's corner, 3 m past its west door (doors at u 27.3 and 33.3); no paper box: at night the pair
	# read as something blocking the door (Yasin 18 Nov)
	G.walk_prop(props, m, sx, sz, "x", 24.2, "prop_trash_receptacle", "dirty")
	G.walk_prop(props, m, sx, sz, "z", 32.5, "prop_bike_rack", "rusty")
	# ---- wear: the heaviest in the zone: oil at the pumps, wash water out of the wash, tyre scrub on the turns
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	for k in 8: W.oil(dec, rr, Vector2(sx * rr.randf_range(48.0, 60.0), sz * rr.randf_range(43.0, 51.0)), 90.0, S.walk_y, 0.95)
	dec.add(14, Vector2(sx * 56.0, sz * 33.5), 0.0, 22.0, 5.0, S.walk_y, Color(1, 1, 1, 0.6))
	I.truck_path(dec, rr, Vector2(sx * 9.0, sz * 44.0), Vector2(sx * 54.0, sz * 44.0))
	I.truck_path(dec, rr, Vector2(sx * 9.0, sz * 79.0), Vector2(sx * 60.0, sz * 75.0))
	I.truck_path(dec, rr, Vector2(sx * 72.0, sz * 36.0), Vector2(sx * 40.0, sz * 36.0))
	for k in 5: dec.add(15, Vector2(sx * rr.randf_range(30.0, 80.0), sz * rr.randf_range(40.0, 85.0)), rr.randf_range(0, 180), 4.0, 4.0, S.walk_y, Color(1, 1, 1, 0.5))
	I.yard_wear(dec, rr, sx, sz, 22.0, 32.0, 99.0, 92.0, 1.8)
	root.set_meta("stalls", stl)
	I.finish(root, g, props, dec, NAME)
	quit()
