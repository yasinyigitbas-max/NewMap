extends SceneTree
## Piece n_apt_b3_w - apartment band fill, BLOCK 3 (B Ave - Adela Ave, 6th St - the residential quarters at z -300), its
## WEST part. Layout row: pos [250, 8, -400], yaw 0 (the B Ave x 6th St junction's frame); u = east of B Ave's centre
## line, v = SOUTH of 6th St's centre line (sx = +1, sz = +1). Outline: u 9.2-125 (B Ave's property line to the lot line
## with n_apt_b3_e), v 9.2-100 (6th St's property line to the residential quarter r_q_250_m200_ne).
##
## LAND (apt_fill_b3_land.gd, measured): the band's steep end. B Ave climbs 2.00 m along the west edge (8.15 -> 10.15),
## 6th St falls toward Adela, the residential quarter behind stands on house terraces 10.30 .. 8.67 m. The ground is one
## smooth surface through all four edges (about 3 %); every building on its own level pad at the middle of its front
## (the six cottages of the bungalow court each on their own little terrace, 0.6 m apart from one end of the court to
## the other); on the shared line with the residential quarter a retaining face wherever their terrace stands above or
## below this block (up to 0.65 m here), facing whoever sees it; their alley's mouth (u 54-60) matched exactly.
##
## WHO LIVES HERE AND WHY:
## The edge where the apartments give way to the houses of the hill: lower and older. On the corner of B Ave and 6th,
## opposite the community room, HILLTOP BOOKS (a tiny old shop: second-hand books, the preschool parents' stop) beside a
## Spanish court; on B Ave the walk-up and a BUNGALOW COURT - six small cottages round a garden walk entered from the
## avenue under an arbor, their post boxes at the gate (retired people, a teacher, a nurse); on 6th St a garden apartment
## and a walk-up; behind them, where the hill looks back over the band to the centre, the VIEW GARDEN: benches facing
## north, a gravel walk, jacarandas, a lamp - and the residents' stalls on the alleys.
## Alleys: u-alley v 54-60 (B Ave's apron at z -346..-340), v-alley u 54-60 (6th St's apron at u 304-310; it runs on into
## the residential quarter's own alley at z -300).
## Walk-in places (rooms built with the block): Hilltop Books.
## Built once by its own script; a draft until Yasin has seen it. Never re-run after that.
const F := preload("res://tools/city/pilot/pieces/apt_fill_lib.gd")
const L := preload("res://tools/city/pilot/pieces/apt_fill_b3_land.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const NAME := "n_apt_b3_w"
const B := [
	["commercial/com_shallow_books", 12.45, 14.7, "-v", "hilltop_books"],
	["apartments/apt_spanish_revival", 28.0, 17.2, "-v", "spanish_court_hill"],
	["ck/ck_apt3_row2", 18.2, 38.0, "-u", "walkup_bave_hill"],
	["apartments/apt_garden_cream", 73.0, 16.7, "-v", "garden_6th_s"],
	["ck/ck_apt3_row3", 106.0, 18.2, "-v", "walkup_6th_sw"],
	["houses/spanish_small", 18.0, 72.0, "+v", "bungalow_1"],
	["houses/beach_white", 29.5, 71.5, "+v", "bungalow_2"],
	["houses/spanish_small", 41.0, 72.0, "+v", "bungalow_3"],
	["houses/narrow_cottage_stucco_clay", 17.0, 90.0, "-v", "bungalow_4"],
	["houses/ranch_porch", 29.5, 88.0, "-v", "bungalow_5"],
	["houses/narrow_cottage_siding", 41.0, 90.0, "-v", "bungalow_6"],
]
func _init() -> void: _run.call_deferred()

func _run() -> void:
	var sx := 1.0; var sz := 1.0
	var ctx := F.begin(NAME, sx, sz)
	F.SURF = L.surface; F.GY = F.terrain; F.outline(sx, sz, 9.2, 9.2, 125.0, 100.0)
	var bl: Node3D = ctx.bl; var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec
	var rr: RandomNumberGenerator = ctx.rr; var paints: Array = ctx.paints; var stalls: Array = ctx.stalls
	var poles: Array = ctx.poles; var blds: Array = ctx.blds; var stops: Array = ctx.stops
	# ---------------------------------------------------------------- land first: pads, the retaining faces, the alleys
	var pads := {}
	for b: Array in B: pads[String(b[4])] = F.pad_for(paints, sx, sz, String(b[0]), float(b[1]), float(b[2]), String(b[3]))
	ctx["walls"] = L.seam_faces(9.2, 125.0)
	F.alley(paints, props, dec, rr, sx, sz, true, 54.0, 9.2, 125.0, poles, [[30.0, 53.3], [95.0, 60.7]], NAN, [1])
	F.alley(paints, props, dec, rr, sx, sz, false, 54.0, 9.2, 100.0, poles, [[30.0, 60.7], [80.0, 60.7]], NAN, [])
	if OS.get_environment("APT_GROUND_ONLY") == "1":
		F.finish(ctx, 9.2, 9.2, 125.0, 100.0); quit(); return
	var bd := {}
	for b: Array in B:
		bd[String(b[4])] = F.place(bl, sx, sz, String(b[0]), float(b[1]), float(b[2]), String(b[3]), String(b[4]), 0.78, pads[String(b[4])])
		blds.append(bd[String(b[4])])

	# ================================================================ A: the corner (u 9.2-54, v 9.2-54)
	var bk: Dictionary = bd.hilltop_books
	paints.append(F.rect(sx, sz, 9.2, 9.2, 15.7, 11.7, "concrete"))            # the shop's step-out on the corner
	F.back_of_house(props, bk, false)
	F.wall(props, bk, "prop_porch_light_coach", "worn", "front", -2.0 - 0.8, 2.2, 0.05)
	F.put(props, "prop_park_bench", "worn", sx, sz, 11.0, 10.4, 180.0)            # a reader's bench under the window, facing 6th, clear of the door (u 14.45)
	F.put(props, "prop_newspaper_box_red", "worn", sx, sz, 16.9, 10.2, 180.0)     # in the gap beside the shop, off the walk
	F.dress(bd.spanish_court_hill, paints, props, dec, rr, sx, sz, 9.2, true, true, [1.0])
	F.dress(bd.walkup_bave_hill, paints, props, dec, rr, sx, sz, 9.2, true, true)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 10.0, 52.0, 54.0, -1.0))
	F.fence_gate(props, sx, sz, 47.4, 22.4, 47.4, 52.2, 15.0)
	F.fence_uv(props, sx, sz, 37.2, 22.4, 47.4, 22.4)
	F.fence_uv(props, sx, sz, 24.4, 52.2, 47.4, 52.2)
	F.fence_uv(props, sx, sz, 24.4, 44.2, 24.4, 52.2)
	F.fence_gate(props, sx, sz, 19.4, 22.4, 19.4, 31.8, 4.7)                      # across the gap between the court and the walk-up, clear of the court's bins
	F.put(props, "tree_jacaranda_a", "normal", sx, sz, 42.0, 30.0, 50.0)
	F.put(props, "prop_clothesline", "worn", sx, sz, 36.0, 44.0, 0.0)

	# ================================================================ D: the bungalow court (u 9.2-54, v 60-100)
	paints.append(F.rect(sx, sz, 9.2, 79.0, 48.0, 81.0, "concrete"))            # the court's garden walk, in from B Ave
	F.put(props, "prop_garden_arbor", "worn", sx, sz, 11.4, 80.0, 90.0)           # the gate arch at the walk's mouth
	for k in 4: F.put(props, "prop_mailbox_post_metal", "worn", sx, sz, 10.6 + k * 0.9, 82.6, 0.0)   # the post boxes at the gate, facing the walk
	for key: String in ["bungalow_1", "bungalow_2", "bungalow_3", "bungalow_4", "bungalow_5", "bungalow_6"]:
		var cb: Dictionary = bd[key]
		var dz := 76.0 if String(cb.face) == "+v" else 84.0
		var dx := float(F.doors_of(String(cb.folder))[0]) if not F.doors_of(String(cb.folder)).is_empty() else 0.0
		var dp := F.at(cb, dx, float(cb.d) * 0.5)
		var wu := dp.x
		if String(cb.face) == "+v": paints.append(F.rect(sx, sz, wu - 0.6, 76.0, wu + 0.6, 79.0, "concrete"))
		else: paints.append(F.rect(sx, sz, wu - 0.6, 81.0, wu + 0.6, 84.0, "concrete"))
		F.wall(props, cb, "prop_porch_light_coach_bronze" if key.ends_with("1") or key.ends_with("4") else "prop_porch_light_barn", "worn", "front", dx - 0.8, 2.1, 0.05)
		F.wall(props, cb, "prop_house_numbers_tile", "worn", "front", dx + 0.75, 1.6, 0.03)
		I.add(props, "plant_potted_succulent", "normal", F.at(cb, dx + 1.2, float(cb.d) * 0.5 + 0.4), rad_to_deg((cb.node as Node3D).rotation.y))
		F.back_of_house(props, cb, true)
		dec.add(14, Vector2(wu, dz + (1.2 if String(cb.face) == "+v" else -1.2)), 0.0, 1.4, 1.4, F.GY, Color(1, 1, 1, 0.45))
	# the court's garden between the rows: bird-of-paradise beds along the walk, two palms, a bench, a fountain
	for k in 3:
		paints.insert(0, F.rect(sx, sz, 14.0 + k * 11.5, 77.2, 20.5 + k * 11.5, 78.6, "mulch"))
		F.put(props, "plant_bird_of_paradise", "normal", sx, sz, 16.0 + k * 11.5, 77.9, k * 40.0)
		F.put(props, "plant_agave_americana_small", "normal", sx, sz, 19.0 + k * 11.5, 77.9, k * 70.0)
	F.put(props, "palm_queen_b", "normal", sx, sz, 35.6, 82.6, 30.0)
	F.put(props, "palm_queen_a", "normal", sx, sz, 23.8, 82.6, 150.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 46.0, 80.0, -90.0)            # at the walk's end, looking back along the court
	F.put(props, "prop_drinking_fountain", "worn", sx, sz, 44.6, 82.8, -90.0)
	F.put(props, "prop_lamp_globe", "worn", sx, sz, 22.6, 81.6)
	F.put(props, "prop_lamp_globe", "worn", sx, sz, 37.0, 78.4)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 61.0, 99.0, 54.0, -1.0))
	F.fence_uv(props, sx, sz, 10.0, 60.8, 47.4, 60.8)                              # the cottages' back yards on the alley
	F.fence_gate(props, sx, sz, 47.4, 60.8, 47.4, 99.6, 19.6)                      # the court's east side, behind the stalls
	F.fence_uv(props, sx, sz, 10.0, 99.6, 47.4, 99.6)                              # the back line (the retaining face under it)
	F.fence_uv(props, sx, sz, 10.0, 60.8, 10.0, 78.4, "fence_picket_white", "fence_post_picket")    # the court's front on B Ave, open at the walk
	F.fence_uv(props, sx, sz, 10.0, 81.6, 10.0, 99.6, "fence_picket_white", "fence_post_picket")

	# ================================================================ B (west, u 60-125, v 9.2-54): 6th St
	F.dress(bd.garden_6th_s, paints, props, dec, rr, sx, sz, 9.2, true, true)
	F.dress(bd.walkup_6th_sw, paints, props, dec, rr, sx, sz, 9.2, true, true)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, true, 62.0, 122.0, 54.0, -1.0))
	F.fence_uv(props, sx, sz, 62.0, 21.4, 62.0, 47.4)
	F.fence_gate(props, sx, sz, 62.0, 47.4, 124.6, 47.4, 31.0)
	F.fence_gate(props, sx, sz, 84.0, 18.0, 96.8, 18.0, 6.4)
	F.fence_uv(props, sx, sz, 115.2, 24.4, 124.6, 24.4)
	F.fence_uv(props, sx, sz, 124.6, 24.4, 124.6, 47.4)
	paints.insert(0, F.rect(sx, sz, 86.0, 30.0, 94.0, 37.0, "mulch"))          # the garden apartment's children: swings on bark
	F.put(props, "prop_swing_set", "worn", sx, sz, 90.0, 33.5, 0.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 90.0, 39.4, 180.0)
	F.put(props, "tree_ficus_a", "normal", sx, sz, 120.0, 32.0, 10.0)

	# ================================================================ E (west, u 60-125, v 60-100): the view garden
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 61.8, 76.0, 60.0, 1.0))
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 84.0, 99.0, 60.0, 1.0))
	F.fence_gate(props, sx, sz, 66.6, 61.6, 66.6, 99.6, 18.4)
	F.fence_gate(props, sx, sz, 66.6, 61.6, 124.6, 61.6, 30.0)
	F.fence_uv(props, sx, sz, 124.6, 61.6, 124.6, 99.6)
	F.fence_uv(props, sx, sz, 66.6, 99.6, 124.6, 99.6, "fence_wrought_iron", "fence_post_wrought_iron", 1.98)   # iron at the back: the garden looks over the hill's yards too
	paints.insert(0, F.rect(sx, sz, 70.0, 66.0, 121.0, 67.6, "gravel"))        # the walk along the garden's north side
	for k in 4: F.put(props, "prop_park_bench", "worn", sx, sz, 76.0 + k * 13.0, 68.6, 180.0)   # benches facing north: the view down over the band to the centre
	F.put(props, "prop_trash_receptacle", "worn", sx, sz, 82.6, 68.6)
	F.put(props, "prop_trash_receptacle", "worn", sx, sz, 108.6, 68.6)
	for t: Array in [["tree_jacaranda_b", 72.0, 76.0], ["tree_jacaranda_a", 92.0, 80.0], ["tree_coral_a", 112.0, 76.0], ["tree_magnolia_b", 102.0, 92.0], ["tree_ficus_b", 80.0, 93.0]]:
		F.put(props, String(t[0]), "normal", sx, sz, float(t[1]), float(t[2]), float(t[1]) * 4.0)
	F.put(props, "prop_lamp_globe", "worn", sx, sz, 96.0, 66.8)
	F.put(props, "prop_picnic_table", "worn", sx, sz, 92.0, 88.0, 0.0)
	F.put(props, "prop_shade_sail", "worn", sx, sz, 92.0, 88.0, 0.0)
	dec.add(14, Vector2(96.0, 72.0), 90.0, 1.0, 14.0, F.GY, Color(1, 1, 1, 0.45))   # people cut across the lawn to the benches

	F.finish(ctx, 9.2, 9.2, 125.0, 100.0)
	quit()
