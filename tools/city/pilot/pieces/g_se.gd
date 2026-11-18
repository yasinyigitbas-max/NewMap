extends SceneTree
## Piece g_se (gritty edge sample, SE: toward the apartment band - the motel and the walk-ups).
## A (corner): a pharmacy + laundromat pair on the corner, then a vacant lot behind chain-link with the billboard over
##   it facing the avenue; an apartment pair on the side street behind low chain-link; parking off the lane.
## B (avenue): the cheap motel - rooms facing its own front lot (stalls nose to the room doors, the office at the west
##   end with the soda and snack machines on its end wall, clear of the doors), the motel's sign over the avenue
##   corner, back of house and bins behind.
## C (side street): a brick shop row (a dead front, the liquor store, the pawn shop) and a walk-up with a bar under it
##   (fire escape on its alley side); their service yard, bins and tenants' parking off the lane behind.
## D (inside, off the lane): the neighbourhood park the block got when the old laundry plant came down (kit
##   park_star_circle, re-dressed worn, chain-link with posts and ONE gate toward the lane).
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/grt_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const CC := preload("res://tools/city/pilot/pieces/cc_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := 1.0; var sz := 1.0
	var ctx := G.begin("g_se", sx, sz)
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	# ---- A: pharmacy + laundry, vacant lot with billboard, apartment pair
	G.shop(ctx, "ck/ck_svc_pawn_fast", 16.0, "-v", "pawn_chicken", ["pawn", "none"])  # audit fix 17 Nov (#9): was mod_svc_row, whose pharmacy + laundromat fronts repeated 13 times
	G.lot(ctx, "vacant", 26.0, 12.0, 52.0, 31.0, "v0", "-v")
	G.home(ctx, "ck/ck_apt3_row2", 42.0, "-u", "apt_pair_a")
	G.home(ctx, "ck/ck_apt3_row2", 40.0, "+v", "rear_pair_a", false, 46.0)
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, true, 28.0, 53.0, A.AL0, -1.0)
	paints.append(A.rect(sx, sz, 10.0, 24.0, 24.0, 30.0, "asphalt"))             # the shops' back strip
	I.yard_wear(dec, rr, sx, sz, 10.0, 24.0, 24.0, 30.0, 1.3)
	# ---- B: the motel
	var mo := A.place(ctx.bl, sx, sz, "extras/motel_inn_court", 80.0, 35.0, "-v", "motel", G.WEAR)
	ctx.blds.append(mo)
	CC.back_of_house(props, mo.node, "extras/motel_inn_court", false)
	I.bld_wear(dec, rr, mo.node, mo.w, mo.d, "extras/motel_inn_court")
	SL.stalls_u(paints, ctx.stalls, sx, sz, 70.0, 10, 29.4, -1.0)
	paints.append(A.rect(sx, sz, 60.0, 29.4, 100.0, 30.05, "concrete"))          # the walk along the room doors
	paints.append(A.rect(sx, sz, 60.0, A.PROP, 100.0, 30.0, "asphalt"))
	var my := rad_to_deg((mo.node as Node3D).rotation.y)
	I.add(props, "prop_vending_soda", "worn", A.at(mo, 17.3, mo.d * 0.5 + 0.95), my)
	I.add(props, "prop_vending_snack", "worn", A.at(mo, 16.0, mo.d * 0.5 + 0.95), my)
	I.add(props, "prop_trash_receptacle", "dirty", A.at(mo, -17.4, mo.d * 0.5 + 0.8), my)      # at the far end, clear of the room doors
	var fv := A.face_dir(sx, sz, "-v")
	I.add(props, "prop_billboard", "worn", A.q(sx, sz, 97.0, 12.5), rad_to_deg(atan2(fv.x, fv.y)))     # the motel sign, VACANCY
	SL.lot_light(props, sx, sz, 61.0, 20.0)
	SL.lot_light(props, sx, sz, 99.0, 20.0)
	I.yard_wear(dec, rr, sx, sz, 60.0, A.PROP, 100.0, 30.0, 1.4)
	G.bins(ctx, 66.0, 46.0, rad_to_deg(atan2(fv.x, fv.y)))
	# ---- C: brick shop row + walk-up, service yard behind
	G.shop(ctx, "urban/urb_brick_row", 70.0, "-u", "brick_shops_c", ["dead", "liquor", "none"])   # audit fix (#9): one pawn shop per quarter
	G.shop(ctx, "ck/ck_brk3_row2_fe", 89.0, "-u", "bar_walkup", ["bar", "none"])
	paints.append(A.rect(sx, sz, 24.0, 60.0, 54.0, 100.0, "asphalt"))
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, false, 62.0, 98.0, A.AL0, -1.0)
	var fu := A.face_dir(sx, sz, "-u")
	G.bins(ctx, 36.0, 80.5, rad_to_deg(atan2(fu.x, fu.y)))     # open toward the back doors
	I.yard_wear(dec, rr, sx, sz, 24.0, 60.0, 54.0, 100.0, 1.2)
	# ---- D: star circle park
	G.C.park(ctx, "park_star_circle", 80.0, 80.0, "-v")
	# the kit park is hedged on two sides only: chain-link round it with posts, ONE gate toward the lane
	for seg: Array in [[61.3, 61.3, 78.8, 61.3], [81.2, 61.3, 98.7, 61.3], [98.7, 61.3, 98.7, 98.7], [98.7, 98.7, 61.3, 98.7], [61.3, 98.7, 61.3, 61.3]]:
		A.privacy(props, Vector2(sx * float(seg[0]), sz * float(seg[1])), Vector2(sx * float(seg[2]), sz * float(seg[3])), "fence_chainlink", "fence_chainlink_post")
	I.add(props, "fence_gate_wrought_iron", "worn", A.q(sx, sz, 80.6, 61.9), 45.0)
	paints.append(A.rect(sx, sz, 79.0, 60.0, 81.0, 62.0, "concrete"))           # lane -> gate
	# audit fix (17 Nov, empty spaces): the park is the block's living room - benches just inside the fence on each
	# side facing in, a bin by each pair, lamps at the gate and the far corners, two picnic tables under the corner
	# trees, the grass worn on the shortcut from the gate across to the far corner
	for bs: Array in [[64.0, 70.0, 90.0], [64.0, 90.0, 90.0], [96.0, 70.0, -90.0], [96.0, 90.0, -90.0], [70.0, 96.5, 180.0], [90.0, 96.5, 180.0]]:
		I.add(props, "prop_park_bench", "worn" if int(bs[0] + bs[1]) % 3 != 0 else "dirty", A.q(sx, sz, float(bs[0]), float(bs[1])), float(bs[2]) * sx if absf(float(bs[2])) == 90.0 else (0.0 if sz < 0 else 180.0))
	for bn: Vector2 in [Vector2(64.0, 72.4), Vector2(96.0, 72.4), Vector2(72.4, 96.5)]: I.add(props, "prop_trash_receptacle", "dirty", A.q(sx, sz, bn.x, bn.y), 0.0)
	for lp: Vector2 in [Vector2(76.5, 60.6), Vector2(96.8, 96.8), Vector2(63.2, 96.8)]: I.add(props, "prop_lamp_globe", "worn", A.q(sx, sz, lp.x, lp.y), 0.0)
	for pt: Vector2 in [Vector2(67.0, 66.0), Vector2(93.0, 66.0)]: I.add(props, "prop_picnic_table", "worn", A.q(sx, sz, pt.x, pt.y), 0.0)
	for k8 in 7: dec.add(14, Vector2(sx * (80.0 + k8 * 2.4), sz * (63.0 + k8 * 4.8)), 25.0, 1.4, 3.2, S.walk_y, Color(1, 1, 1, 0.45))
	G.done(ctx, "grass", true)
	quit()
