extends SceneTree
## Piece n_hs_b1_amber (high street fill, block 1, part "Amber west, 10th-11th south half"): u -50..-16,
## v 97.5..190.3: Amber Ave from the pilot's hotel (b_sw ends at v 97.5) to the 11th St corner, the rear lot behind it
## and the pilot's service alley carried on south to the cross alley. Placed at grid [0, 4.0, 0], yaw 0. Run once;
## never when locked.
##
## WHY (architect / planner): the same high street continuing, but built up (Yasin: the first high street was too thin,
## 1-2 storeys and empty rear lots). Street wall at zero setback like the pilot, 2-4 storeys: a three-storey brick row
## next to the hotel (shops below, flats above), then a PASEO (the walk from the town's parking garage behind to the
## shops), the block's landmark, the TOWN LIBRARY set back behind a small plaza with two jacarandas (Coronado's library
## stands on its main street), an Orange-style row of shops, a coffee house next to the library, and a four-storey brick
## corner on 11th St, the road to the beach.
## Behind: the rear lot off the service alley (stalls along the alley like the pilot's), the library's staff parking
## and book-van strip, the corner yard (residents' and shop parking off one aisle) closed to 11th St by a block wall
## and planting. Back of house on every building: bins by who uses them (food = green dumpster), condensers, meters.
## LAND: level at the high street height 4.15 like the pilot; only the corner yard eases over its last 14 m down to the
## 11th St walk (4.13 .. 3.99 at its edge).
## 19 Nov pass 1: ground only, checked (ground_check / seams 0.8 cm max). Pass 2: buildings and props.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B1 := preload("res://tools/city/pilot/pieces/n_hs_b1_site.gd")

const X0 := -50.0
const X1 := -16.0
const ZN := 97.5
const ZS := 190.3
## the frontage, north to south (v): brick row, paseo, library (set back), shop row, coffee house, corner
const Z_PASEO := [116.06, 118.86]
const Z_LIB := [118.86, 144.03]
const LIB_FRONT := -22.0          # the library's front wall (6 m behind the building line; its porch reaches -18.05)
const TREES := [123.3, 139.6]     # plaza trees (in wells), clear of the library door (v 131.31)

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b1_amber"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b1_amber")
	var yy := B1.L(B1.g_yard)
	var y0 := 0.15                     # local pad height of everything level (4.15)
	# ================================================================ ground
	var paints: Array = []
	for tz: float in TREES: paints.append([-20.25, tz - 0.75, -18.75, tz + 0.75, "-"])     # tree wells (drawn by S.tree_well)
	# stall lines: north lot (off the alley, u -44..-39), library staff (parallel, u -44..-41.6), corner yard (west row
	# u -50..-45 facing east, east row u -39..-34 facing west, one 6 m aisle between)
	for z: float in [99.2, 101.9, 104.6, 107.3, 110.0, 112.7, 115.4]: paints.append([-44.0, z - 0.05, -39.0, z + 0.05, "white"])
	for z: float in [120.0, 126.7, 133.4, 140.1]: paints.append([-44.0, z - 0.05, -41.6, z + 0.05, "white"])
	for k in 15:
		var z := 148.0 + 2.7 * k
		paints.append([-50.0, z - 0.05, -45.0, z + 0.05, "white"])
		paints.append([-39.0, z - 0.05 - 2.0, -34.0, z + 0.05 - 2.0, "white"])
	paints.append_array([
		[-44.0, Z_PASEO[0], X1, Z_PASEO[1], "plaza"],                  # the paseo: garage -> Amber (crosses the lot as a walk)
		[LIB_FRONT, Z_LIB[0], X1, Z_LIB[1], "plaza"],                  # library plaza
		[X0, ZN, -44.0, 146.0, "asphalt"],                             # the service alley, carried on south
		[-30.0, ZN, X1, ZS, "concrete"],                               # under the frontage buildings
		[-39.5, Z_LIB[0], LIB_FRONT, Z_LIB[1], "concrete"],            # under the library
		[X0, 187.3, -32.0, ZS, "grass"],                               # planting strip between the corner yard and 11th St
	])
	H.paint(g, X0, ZN, X1, ZS, paints, "asphalt", yy)
	for tz: float in TREES: S.tree_well(g, Vector2(-19.5, tz))
	H.skirt(g, Vector2(X1, ZN), Vector2(X1, ZS), yy, "concrete")
	H.skirt(g, Vector2(X0, ZS), Vector2(X1, ZS), yy, "concrete")
	H.skirt(g, Vector2(X0, ZN), Vector2(X1, ZN), yy, "concrete")
	# ================================================================ buildings (front on u -16 facing Amber: yaw 90)
	K.building(bl, "urban/urb_brick_row", Vector3(-23.0, y0, 106.88), 90.0, "brick_row")              # shops + 2 floors of flats; doors v 98.98 / 104.98 / 110.98
	K.building(bl, "civic/civ_library", Vector3(-30.0, y0, 131.31), 90.0, "library")                # the landmark, set back; door v 131.31
	K.building(bl, "commercial/com_orange_row", Vector3(-23.0, y0, 153.48), 90.0, "orange_row")        # three shops; doors v 145.72 / 155.40 / 157.56
	K.building(bl, "commercial/com_cafe_seaside", Vector3(-23.0, y0, 166.70), 90.0, "cafe")      # coffee house; door v 168.46
	K.building(bl, "urban/urb_brick_corner", Vector3(-24.0, y0, 181.07), 90.0, "corner")           # 4 storeys on the 11th St corner; door v 174.27
	# ================================================================ props (each with its reason)
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yy, yaw, collide)
	# ---- library plaza: shade, a place to sit and read in the sun, bikes, the entrance kept clear (door v 131.31 +- 2.5)
	P.call("tree_jacaranda_a", "normal", -19.5, TREES[0], 35.0)                       # purple shade over the benches (wells in the paving)
	P.call("tree_jacaranda_b", "normal", -19.5, TREES[1], 210.0)
	P.call("prop_park_bench", "worn", -20.9, 126.6, 90.0)                             # faces Amber: people-watching under the north tree
	P.call("prop_park_bench", "worn", -20.9, 136.2, 90.0)                             # the same under the south tree
	P.call("prop_trash_receptacle", "worn", -20.9, 124.6)                            # at the bench end, away from the door
	P.call("prop_recycling_receptacle", "worn", -20.9, 138.2)
	P.call("prop_bike_rack", "worn", -21.5, 120.5, 90.0)                              # parallel to the facade, out of the walk
	P.call("plant_potted_leafy", "normal", -17.2, 128.3, 0.0, false)                  # pair of planters flanking the entrance axis
	P.call("plant_potted_leafy", "normal", -17.2, 134.3, 0.0, false)
	P.call("prop_drinking_fountain", "worn", -21.4, 142.9, 90.0)                      # at the plaza's south end, by the coffee side
	P.call("prop_lamp_victorian", "worn", -16.7, 119.5)                               # the plaza's corners lit like the street
	P.call("prop_lamp_victorian", "worn", -16.7, 143.4)
	# ---- paseo (garage -> Amber): lit along the library's wall, nothing else in the 2.8 m walk
	P.call("prop_lamp_globe", "worn", -24.0, 118.55)
	P.call("prop_lamp_globe", "worn", -35.0, 118.55)
	# ---- coffee house: pots by its door at the building line (as the pilot's cafes), newspaper boxes for the morning
	P.call("plant_potted_succulent", "normal", -15.65, 167.31, 0.0, false)
	P.call("plant_potted_succulent", "normal", -15.65, 169.61, 0.0, false)
	P.call("prop_newspaper_box_blue", "worn", -15.75, 163.6, 90.0)
	P.call("prop_newspaper_box_red", "worn", -15.75, 164.3, 90.0)
	# ---- north rear lot (behind the brick row): its back of house, the lot lit at night
	P.call("prop_dumpster_3yd_green", "worn", -30.95, 98.9, 90.0)                     # the deli in the brick row (clear of the back doors at v 100.88 / 106.88 / 112.88)
	P.call("prop_recycling_receptacle", "worn", -30.6, 102.6, 90.0)
	P.call("prop_ac_condenser", "worn", -30.75, 114.6, 90.0)
	P.call("prop_lot_light_pole", "worn", -38.5, 115.6)
	P.call("prop_golf_cart_white", "worn", -41.5, 113.35, 90.0)                       # a Coronado touch: someone came in by golf cart
	# ---- library service strip: staff cars along the alley, the book van's place, its recycling
	P.call("prop_dumpster_3yd_blue", "worn", -40.45, 142.6, 90.0)                     # paper and card: blue (clear of the back door at v 140.31)
	P.call("prop_ac_condenser", "worn", -40.2, 122.0, 90.0)
	P.call("prop_ac_condenser", "worn", -40.2, 124.0, 90.0)
	# ---- south rear lot / corner yard
	P.call("prop_dumpster_3yd_blue", "worn", -31.0, 145.6, 90.0)                      # the shop row (boxes); its back doors at v 148.68 / 154.68 / 160.68 kept clear
	P.call("prop_recycling_receptacle", "worn", -30.6, 147.3, 90.0)
	P.call("prop_ac_condenser", "worn", -30.75, 150.3, 90.0)
	P.call("prop_ac_condenser", "worn", -30.75, 159.2, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", -31.0, 164.6, 90.0)                     # the coffee house (grounds, milk cartons)
	P.call("prop_lot_light_pole", "worn", -32.0, 156.0)
	P.call("prop_dumpster_3yd_green", "worn", -33.0, 178.0, 90.0)                     # the corner's ground-floor shop
	for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -33.0, 182.4 + 0.8 * k, 90.0)   # the flats above (back door v 181.07, loading door 184.8..187.4 clear)
	P.call("prop_ac_condenser", "worn", -32.75, 172.4, 90.0)
	# ---- service sides: meter banks and gas meters on the back walls (between the back doors' and windows' places:
	# check_life reads the walls' openings), downspouts at the back corners, the flats' bin carts
	for m: Array in [[-30.02, 108.2], [-38.02, 126.6]]:     # (the shop row's back wall has small windows where a bank would go: none there)
		for k in 3: H.put(props, "prop_meter_electric", "worn", float(m[0]), float(m[1]) + 0.42 * k, func(x: float, z: float) -> float: return float(yy.call(x, z)) + 1.05, -90.0, false)
		H.put(props, "prop_meter_gas", "rusty", float(m[0]), float(m[1]) + 1.7, func(x: float, z: float) -> float: return float(yy.call(x, z)) + 0.2, -90.0, false)
	for z: float in [115.85, 144.4, 163.4, 170.6]: H.put(props, "prop_downspout_3m", "worn", -30.0, z, yy, -90.0, false)
	for k in 3:
		P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -30.55, 103.6 + 0.8 * k, 90.0)    # flats over the brick row
		P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -30.55, 156.0 + 0.8 * k, 90.0)    # flats over the shop row
	P.call("prop_golf_cart_blue", "worn", -36.5, 166.25, 90.0)                        # another cart in the yard's east row
	P.call("prop_shopping_cart", "worn", -32.4, 176.2, 30.0)                          # strayed from the market on 10th: someone always leaves one
	# the yard's block wall to 11th St (the yard's privacy and the street's tidy edge), a tag on its yard side by the
	# dumpster, coral trees on the street side in the planting strip
	for k in 9:      # from the corner building's back wall (u -32) west to the lot line wall of n_hs_b1_eleventh
		var x := -32.0 - 2.03 * (k + 0.5)
		P.call("fence_graffiti_cmu_panel" if k == 4 else "fence_cmu_wall", "worn", x, 188.4, 0.0)
	P.call("tree_coral_a", "normal", -45.0, 189.6, 20.0)
	P.call("tree_coral_b", "normal", -37.0, 189.6, 160.0)
	# wheel stops: every stall that faces something (the alley stalls nose to the lot, the yard rows nose to wall / strip)
	for z: float in [100.55, 103.25, 105.95, 108.65, 111.35, 114.05]: P.call("prop_wheel_stop_concrete", "worn", -39.6, z, 90.0)
	for k in 14:
		P.call("prop_wheel_stop_concrete", "worn", -49.4, 149.35 + 2.7 * k, 90.0)
		P.call("prop_wheel_stop_concrete", "worn", -34.6, 147.35 + 2.7 * k, 90.0)
	# ================================================================ wear (where its cause is)
	var oil := [[-41.5, 100.55], [-41.5, 105.95], [-41.5, 108.65], [-41.5, 111.35], [-42.8, 123.3], [-42.8, 136.7],
		[-47.5, 149.35], [-47.5, 154.75], [-47.5, 160.15], [-47.5, 165.55], [-47.5, 173.65], [-47.5, 179.05],
		[-36.5, 150.05], [-36.5, 155.45], [-36.5, 163.55], [-36.5, 168.95], [-36.5, 176.95], [-36.5, 182.35]]
	for o: Array in oil: W.oil(dec, rr, Vector2(float(o[0]), float(o[1])), 90.0, yy, 0.7)          # cars stand here every day
	var cracks := [[-47.0, 104.0], [-46.5, 121.0], [-47.5, 138.0], [-41.0, 147.0], [-42.0, 158.0], [-42.0, 172.0], [-41.5, 184.0], [-35.0, 106.0]]
	for c: Array in cracks:
		dec.add(0, Vector2(float(c[0]), float(c[1])), rr.randf_range(0, 360), 4.0, 1.6, yy, Color(0.14, 0.14, 0.14, 0.9))   # old asphalt, sealed
	W.lane_wear(dec, rr, -47.0, ZN, 146.0, true, yy)                                  # the alley: the drip line down the middle
	W.lane_wear(dec, rr, -42.0, 146.0, 186.0, true, yy)                               # the yard aisle
	for d: Array in [[-31.0, 164.6, 3.0, 2.4], [-33.0, 178.0, 3.0, 2.4], [-40.45, 142.6, 3.0, 2.4], [-33.0, 183.2, 1.4, 3.2], [-30.95, 98.9, 3.0, 2.4], [-31.0, 145.6, 3.0, 2.4]]:
		dec.add(14, Vector2(float(d[0]), float(d[1])), 90.0, float(d[2]), float(d[3]), yy, Color(1, 1, 1, 0.7))   # grime under the bins: they leak
	# the parking garage's mouth (across the alley): cars swing in and out and brake at the barrier
	dec.add(8, Vector2(-47.6, 114.6), 35.0, 0.9, 5.0, yy, Color(1, 1, 1, 0.35))
	dec.add(8, Vector2(-47.6, 118.3), -35.0, 0.9, 5.0, yy, Color(1, 1, 1, 0.35))
	W.oil(dec, rr, Vector2(-48.3, 116.45), 90.0, yy, 0.6)
	dec.add(14, Vector2(-19.0, 131.31), 90.0, 2.4, 3.0, yy, Color(1, 1, 1, 0.4))     # worn paving in front of the library door
	dec.add(14, Vector2(-25.0, 117.46), 0.0, 9.0, 1.4, yy, Color(1, 1, 1, 0.3))      # the paseo's walking line
	H.finish(root, g, props, dec, "n_hs_b1_amber")
	quit()
