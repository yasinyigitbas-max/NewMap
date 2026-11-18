extends SceneTree
## Piece a_nw (apartment band sample, NW). Corner: the laundromat + pharmacy (people wait outside on the bench). A: a
## white court and a walk-up on the avenue, a 3-storey walk-up on the side street. B: the beach condo and a townhouse
## row. C: a stucco mid-rise and a Spanish court. D: two dingbats facing the alley with the tenants' cars under them,
## and behind them the residents' community garden: bark beds planted with succulents and bird-of-paradise, an arbor,
## chairs, a picnic table, a hose cart, a fence with one gate. Run once; never when locked.
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := -1.0; var sz := -1.0
	var ctx := A.block("a_nw", sx, sz, {"corner": "modular/examples/mod_svc_row", "corner_label": "laundromat", "corner_life": "laundry",
		"a_av": ["apartments/apt_court_white", "ck/ck_apt3_row2"], "a_side": ["ck/ck_apt3_row3"],
		"b_av": ["apartments/apt_beach_condo", "apartments/apt_townhouse_cays"], "b_ding": "",
		"a_rear": ["ck/ck_apt3_row3"], "b_rear": ["ck/ck_apt3_row3", "ck/ck_apt3_row2"], "c_rear": ["ck/ck_apt3_row2", "ck/ck_apt3_row3"],
		"c_side": ["apartments/apt_stucco3_cream", "apartments/apt_spanish_revival"]})
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var stalls: Array = ctx.stalls
	var bl: Node3D = ctx.bl
	# ---- D: alley dingbats over carports
	for du: float in [69.0, 87.0]:
		var db := A.place(bl, sx, sz, "apartments/apt_dingbat_teal" if du < 80.0 else "apartments/apt_dingbat_pink", du, A.AL1 + 0.4 + 8.0, "-v", "dingbat_%d" % int(du))
		ctx.blds.append(db)
		A.CC.back_of_house(props, db.node, String(db.folder), true)
		I.add(props, "prop_dingbat_stair", "worn", A.at(db, -6.0 - 0.6, 0.0), rad_to_deg((db.node as Node3D).rotation.y) - 90.0, false)   # kit batch 2
		SL.stalls_u(paints, stalls, sx, sz, du - 5.4, 4, A.AL1 + 0.4, 1.0)
		I.add(props, "prop_trash_cart_black", "worn", A.q(sx, sz, du + 6.8, A.AL1 + 1.2), 0.0)
		I.add(props, "prop_trash_cart_green", "worn", A.q(sx, sz, du + 6.8, A.AL1 + 2.25), 0.0)
	paints.append(A.rect(sx, sz, 62.0, 60.0, 94.0, 66.0, "asphalt"))
	# ---- D: community garden behind
	A.privacy(props, Vector2(sx * 61.0, sz * 78.5), Vector2(sx * 78.8, sz * 78.5))
	A.privacy(props, Vector2(sx * 81.2, sz * 78.5), Vector2(sx * 99.0, sz * 78.5))
	for bed in 4:
		var u0 := 64.0 + bed * 8.5
		paints.append(A.rect(sx, sz, u0, 82.0, u0 + 5.5, 96.0, "mulch"))
		for k in 3:
			I.add(props, ["plant_agave_americana_small", "plant_bird_of_paradise", "plant_bougainvillea_mound"][(bed + k) % 3], "normal", A.q(sx, sz, u0 + 2.75, 84.5 + k * 4.5), (bed * 3 + k) * 47.0)
	paints.append(A.rect(sx, sz, 78.8, 78.5, 81.2, 97.0, "concrete"))
	I.add(props, "prop_garden_arbor", "worn", A.q(sx, sz, 80.0, 79.8), 0.0)
	I.add(props, "prop_picnic_table", "worn", A.q(sx, sz, 92.0, 97.6), 0.0)
	for k in 2: I.add(props, "prop_adirondack_white", "worn", A.q(sx, sz, 63.0 + k * 1.5, 97.8), 180.0 + k * 20.0)
	I.add(props, "prop_hose_reel_cart", "worn", A.q(sx, sz, 82.0, 81.0), 30.0)
	I.add(props, "prop_sprinkler_impact", "worn", A.q(sx, sz, 72.5, 89.0), 0.0, false)
	I.add(props, "tree_coral_b", "normal", A.q(sx, sz, 97.0, 82.0), 40.0)
	A.done(ctx, "a_nw")
	quit()
