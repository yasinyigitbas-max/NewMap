extends SceneTree
## Piece g_ne (gritty edge sample, NE: the shopping side of the edge).
## A (corner): the corner market (papers, the ice chest, bins), a dive bar on the side street (smokers' bin, bike
##   rack), the market's delivery yard with a tagged bin enclosure, staff and customer stalls off the lane.
## B (avenue): a brick walk-up with the pawn shop under it (fire escape down its alley side) and a brick shop row - one
##   dead front, the laundromat, a bar - then the tenants' parking off the lane and their bins.
## C (side street): an apartment row with its middle bay boarded up and an apartment pair, both behind low chain-link
##   with open gaps at the walks; a pink dingbat facing the lane with the cars under it; the shared court between them
##   (yard life placed by use).
## D (inside): a stalled building site behind screened temp fence - k-rails, the roll-off, drums, cones, a container
##   site office nobody visits, the ruts of the last truck in.
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/grt_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := 1.0; var sz := -1.0
	var ctx := G.begin("g_ne", sx, sz)
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	# ---- A: corner market + dive bar + delivery yard
	G.shop(ctx, "extras/ext_grocery_market", 25.0, "-v", "corner_market", ["liquor", "liquor"])
	for k in 4: I.add(props, "prop_propane_cylinder_100lb", "rusty", A.q(sx, sz, 39.0 + k * 0.45, 10.4), 0.0)   # propane exchange at the forecourt corner, away from the doors
	G.shop(ctx, "commercial/com_bar_crown", 46.0, "-u", "dive_bar", ["bar"])
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, true, 28.0, 53.0, A.AL0, -1.0)
	paints.append(A.rect(sx, sz, A.PROP, A.PROP, 54.0, 54.0, "asphalt"))
	var fu := A.face_dir(sx, sz, "-u")
	G.bins(ctx, 47.0, 32.0, rad_to_deg(atan2(fu.x, fu.y)))
	I.yard_wear(dec, rr, sx, sz, 12.0, 36.0, 54.0, 54.0, 1.3)
	I.truck_path(dec, rr, Vector2(sx * 54.0, sz * 40.0), Vector2(sx * 30.0, sz * 38.0))    # the delivery van backs to the market's door
	# ---- B: brick walk-up + brick shop row, tenants' parking
	G.shop(ctx, "ck/ck_brk3_row2_fe", 67.0, "-v", "deli_walkup", ["none", "none"])   # audit fix (#9): the edge had a pawn shop in every quarter
	G.shop(ctx, "urban/urb_brick_row", 86.0, "-v", "brick_shops", ["dead", "none", "none"])   # audit fix (#9): a laundromat in every quarter and two bars here
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, true, 61.0, 99.0, A.AL0, -1.0)
	paints.append(A.rect(sx, sz, 60.0, A.PROP, 100.0, 54.0, "asphalt"))
	var fv := A.face_dir(sx, sz, "-v")
	G.bins(ctx, 90.0, 33.0, rad_to_deg(atan2(fv.x, fv.y)))
	I.yard_wear(dec, rr, sx, sz, 60.0, 26.0, 100.0, 54.0, 1.2)
	# ---- C: homes on the side street, the lane dingbat, the court between
	G.home(ctx, "ck/ck_apt3_row3_boarded", 71.0, "-u", "boarded_apts")
	G.home(ctx, "ck/ck_apt3_row2", 90.0, "-u", "apt_pair_c")
	G.dingbat(ctx, "apartments/apt_dingbat_pink", 72.0, "+u", "lane_dingbat")
	G.home(ctx, "ck/ck_apt3_row2", 90.0, "+u", "rear_pair_c", false, 50.0)
	# ---- D: stalled building site
	G.lot(ctx, "site", 62.0, 62.0, 98.0, 98.0, "v0")
	# audit fix (17 Nov, empty spaces): the work stopped after the dig and the first slab - the excavation (bare earth)
	# with a water-barrier line along its edge, the poured slab, a second container for tools, stacked k-rails, the
	# generator's fuel tank, a light tower, a temp-fence stand left inside, more cones and drums
	paints.insert(0, A.rect(sx, sz, 66.0, 76.0, 86.0, 94.0, "mulch"))       # the dig
	paints.insert(0, A.rect(sx, sz, 86.5, 78.0, 96.0, 90.0, "curb"))        # the slab
	for k in 5: I.add(props, "prop_water_barrier_white" if k % 2 == 0 else "prop_water_barrier_orange", "dirty", A.q(sx, sz, 76.0 + k * 2.6, 74.8), 0.0)
	I.add(props, "prop_container_20ft_blue", "rusty", A.q(sx, sz, 92.0, 66.5), 90.0)
	for k2 in 2: I.add(props, "prop_k_rail", "worn", A.q(sx, sz, 94.0, 72.0 + k2 * 1.0), 0.0)
	I.add(props, "prop_tank_horizontal_propane", "rusty", A.q(sx, sz, 88.5, 70.0), 0.0)
	SL.lot_light(props, sx, sz, 90.5, 76.0)
	I.add(props, "prop_temp_fence_stand", "worn", A.q(sx, sz, 64.5, 70.0), 30.0)
	for k3 in 4: I.add(props, "prop_cone_28in", "dirty", A.q(sx, sz, 87.0 + k3 * 2.6, 75.5), k3 * 40.0)
	for k4 in 3: I.add(props, "prop_channelizer_drum", "dirty", A.q(sx, sz, 66.5, 92.0 - k4 * 0.9), 0.0)
	for k5 in 8: dec.add(6 + k5 % 2, Vector2(sx * rr.randf_range(87.0, 95.0), sz * rr.randf_range(79.0, 89.0)), rr.randf_range(0, 180), 1.2, 1.0, S.walk_y, Color(1, 1, 1, 0.5))
	paints.append(A.rect(sx, sz, 76.0, 60.0, 84.0, 62.0, "asphalt"))
	G.done(ctx, "grass", true)
	quit()
