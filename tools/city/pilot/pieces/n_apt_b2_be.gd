extends SceneTree
## Piece n_apt_b2_be - apartment band fill, BLOCK 2 (B Ave - Adela Ave, 7th - 6th St), its EAST part on 6th St:
## 6th St x Adela Ave. Layout row: pos [250, 6, -600], yaw 0 (the sample's junction frame); u = east of B Ave's centre
## line, v = SOUTH of 7th St's centre line (sx = +1, sz = +1). Outline: u 100-240.8, v 100-190.8 (the lot lines with
## n_apt_b2_bw and n_apt_b2_7th to Adela's and 6th St's property lines).
##
## LAND (apt_fill_b2_land.gd, measured): 6th St falls along this piece from 7.50 m at u 100 to 6.15 at u 225; Adela is
## level at 6.15; the B Ave rise reaches in from the west (f(v)), so the ground slopes gently down to the north-east
## corner (steepest about 1.8 %). Every building stands on a level pad at the height of the middle of its front, eased
## into the slope over 5 m; the edges stay exactly on the measured street heights. The 6th St row and the alley
## townhouses step DOWN the hill one pad after another (front pads 1.42 -> 0.40 local along 6th St).
##
## WHO LIVES HERE AND WHY:
## The hill side of the band, families who want a garage: on the alley a row of GARAGE TOWNHOUSES (the kit's townhouses
## with their roll-up doors) facing the alley, each with its car on the drive and a small fenced back yard; on 6th St a
## condo, a stucco block, a walk-up and a white court; in the middle a GARDEN COURT (two garden wings facing each other
## across a paved walk) whose lawn runs east to the residents' play and picnic lawn; on the corner of 6th and Adela the
## BIKE SHOP (the hill's kids and the beach riders), on Adela a walk-up and a Spanish court.
## Alleys: u-alley v 140-146 (B Ave's and Adela's aprons at z -460..-454), v-alley u 190-196 (6th St's apron at u 440-446).
## Walk-in places (rooms built with the block): the bike shop.
## Built once by its own script; a draft until Yasin has seen it. Never re-run after that.
const F := preload("res://tools/city/pilot/pieces/apt_fill_lib.gd")
const L := preload("res://tools/city/pilot/pieces/apt_fill_b2_land.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const NAME := "n_apt_b2_be"
const B := [
	["apartments/apt_beach_condo", 112.0, 182.3, "+v", "condo_6th"],
	["apartments/apt_stucco3_peach", 134.5, 181.8, "+v", "stucco_6th"],
	["ck/ck_apt3_row3", 157.0, 181.8, "+v", "walkup_6th"],
	["apartments/apt_court_white", 177.4, 183.3, "+v", "white_court_6th"],
	["apartments/apt_townhouse_modern", 112.0, 157.0, "-v", "townhouses_1"],
	["apartments/apt_townhouse_cays", 134.6, 157.0, "-v", "townhouses_2"],
	["apartments/apt_townhouse_modern", 157.0, 157.0, "-v", "townhouses_3"],
	["apartments/apt_townhouse_cays", 178.6, 157.0, "-v", "townhouses_4"],
	["apartments/apt_garden_mint", 120.8, 108.5, "+v", "court_wing_s"],
	["apartments/apt_garden_cream", 120.8, 130.5, "-v", "court_wing_n"],
	["commercial/com_surf_shop", 236.3, 181.3, "+v", "bike_shop"],
	["ck/ck_apt3_row2", 214.0, 181.8, "+v", "walkup_6th_adela"],
	["ck/ck_apt3_row3", 231.8, 160.0, "+u", "walkup_adela_6th"],
	["apartments/apt_spanish_revival", 232.8, 112.0, "+u", "spanish_court_adela"],
	["ck/ck_apt3_row2", 231.8, 131.0, "+u", "walkup_adela_n2"],
]
func _init() -> void: _run.call_deferred()

func _run() -> void:
	var sx := 1.0; var sz := 1.0
	var ctx := F.begin(NAME, sx, sz)
	F.SURF = L.surface; F.GY = F.terrain; F.outline(sx, sz, 100.0, 100.0, 240.8, 190.8)
	var bl: Node3D = ctx.bl; var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec
	var rr: RandomNumberGenerator = ctx.rr; var paints: Array = ctx.paints; var stalls: Array = ctx.stalls
	var poles: Array = ctx.poles; var blds: Array = ctx.blds; var stops: Array = ctx.stops
	# ---------------------------------------------------------------- land first
	var pads := {}
	for b: Array in B: pads[String(b[4])] = F.pad_for(paints, sx, sz, String(b[0]), float(b[1]), float(b[2]), String(b[3]))
	F.pad_rect(paints, sx, sz, 150.0, 104.0, 166.0, 116.0, F.SURF.call(158.0, 110.0))   # the play lawn's bark pad, level
	F.alley(paints, props, dec, rr, sx, sz, true, 140.0, 100.0, 240.8, poles, [[105.0, 139.3], [215.0, 146.7]], NAN, [0])
	F.alley(paints, props, dec, rr, sx, sz, false, 190.0, 100.0, 190.8, poles, [[130.0, 189.3], [180.0, 189.3]], NAN, [1])
	if OS.get_environment("APT_GROUND_ONLY") == "1":
		F.finish(ctx, 100.0, 100.0, 240.8, 190.8); quit(); return
	var bd := {}
	for b: Array in B:
		bd[String(b[4])] = F.place(bl, sx, sz, String(b[0]), float(b[1]), float(b[2]), String(b[3]), String(b[4]), 0.75, pads[String(b[4])])
		blds.append(bd[String(b[4])])

	# ================================================================ S3e (u 100-190, v 146-190.8): 6th St row + alley townhouses
	for key: String in ["condo_6th", "stucco_6th", "walkup_6th", "white_court_6th"]:
		F.dress(bd[key], paints, props, dec, rr, sx, sz, 190.8, true, true, [-1.0, 1.0])
	# the townhouses: the drive in front of every roll-up, the family car on it, the door walks are the drive itself
	paints.append(F.rect(sx, sz, 101.0, 146.0, 189.0, 152.0, "concrete"))
	for key2: String in ["townhouses_1", "townhouses_2", "townhouses_3", "townhouses_4"]:
		var tb: Dictionary = bd[key2]
		F.dress(tb, paints, props, dec, rr, sx, sz, 152.0, false, true, [])
		var roll: Array = [-7.8, 1.4] if String(tb.folder).contains("cays") else [-7.2, 1.2]
		for lx: float in roll:
			var p := F.at(tb, lx, 5.0 + 3.0)
			stalls.append([p.x, p.z, 0.0, F.gy(p.x, p.z)])                         # nose to the roll-up
			W.oil(dec, rr, Vector2(p.x, p.z), 0.0, F.GY, rr.randf_range(0.5, 0.85))
			dec.add(8, Vector2(p.x, p.z - 1.0), rr.randf_range(-15, 15), 0.5, 3.5, F.GY, Color(1, 1, 1, 0.35))   # tyres turning in from the alley
	# the townhouses' back yards (v 162-169), fenced lot by lot, the street row's shared yard behind (v 169-176)
	F.fence_uv(props, sx, sz, 101.0, 169.0, 189.0, 169.0)
	# side yards between the townhouses: closed at the front by a gate, divided down to the back fence
	for g3: Array in [[121.2, 124.8, 123.0], [144.4, 147.8, 146.2], [166.2, 168.8, 167.6]]:
		F.fence_gate(props, sx, sz, float(g3[0]), 153.0, float(g3[1]), 153.0, (float(g3[1]) - float(g3[0])) * 0.5)
		F.fence_uv(props, sx, sz, float(g3[2]), 153.0, float(g3[2]), 169.0)
	F.fence_uv(props, sx, sz, 102.8, 153.0, 101.0, 153.0)
	F.fence_uv(props, sx, sz, 101.0, 153.0, 101.0, 169.0)
	F.fence_uv(props, sx, sz, 188.4, 153.0, 189.0, 153.0)
	F.fence_uv(props, sx, sz, 189.0, 153.0, 189.0, 169.0)
	for g2: Array in [[121.2, 124.8], [144.4, 147.8], [166.2, 168.8]]:      # between the street row buildings, mid-depth
		F.fence_gate(props, sx, sz, float(g2[0]), 182.0, float(g2[1]), 182.0, (float(g2[1]) - float(g2[0])) * 0.5)
	F.fence_uv(props, sx, sz, 101.0, 169.0, 101.0, 182.0)                          # the west end, to the condo's side
	F.fence_uv(props, sx, sz, 101.0, 182.0, 102.8, 182.0)
	F.put(props, "tree_jacaranda_a", "normal", sx, sz, 145.6, 172.5, 20.0)
	F.put(props, "tree_ficus_b", "normal", sx, sz, 110.0, 173.0, 200.0)
	F.put(props, "prop_clothesline", "worn", sx, sz, 166.0, 172.5, 0.0)

	# ================================================================ S4e (u 100-190, v 100-140): the garden court and the lawn
	for key3: String in ["court_wing_s", "court_wing_n"]: F.dress(bd[key3], paints, props, dec, rr, sx, sz, 119.6 if key3 == "court_wing_s" else 119.6, false, false)
	paints.append(F.rect(sx, sz, 100.6, 118.9, 140.0, 120.3, "concrete"))      # the court's walk, from the lot line to the lawn
	for p2: Vector2 in [Vector2(112.0, 116.0), Vector2(129.6, 116.0), Vector2(112.0, 123.2), Vector2(129.6, 123.2)]:
		F.put(props, "palm_queen_a" if int(p2.x) % 2 == 0 else "palm_queen_b", "normal", sx, sz, p2.x, p2.y, p2.x * 9.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 117.0, 117.8, 0.0)             # facing the walk, between the doors' walks
	F.put(props, "prop_park_bench", "worn", sx, sz, 124.6, 121.4, 180.0)
	F.put(props, "prop_drinking_fountain", "worn", sx, sz, 104.0, 117.6, 0.0)
	F.put(props, "prop_lamp_globe", "worn", sx, sz, 104.0, 121.6)
	F.put(props, "prop_lamp_globe", "worn", sx, sz, 137.0, 121.6)
	# the play and picnic lawn: a bark pad with the play structure, swings and a slide, the parents' benches facing it,
	# picnic tables each under its own sail, the grill, bins
	paints.insert(0, F.rect(sx, sz, 150.0, 104.0, 166.0, 116.0, "mulch"))
	F.put(props, "prop_play_structure", "worn", sx, sz, 158.0, 110.0, 0.0)
	F.put(props, "prop_swing_set", "worn", sx, sz, 152.8, 106.4, 0.0)
	F.put(props, "prop_slide", "worn", sx, sz, 163.6, 106.0, 0.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 158.0, 118.4, 180.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 147.6, 110.0, 90.0)
	F.put(props, "prop_trash_receptacle", "worn", sx, sz, 160.0, 118.4)
	dec.add(14, Vector2(152.8, 106.4), 0.0, 3.0, 2.2, F.GY, Color(1, 1, 1, 0.55))
	for t: Array in [[172.0, 106.0], [172.0, 127.0]]:
		F.put(props, "prop_picnic_table", "worn", sx, sz, float(t[0]), float(t[1]), 90.0)
		F.put(props, "prop_shade_sail", "worn", sx, sz, float(t[0]), float(t[1]), 90.0)
	F.put(props, "prop_bbq_gas_cart", "worn", sx, sz, 178.0, 116.0, -90.0)
	F.put(props, "prop_recycling_receptacle", "worn", sx, sz, 176.6, 120.6)
	for t2: Array in [["tree_coral_a", 146.0, 130.0], ["tree_magnolia_a", 166.0, 130.0], ["tree_ficus_a", 181.0, 104.0], ["tree_jacaranda_b", 146.0, 102.5]]:
		F.put(props, String(t2[0]), "normal", sx, sz, float(t2[1]), float(t2[2]), float(t2[1]) * 5.0)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, true, 136.0, 188.0, 140.0, -1.0))
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 101.0, 124.0, 190.0, -1.0))
	# (the lawn is open to the stalls round it, as a small park: no fence ends in the open)

	# ================================================================ S6 corner (u 196-240.8, v 146-190.8)
	var bs: Dictionary = bd.bike_shop
	paints.append(F.rect(sx, sz, 222.0, 188.3, 240.8, 190.8, "concrete"))
	F.back_of_house(props, bs, false)
	F.wall(props, bs, "prop_porch_light_barn", "worn", "front", -3.3 - 0.9, 2.3, 0.05)
	# door at u 239.6 (local -3.3): two racks along the forecourt west of it (bikes for sale stand in them), a bench
	F.put(props, "prop_bike_rack", "rusty", sx, sz, 233.0, 189.9, 0.0)
	F.put(props, "prop_bike_rack", "worn", sx, sz, 228.0, 189.9, 0.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 224.0, 189.2, 0.0)
	F.put(props, "prop_trash_receptacle", "worn", sx, sz, 236.4, 190.2)
	F.grime(dec, Vector2(222.0, 188.6), Vector2(240.8, 188.6), rr)
	F.dress(bd.walkup_6th_adela, paints, props, dec, rr, sx, sz, 190.8, true, true)
	F.dress(bd.walkup_adela_6th, paints, props, dec, rr, sx, sz, 240.8, true, true)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 148.4, 172.0, 196.0, 1.0))
	F.fence_gate(props, sx, sz, 202.6, 147.6, 202.6, 175.6, 12.0)
	F.fence_uv(props, sx, sz, 202.6, 175.6, 207.8, 175.6)
	F.fence_uv(props, sx, sz, 202.6, 147.6, 225.6, 147.6)
	F.fence_uv(props, sx, sz, 225.6, 147.6, 225.6, 150.8)
	F.fence_gate(props, sx, sz, 220.2, 178.0, 231.6, 178.0, 5.6)
	F.fence_gate(props, sx, sz, 238.0, 169.2, 238.0, 174.1, 2.4)
	F.put(props, "prop_picnic_table", "worn", sx, sz, 214.0, 162.0, 90.0)
	F.put(props, "tree_coral_b", "normal", sx, sz, 208.5, 152.0, 75.0)
	F.put(props, "prop_hose_reel_cart", "worn", sx, sz, 229.0, 172.6, 0.0)     # the shop rinses bikes out back

	# ================================================================ S7n (u 196-240.8, v 100-140)
	F.dress(bd.spanish_court_adela, paints, props, dec, rr, sx, sz, 240.8, true, true, [-1.0])
	F.dress(bd.walkup_adela_n2, paints, props, dec, rr, sx, sz, 240.8, true, true, [1.0])
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 101.0, 139.0, 196.0, 1.0))
	F.fence_gate(props, sx, sz, 202.6, 99.9, 202.6, 139.6, 19.0)                   # from n_apt_b2_7th's lot-line fence corner
	F.fence_uv(props, sx, sz, 202.6, 139.6, 225.6, 139.6)
	F.fence_uv(props, sx, sz, 225.6, 139.6, 225.6, 137.2)
	F.fence_uv(props, sx, sz, 225.6, 99.9, 227.6, 99.9)
	F.fence_uv(props, sx, sz, 227.6, 99.9, 227.6, 102.8)
	F.fence_uv(props, sx, sz, 227.6, 121.2, 225.6, 121.2)
	F.fence_gate(props, sx, sz, 225.6, 121.2, 225.6, 124.8, 1.8)
	F.put(props, "tree_magnolia_b", "normal", sx, sz, 209.0, 112.0, 30.0)
	F.put(props, "prop_clothesline", "worn", sx, sz, 214.0, 130.5, 90.0)
	paints.insert(0, F.rect(sx, sz, 205.5, 120.0, 208.5, 127.0, "mulch"))
	for k in 3: F.put(props, ["plant_bird_of_paradise", "plant_agave_americana_small", "plant_potted_leafy"][k], "normal", sx, sz, 207.0, 121.2 + k * 2.3, k * 60.0)

	F.finish(ctx, 100.0, 100.0, 240.8, 190.8)
	quit()
