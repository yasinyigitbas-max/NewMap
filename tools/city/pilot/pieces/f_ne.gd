extends SceneTree
## Piece f_ne (waterfront sample, NE): the bayfront block across the drive from the marina. Corner: the seaside cafe
## (narrow: a bench, a bin and a bike rack out front - the table set needs more frontage than its 6 m). A: a beach condo facing the bay, a white court on the
## side street. B: the harbour office (dock master, permits) and a second beach condo, their fronts to the water.
## C: Cays-style townhouses with garages and an apartment pair. Rear rows round shared courts, parking off the lanes,
## yard life placed by use (apartment-band method). Run once; never when locked.
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var ctx := A.block("f_ne", 1.0, -1.0, {"corner": "commercial/com_cafe_seaside", "corner_label": "seaside_cafe", "corner_life": "laundry",
		"a_av": ["apartments/apt_beach_condo"], "a_side": ["apartments/apt_court_white"],
		"b_av": ["civic/civ_harbor_office", "apartments/apt_beach_condo"], "b_ding": "",
		"a_rear": ["ck/ck_apt3_row2"], "b_rear": ["ck/ck_apt3_row3"], "c_rear": ["ck/ck_apt3_row2"],
		"c_side": ["apartments/apt_townhouse_cays", "ck/ck_apt3_row2"]})
	# ---- D (inside, off the lanes): the boat storage yard - where the marina's trailer boats live between trips
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	var sx := 1.0; var sz := -1.0
	var P := func(u: float, v: float) -> Vector2: return Vector2(sx * u, sz * v)
	I.lot_fence(props, P.call(61.0, 61.0), P.call(77.0, 61.0), true)
	I.lot_fence(props, P.call(83.0, 61.0), P.call(99.0, 61.0), true)
	I.add(props, "fence_gate_rolling_chainlink", "rusty", A.q(sx, sz, 74.0, 61.4), 0.0)
	I.lot_fence(props, P.call(99.0, 61.0), P.call(99.0, 99.0), true)
	I.lot_fence(props, P.call(99.0, 99.0), P.call(61.0, 99.0), true)
	I.lot_fence(props, P.call(61.0, 99.0), P.call(61.0, 61.0), true)
	paints.append(A.rect(sx, sz, 61.0, 61.0, 99.0, 99.0, "gravel"))
	paints.append(A.rect(sx, sz, 77.0, 60.0, 83.0, 61.0, "asphalt"))
	for row: float in [70.0, 90.0]:
		for k in 7: I.add(props, "prop_boat_trailer", "worn", A.q(sx, sz, 65.0 + k * 4.4, row), 0.0)     # bows to the aisle
	for kr in 2: I.add(props, "prop_kayak_rack", "worn", A.q(sx, sz, 66.0 + kr * 5.0, 97.2), 0.0)
	SL.lot_light(props, sx, sz, 97.5, 80.0)
	I.add(props, "prop_dumpster_3yd_green", "rusty", A.q(sx, sz, 96.5, 63.5), 90.0)
	I.truck_path(dec, rr, P.call(80.0, 60.0), P.call(80.0, 80.0))
	I.yard_wear(dec, rr, sx, sz, 61.0, 61.0, 99.0, 99.0, 0.8)
	A.done(ctx, "f_ne")
	quit()
