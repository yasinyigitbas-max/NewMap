extends SceneTree
## Piece f_nw (waterfront sample, NW): the bayfront block across the drive from the beach. Corner: the surf shop
## (papers, the ice chest beach-goers raid, a bin). A: a Spanish court; the side street gets a beach condo.
## B: the Shores condo tower facing the beach (the sample's tall landmark from the water). C: a white court and an
## apartment pair; a dingbat on the lane with cars under it. Rear rows, courts, lane parking and yard life as in the
## apartment band. Run once; never when locked.
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var ctx := A.block("f_nw", -1.0, -1.0, {"corner": "commercial/com_surf_shop", "corner_label": "surf_shop", "corner_life": "market",
		"a_av": ["apartments/apt_spanish_white"], "a_side": ["apartments/apt_beach_condo"],
		"b_av": ["urban/twr_condo_shores"], "b_ding": "apartments/apt_dingbat_pink",
		"a_rear": ["ck/ck_apt3_row3"], "b_rear": [], "c_rear": ["ck/ck_apt3_row2"],
		"c_side": ["apartments/apt_court_white", "ck/ck_apt3_row2"]})
	# audit fix (17 Nov): the surf shop's papers are slid off its door to just past its corner, onto the lawn. Its paved
	# front now runs 2.2 m past that corner so the papers stand on paving.
	for b: Dictionary in ctx.blds:
		if String((b.node as Node3D).name) != "surf_shop": continue
		var bt := (b.node as Node3D).transform
		var c0: Vector3 = bt * Vector3(-float(b.w) * 0.5 - 2.2, 0.0, float(b.d) * 0.5)
		var c1: Vector3 = bt * Vector3(float(b.w) * 0.5, 0.0, float(b.d) * 0.5 + 2.2)
		ctx.paints.insert(0, [minf(c0.x, c1.x), minf(c0.z, c1.z), maxf(c0.x, c1.x), maxf(c0.z, c1.z), "concrete"])
	# ---- D (inside, off the lanes): beach parking - the beach is what everybody drives here for
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	var stalls: Array = ctx.stalls
	var sx := -1.0; var sz := -1.0
	SL.stalls_u(paints, stalls, sx, sz, 62.0, 12, 61.0, 1.0)
	SL.stalls_u(paints, stalls, sx, sz, 62.0, 13, 79.0, -1.0)
	SL.stalls_u(paints, stalls, sx, sz, 62.0, 13, 80.5, 1.0)
	SL.stalls_u(paints, stalls, sx, sz, 62.0, 13, 98.5, -1.0)
	paints.append(A.rect(sx, sz, 61.0, 60.0, 99.0, 99.0, "asphalt"))
	I.add(props, "prop_pay_station", "worn", A.q(sx, sz, 98.2, 63.0), 90.0 * sx)       # at the way in from the lane
	I.add(props, "prop_sign_no_parking", "worn", A.q(sx, sz, 98.2, 64.6), 90.0 * sx)
	for lu: float in [70.0, 88.0]: SL.lot_light(props, sx, sz, lu, 79.75)
	for bu: float in [62.5, 97.0]: I.add(props, "prop_trash_receptacle", "dirty", A.q(sx, sz, bu, 80.0), 0.0)
	SL.stall_wear(dec, rr, stalls.slice(stalls.size() - 51), 0.75)
	SL.aisle_wear(dec, rr, sx, sz, 61.0, 99.0, 70.0)
	SL.aisle_wear(dec, rr, sx, sz, 61.0, 99.0, 89.5)
	for k in 8: dec.add(4 + k % 2, Vector2(sx * rr.randf_range(62.0, 98.0), sz * rr.randf_range(62.0, 98.0)), rr.randf_range(0, 180), rr.randf_range(1.5, 3.0), rr.randf_range(0.8, 1.6), A.S.walk_y, Color(0.86, 0.79, 0.64, 0.5))   # sand off people's feet
	SL.drains(props, sx, sz, [Vector2(80.0, 70.0), Vector2(80.0, 89.5)])
	A.done(ctx, "f_nw")
	quit()
