extends SceneTree
## Piece g_nw (gritty edge sample, NW: the side that faces the industrial sample - the roughest corner).
## A (corner): an old one-storey shop row on the avenue - a pawn shop, an abandoned false-front between, a laundromat
##   (people wait on the bench, the soda machine by the door, a cart for the washing) - and a dead pair (boarded shop,
##   abandoned front) on the side street. Behind them the shared service yard: their dumpsters at the back doors, a
##   tagged bin enclosure, a small customer lot entered from the lane.
## B (avenue): an auto body shop with its work apron, and its fenced car pound beside it (barbed chain-link, a rolling
##   gate to the avenue, cars waiting for parts in two rows, a lot light).
## C (side street): a small warehouse (rented by the body shop for parts) behind a truck apron, and next to it a
##   narrow vacant lot behind chain-link - gravel, self-seeded agaves, a dumped cart - with the billboard over it
##   facing the side street (the only rent the lot earns).
## D (inside, off both lanes): the scrap / salvage yard - containers, the roll-off, drums, k-rails, a row of wrecks.
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/grt_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const C := preload("res://tools/city/pilot/pieces/civ_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := -1.0; var sz := -1.0
	var ctx := G.begin("g_nw", sx, sz)
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	# ---- A: shop rows + service yard
	G.shop(ctx, "ck/ck_grt_row3", 22.0, "-v", "pawn_laundry_row", ["pawn", "dead", "laundry"])
	G.shop(ctx, "ck/ck_grt_row2", 35.0, "-u", "boarded_pair", ["dead", "dead"])
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, true, 28.0, 53.0, A.AL0, -1.0)    # customers nose in off the lane
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, false, 30.0, 46.0, A.AL0, -1.0)
	paints.append(A.rect(sx, sz, A.PROP, A.PROP, 54.0, 54.0, "asphalt"))      # the service yard (forecourts are painted first)
	var fv := A.face_dir(sx, sz, "+v")
	G.bins(ctx, 36.0, 28.6, rad_to_deg(atan2(fv.x, fv.y)))
	I.yard_wear(dec, rr, sx, sz, 12.0, 24.0, 54.0, 54.0, 1.3)
	SL.lot_light(props, sx, sz, 30.0, 40.0)
	# ---- B: body shop + car pound
	var rep := A.place(ctx.bl, sx, sz, "industrial/ind_repair", 71.0, 28.0, "-v", "body_shop", G.WEAR)
	ctx.blds.append(rep)
	G.CC.back_of_house(props, rep.node, "industrial/ind_repair", false)
	I.bld_wear(dec, rr, rep.node, rep.w, rep.d, "industrial/ind_repair")
	paints.append(A.rect(sx, sz, 60.0, A.PROP, 100.0, 54.0, "asphalt"))
	for k in 2: I.add(props, "prop_cone_28in", "dirty", A.q(sx, sz, 62.0 + k * 0.9, 18.0), k * 40.0)
	I.back_door_clutter(props, rr, A.at(rep, 4.0, -rep.d * 0.5 - 5.0), rad_to_deg((rep.node as Node3D).rotation.y) + 180.0, "yard")
	for e: float in [0.6, 6.0]:     # trucks and cars nosing into the bays
		var dp: Vector3 = A.at(rep, e, rep.d * 0.5 + 0.2)
		I.truck_path(dec, rr, Vector2(dp.x, sz * A.PROP), Vector2(dp.x, dp.z))
	# the pound: barbed chain-link, rolling gate on the avenue side
	I.lot_fence(props, Vector2(sx * 82.0, sz * 12.0), Vector2(sx * 87.0, sz * 12.0), true)
	I.lot_fence(props, Vector2(sx * 93.0, sz * 12.0), Vector2(sx * 99.0, sz * 12.0), true)
	I.add(props, "fence_gate_rolling_chainlink", "rusty", A.q(sx, sz, 84.0, 12.4), 0.0)
	I.lot_fence(props, Vector2(sx * 99.0, sz * 12.0), Vector2(sx * 99.0, sz * 52.0), true)
	I.lot_fence(props, Vector2(sx * 99.0, sz * 52.0), Vector2(sx * 82.0, sz * 52.0), true)
	I.lot_fence(props, Vector2(sx * 82.0, sz * 52.0), Vector2(sx * 82.0, sz * 12.0), true)
	SL.stalls_v(paints, ctx.stalls, sx, sz, 16.0, 12, 83.0, 1.0)
	SL.stalls_v(paints, ctx.stalls, sx, sz, 16.0, 12, 98.0, -1.0)
	SL.lot_light(props, sx, sz, 90.5, 50.5)
	I.yard_wear(dec, rr, sx, sz, 82.0, 12.0, 99.0, 52.0, 1.5)
	# ---- C: parts warehouse + narrow vacant lot with the billboard
	var wh := A.place(ctx.bl, sx, sz, "modular/examples/mod_wh_shed", 26.0, 74.0, "-u", "parts_warehouse", G.WEAR)
	ctx.blds.append(wh)
	G.CC.back_of_house(props, wh.node, "modular/examples/mod_wh_shed", false)
	I.bld_wear(dec, rr, wh.node, wh.w, wh.d, "modular/examples/mod_wh_shed")
	G.lot(ctx, "vacant", 12.0, 88.5, 52.0, 98.0, "u1", "-u")
	paints.append(A.rect(sx, sz, A.PROP, 60.0, 54.0, 87.5, "asphalt"))        # truck apron in front, yard behind
	I.truck_path(dec, rr, Vector2(sx * A.PROP, sz * 70.0), Vector2(sx * 13.5, sz * 70.0))
	I.yard_wear(dec, rr, sx, sz, A.PROP, 60.0, 54.0, 87.5, 1.2)
	I.back_door_clutter(props, rr, A.at(wh, 6.0, -wh.d * 0.5 - 4.0), rad_to_deg((wh.node as Node3D).rotation.y) + 180.0, "yard")
	# ---- D: scrap yard off the lane
	G.lot(ctx, "scrap", 62.0, 62.0, 98.0, 98.0, "v0")
	paints.append(A.rect(sx, sz, 76.0, 60.0, 84.0, 62.0, "asphalt"))          # gate apron
	G.done(ctx, "gravel", false)
	quit()
