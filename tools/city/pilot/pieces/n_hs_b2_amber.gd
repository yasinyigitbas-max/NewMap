extends SceneTree
## Piece n_hs_b2_amber (high street fill, block 2, part "Amber west, 9th-10th north half"): u -50..-16, v -190.3..-97.5:
## Amber Ave from the pilot's block b_nw (it ends at v -97.5) up the rise to the 9th St corner, the rear lot behind it
## and the pilot's service alley carried on north to the cross alley. Placed at grid [0, 4.0, 0], yaw 0. Run once;
## never when locked.
##
## WHY (architect / planner): Amber climbs 2 m here (3.5 % at its steepest). The street wall continues, built up and
## stepping up the hill one level pad per building like an old main street: a three-storey stucco block (taqueria below,
## flats above), the town's savings bank, then the block's landmark, the RED-SPIRE CHURCH, set back behind a level
## forecourt on the rise so its spire closes the view up Amber; beside it the church walk, the way from Amber to its
## community hall on 9th St behind; an Orange-style corner pair of shops (ice cream, gallery), a three-storey brick row
## with fire escapes (hardware below), a brick corner on 9th (bookshop). Behind: the rear lot with stalls off the alley,
## the yard north of the church walk for the shops' staff and deliveries.
## LAND (n_hs_b2_site.gd): the whole part follows Amber's own rise (flat across, rising north). Each building stands on
## a level pad at the walk height of its door; a 0.6 m band along Amber follows the walk exactly; the faces between the
## pads and the sloping ground are low retaining walls / plinths.
## PASS 1 = ground only (checked before anything stands on it); PASS 2 = buildings and props.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B2 := preload("res://tools/city/pilot/pieces/n_hs_b2_site.gd")

const X0 := -50.0
const X1 := -16.0
const ZN := -190.3
const ZS := -97.5
const XF := -16.6          # building fronts (the 0.6 m band in front follows the walk)
const WALK := [-152.4, -147.59]     # the church walk, Amber -> community hall
## the frontage (v ranges of the meshes), door v, pad = the walk height at the door
## [label, folder, v_north, v_south, centre v, centre u, door v, depth back u]
const FRONT := [
	["stucco", "apartments/apt_stucco3_cream", -118.14, -97.7, -107.92, -22.6, -107.92, -30.4],
	["bank", "commercial/com_bank", -133.14, -118.24, -125.69, -23.6, -125.69, -31.6],
	["church", "landmarks/lmk_red_spire_church", -147.59, -133.24, -140.74, -32.0, -140.74, -43.72],
	["shops", "commercial/com_orange_corner", -165.3, -152.4, -158.85, -23.6, -158.85, -31.3],
	["hardware", "ck/ck_brk3_row2_fe", -177.4, -165.4, -171.4, -23.6, -170.3, -30.9],
	["corner", "ck/ck_brk3_corner2", -189.5, -177.5, -183.5, -23.6, -188.4, -30.9],
]

func _init() -> void: _run.call_deferred()

static func pad_y(d: Array) -> float: return B2.amber(float(d[6]))

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b2_amber"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b2_amber")
	var yf := B2.L(B2.g)
	# ================================================================ ground
	var paints: Array = []
	for d: Array in FRONT:
		var x0: float = float(d[7]) - 0.3
		var x1: float = -21.0 if String(d[0]) == "church" else XF
		paints.append([x0, float(d[2]), x1, float(d[3]), "-"])            # the building's pad (drawn below, level)
	paints.append([-21.0, -147.59, XF, -133.24, "-"])                     # the church forecourt (level, below)
	# stalls: rear lot off the alley (u -44..-39), north yard: west row u -50..-45, east row u -40..-35, aisle between
	for k in 12: paints.append([-44.0, -99.2 - 2.7 * k - 0.05, -39.0, -99.2 - 2.7 * k + 0.05, "white"])
	for k in 13:
		paints.append([X0, -155.0 - 2.7 * k - 0.05, -45.0, -155.0 - 2.7 * k + 0.05, "white"])
		paints.append([-40.0, -155.0 - 2.7 * k - 0.05, -35.0, -155.0 - 2.7 * k + 0.05, "white"])
	paints.append_array([
		[X0, WALK[0], XF, WALK[1], "plaza"],                     # the church walk
		[XF, ZN, X1, ZS, "concrete"],                            # the band along Amber's walk
		[X0, ZN, X1, -189.6, "concrete"],                        # the band along 9th St's walk
	])
	H.paint(g, X0, ZN, X1, ZS, paints, "asphalt", yf)
	for d: Array in FRONT:
		var y := pad_y(d) - B2.PAD_Y
		var x0: float = float(d[7]) - 0.3
		var x1: float = -21.0 if String(d[0]) == "church" else XF
		H.level_pad(g, "concrete", x0, float(d[2]), x1, float(d[3]), y, yf)
	var ych := pad_y(FRONT[2]) - B2.PAD_Y
	H.level_pad(g, "plaza", -21.0, -147.59, XF, -133.24, ych, yf, "nse")          # forecourt: its west edge is the church pad
	# skirts (all flush with their neighbours: Amber's walk, 9th St's walk, the pilot's b_nw)
	H.skirt(g, Vector2(X1, ZN), Vector2(X1, ZS), yf, "concrete")
	H.skirt(g, Vector2(X0, ZN), Vector2(X1, ZN), yf, "concrete")
	H.skirt(g, Vector2(X0, ZS), Vector2(X1, ZS), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	H.finish(root, g, props, dec, "n_hs_b2_amber")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	# ================================================================ buildings (front on u -16.6 facing Amber: yaw 90)
	for d: Array in FRONT:
		K.building(bl, String(d[1]), Vector3(float(d[5]), pad_y(d) - B2.PAD_Y, float(d[4])), 90.0, String(d[0]))
	var ych := func(_x: float, _z: float) -> float: return pad_y(FRONT[2]) - B2.PAD_Y
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var Pc := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, ych, yaw, collide)
	# ---- church forecourt (level; the door v -140.74 kept clear +- 3 m): planters flanking the axis, benches at its
	# ends facing Amber for people waiting after the service, the corners lit like the street
	Pc.call("plant_potted_leafy", "normal", -19.2, -137.4, 0.0, false)
	Pc.call("plant_potted_leafy", "normal", -19.2, -144.1, 0.0, false)
	Pc.call("prop_park_bench", "worn", -20.3, -134.9, 90.0)
	Pc.call("prop_park_bench", "worn", -20.3, -146.0, 90.0)
	Pc.call("prop_lamp_victorian", "worn", -16.95, -133.7)
	Pc.call("prop_lamp_victorian", "worn", -16.95, -147.1)
	# ---- the church walk (Amber -> the community hall): lit along the shop wall, nothing else in it
	for x: float in [-23.0, -33.0, -43.0]: P.call("prop_lamp_globe", "worn", x, -152.0)
	# ---- shop doors on the band (as the pilot's): pots by the taqueria and the ice-cream shop, the hardware's propane
	# exchange cage beside (not in front of) its door, papers at the bookshop corner
	for z: float in [-106.77, -109.07]: P.call("plant_potted_succulent", "normal", -16.25, z, 0.0, false)
	for z: float in [-156.62, -155.9]: P.call("plant_potted_succulent", "normal", -16.25, z, 0.0, false)
	for k in 3: P.call("prop_propane_cylinder_100lb", "worn", -16.3, -166.2 - 0.45 * k)
	P.call("prop_newspaper_box_red", "worn", -16.3, -178.3, 90.0)
	P.call("prop_newspaper_box_blue", "worn", -16.3, -179.0, 90.0)
	# ---- rear lot behind the salon block and the bank (back doors v -107.92 / -121.69 kept clear)
	for k in 11: P.call("prop_wheel_stop_concrete", "worn", -39.6, -100.55 - 2.7 * k, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", -31.1, -101.6, 90.0)                     # the taqueria (food)
	for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -30.75, -110.1 - 0.8 * k, 90.0)   # the flats over it
	P.call("prop_ac_condenser", "worn", -30.95, -114.6, 90.0)
	P.call("prop_dumpster_3yd_blue", "worn", -32.3, -129.6, 90.0)                      # the bank: paper (shredding bins inside)
	P.call("prop_ac_condenser", "worn", -32.15, -125.6, 90.0)
	P.call("prop_lot_light_pole", "worn", -36.0, -117.0)
	for k in 3: H.put(props, "prop_meter_electric", "worn", -30.12, -103.0 - 0.42 * k, func(x: float, z: float) -> float: return float(yf.call(x, z)) + 1.05, -90.0, false)
	H.put(props, "prop_meter_gas", "rusty", -30.12, -104.7, func(x: float, z: float) -> float: return float(yf.call(x, z)) + 0.2, -90.0, false)
	for z: float in [-98.0, -117.9]: P.call("prop_downspout_3m", "worn", -30.12, z, -90.0, false)
	# ---- north yard (staff and deliveries of the shops; back doors v -154.65 / -160.65 / -168.4 / -174.4 / -186.5)
	for k in 12:
		P.call("prop_wheel_stop_concrete", "worn", -49.4, -156.35 - 2.7 * k, 90.0)
		P.call("prop_wheel_stop_concrete", "worn", -35.6, -156.35 - 2.7 * k, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", -32.0, -157.6, 90.0)                     # the ice-cream shop (food)
	P.call("prop_dumpster_3yd_blue", "worn", -31.6, -171.4, 90.0)                      # the hardware (cardboard)
	for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -31.6, -178.0 - 0.8 * k, 90.0)   # flats above
	P.call("prop_recycling_receptacle", "worn", -31.5, -183.0, 90.0)                   # the bookshop
	P.call("prop_ac_condenser", "worn", -31.6, -164.4, 90.0)
	P.call("prop_lot_light_pole", "worn", -33.0, -175.0)
	P.call("prop_golf_cart_white", "worn", -37.5, -169.85, 90.0)                       # the hardware owner's runabout
	# ================================================================ wear (where its cause is)
	for o: Array in [[-41.5, -100.55], [-41.5, -105.95], [-41.5, -111.35], [-41.5, -119.45], [-41.5, -124.85], [-47.5, -156.35],
			[-47.5, -161.75], [-47.5, -172.55], [-47.5, -177.95], [-37.5, -159.05], [-37.5, -164.45], [-37.5, -175.25], [-37.5, -183.35]]:
		W.oil(dec, rr, Vector2(float(o[0]), float(o[1])), 90.0, yf, 0.7)
	for c: Array in [[-47.0, -104.0], [-46.5, -121.0], [-47.5, -138.0], [-42.0, -166.0], [-42.5, -181.0], [-35.5, -110.0]]:
		dec.add(0, Vector2(float(c[0]), float(c[1])), rr.randf_range(0, 360), 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
	W.lane_wear(dec, rr, -47.0, -146.0, ZS, true, yf)
	W.lane_wear(dec, rr, -42.5, ZN + 1.0, -152.4, true, yf)
	for d: Array in [[-31.1, -101.6], [-32.3, -129.6], [-32.0, -157.6], [-31.6, -171.4]]:
		dec.add(14, Vector2(float(d[0]), float(d[1])), 90.0, 3.0, 2.4, yf, Color(1, 1, 1, 0.7))
	dec.add(14, Vector2(-18.5, -140.74), 90.0, 2.6, 3.0, ych, Color(1, 1, 1, 0.4))      # worn paving at the church door
	dec.add(14, Vector2(-32.0, -150.0), 0.0, 28.0, 1.4, yf, Color(1, 1, 1, 0.3))        # the church walk's walking line
