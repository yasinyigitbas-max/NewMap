extends SceneTree
## Piece v_se (civic + parks band, SE): PUBLIC SAFETY. A (corner): the police station with its forecourt, the patrol
## cars' lot behind (fenced, gate to the lane). B (avenue): the post office - forecourt, the blue collection boxes,
## benches - and the mail trucks' yard behind off the lane (rolloff for cardboard, cones). C (side street): Fire
## Station 2, its engine bays opening onto the lane by the street apron, the concrete apron with the hose-test drain,
## the crew's grill and chairs out back. D (inside): the dog run (kit park, chain-link with posts, one gate on the
## lane), worn grass along the fence where the dogs run. Run once; never when locked.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const C := preload("res://tools/city/pilot/pieces/civ_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := 1.0; var sz := 1.0
	var ctx := C.begin("v_se", sx, sz)
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	# ---- A: police
	C.bld(ctx, "civic/civ_police", 31.6, 22.2, "-v", "police", A.PROP, 6.0)
	SL.bollards(props, sx, sz, [Vector2(27.0, 9.8), Vector2(31.6, 9.8), Vector2(36.2, 9.8)])
	I.add(props, "prop_bench_bus_stop", "worn", A.q(sx, sz, 43.0, 13.0), 180.0 if sz > 0 else 0.0)
	C.lot(ctx, 11.0, 33.0, 52.0, 53.5)
	paints.append(A.rect(sx, sz, 45.0, 52.0, 51.0, 54.0, "asphalt"))
	A.privacy(props, Vector2(sx * 10.5, sz * 32.0), Vector2(sx * 53.5, sz * 32.0), "fence_chainlink_lot", "fence_chainlink_lot_post")
	# ---- B: post office
	C.bld(ctx, "civic/civ_post_office", 80.0, 22.7, "-v", "post_office", A.PROP, 7.0)
	for k in 3: I.add(props, "prop_usps_collection_box", "worn", A.q(sx, sz, 66.0 + k * 0.8, 11.0), 180.0 if sz > 0 else 0.0)
	for k in 2: I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 88.0 + k * 5.0, 11.0), 180.0 if sz > 0 else 0.0)
	I.add(props, "prop_newspaper_box_red", "worn", A.q(sx, sz, 70.0, 11.0), 180.0 if sz > 0 else 0.0)
	_pad(ctx, 64.8, A.PROP, 71.4, 12.4)        # audit fix: the drive-up boxes and the papers stand on paving at the kerb
	SL.stalls_u(paints, ctx.stalls, sx, sz, 64.0, 10, 37.0, 1.0)            # the mail vans, nose to the back fence
	paints.append(A.rect(sx, sz, 62.0, 34.0, 98.0, 53.5, "asphalt"))        # mail trucks' yard
	for k in 4: W.oil(dec, rr, Vector2(sx * (66.0 + k * 8.0), sz * 44.0), 0.0, S.walk_y, 0.9)
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", A.q(sx, sz, 95.0, 40.0), 0.0)
	for k in 4: I.add(props, "prop_cone_28in", "dirty", A.q(sx, sz, 64.0 + k * 1.2, 51.5), k * 33.0)
	I.add(props, "prop_utility_pole_transformer", "worn", A.q(sx, sz, 98.0, 52.0), 90.0)
	I.yard_wear(dec, rr, sx, sz, 62.0, 34.0, 98.0, 53.5, 1.4)
	# ---- C: fire station, bays to the lane
	C.bld(ctx, "civic/civ_fire_station", 30.0, 71.0, "-v", "fire_station_2", 60.0, 10.0)   # forecourt: no yard tree on the apron
	paints.insert(0, A.rect(sx, sz, 19.0, 60.0, 41.0, 63.0, "concrete"))
	props.add("prop_storm_drain_grate", "dirty", A.q(sx, sz, 30.0, 60.4, 0.002), 0.0, false)
	for k in 6: dec.add(8, Vector2(sx * (22.0 + k * 3.5), sz * 58.0), 0.0, 0.7, 5.0, S.walk_y, Color(1, 1, 1, 0.55))
	I.add(props, "prop_bbq_gas_cart", "worn", A.q(sx, sz, 22.0, 84.0), 0.0)
	I.add(props, "prop_patio_set_4", "worn", A.q(sx, sz, 27.0, 85.0), 15.0)
	for k in 3: I.add(props, "prop_adirondack_wood", "worn", A.q(sx, sz, 34.0 + k * 1.6, 85.5), 180.0 + k * 10.0)
	I.add(props, "prop_water_barrier_orange", "dirty", A.q(sx, sz, 46.0, 66.0), 90.0)
	for k in 3: I.add(props, "prop_channelizer_drum", "dirty", A.q(sx, sz, 48.0, 64.0 + k * 0.9), 0.0)
	# ---- D: dog run
	C.park(ctx, "park_dog_run", 80.0, 80.0, "+u")
	for k in 2: I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 62.0, 68.0 + k * 22.0), 90.0 if sx > 0 else -90.0)
	# audit fix (17 Nov, empty spaces; benches just outside the fence on the lane side): owners stand along the fence and talk - more benches facing the run, a bag post
	# (bin) at the gate and at each bench pair, shade trees outside the corners, a lamp for the evening walk, the
	# grass worn bare along the fence line where the dogs run and at the gate
	for k3 in 3: I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 70.0 + k3 * 10.0, 61.1), 0.0 if sz > 0 else 180.0)
	for bp: Vector2 in [Vector2(62.0, 74.0), Vector2(62.0, 86.0), Vector2(75.0, 61.1)]: I.add(props, "prop_trash_receptacle", "dirty", A.q(sx, sz, bp.x, bp.y), 0.0)
	for tp: Vector2 in [Vector2(61.5, 62.5), Vector2(98.5, 62.5), Vector2(61.5, 97.5), Vector2(98.5, 97.5)]: I.add(props, "tree_ficus_b" if tp.x > 80.0 else "tree_magnolia_a", "normal", A.q(sx, sz, tp.x, tp.y), tp.y * 5.0)
	I.add(props, "prop_lamp_globe", "worn", A.q(sx, sz, 61.0, 80.0), 0.0)
	for k4 in 16:
		var t := float(k4) / 16.0 * 4.0
		var side := int(t); var f := t - side
		var pu: float = [63.5 + f * 33.0, 96.5, 96.5 - f * 33.0, 63.5][side]
		var pv: float = [66.5, 66.5 + f * 27.0, 93.5, 93.5 - f * 27.0][side]
		dec.add(14, Vector2(sx * pu, sz * pv), (90.0 if side % 2 == 1 else 0.0), 1.4, 4.0, S.walk_y, Color(1, 1, 1, 0.45))
	C.done(ctx)
	quit()

## audit fix (17 Nov): a paved pad (mail boxes, papers stood on the lawn)
func _pad(ctx: Dictionary, u0: float, v0: float, u1: float, v1: float) -> void:
	(ctx.paints as Array).insert(0, A.rect(float(ctx.sx), float(ctx.sz), u0, v0, u1, v1, "plaza"))
