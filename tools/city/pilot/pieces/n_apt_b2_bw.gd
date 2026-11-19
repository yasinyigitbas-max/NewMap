extends SceneTree
## Piece n_apt_b2_bw - apartment band fill, BLOCK 2 (B Ave - Adela Ave, 7th - 6th St), its WEST part: B Ave x 6th St,
## the HIGH corner. Layout row: pos [250, 6, -600], yaw 0; u = east of B Ave's centre line, v = SOUTH of 7th St's centre
## line (sx = +1, sz = +1). Outline: u 9.2-100 (B Ave's property line to the lot line with n_apt_b2_be), v 100-190.8 (the
## lot line with the sample's a_se to 6th St's property line).
##
## LAND (apt_fill_b2_land.gd, measured): B Ave climbs along this piece's west edge from 6.15 m (v 100, level with a_se)
## to 8.15 m at v 179 (2.00 m, steepest about 3.5 %); 6th St comes down from 8.15 at the corner to 7.50 at u 100. The
## piece is the corner of a gentle hill: 2.00 m from its north-east to its south-west corner. Nothing stands on the
## slope: the buildings each on a level pad at the middle of their front (the B Ave walk-ups 0.29 and 0.93 local apart:
## they STEP up the avenue), the community room on the top pad (2.15), its play yard on its own level pad; the pads ease
## into the surface over 5 m and never within 3 m of an edge, so every edge stays exactly on the measured street heights
## and on a_se's level ground.
##
## WHO USES IT AND WHY:
## The top of the band, where B Ave climbs to the houses of the hill: families. On the corner of B Ave and 6th the
## COMMUNITY ROOM of the apartments with its PRESCHOOL (the neighbourhood association's hall: meetings at night, the
## little ones in the day), its fenced play yard behind on its own level pad (play structure, swings, slide on bark,
## tables under sails, benches for the parents), the parents' and staff's stalls off the alley. On B Ave two walk-ups
## stepping up the hill, their yard with vegetable beds; on 6th St a Spanish court and a walk-up; the lock-up garages on
## the alley and the residents' barbecue terrace beside them.
## Alleys: v-alley u 54-60 (continues a_se's to 6th St's apron at u 304-310), u-alley v 140-146 (B Ave's apron at
## z -460..-454).
## Walk-in places (rooms built with the block): the community room / preschool.
## Built once by its own script; a draft until Yasin has seen it. Never re-run after that.
const F := preload("res://tools/city/pilot/pieces/apt_fill_lib.gd")
const L := preload("res://tools/city/pilot/pieces/apt_fill_b2_land.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const NAME := "n_apt_b2_bw"
const B := [
	["civic/civ_community_center", 25.0, 179.8, "+v", "community_room"],
	["ck/ck_apt3_row3", 18.2, 111.0, "-u", "walkup_b_hill_n"],
	["ck/ck_apt3_row2", 18.2, 131.0, "-u", "walkup_b_hill_s"],
	["apartments/apt_spanish_white", 70.0, 182.8, "+v", "spanish_court_6th"],
	["ck/ck_apt3_row2", 91.0, 181.8, "+v", "walkup_6th_w"],
]
const GAR := ["garages/single_stucco_clay", "garages/single_siding_comp", "garages/single_stucco_comp", "garages/single_stucco_flat", "garages/single_stucco_clay", "garages/single_stucco_comp", "garages/single_siding_comp", "garages/single_stucco_flat"]
func _init() -> void: _run.call_deferred()

func _run() -> void:
	var sx := 1.0; var sz := 1.0
	var ctx := F.begin(NAME, sx, sz)
	F.SURF = L.surface; F.GY = F.terrain; F.outline(sx, sz, 9.2, 100.0, 100.0, 190.8)
	var bl: Node3D = ctx.bl; var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec
	var rr: RandomNumberGenerator = ctx.rr; var paints: Array = ctx.paints; var stalls: Array = ctx.stalls
	var poles: Array = ctx.poles; var blds: Array = ctx.blds; var stops: Array = ctx.stops
	# ---------------------------------------------------------------- land first: pads, the play yard's pad, the alleys
	var pads := {}
	for b: Array in B: pads[String(b[4])] = F.pad_for(paints, sx, sz, String(b[0]), float(b[1]), float(b[2]), String(b[3]))
	for k in GAR.size(): pads["lockup_%d" % k] = F.pad_for(paints, sx, sz, String(GAR[k]), 63.6, 104.4 + k * 3.7, "-u")
	var yard_h := float(F.SURF.call(28.5, 162.0))
	F.pad_rect(paints, sx, sz, 13.0, 150.0, 44.0, 172.6, yard_h)
	var terrace_h := float(F.SURF.call(82.0, 118.0))
	F.pad_rect(paints, sx, sz, 72.0, 110.0, 94.0, 127.0, terrace_h)               # the barbecue terrace, level
	F.alley(paints, props, dec, rr, sx, sz, false, 54.0, 100.0, 190.8, poles, [[135.0, 60.7], [175.0, 60.7]], NAN, [1])
	F.alley(paints, props, dec, rr, sx, sz, true, 140.0, 9.2, 100.0, poles, [[15.0, 139.3], [40.0, 146.7]], NAN, [])
	if OS.get_environment("APT_GROUND_ONLY") == "1":
		F.finish(ctx, 9.2, 100.0, 100.0, 190.8); quit(); return
	var bd := {}
	for b: Array in B:
		bd[String(b[4])] = F.place(bl, sx, sz, String(b[0]), float(b[1]), float(b[2]), String(b[3]), String(b[4]), 0.72, pads[String(b[4])])
		blds.append(bd[String(b[4])])

	# ================================================================ S1: the community room and preschool (u 9.2-54, v 146-190.8)
	var cr: Dictionary = bd.community_room
	paints.append(F.rect(sx, sz, 13.0, 186.8, 37.0, 190.8, "plaza"))            # the drop-off forecourt on 6th St
	F.back_of_house(props, cr, false)
	F.put(props, "prop_park_bench", "worn", sx, sz, 16.0, 189.4, 0.0)            # parents wait at pick-up, facing the street
	F.put(props, "prop_park_bench", "worn", sx, sz, 34.0, 189.4, 0.0)
	F.put(props, "prop_bike_rack", "worn", sx, sz, 29.6, 190.2, 0.0)
	F.put(props, "prop_trash_receptacle", "worn", sx, sz, 19.2, 190.2)
	for p0: Vector2 in [Vector2(13.6, 187.4), Vector2(36.4, 187.4)]: F.put(props, "plant_potted_leafy", "normal", sx, sz, p0.x, p0.y, 0.0)
	F.wall(props, cr, "prop_porch_light_coach_bronze", "worn", "front", -1.8, 2.4, 0.05)
	F.wall(props, cr, "prop_porch_light_coach_bronze", "worn", "front", 1.8, 2.4, 0.05)
	F.grime(dec, Vector2(13.0, 186.4), Vector2(37.0, 186.4), rr)
	# the play yard behind it, its own level pad: wrought iron round it (it faces B Ave), the gate toward the stalls
	paints.insert(0, F.rect(sx, sz, 17.0, 153.0, 33.0, 165.0, "mulch"))
	F.fence_uv(props, sx, sz, 13.0, 172.6, 13.0, 150.0, "fence_wrought_iron", "fence_post_wrought_iron", 1.98)
	F.fence_uv(props, sx, sz, 13.0, 150.0, 44.0, 150.0, "fence_wrought_iron", "fence_post_wrought_iron", 1.98)
	F.fence_gate(props, sx, sz, 44.0, 150.0, 44.0, 172.6, 11.0, "fence_wrought_iron", "fence_post_wrought_iron", "fence_gate_wrought_iron", 1.98)
	F.fence_uv(props, sx, sz, 44.0, 172.6, 37.2, 172.6, "fence_wrought_iron", "fence_post_wrought_iron", 1.98)
	F.put(props, "prop_play_structure", "worn", sx, sz, 25.0, 159.0, 90.0)
	F.put(props, "prop_swing_set", "worn", sx, sz, 19.6, 155.6, 0.0)
	F.put(props, "prop_slide", "worn", sx, sz, 30.6, 155.0, 0.0)
	dec.add(14, Vector2(19.6, 155.6), 0.0, 3.0, 2.2, F.GY, Color(1, 1, 1, 0.55))
	for t: Array in [[38.0, 156.0], [38.0, 166.0]]:
		F.put(props, "prop_picnic_table", "worn", sx, sz, float(t[0]), float(t[1]), 90.0)
		F.put(props, "prop_shade_sail", "worn", sx, sz, float(t[0]), float(t[1]), 90.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 25.0, 167.2, 180.0)          # the teacher watches the play
	F.put(props, "prop_drinking_fountain", "worn", sx, sz, 15.0, 168.0, 90.0)
	F.put(props, "prop_trash_receptacle", "worn", sx, sz, 15.0, 170.4)
	F.put(props, "tree_coral_a", "normal", sx, sz, 16.0, 151.8, 40.0)
	F.put(props, "tree_jacaranda_b", "normal", sx, sz, 41.0, 152.0, 200.0)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 147.0, 175.0, 54.0, -1.0))   # parents and staff
	F.put(props, "tree_magnolia_a", "normal", sx, sz, 44.6, 180.0, 10.0)          # shade over the stall row's end

	# ================================================================ S2 (u 9.2-54, v 100-140): two walk-ups stepping up B Ave
	for key: String in ["walkup_b_hill_n", "walkup_b_hill_s"]: F.dress(bd[key], paints, props, dec, rr, sx, sz, 9.2, true, true)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 100.6, 138.6, 54.0, -1.0))
	F.fence_gate(props, sx, sz, 47.6, 100.4, 47.6, 139.4, 19.0)
	F.fence_uv(props, sx, sz, 24.4, 100.4, 47.6, 100.4)
	F.fence_uv(props, sx, sz, 24.4, 100.4, 24.4, 101.8)
	F.fence_uv(props, sx, sz, 47.6, 139.4, 24.4, 139.4)
	F.fence_uv(props, sx, sz, 24.4, 139.4, 24.4, 137.2)
	F.fence_gate(props, sx, sz, 22.0, 120.2, 22.0, 124.8, 2.3)
	for k in 3:                                                                    # vegetable beds along the yard's sunny side
		paints.insert(0, F.rect(sx, sz, 30.0 + k * 5.0, 104.0, 33.5 + k * 5.0, 110.0, "mulch"))
		for j in 2: F.put(props, ["plant_agave_americana_small", "plant_bird_of_paradise", "plant_potted_leafy"][(k + j) % 3], "normal", sx, sz, 31.75 + k * 5.0, 105.5 + j * 3.0, (k + j) * 47.0)
	F.put(props, "prop_clothesline", "worn", sx, sz, 36.0, 131.0, 0.0)
	F.put(props, "tree_ficus_b", "normal", sx, sz, 42.0, 120.0, 90.0)
	F.put(props, "prop_hose_reel_cart", "worn", sx, sz, 28.6, 102.0, 0.0)

	# ================================================================ S3w (u 60-100, v 146-190.8): 6th St
	F.dress(bd.spanish_court_6th, paints, props, dec, rr, sx, sz, 190.8, true, true, [-1.0])
	F.dress(bd.walkup_6th_w, paints, props, dec, rr, sx, sz, 190.8, true, true, [1.0])
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 147.0, 170.0, 60.0, 1.0))
	F.fence_uv(props, sx, sz, 66.6, 146.6, 66.6, 177.6)
	F.fence_gate(props, sx, sz, 66.6, 146.6, 99.6, 146.6, 17.0)
	F.fence_uv(props, sx, sz, 99.6, 146.6, 99.6, 175.6)
	F.fence_uv(props, sx, sz, 99.6, 175.6, 97.2, 175.6)
	F.fence_gate(props, sx, sz, 79.2, 178.0, 84.8, 178.0, 2.8)
	F.put(props, "tree_jacaranda_a", "normal", sx, sz, 92.0, 152.0, 120.0)
	F.put(props, "prop_patio_set_4", "worn", sx, sz, 80.0, 160.0, 15.0)
	F.put(props, "prop_bbq_kettle", "worn", sx, sz, 83.0, 158.0, 0.0)

	# ================================================================ S4 (u 60-100, v 100-140): lock-up garages + barbecue terrace
	for k in GAR.size():
		var gb := F.place(bl, sx, sz, String(GAR[k]), 63.6, 104.4 + k * 3.7, "-u", "lockup_%d" % k, 0.85, pads["lockup_%d" % k])
		blds.append(gb)
		W.oil(dec, rr, Vector2(58.5, 104.4 + k * 3.7), 90.0, F.GY, 0.55)
	paints.append(F.rect(sx, sz, 60.0, 102.5, 60.6, 132.4, "concrete"))
	paints.insert(0, F.rect(sx, sz, 72.0, 110.0, 94.0, 127.0, "concrete"))     # the terrace slab
	for t2: Array in [[78.0, 115.0], [88.0, 115.0]]:
		F.put(props, "prop_picnic_table", "worn", sx, sz, float(t2[0]), float(t2[1]), 0.0)
		F.put(props, "prop_shade_sail", "worn", sx, sz, float(t2[0]), float(t2[1]), 0.0)
	F.put(props, "prop_bbq_gas_cart", "worn", sx, sz, 83.0, 125.2, 180.0)
	F.put(props, "prop_bbq_kettle", "worn", sx, sz, 76.0, 124.6, 0.0)
	F.put(props, "prop_adirondack_wood", "worn", sx, sz, 92.0, 121.0, -100.0)
	F.put(props, "prop_adirondack_white", "worn", sx, sz, 92.2, 123.4, -80.0)
	F.put(props, "prop_trash_receptacle", "worn", sx, sz, 73.0, 111.0)
	F.put(props, "prop_lamp_globe", "worn", sx, sz, 94.8, 109.4)
	F.put(props, "tree_ficus_a", "normal", sx, sz, 96.5, 129.0, 300.0)
	F.put(props, "tree_coral_b", "normal", sx, sz, 70.0, 104.0, 210.0)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, true, 70.0, 99.4, 140.0, -1.0))
	F.fence_gate(props, sx, sz, 67.2, 133.4, 99.6, 133.4, 16.0)
	F.fence_uv(props, sx, sz, 67.2, 133.4, 67.2, 100.4)
	F.fence_uv(props, sx, sz, 67.2, 100.4, 99.6, 100.4)
	F.fence_uv(props, sx, sz, 99.6, 100.4, 99.6, 133.4)

	F.finish(ctx, 9.2, 100.0, 100.0, 190.8)
	quit()
