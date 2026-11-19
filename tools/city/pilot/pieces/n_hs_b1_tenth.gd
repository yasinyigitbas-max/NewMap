extends SceneTree
## Piece n_hs_b1_tenth (high street fill, block 1, part "Tenth Street Court"): u -100..-50, v 9.2..97.5, between the
## residential growth on the west (r_q_m200_0_se), 10th St on the north and the pilot's alley / pocket-park block b_sw
## on the east. Placed at grid [0, 4.0, 0], yaw 0 (the pilot's frame). Run once; never when locked.
##
## WHY (city planner): this is the step from the high street to the houses (CITY_PLAN: "apartments between the centre
## and the houses"). On 10th St, a three-storey corner building with a shop below (the neighbourhood's market, by the
## alley mouth where deliveries come in) and a Spanish-revival apartment house behind front gardens. Behind them a
## shared court (the residents' garden: kids' corner, a table under a sail, a barbecue, washing lines), closed on the
## south by a second row of garden apartments facing the court. The residential quadrant's rear alley (v 54..60) is
## carried on through to the pilot's alley, so the houses' back lane and the high street's service alley are one
## network. South of it, the residents' car park (40 stalls, open to both alleys) and, on the bank down to the houses,
## a community garden.
## LAND (n_hs_b1_site.gd): all of it at the high street level 4.15 except a 2 m edge on the court's west side and the
## 17 m bank on the alley / garden's west side, which come down to the residential edge (4.15 -> 3.67).
## 19 Nov pass 1: ground only, checked (ground_check / seams). Pass 2: buildings and props.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B1 := preload("res://tools/city/pilot/pieces/n_hs_b1_site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")

const X0 := -100.0
const X1 := -50.0
const ZS := 97.5            # south edge (shared with n_hs_b1_eleventh)
const Z_FRONT := 12.2       # building fronts / end of the front gardens and the market's forecourt
const Z_AL0 := 54.0         # the alley carried through from the houses
const Z_AL1 := 60.0

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["tree_torrey_pine_b", "normal", -85.2, 62.9, 123.0],
	["tree_jacaranda_a", "normal", -97.2, 62.4, 176.0],
	["tree_coral_b", "normal", -99.8, 32.4, 229.0],
	["tree_magnolia_a", "normal", -77.8, 32.9, 282.0],
	["palm_queen_a", "normal", -50.2, 34.4, 335.0],
	["tree_ficus_b", "normal", -59.2, 34.4, 28.0],
	["plant_iceplant_patch", "normal", -84.2, 32.9, 207.0, false],
	["plant_bougainvillea_mound", "normal", -55.2, 35.4, 278.0, false],
	["prop_sprinkler_impact", "worn", -99.8, 37.4, 349.0, false],
	["plant_bird_of_paradise", "normal", -98.8, 27.4, 60.0, false],
	["prop_sprinkler_popup", "worn", -80.8, 36.9, 131.0, false],
	["plant_agave_americana_small", "normal", -98.8, 13.9, 202.0, false],
	["plant_iceplant_patch", "normal", -98.8, 19.9, 273.0, false],
	["plant_bougainvillea_mound", "normal", -53.8, 30.4, 344.0, false],
	["plant_potted_succulent", "normal", -92.8, 32.9, 90.0, false],
	["prop_trash_receptacle", "worn", -73.8, 11.4, 180.0],
	["plant_potted_succulent", "normal", -76.2, 43.9, 270.0, false],
]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b1_tenth"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b1_tenth")
	var yc := B1.L(B1.g_court)        # local heights, court part (v < 54)
	var yw := B1.L(B1.g_west)         # local heights, alley + car park + garden (v >= 54)
	var e10 := func(x: float) -> float: return B1.edge10(x)
	var zf := func(_x: float) -> float: return Z_FRONT
	var y0 := 0.15
	# ================================================================ ground
	# front band (10th St edge .. fronts): the apartment house's front garden (a path to each of its three doors), the
	# passage into the court, the market's paved forecourt
	for r: Array in [[-100.0, -92.6, "grass"], [-92.6, -91.2, "concrete"], [-91.2, -86.2, "grass"], [-86.2, -84.8, "concrete"],
			[-84.8, -79.8, "grass"], [-79.8, -78.4, "concrete"], [-78.4, -75.8, "grass"], [-75.8, -50.0, "plaza"]]:
		H.band(g, String(r[2]), float(r[0]), float(r[1]), e10, zf, yc)
	# court (fronts .. alley)
	var court_paints := [
		[-75.6, Z_FRONT, -73.8, 41.2, "plaza"],         # the path from 10th through the passage, across the court, to the rear gap
		[-78.33, 41.18, -73.67, 52.5, "plaza"],         # rear gap between the two rear buildings (to the car park)
		[-97.0, 39.2, -52.0, 41.2, "plaza"],            # walk along the rear row's front doors
		[-75.78, Z_FRONT, -71.44, 27.8, "plaza"],       # passage between the two front buildings
		[-71.0, 30.0, -63.0, 37.0, "mulch"],            # kids' corner: bark under the swing, the slide, the climbing frame
		[-96.0, 29.0, -88.0, 36.5, "plaza"],            # sitting terrace: table under the sail, barbecue
		[-97.0, 41.18, -50.0, 54.0, "concrete"],        # under the rear row and its service strip along the alley
		[-94.95, Z_FRONT, -51.0, 27.8, "concrete"],     # under the front row
	]
	H.paint(g, X0, Z_FRONT, X1, Z_AL0, court_paints, "grass", yc)
	# the alley, carried through (its concrete gutter in line with the houses' alley)
	H.paint(g, X0, Z_AL0, X1, Z_AL1, [[X0, 56.6, X1, 57.4, "concrete"]], "asphalt", yw)
	H.step_face(g, Vector2(X0, Z_AL0), Vector2(X1, Z_AL0), yc, yw)
	# car park + community garden
	var lot := []
	# stall lines (2.8 m stalls, 5 m deep): rows at u -83..-78 (west), -71.5..-61.5 (double), -55..-50 (east)
	for row: Array in [[-83.0, -78.0], [-71.5, -66.5], [-66.5, -61.5], [-55.0, -50.0]]:
		var z := 61.5
		while z <= 89.5 + 1e-3:
			lot.append([float(row[0]), z - 0.05, float(row[1]), z + 0.05, "white"]); z += 2.8
	lot.append([-66.55, 61.5, -66.45, 89.5, "white"])                # the double row's middle line
	lot.append([-71.5, 60.0, -61.5, 61.5, "grass"])                  # planted island at the double row's north end (light, tree)
	lot.append([-71.5, 89.5, -61.5, 91.0, "grass"])                  # and at its south end
	lot.append([-83.0, 60.0, -50.0, 96.0, "asphalt"])                # the car park (entries: the alley, and the pilot's alley at its south-east)
	lot.append([-97.0, 75.4, -83.0, 77.0, "plaza"])                  # garden path from the car park
	lot.append([-97.0, 64.0, -86.0, 74.5, "mulch"])                  # garden beds (north)
	lot.append([-97.0, 79.0, -86.0, 94.0, "mulch"])                  # garden beds (south)
	H.paint(g, X0, Z_AL1, X1, ZS, lot, "grass", yw)
	_skirts(g, yc, yw)
	# ================================================================ buildings
	# 10th St faces north: yaw 180. Market corner (3 storeys, shop below, flats with balconies), apartment house
	K.building(bl, "apartments/apt_stucco3_peach", Vector3(-61.22, y0, 20.3), 180.0, "market")     # u -71.44..-51.0, front v 12.2; shop door u -61.22
	K.building(bl, "apartments/apt_spanish_revival", Vector3(-85.5, y0, 18.7), 180.0, "spanish")    # u -94.95..-75.78, front v 12.2; doors u -91.9 / -85.5 / -79.1
	# rear row facing the court (north): yaw 180, backs on the alley side
	K.building(bl, "apartments/apt_court_white", Vector3(-87.4, y0, 47.28), 180.0, "court_rear")       # u -97.0..-78.33, front v 41.18
	K.building(bl, "apartments/apt_garden_cream", Vector3(-62.2, y0, 47.28), 180.0, "garden_rear")      # u -73.67..-50.17, front v 41.18
	# ================================================================ props (each with its reason)
	var Pc := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yc, yaw, collide)
	var Pw := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yw, yaw, collide)
	# ---- the market's forecourt on 10th: ice and papers for the neighbourhood, bikes parallel to the shop front,
	# the door (u -61.22) kept clear
	Pc.call("prop_ice_chest", "worn", -66.0, 11.5, 180.0)
	Pc.call("prop_newspaper_box_red", "worn", -56.6, 11.75, 180.0)
	Pc.call("prop_newspaper_box_blue", "worn", -55.9, 11.75, 180.0)
	Pc.call("prop_trash_receptacle", "worn", -57.9, 11.75)
	Pc.call("prop_bike_rack", "worn", -69.6, 11.85, 0.0)
	# ---- the apartment house's front garden: low hedge along the walk (open at the three paths), planting by the
	# doors, the mailbox at the main path, a fan palm in the side yard
	H.hedge(props, Vector2(-99.6, 9.95), Vector2(-92.8, 9.95), yc)
	H.hedge(props, Vector2(-91.0, 9.95), Vector2(-86.4, 9.95), yc)
	H.hedge(props, Vector2(-84.6, 9.95), Vector2(-80.0, 9.95), yc)
	H.hedge(props, Vector2(-78.2, 9.95), Vector2(-75.9, 9.95), yc)
	Pc.call("plant_bougainvillea_mound", "normal", -97.6, 14.6, 0.0, false)          # against the house's side wall, off the hedge
	Pc.call("plant_bird_of_paradise", "normal", -87.9, 11.1, 0.0, false)
	Pc.call("plant_agave_americana_small", "normal", -83.0, 11.0, 0.0, false)
	Pc.call("prop_mailbox_post_metal", "worn", -84.45, 10.4, 180.0)
	Pc.call("palm_mexican_fan_a", "normal", -98.4, 19.0, 40.0)
	# ---- the court's west side closed to the neighbours' gardens: a privacy fence from the apartment house's back
	# corner to the rear row's front corner (posts at every joint)
	# (both ends run 0.2-1.1 m into the buildings' walls, hidden there, so they meet the walls by the kits' footprints)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-96.3, 24.2), Vector2(-96.3, 42.6), yc, 2.01)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-96.3, 24.2), Vector2(-94.4, 24.2), yc, 2.01)
	# ---- the court's east side on the pilot's alley: fence with the residents' side gate at its south end
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-51.15, 26.8), Vector2(-51.15, 39.9), yc, 2.01)
	Pc.call("fence_gate_privacy", "worn", -51.15, 40.45, 90.0)
	Pc.call("fence_post_privacy", "worn", -51.15, 41.0, 0.0)
	H.short_panel(props, "fence_wood_privacy", Vector2(-51.15, 41.0), Vector2(-51.15, 42.3), yc, 2.01)
	# ---- the court: kids' corner on bark, a bench watching it (parents), a table under its own sail with the
	# barbecue, washing lines on the lawn, two trees, lamps along the walk
	Pc.call("prop_swing_set", "worn", -67.0, 32.0, 0.0)
	Pc.call("prop_slide", "worn", -64.5, 34.6, 0.0)
	Pc.call("prop_play_structure", "worn", -69.4, 35.1, 90.0)
	Pc.call("prop_park_bench", "worn", -67.0, 38.55, 180.0)                           # faces the kids' corner
	Pc.call("prop_park_bench", "worn", -72.6, 33.5, 90.0)                             # the same, from the path side
	Pc.call("prop_picnic_table", "worn", -92.0, 32.8, 0.0)
	Pc.call("prop_shade_sail", "worn", -92.0, 32.8, 0.0, false)                       # over the table it shades
	Pc.call("prop_bbq_kettle", "worn", -89.0, 35.6, 0.0)
	Pc.call("prop_clothesline", "worn", -82.0, 32.6, 90.0)                            # washing in the sun, off the paths
	Pc.call("tree_coral_a", "normal", -93.2, 37.9, 75.0)
	Pc.call("tree_jacaranda_b", "normal", -57.0, 33.5, 140.0)
	Pc.call("prop_lamp_globe", "worn", -84.0, 38.7)
	Pc.call("prop_lamp_globe", "worn", -61.5, 38.7)
	# ---- back of house: condensers behind every building, the flats' bin carts on the service strip by the alley
	Pc.call("prop_ac_condenser", "worn", -92.6, 25.7, 0.0)                         # clear of the back doors (u -89.3 / -81.7)
	Pc.call("prop_hose_reel_cart", "worn", -80.0, 25.45, 0.0)
	Pc.call("prop_ac_condenser", "worn", -56.0, 28.5, 0.0)
	for x: float in [-89.0, -83.0, -66.0, -60.0]: Pc.call("prop_ac_condenser", "worn", x, 53.1, 0.0)
	for k in 3:
		Pc.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -95.5 + 0.8 * k, 53.15, 0.0)
		Pc.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -55.1 + 0.8 * k, 53.15, 0.0)
	# ---- the alley: a drain grate in the gutter at its low (west) end, where the water runs
	Pw.call("prop_storm_drain_grate", "worn", -97.0, 57.0, 0.0, false)
	# ---- car park: wheel stops in every stall, two lights and two trees on the planted islands
	for k in 10:
		var zc := 62.9 + 2.8 * k
		Pw.call("prop_wheel_stop_concrete", "worn", -82.4, zc, 90.0)
		Pw.call("prop_wheel_stop_concrete", "worn", -67.1, zc, 90.0)
		Pw.call("prop_wheel_stop_concrete", "worn", -65.9, zc, 90.0)
		Pw.call("prop_wheel_stop_concrete", "worn", -50.6, zc, 90.0)
	Pw.call("prop_lot_light_pole", "worn", -66.5, 60.75)
	Pw.call("prop_lot_light_pole", "worn", -66.5, 90.25)
	Pw.call("tree_magnolia_a", "normal", -69.8, 60.75, 30.0)
	Pw.call("tree_magnolia_b", "normal", -63.2, 90.25, 200.0)
	H.hedge(props, Vector2(-83.0, 96.75), Vector2(-51.0, 96.75), yw)                 # screens the lot from the garage walk
	# ---- community garden on the bank: picket fence with ONE gate at the path, beds, an arbor where the path ends,
	# a bench facing the beds, a table, compost carts against the fence, a shade tree
	H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(-99.4, 61.0), Vector2(-83.4, 61.0), yw, 2.0)
	H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(-99.4, 97.0), Vector2(-83.4, 97.0), yw, 2.0)
	H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(-99.4, 61.0), Vector2(-99.4, 97.0), yw, 2.0)
	H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(-83.4, 61.0), Vector2(-83.4, 97.0), yw, 2.0, "worn", [[15.0, 2.0]])
	Pw.call("fence_gate_picket", "worn", -83.95, 75.05, 0.0)                         # the gate stands open, swung back inside
	Pw.call("prop_garden_arbor", "worn", -96.0, 76.2, 90.0)
	Pw.call("prop_park_bench", "worn", -90.0, 77.75, 0.0)                             # faces the south beds
	Pw.call("prop_picnic_table", "worn", -90.5, 62.6, 0.0)
	Pw.call("prop_trash_cart_green", "worn", -98.4, 61.8, 0.0)
	Pw.call("prop_trash_cart_green", "worn", -97.6, 61.8, 0.0)
	Pw.call("tree_coral_b", "normal", -97.5, 95.0, 300.0)
	for pl: Array in [["plant_bird_of_paradise", -94.0, 66.5], ["plant_agave_americana_small", -90.0, 69.0], ["plant_iceplant_patch", -88.4, 66.4],
			["plant_bird_of_paradise", -94.5, 82.0], ["plant_iceplant_patch", -90.5, 85.5], ["plant_agave_americana_small", -88.0, 90.5], ["plant_bougainvillea_mound", -94.6, 89.8]]:
		Pw.call(String(pl[0]), "normal", float(pl[1]), float(pl[2]), 0.0, false)
	# ================================================================ wear (where its cause is)
	W.lane_wear(dec, rr, 57.0, X0, X1, false, yw)                                     # the alley's drip line
	for o: Array in [[-80.5, 62.9], [-80.5, 68.5], [-80.5, 74.1], [-80.5, 82.5], [-69.0, 65.7], [-69.0, 71.3], [-69.0, 79.7], [-69.0, 85.3],
			[-64.0, 62.9], [-64.0, 76.9], [-64.0, 82.5], [-52.5, 65.7], [-52.5, 74.1], [-52.5, 79.7], [-52.5, 88.1]]:
		W.oil(dec, rr, Vector2(float(o[0]), float(o[1])), 90.0, yw, 0.7)               # the residents' cars stand here every night
	for c: Array in [[-74.5, 70.0], [-58.0, 80.0], [-74.0, 93.0], [-60.0, 93.5], [-90.0, 57.0], [-62.0, 56.0]]:
		dec.add(0, Vector2(float(c[0]), float(c[1])), rr.randf_range(0, 360), 4.0, 1.6, yw, Color(0.14, 0.14, 0.14, 0.9))
	for d: Array in [[-94.7, 53.15], [-54.3, 53.15]]:
		dec.add(14, Vector2(float(d[0]), float(d[1])), 0.0, 3.0, 1.4, yc, Color(1, 1, 1, 0.6))     # under the bin carts
	dec.add(14, Vector2(-61.22, 11.0), 0.0, 2.4, 1.8, yc, Color(1, 1, 1, 0.45))        # in front of the market door
	dec.add(14, Vector2(-74.7, 20.0), 0.0, 1.2, 14.0, yc, Color(1, 1, 1, 0.3))         # the passage's walking line
	dec.add(14, Vector2(-67.0, 32.0), 0.0, 2.6, 1.6, yc, Color(0.78, 0.7, 0.48, 0.5))  # bark scuffed under the swings
	H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b1_tenth")
	quit()

func _skirts(g: K.Ground, yc: Callable, yw: Callable) -> void:
	var yall := func(x: float, z: float) -> float: return float(yc.call(x, z)) if z < Z_AL0 else float(yw.call(x, z))
	var wbot := func(_x: float, z: float) -> float: return B1.west_skirt_bot(z)
	H.skirt(g, Vector2(X0, 9.2), Vector2(X0, Z_AL0), yc, "wall", wbot)
	H.skirt(g, Vector2(X0, Z_AL0), Vector2(X0, ZS), yw, "wall", wbot)
	# 10th St edge (flush with the walk; the skirt hides under the walk's edge) and the pilot's alley edge
	var pts := PackedVector2Array()
	for k in 26: pts.append(Vector2(lerpf(X0, X1, k / 25.0), B1.edge10(lerpf(X0, X1, k / 25.0))))
	for k in pts.size() - 1: H.skirt(g, pts[k], pts[k + 1], yc, "concrete")
	H.skirt(g, Vector2(X1, B1.edge10(X1)), Vector2(X1, ZS), yall, "wall")
