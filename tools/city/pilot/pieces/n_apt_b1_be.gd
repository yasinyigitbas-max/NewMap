extends SceneTree
## Piece n_apt_b1_be - apartment band fill, BLOCK 1, its EAST part on 8th St: 8th St x Adela Ave.
## Layout row: pos [250, 6, -600], yaw 0 (the apartment sample's junction frame). Quadrant coordinates: u = east of
## B Ave's centre line, v = north of 7th St's centre line (sx = +1, sz = -1). Outline: u 100-240.8 (lot line with
## n_apt_b1_bw to Adela's property line), v 100-190.8 (lot line with n_apt_b1_7th to 8th St's property line).
##
## LAND: the land under it lies 6.02-6.40 m (a 25 cm hump in the middle of the tennis lawn); 8th St and Adela are built
## at pad 6.0, walk 6.15. One level floor at the walk height: every street edge flush; the hump is 25 cm at most and
## the trial land fit lowers it under the floor (5 cm under). No step inside: nothing here needs a retaining wall.
##
## WHO LIVES HERE AND WHY:
## The 1960s end of the block, toward the golf course and the ring road: stucco boxes and dingbats built for the
## young renters of that time - and still rented by the same kind of people: sailors from the air station, nurses
## from the hospital, couples who cannot buy yet. They have cars (the dingbats stand over their carports on the alley)
## and they play: the complex kept its two TENNIS COURTS in the middle of the block, and the dingbat tenants dug a
## sand court for volleyball behind their buildings.
##  S3e (u 100-190, v 146-190.8): on 8th St a row of two three-storey stucco blocks, a small walk-up and a beach-style
##     condo (lobby doors); behind them three dingbats facing the u-alley with four stalls under each; between the
##     dingbats the tenants' yard: the SAND VOLLEYBALL court, a picnic table under a sail, their bins in an enclosure
##     the truck reaches from the alley; street-row tenants park on stalls off the v-alley.
##  S6 corner (u 196-240.8, v 146-190.8): the TAQUERIA on the corner of 8th and Adela (tables on its forecourt, a
##     bike rack: golfers and the ring road's traffic stop here), a NAIL SALON beside it, a walk-up on 8th, a garden
##     apartment on Adela; customers' stalls off the v-alley with the restaurant's bins enclosure.
##  S4e (u 100-190, v 100-140): the TENNIS COURTS (kit park_tennis_courts, worn, fence rebuilt with posts, one gate
##     toward the alley the players come from) and the courts' lawn: benches facing the courts, picnic tables each
##     under its own sail, a grill, a fountain, lamps; visitor stalls off the v-alley.
##  S7n (u 196-240.8, v 100-140): a white court and a walk-up on Adela, their yards behind, stalls off the v-alley.
## Alleys: u-alley v 140-146 (Adela's apron at v -740..-746 m), v-alley u 190-196 (8th St's apron at u 440-446).
## Walk-in places (rooms pass, NOT built here): the taqueria, the nail salon; the stucco blocks' and condo's lobbies.
## Built once by its own script; a draft until Yasin has seen it. Never re-run after that.
const F := preload("res://tools/city/pilot/pieces/apt_fill_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const C := preload("res://tools/city/pilot/pieces/civ_lib.gd")
const NAME := "n_apt_b1_be"
func _init() -> void: _run.call_deferred()

func _run() -> void:
	var sx := 1.0; var sz := -1.0
	var ctx := F.begin(NAME, sx, sz)
	var bl: Node3D = ctx.bl; var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec
	var rr: RandomNumberGenerator = ctx.rr; var paints: Array = ctx.paints; var stalls: Array = ctx.stalls
	var poles: Array = ctx.poles; var blds: Array = ctx.blds; var stops: Array = ctx.stops
	# ---------------------------------------------------------------- alleys (ground first)
	F.alley(paints, props, dec, rr, sx, sz, true, 140.0, 100.0, 240.8, poles, [[146.5, 139.3], [187.0, 146.7], [217.0, 139.3]], NAN, [1])
	F.alley(paints, props, dec, rr, sx, sz, false, 190.0, 100.0, 190.8, poles, [[170.0, 189.3], [125.0, 189.3]], NAN, [])
	if OS.get_environment("APT_GROUND_ONLY") == "1":
		F.finish(ctx, 100.0, 100.0, 240.8, 190.8); quit(); return

	# ================================================================ S3e (u 100-190, v 146-190.8)
	var row: Array = [["apartments/apt_stucco3_cream", 113.9, 181.8, "stucco_8th_w"], ["ck/ck_apt3_row2", 133.8, 181.8, "walkup_8th_e"],
		["apartments/apt_beach_condo", 153.2, 182.3, "condo_8th"], ["apartments/apt_stucco3_peach", 176.1, 181.8, "stucco_8th_e"]]
	for r: Array in row:
		var b := F.place(bl, sx, sz, String(r[0]), float(r[1]), float(r[2]), "+v", String(r[3]))
		F.dress(b, paints, props, dec, rr, sx, sz, 190.8, true, true, [-1.0, 1.0])
		blds.append(b)
	# the dingbats over their carports, facing the alley (cars nose straight in from it)
	for e: Array in [[110.0, "apartments/apt_dingbat_teal"], [131.0, "apartments/apt_dingbat_pink"], [168.0, "apartments/apt_dingbat_teal"]]:
		var du := float(e[0])
		var db := F.place(bl, sx, sz, String(e[1]), du, 154.4, "-v", "dingbat_%d" % int(du))
		F.dress(db, paints, props, dec, rr, sx, sz, 146.4, false, false)
		blds.append(db)
		SL.stalls_u(paints, stalls, sx, sz, du - 5.4, 4, 146.4, 1.0)          # under the building: no wheel stops (nose to the stair wall)
		paints.append(F.rect(sx, sz, du - 6.0, 146.0, du + 6.0, 152.6, "asphalt"))
		for k in 4: W.oil(dec, rr, Vector2(du - 4.05 + k * 2.7, -149.2), 0.0, F.GY, rr.randf_range(0.55, 0.9))
	# the tenants' yard between the second and third dingbat: fence on the alley with a gate, the sand court, a table
	# under a sail, the bins enclosure open to the alley
	F.enclosure(props, F.q(sx, sz, 140.5, 150.4), 0.0)                           # open toward the alley (-v): the truck backs in
	F.fence_uv(props, sx, sz, 143.8, 147.8, 143.8, 146.6)                          # from the enclosure's side wall
	F.fence_gate(props, sx, sz, 143.8, 146.6, 161.8, 146.6, 12.0)                 # the rest of the yard's alley side, a gate
	F.fence_uv(props, sx, sz, 116.2, 146.6, 124.8, 146.6)                          # gap between the first two dingbats
	F.fence_uv(props, sx, sz, 99.8, 146.6, 103.8, 146.6)                           # to n_apt_b1_bw's lot-line fence
	# the sand court, long along v (the net is 13.3 m: it spans the court's width along u)
	paints.insert(0, F.rect(sx, sz, 144.0, 149.0, 157.5, 165.0, "sand"))
	F.put(props, "prop_volleyball_net", "worn", sx, sz, 150.75, 157.0, 0.0)
	dec.add(14, Vector2(150.75, -157.0), 0.0, 12.0, 2.4, F.GY, Color(1, 1, 1, 0.35))   # sand trodden flat under the net
	F.put(props, "prop_picnic_table", "worn", sx, sz, 140.2, 169.5, 0.0)
	F.put(props, "prop_shade_sail", "worn", sx, sz, 140.2, 169.5, 0.0)            # OVER the table it shades
	F.put(props, "prop_adirondack_white", "worn", sx, sz, 159.4, 158.0, -100.0)   # watching the game
	F.put(props, "prop_adirondack_wood", "worn", sx, sz, 159.6, 155.6, -80.0)
	F.put(props, "prop_bbq_kettle", "worn", sx, sz, 158.6, 169.0, 0.0)
	F.put(props, "prop_lamp_globe", "worn", sx, sz, 143.0, 166.2)                 # for the evening games
	# street-row tenants' stalls off the v-alley, the yard fence behind them with a gate, closed to the stucco's back
	var s3 := F.pad(paints, stalls, dec, rr, sx, sz, false, 147.0, 174.0, 190.0, -1.0)
	stops.append_array(s3)
	F.fence_gate(props, sx, sz, 183.4, 146.6, 183.4, 175.6, 15.0)
	F.fence_uv(props, sx, sz, 174.2, 146.6, 183.4, 146.6)
	# the gaps between the street-row buildings, each with a gate (tenants cut through to the alley)
	F.fence_uv(props, sx, sz, 99.8, 175.6, 104.2, 175.6)                            # from n_apt_b1_bw's corner post to the stucco's back corner
	for g: Array in [[123.6, 127.6], [140.0, 144.0], [162.4, 166.4]]:
		F.fence_gate(props, sx, sz, float(g[0]), 178.5, float(g[1]), 178.5, (float(g[1]) - float(g[0])) * 0.5)
	F.put(props, "tree_ficus_a", "normal", sx, sz, 121.0, 166.0, 140.0)
	F.put(props, "prop_clothesline", "worn", sx, sz, 176.0, 166.5, 0.0)

	# ================================================================ S6: the corner (u 196-240.8, v 146-190.8)
	var taq := F.place(bl, sx, sz, "commercial/com_bistro", 234.8, 181.3, "+v", "taqueria", 0.75)
	var nails := F.place(bl, sx, sz, "commercial/com_realty", 225.3, 181.3, "+v", "nail_salon", 0.7)
	paints.append(F.rect(sx, sz, 222.3, 188.3, 240.8, 190.8, "concrete"))        # the forecourt
	for b: Dictionary in [taq, nails]:
		F.back_of_house(props, b, false); blds.append(b)
	# taqueria door at u 230.0: two tables on the forecourt east of it (the corner gets the sun), a bin, a rack by the
	# nail salon's wall; the salon: a pot by its door, nothing in front of it
	F.put(props, "prop_patio_set_4", "worn", sx, sz, 234.6, 189.5, 10.0)
	F.put(props, "prop_patio_set_4", "worn", sx, sz, 238.6, 189.5, -15.0)
	F.put(props, "prop_trash_receptacle", "dirty", sx, sz, 232.0, 190.1)
	F.put(props, "prop_bike_rack", "rusty", sx, sz, 226.4, 190.2, 0.0)
	I.add(props, "plant_potted_succulent", "normal", F.at(nails, 0.4, 7.35), 180.0)
	F.wall(props, taq, "prop_porch_light_barn", "worn", "front", 4.8 - 0.9, 2.4, 0.05)
	dec.add(14, Vector2(230.0, -189.4), 0.0, 2.4, 1.8, F.GY, Color(1, 1, 1, 0.6))
	F.grime(dec, Vector2(222.3, -188.0), Vector2(240.8, -188.0), rr)
	var wk := F.place(bl, sx, sz, "ck/ck_apt3_row2", 208.0, 181.8, "+v", "walkup_8th_adela")
	F.dress(wk, paints, props, dec, rr, sx, sz, 190.8, true, true)
	blds.append(wk)
	var gc := F.place(bl, sx, sz, "apartments/apt_garden_cream", 233.3, 159.3, "+u", "garden_adela_n")
	F.dress(gc, paints, props, dec, rr, sx, sz, 240.8, true, false)
	blds.append(gc)
	var s6 := F.pad(paints, stalls, dec, rr, sx, sz, false, 147.0, 158.0, 196.0, 1.0)
	stops.append_array(s6)
	paints.append(F.rect(sx, sz, 196.0, 158.0, 202.3, 168.4, "asphalt"))
	F.enclosure(props, F.q(sx, sz, 199.5, 163.2), -90.0)                          # the restaurant's bins, open to the alley
	dec.add(14, Vector2(197.0, -163.2), 0.0, 1.6, 4.0, F.GY, Color(1, 1, 1, 0.7))  # grease and dirt at the enclosure mouth
	F.fence_gate(props, sx, sz, 202.6, 146.6, 202.6, 175.6, 6.0)
	F.fence_uv(props, sx, sz, 202.6, 146.6, 228.6, 146.6)
	F.fence_uv(props, sx, sz, 228.6, 146.6, 228.6, 148.3)
	F.fence_uv(props, sx, sz, 237.6, 170.3, 239.6, 170.3)                            # from the garden wing's front corner
	F.fence_gate(props, sx, sz, 239.6, 170.3, 239.6, 174.1, 1.9)                  # staff out to Adela between garden wing and taqueria
	F.fence_gate(props, sx, sz, 214.2, 177.0, 222.1, 177.0, 4.0)
	# the restaurant's back: the cooks' smoke bench by the back door, a bucket-bin, the gas bottles
	F.put(props, "prop_park_bench", "worn", sx, sz, 231.0, 172.0, 180.0)
	F.put(props, "prop_trash_receptacle", "dirty", sx, sz, 228.0, 172.4)
	for k in 2: F.put(props, "prop_propane_cylinder_100lb", "rusty", sx, sz, 237.9 - k * 0.5, 172.9)
	F.put(props, "tree_coral_b", "normal", sx, sz, 212.0, 155.0, 15.0)
	F.put(props, "prop_patio_set_4", "worn", sx, sz, 218.0, 160.0, 25.0)
	F.put(props, "prop_bbq_gas_cart", "worn", sx, sz, 221.5, 157.5, 90.0)

	# ================================================================ S4e (u 100-190, v 100-140): the tennis courts
	C.park(ctx, "park_tennis_courts", 123.0, 120.0, "+v")
	# the courts' lawn (u 143-183): benches facing the courts, two tables each under its own sail, a grill, fountain
	for e: Array in [[145.2, 112.0], [145.2, 126.0]]:
		F.put(props, "prop_park_bench", "worn", sx, sz, float(e[0]), float(e[1]), 90.0 * sx * -1.0 + 0.0)   # backs to the lawn, faces the courts
	for t: Array in [[157.0, 109.0], [157.0, 129.0]]:
		F.put(props, "prop_picnic_table", "worn", sx, sz, float(t[0]), float(t[1]), 90.0)
		F.put(props, "prop_shade_sail", "worn", sx, sz, float(t[0]), float(t[1]), 90.0)
	F.put(props, "prop_bbq_gas_cart", "worn", sx, sz, 166.0, 119.0, -90.0)
	F.put(props, "prop_drinking_fountain", "worn", sx, sz, 145.4, 119.0, 90.0)
	F.put(props, "prop_trash_receptacle", "worn", sx, sz, 162.0, 121.6)
	F.put(props, "prop_recycling_receptacle", "worn", sx, sz, 162.9, 121.6)
	for lp: Vector2 in [Vector2(150.0, 104.0), Vector2(150.0, 136.0), Vector2(176.0, 119.0)]: F.put(props, "prop_lamp_globe", "worn", sx, sz, lp.x, lp.y)
	for t2: Array in [["tree_magnolia_a", 172.0, 106.0], ["tree_ficus_b", 172.0, 133.0], ["tree_coral_a", 179.0, 119.0]]:
		F.put(props, String(t2[0]), "normal", sx, sz, float(t2[1]), float(t2[2]), float(t2[1]) * 7.0)
	dec.add(14, Vector2(150.0, -119.0), 90.0, 1.2, 12.0, F.GY, Color(1, 1, 1, 0.5))    # the path worn from the gate to the tables
	F.put(props, "tree_jacaranda_b", "normal", sx, sz, 165.0, 104.0, 30.0)
	F.put(props, "tree_magnolia_b", "normal", sx, sz, 165.0, 135.0, 140.0)
	F.put(props, "prop_garden_arbor", "worn", sx, sz, 178.0, 112.0, -90.0)       # the old clubhouse corner, two chairs under it
	F.put(props, "prop_adirondack_white", "worn", sx, sz, 176.4, 111.0, -60.0)
	F.put(props, "prop_adirondack_white", "worn", sx, sz, 176.4, 113.4, -120.0)
	F.put(props, "prop_hose_reel_cart", "worn", sx, sz, 182.0, 126.0, -90.0)    # the lawn is watered by hand
	var s4 := F.pad(paints, stalls, dec, rr, sx, sz, false, 101.0, 139.0, 190.0, -1.0)
	stops.append_array(s4)
	F.fence_gate(props, sx, sz, 183.4, 100.4, 183.4, 139.6, 19.0)
	F.fence_uv(props, sx, sz, 142.0, 135.4, 142.0, 139.6)                            # on from the courts' fence corner
	F.fence_gate(props, sx, sz, 142.0, 139.6, 183.4, 139.6, 7.4)
	F.fence_uv(props, sx, sz, 142.0, 101.0, 142.0, 100.4)
	F.fence_uv(props, sx, sz, 142.0, 100.4, 183.4, 100.4)

	# ================================================================ S7n (u 196-240.8, v 100-140)
	var wc := F.place(bl, sx, sz, "apartments/apt_court_white", 233.3, 110.4, "+u", "white_court_adela")
	var w7 := F.place(bl, sx, sz, "ck/ck_apt3_row3", 231.8, 129.6, "+u", "walkup_adela_n")
	F.dress(wc, paints, props, dec, rr, sx, sz, 240.8, true, true, [-1.0])
	F.dress(w7, paints, props, dec, rr, sx, sz, 240.8, true, true, [-1.0])
	blds.append(wc); blds.append(w7)
	var s7 := F.pad(paints, stalls, dec, rr, sx, sz, false, 101.0, 139.0, 196.0, 1.0)
	stops.append_array(s7)
	F.fence_gate(props, sx, sz, 202.6, 100.4, 202.6, 139.6, 19.0)
	F.fence_uv(props, sx, sz, 202.6, 139.6, 225.6, 139.6)
	F.fence_uv(props, sx, sz, 225.6, 139.6, 225.6, 138.8)                            # to the walk-up's back corner
	F.fence_uv(props, sx, sz, 202.6, 100.4, 228.6, 100.4)
	F.fence_uv(props, sx, sz, 228.6, 100.4, 228.6, 101.8)
	F.fence_uv(props, sx, sz, 228.6, 118.9, 228.6, 120.5)
	F.put(props, "prop_clothesline", "worn", sx, sz, 212.0, 127.0, 90.0)
	F.put(props, "tree_jacaranda_a", "normal", sx, sz, 208.0, 106.0, 260.0)
	paints.insert(0, F.rect(sx, sz, 205.5, 112.0, 208.5, 121.0, "mulch"))      # a vegetable bed in the sun
	for k in 3: F.put(props, ["plant_agave_americana_small", "plant_potted_leafy", "plant_bird_of_paradise"][k], "normal", sx, sz, 207.0, 113.6 + k * 2.9, k * 50.0)

	# ================================================================ POLISH PASS (Yasin 19 Nov: "run a polish pass in all your
	# quarters ... plenty of props"): only ADDS, with its own random sequence, after everything above (which stays identical):
	# every building's downspouts, house numbers, vine or dish, back-wall grime; and the spots chosen here, each a cluster
	# whose items go in only where their own spot is free (apt_fill_lib.polish_*)
	var prr := W.rng_for(NAME + "_polish")
	var prect := Rect2(100.0, -190.8, 140.8, 90.8)
	for pb: Dictionary in blds: F.polish_building(ctx, pb, prr, prect)
	for psp: Array in [["sit", 113, 170, 0], ["sit", 156, 172, 0], ["garden", 134, 167, 0], ["lounge", 146, 175, 0], ["garden", 160, 102, 0], ["shade", 176, 126, 0], ["garden", 222, 166, 0], ["wash", 210, 168, 0], ["bins", 204.5, 150, 0], ["sit", 214, 115, 0], ["tools", 222, 104, 0], ["garden", 212, 136, 0]]:
		F.polish_spot(ctx, String(psp[0]), float(psp[1]), float(psp[2]), float(psp[3]), prr, prect)

	F.finish(ctx, 100.0, 100.0, 240.8, 190.8)
	quit()
