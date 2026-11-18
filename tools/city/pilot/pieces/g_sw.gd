extends SceneTree
## Piece g_sw (gritty edge sample, SW: between industrial and the apartment band - the brick walk-ups).
## A (corner): a continuous brick street wall on the avenue - the corner walk-up with the liquor store under it, a
##   walk-up with the laundromat (fire escape on its alley side), then a boarded pair that never re-let; a second
##   walk-up with a fire escape down the side street. Behind: a back strip for the shops' bins, then the walk-ups'
##   shared court (clotheslines, chairs, the kids' corner - placed by use).
## B (avenue): two apartment rows behind low chain-link front fences (gaps at the walks), parking off the lane.
## C (side street): an apartment pair and a row on the street, a dingbat facing the lane with the cars under it.
## D (inside): the residents' parking off the lane, a tot lot (kit park_pocket_orange, worn, one gate toward the
##   parking) and the community garden the block made of a dead corner (chain-link, ONE gate
##   toward the lot, mulch beds, agaves and bougainvillea, hose reel, a picnic table under a sail, a bench facing the
##   beds).
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/grt_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const C := preload("res://tools/city/pilot/pieces/civ_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := -1.0; var sz := 1.0
	var ctx := G.begin("g_sw", sx, sz)
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	# ---- A: brick street wall + court
	G.shop(ctx, "ck/ck_brk3_corner2", 16.0, "-v", "corner_liquor", ["none", "liquor"])
	G.shop(ctx, "ck/ck_brk3_row2_fe", 29.0, "-v", "walkup_shops", ["none", "none"])   # audit fix (#9): one laundromat for the edge (g_nw)
	G.shop(ctx, "ck/ck_grt_row2", 43.0, "-v", "boarded_pair", ["dead", "dead"])
	G.shop(ctx, "ck/ck_brk3_row2_fe", 37.0, "-u", "side_walkup", ["none", "none"])
	paints.append(A.rect(sx, sz, 22.0, 25.5, 54.0, 31.0, "asphalt"))            # the shops' back strip, open to the lane
	I.yard_wear(dec, rr, sx, sz, 22.0, 25.5, 54.0, 31.0, 1.4)
	# ---- B: apartment rows behind chain-link
	G.home(ctx, "ck/ck_apt3_row2", 68.0, "-v", "apt_pair_b")
	G.home(ctx, "ck/ck_apt3_row3", 88.0, "-v", "apt_row_b")
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, true, 61.0, 99.0, A.AL0, -1.0)
	# rear row (courtyard plan): back houses facing the lane parking, the shared court between the two rows
	G.home(ctx, "ck/ck_brk3_row2", 68.0, "+v", "rear_walkup_b", false, 44.0)
	G.home(ctx, "ck/ck_apt3_row3", 88.0, "+v", "rear_row_b", false, 44.0)
	# ---- C: side street homes + lane dingbat
	G.home(ctx, "ck/ck_apt3_row2", 70.0, "-u", "apt_pair_c")
	G.home(ctx, "ck/ck_apt3_row3", 89.0, "-u", "apt_row_c")
	G.dingbat(ctx, "apartments/apt_dingbat_teal", 84.0, "+u", "lane_dingbat")
	G.home(ctx, "ck/ck_brk3_row2", 68.0, "+u", "rear_walkup_c", false, 50.0)
	# ---- D: residents' lot + community garden
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, true, 61.0, 99.0, A.AL1, 1.0)     # residents nose in off the lane
	G.C.park(ctx, "park_pocket_orange", 70.0, 75.5, "-v")                         # the tot lot by the garden
	var gu0 := 64.0; var gv0 := 84.0; var gu1 := 96.0; var gv1 := 97.0
	for seg: Array in [[gu0, gv0, 78.8, gv0], [81.2, gv0, gu1, gv0], [gu1, gv0, gu1, gv1], [gu1, gv1, gu0, gv1], [gu0, gv1, gu0, gv0]]:
		A.privacy(props, Vector2(sx * float(seg[0]), sz * float(seg[1])), Vector2(sx * float(seg[2]), sz * float(seg[3])), "fence_chainlink", "fence_chainlink_post")
	I.add(props, "fence_gate_wrought_iron", "worn", A.q(sx, sz, 80.6, gv0 + 0.6), 45.0)
	paints.append(A.rect(sx, sz, 79.0, 67.0, 81.0, gv0, "concrete"))            # path from the lane parking to the gate
	# two planting beds on the gate side; the sitting corner on its own clear ground at the far end, the sail OVER the
	# table it shades (Yasin 17 Nov: the sail stood over a bed and the table sat beside it in the sun)
	for k in 2:
		var bu := 67.0 + k * 9.5
		paints.append(A.rect(sx, sz, bu, 88.0, bu + 6.5, 94.5, "mulch"))
		for j in 2:
			I.add(props, ["plant_agave_americana_small", "plant_bird_of_paradise", "plant_bougainvillea_mound"][(k + j) % 3], "normal", A.q(sx, sz, bu + 1.6 + j * 3.3, 91.2), (k * 3 + j) * 40.0)
	I.add(props, "prop_hose_reel_cart", "worn", A.q(sx, sz, 65.5, 86.0), 0.0)
	I.add(props, "prop_picnic_table", "worn", A.q(sx, sz, 90.5, 91.2), 90.0)
	I.add(props, "prop_shade_sail", "worn", A.q(sx, sz, 90.5, 91.2), 0.0)
	dec.add(14, Vector2(sx * 90.5, sz * 91.2), 0.0, 3.4, 3.0, S.walk_y, Color(1, 1, 1, 0.5))     # trodden ground round the table
	var fb := A.face_dir(sx, sz, "+v")
	I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 71.0, 86.0), rad_to_deg(atan2(fb.x, fb.y)))     # faces the beds, clear of the gate path
	dec.add(14, Vector2(sx * 80.0, sz * 86.5), 0.0, 2.2, 3.0, S.walk_y, Color(1, 1, 1, 0.5))
	# audit fix (17 Nov, empty spaces): a real allotment - two more beds, pots along the back fence, the compost
	# carts by the gate, an arbor over the path, a second bench, trodden paths between the beds
	for k9 in 2:
		var bu2 := 85.5 + k9 * 0.0
		paints.insert(0, A.rect(sx, sz, 64.8 + k9 * 9.5, 85.0, 70.8 + k9 * 9.5, 86.8, "mulch"))
		I.add(props, "plant_agave_americana_small" if k9 == 0 else "plant_bird_of_paradise", "normal", A.q(sx, sz, 67.8 + k9 * 9.5, 85.9), k9 * 70.0)
	for k10 in 6: I.add(props, ["plant_potted_leafy", "plant_potted_succulent"][k10 % 2], "normal", A.q(sx, sz, 66.0 + k10 * 3.2, 95.6), k10 * 33.0)
	for k11 in 2: I.add(props, ["prop_trash_cart_green", "prop_trash_cart_black"][k11], "dirty", A.q(sx, sz, 84.0 + k11 * 0.9, 85.2), 0.0)
	I.add(props, "prop_garden_arbor", "worn", A.q(sx, sz, 80.0, 89.0), 0.0)
	I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 94.5, 86.0), rad_to_deg(atan2(fb.x, fb.y)))
	for k12 in 3: dec.add(14, Vector2(sx * (74.8 + k12 * 0.0), sz * (88.0 + k12 * 2.6)), 0.0, 1.2, 2.6, S.walk_y, Color(1, 1, 1, 0.45))
	G.done(ctx, "grass", true)
	quit()
