extends SceneTree
## Piece n_apt_b2_7th - apartment band fill, BLOCK 2 (B Ave - Adela Ave, 7th - 6th St), its NORTH part on 7th St:
## 7th St x Adela Ave. Layout row: pos [250, 6, -600], yaw 0 (the apartment sample's junction frame). Quadrant
## coordinates: u = east of B Ave's centre line, v = SOUTH of 7th St's centre line (sx = +1, sz = +1). Outline: u 100-240.8
## (the lot line with the sample's a_se to Adela's property line), v 9.2-100 (7th St's property line to the lot line with
## n_apt_b2_be).
##
## LAND: flat. Measured: 7th St, Adela and a_se all at walk 6.15 m; the block's surface (apt_fill_b2_land.gd) is 0.15
## (local) over this whole piece (the B Ave rise starts south of v 100). The land under it lies 6.10-6.37 m (the same
## hump as block 1, south of 7th St); the trial land fit takes it 5 cm under the floor. Every building on its pad at
## 0.15: level, flush with both streets and a_se.
##
## WHO USES IT AND WHY:
## Across 7th St from block 1's shop corner. 7th is the bus street, so this side has the band's CHURCH: a 1950s community
## church on 7th St with a paved plaza where people stand after the service (benches, palms in beds, a rack for the
## bikes), its side door to the parking lot behind - the church lot doubles as the flats' overflow parking in the week.
##  S5 (u 100-190, v 9.2-54): the church, a small walk-up, a garden apartment and a stucco block on 7th St; behind the
##     church its stalls on the alley, behind the flats their fenced yards (patios, a clothesline, a shade tree).
##  S8 corner (u 196-240.8, v 9.2-54): the CORNER MARKET (a brick corner block, the shop downstairs, a flat above): ice
##     chest and propane cage on its forecourt, papers, a rack - it faces the pharmacy corner across 7th St, so the
##     crossroads has its everyday shopping on two corners; a white court on 7th and a walk-up on Adela; customers'
##     stalls and the shop's bins enclosure off the v-alley; the staff's table in the yard.
##  S4 (u 100-190, v 60-100): the church's own lot (one row of stalls, a wide aisle open to the alley, lot lights, a
##     planted edge with jacarandas) and the COMMUNITY GARDEN of the flats: a white picket fence with one gate on the
##     alley, raised beds, a tool shed, compost carts, an arbor with two chairs, a bench in the shade.
##  S7s (u 196-240.8, v 60-100): a Spanish court and a walk-up on Adela, their yards, stalls off the v-alley.
## Alleys: u-alley v 54-60 (continues a_se's to Adela's apron at z -546..-540), v-alley u 190-196 (7th St's apron at
## u 440-446). Poles on gravel pads where no stall, fence or building is.
## Walk-in places (rooms built with the block): the church, the corner market.
## Built once by its own script; a draft until Yasin has seen it. Never re-run after that.
const F := preload("res://tools/city/pilot/pieces/apt_fill_lib.gd")
const L := preload("res://tools/city/pilot/pieces/apt_fill_b2_land.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const NAME := "n_apt_b2_7th"
## every building: folder, u, v, face, label (the pads are registered from this list BEFORE anything stands on the ground)
const B := [
	["civic/civ_church", 115.0, 27.2, "-v", "church_7th"],
	["ck/ck_apt3_row2", 134.0, 18.2, "-v", "walkup_7th_s"],
	["apartments/apt_garden_mint", 153.8, 16.7, "-v", "garden_7th_s"],
	["apartments/apt_stucco3_peach", 177.5, 18.2, "-v", "stucco_7th_s"],
	["ck/ck_brk3_corner2", 234.8, 18.7, "-v", "corner_market"],
	["apartments/apt_court_white", 213.4, 16.7, "-v", "white_court_7th_s"],
	["ck/ck_apt3_row3", 231.8, 43.0, "+u", "walkup_adela_7th"],
	["apartments/apt_spanish_white", 232.8, 71.0, "+u", "spanish_adela"],
	["ck/ck_apt3_row2", 231.8, 90.0, "+u", "walkup_adela_mid"],
	["garages/single_siding_comp", 184.5, 93.5, "-u", "garden_shed"],
]
func _init() -> void: _run.call_deferred()

func _run() -> void:
	var sx := 1.0; var sz := 1.0
	var ctx := F.begin(NAME, sx, sz)
	F.SURF = L.surface; F.GY = F.terrain; F.outline(sx, sz, 100.0, 9.2, 240.8, 100.0)
	var bl: Node3D = ctx.bl; var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec
	var rr: RandomNumberGenerator = ctx.rr; var paints: Array = ctx.paints; var stalls: Array = ctx.stalls
	var poles: Array = ctx.poles; var blds: Array = ctx.blds; var stops: Array = ctx.stops
	# ---------------------------------------------------------------- land first: a pad under every building, then the alleys
	var pads := {}
	for b: Array in B: pads[String(b[4])] = F.pad_for(paints, sx, sz, String(b[0]), float(b[1]), float(b[2]), String(b[3]))
	F.alley(paints, props, dec, rr, sx, sz, true, 54.0, 100.0, 240.8, poles, [[143.0, 60.7], [155.0, 53.3], [215.0, 53.3]], NAN, [1])
	F.alley(paints, props, dec, rr, sx, sz, false, 190.0, 9.2, 100.0, poles, [[30.0, 189.3], [80.0, 196.7]], NAN, [])
	if OS.get_environment("APT_GROUND_ONLY") == "1":
		F.finish(ctx, 100.0, 9.2, 240.8, 100.0); quit(); return
	var bd := {}
	for b: Array in B:
		bd[String(b[4])] = F.place(bl, sx, sz, String(b[0]), float(b[1]), float(b[2]), String(b[3]), String(b[4]), 0.8 if String(b[0]).begins_with("garages") else 0.75, pads[String(b[4])])
		blds.append(bd[String(b[4])])

	# ================================================================ S5 (u 100-190, v 9.2-54)
	var ch: Dictionary = bd.church_7th
	paints.append(F.rect(sx, sz, 102.0, 9.2, 128.0, 14.2, "plaza"))            # the church plaza, people stand here after the service
	paints.insert(0, F.rect(sx, sz, 102.6, 10.0, 106.4, 13.6, "mulch"))         # two beds framing the steps, a palm in each
	paints.insert(0, F.rect(sx, sz, 123.6, 10.0, 127.4, 13.6, "mulch"))
	F.put(props, "palm_queen_a", "normal", sx, sz, 104.5, 11.8, 30.0)
	F.put(props, "palm_queen_b", "normal", sx, sz, 125.5, 11.8, 200.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 109.4, 10.2, 0.0)           # benches at the plaza's sides, facing it, clear of the door's line
	F.put(props, "prop_park_bench", "worn", sx, sz, 120.6, 10.2, 0.0)
	F.put(props, "prop_trash_receptacle", "worn", sx, sz, 107.4, 10.0)
	F.put(props, "prop_bike_rack", "rusty", sx, sz, 126.0, 15.6, 90.0)          # along the church's east flank, off the plaza
	for lp: Vector2 in [Vector2(106.8, 14.6), Vector2(123.2, 14.6)]: F.put(props, "prop_lamp_victorian", "worn", sx, sz, lp.x, lp.y)
	F.back_of_house(props, ch, false)
	F.grime(dec, Vector2(108.0, 14.6), Vector2(122.0, 14.6), rr)
	dec.add(14, Vector2(115.0, 12.0), 0.0, 3.0, 3.0, F.GY, Color(1, 1, 1, 0.45))   # worn in front of the doors
	paints.append(F.rect(sx, sz, 122.4, 38.2, 124.0, 47.7, "concrete"))        # side door walk to the lot
	paints.append(F.rect(sx, sz, 122.0, 38.2, 124.0, 40.0, "concrete"))
	for k in 3: F.put(props, "hedge_boxwood_low_2m", "normal", sx, sz, 106.8, 16.0 + k * 9.0, 90.0)   # a low hedge along the church's west flank
	F.put(props, "tree_jacaranda_a", "normal", sx, sz, 104.5, 44.0, 70.0)       # the church's old tree in its back corner
	for key: String in ["walkup_7th_s", "garden_7th_s", "stucco_7th_s"]:
		F.dress(bd[key], paints, props, dec, rr, sx, sz, 9.2, true, true, [-1.0, 1.0])
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, true, 101.0, 141.0, 54.0, -1.0))     # the church's stalls on the alley
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, true, 168.0, 188.0, 54.0, -1.0))     # the stucco block's
	F.fence_uv(props, sx, sz, 127.8, 24.4, 127.8, 47.4)
	F.fence_gate(props, sx, sz, 127.8, 47.4, 142.8, 47.4, 7.5)
	F.fence_uv(props, sx, sz, 142.8, 47.4, 142.8, 21.4)
	F.fence_gate(props, sx, sz, 142.8, 47.4, 167.8, 47.4, 12.5)
	F.fence_uv(props, sx, sz, 167.8, 47.4, 167.8, 24.4)
	F.fence_uv(props, sx, sz, 167.8, 47.4, 188.0, 47.4)
	F.fence_uv(props, sx, sz, 188.0, 47.4, 188.0, 24.4)
	F.fence_uv(props, sx, sz, 188.0, 24.4, 187.2, 24.4)                              # to the stucco block's back corner
	F.put(props, "prop_clothesline", "worn", sx, sz, 134.0, 36.0, 0.0)
	F.put(props, "tree_ficus_a", "normal", sx, sz, 160.0, 42.0, 140.0)
	paints.insert(0, F.rect(sx, sz, 146.0, 33.0, 154.0, 40.0, "mulch"))         # the garden apartment's children: a swing on bark
	F.put(props, "prop_swing_set", "worn", sx, sz, 150.0, 36.5, 0.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 150.0, 42.2, 180.0)
	F.put(props, "tree_coral_b", "normal", sx, sz, 182.5, 41.0, 20.0)

	# ================================================================ S8 corner (u 196-240.8, v 9.2-54)
	var mk: Dictionary = bd.corner_market
	paints.append(F.rect(sx, sz, 222.0, 9.2, 240.8, 11.7, "concrete"))         # the market's forecourt
	F.back_of_house(props, mk, true)
	F.wall(props, mk, "prop_porch_light_barn", "worn", "front", 4.9 - 0.9, 2.3, 0.05)
	# shop door at u 229.9, the flat's door at u 237.8: the ice chest and the propane cage under the window between them
	F.put(props, "prop_ice_chest", "worn", sx, sz, 232.3, 10.6, 180.0)
	for k in 4: F.put(props, "prop_propane_cylinder_100lb", "rusty", sx, sz, 233.6 + k * 0.45, 10.9)
	F.put(props, "prop_newspaper_box_red", "worn", sx, sz, 222.8, 10.6, 180.0)
	F.put(props, "prop_newspaper_box_blue", "worn", sx, sz, 223.5, 10.6, 180.0)
	F.put(props, "prop_trash_receptacle", "dirty", sx, sz, 227.4, 10.5)
	F.put(props, "prop_bike_rack", "rusty", sx, sz, 225.4, 9.9, 0.0)
	F.grime(dec, Vector2(222.0, 11.3), Vector2(240.8, 11.3), rr)
	dec.add(14, Vector2(229.9, 10.4), 0.0, 2.2, 1.8, F.GY, Color(1, 1, 1, 0.6))
	F.dress(bd.white_court_7th_s, paints, props, dec, rr, sx, sz, 9.2, true, true, [-1.0])
	F.dress(bd.walkup_adela_7th, paints, props, dec, rr, sx, sz, 240.8, true, true, [-1.0, 1.0])
	paints.append(F.rect(sx, sz, 196.0, 15.8, 202.3, 28.4, "asphalt"))
	F.enclosure(props, F.q(sx, sz, 199.5, 22.0), -90.0)                         # the market's bins, open to the alley
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 28.5, 52.5, 196.0, 1.0))
	F.fence_gate(props, sx, sz, 202.6, 21.4, 202.6, 52.4, 14.0)
	F.fence_uv(props, sx, sz, 202.6, 21.4, 204.8, 21.4)
	F.fence_uv(props, sx, sz, 202.6, 52.4, 225.6, 52.4)
	F.fence_gate(props, sx, sz, 222.0, 18.0, 228.6, 18.0, 3.3)                   # between the court and the market
	F.fence_gate(props, sx, sz, 238.0, 25.9, 238.0, 33.8, 4.0)                  # the market's staff out to Adela
	F.put(props, "prop_picnic_table", "worn", sx, sz, 215.0, 34.0, 90.0)        # the shopkeeper's family eat here
	F.put(props, "tree_magnolia_b", "normal", sx, sz, 210.0, 44.0, 300.0)
	for k in 3: F.put(props, ["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", sx, sz, 203.6, 30.0 + k * 0.85, 90.0)

	# ================================================================ S4 (u 100-190, v 60-100)
	# the church lot: open to the alley along its whole north side, one row of stalls along its south edge
	paints.append(F.rect(sx, sz, 101.0, 60.0, 141.0, 78.4, "asphalt"))
	var lot := stalls.size()
	SL.stalls_u(paints, stalls, sx, sz, 101.6, 14, 72.6, 1.0)
	for k in range(lot, stalls.size()): (stalls[k] as Array).append(F.gy(float(stalls[k][0]), float(stalls[k][1])))
	stops.append_array(stalls.slice(lot))
	for k in range(lot, stalls.size()):
		if rr.randf() < 0.5: W.oil(dec, rr, Vector2(float(stalls[k][0]), float(stalls[k][1])), 0.0, F.GY, rr.randf_range(0.5, 0.8))
	SL.aisle_wear(dec, rr, sx, sz, 102.0, 140.0, 66.5)
	F.put(props, "prop_lot_light_pole", "worn", sx, sz, 112.0, 79.4, 0.0)
	F.put(props, "prop_lot_light_pole", "worn", sx, sz, 130.0, 79.4, 0.0)
	for t: Array in [["tree_jacaranda_b", 106.0, 83.0], ["tree_jacaranda_a", 121.0, 83.5], ["tree_jacaranda_b", 136.0, 83.0]]:
		F.put(props, String(t[0]), "normal", sx, sz, float(t[1]), float(t[2]), float(t[1]) * 3.0)
	F.put(props, "prop_sign_no_parking", "worn", sx, sz, 141.6, 61.0, -90.0)    # "church parking Sundays"
	# the community garden: a picket fence with ONE gate on the alley, beds in two rows, the shed, the compost
	F.fence_gate(props, sx, sz, 145.0, 63.0, 188.0, 63.0, 21.5, "fence_picket_white", "fence_post_picket", "fence_gate_picket")
	F.fence_uv(props, sx, sz, 188.0, 63.0, 188.0, 98.0, "fence_picket_white", "fence_post_picket")
	F.fence_uv(props, sx, sz, 188.0, 98.0, 145.0, 98.0, "fence_picket_white", "fence_post_picket")
	F.fence_uv(props, sx, sz, 145.0, 98.0, 145.0, 63.0, "fence_picket_white", "fence_post_picket")
	var pl := ["plant_agave_americana_small", "plant_bird_of_paradise", "plant_bougainvillea_mound", "plant_potted_leafy"]
	for row in 2:
		for k in 5:
			var bu := 148.5 + k * 6.0; var bv := 68.5 + row * 13.0
			paints.insert(0, F.rect(sx, sz, bu, bv, bu + 3.2, bv + 8.0, "mulch"))
			for j in 2: F.put(props, String(pl[(k + j + row) % 4]), "normal", sx, sz, bu + 1.6, bv + 2.0 + j * 4.0, (k * 3 + j) * 41.0)
	paints.insert(0, F.rect(sx, sz, 165.4, 63.0, 167.6, 98.0, "gravel"))     # the gravel walk from the gate down the middle
	F.put(props, "prop_garden_arbor", "worn", sx, sz, 166.5, 95.6, 0.0)
	F.put(props, "prop_adirondack_wood", "worn", sx, sz, 165.4, 94.0, 160.0)
	F.put(props, "prop_adirondack_white", "worn", sx, sz, 167.6, 94.0, 200.0)
	F.put(props, "prop_trash_cart_green", "dirty", sx, sz, 180.0, 96.8, 0.0)     # compost
	F.put(props, "prop_trash_cart_green", "dirty", sx, sz, 180.9, 96.8, 0.0)
	F.put(props, "prop_hose_reel_cart", "worn", sx, sz, 163.6, 65.0, 0.0)
	F.put(props, "prop_sprinkler_impact", "worn", sx, sz, 157.0, 81.0, 0.0, false)
	F.put(props, "prop_park_bench", "worn", sx, sz, 146.4, 94.0, 90.0)           # under the coral tree, looking down the beds
	F.put(props, "tree_coral_a", "normal", sx, sz, 148.6, 96.0, 120.0)
	F.put(props, "prop_lamp_globe", "worn", sx, sz, 168.0, 64.4)

	# ================================================================ S7s (u 196-240.8, v 60-100)
	F.dress(bd.spanish_adela, paints, props, dec, rr, sx, sz, 240.8, true, true, [-1.0])
	F.dress(bd.walkup_adela_mid, paints, props, dec, rr, sx, sz, 240.8, true, true, [1.0])
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 61.0, 77.0, 196.0, 1.0))
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 83.0, 99.0, 196.0, 1.0))
	F.fence_gate(props, sx, sz, 202.6, 60.4, 202.6, 99.6, 20.0)
	F.fence_uv(props, sx, sz, 202.6, 60.4, 227.6, 60.4)
	F.fence_uv(props, sx, sz, 227.6, 60.4, 227.6, 61.8)
	F.fence_uv(props, sx, sz, 227.6, 80.2, 225.6, 80.2)
	F.fence_gate(props, sx, sz, 225.6, 80.2, 225.6, 83.8, 1.8)
	F.fence_uv(props, sx, sz, 202.6, 99.6, 225.6, 99.6)
	F.fence_uv(props, sx, sz, 225.6, 99.6, 225.6, 96.2)
	F.put(props, "tree_jacaranda_a", "normal", sx, sz, 209.0, 70.0, 45.0)
	F.put(props, "prop_clothesline", "worn", sx, sz, 214.0, 90.0, 90.0)

	# ================================================================ POLISH PASS (Yasin 19 Nov: "run a polish pass in all your
	# quarters ... plenty of props"): only ADDS, with its own random sequence, after everything above (which stays identical):
	# every building's downspouts, house numbers, vine or dish, back-wall grime; and the spots chosen here, each a cluster
	# whose items go in only where their own spot is free (apt_fill_lib.polish_*)
	var prr := W.rng_for(NAME + "_polish")
	var prect := Rect2(100.0, 9.2, 140.8, 90.8)
	for pb: Dictionary in blds: F.polish_building(ctx, pb, prr, prect)
	for psp: Array in [["sit", 135, 30, 0], ["lounge", 160, 28, 0], ["garden", 156, 44, 0], ["sit", 175, 34, 0], ["tools", 186, 44, 90], ["garden", 220, 26, 0], ["sit", 210, 48, 0], ["sit", 212, 64, 0], ["garden", 208, 96, 0], ["lounge", 220, 86, 90]]:
		F.polish_spot(ctx, String(psp[0]), float(psp[1]), float(psp[2]), float(psp[3]), prr, prect)

	F.finish(ctx, 100.0, 9.2, 240.8, 100.0)
	quit()
