extends SceneTree
## Piece a_se (apartment band sample, SE). Corner: the neighbourhood bar (smokers' corner outside, the dumpster out
## back). A: a townhouse row and a walk-up on the avenue, a white court on the side street. B: a walk-up and a stucco
## mid-rise, a dingbat facing the alley. C: a townhouse row and a brick walk-up. D: a garden court - two garden
## apartment wings face each other across a lawn with a paved walk, queen palms, benches, the shared grill and
## picnic table, entered from the alley; the tenants' garages face the other alley. Run once; never when locked.
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := 1.0; var sz := 1.0
	var ctx := A.block("a_se", sx, sz, {"corner": "commercial/com_bar_crown", "corner_label": "corner_bar", "corner_life": "bar",
		"a_av": ["apartments/apt_townhouse_cays", "ck/ck_apt3_row2"], "a_side": ["apartments/apt_court_white"],
		"b_av": ["ck/ck_apt3_row3", "apartments/apt_stucco3_cream"], "b_ding": "apartments/apt_dingbat_teal",
		"a_rear": ["ck/ck_apt3_row3"], "b_rear": ["ck/ck_apt3_row2"], "c_rear": ["ck/ck_apt3_row3", "ck/ck_apt3_row2"],
		"c_side": ["apartments/apt_townhouse_modern", "ck/ck_brk3_row2"]})
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	var bl: Node3D = ctx.bl
	# ---- D: garden court
	var w1 := A.place(bl, sx, sz, "apartments/apt_garden_cream", 75.0, A.AL1 + 1.0 + 4.5, "+v", "court_south_wing")
	var w2 := A.place(bl, sx, sz, "apartments/apt_garden_mint", 75.0, 98.6 - 4.5, "-v", "court_north_wing")
	for wb: Dictionary in [w1, w2]:
		A.dress(wb, paints, props, dec, rr, sx, sz, 80.0, false, false)
		ctx.blds.append(wb)
	paints.append(A.rect(sx, sz, 60.5, 79.0, 90.0, 81.0, "concrete"))
	for p: Vector2 in [Vector2(63.0, 74.0), Vector2(88.0, 74.0), Vector2(63.0, 86.0), Vector2(88.0, 86.0)]:   # court corners, clear of the door walks
		I.add(props, "palm_queen_a" if int(p.x) % 2 == 0 else "palm_queen_b", "normal", A.q(sx, sz, p.x, p.y), p.x * 13.0)
	for e: Array in [[71.0, 77.8, 180.0], [79.0, 82.2, 0.0]]:
		I.add(props, "prop_park_bench", "worn", A.q(sx, sz, float(e[0]), float(e[1])), float(e[2]) if sz > 0 else float(e[2]) + 180.0)
	I.add(props, "prop_bbq_gas_cart", "worn", A.q(sx, sz, 87.0, 76.0), -90.0)
	I.add(props, "prop_picnic_table", "worn", A.q(sx, sz, 83.0, 85.0), 0.0)
	I.add(props, "prop_trash_receptacle", "worn", A.q(sx, sz, 62.0, 77.6), 0.0)
	for k in 3: I.add(props, "plant_bougainvillea_mound", "normal", A.q(sx, sz, 64.0 + k * 11.0, 80.0 + (1.6 if k % 2 == 0 else -1.6)), k * 70.0)
	# the court's east end: a magnolia and a bench in its shade
	I.add(props, "tree_magnolia_a", "normal", A.q(sx, sz, 94.0, 80.0), 33.0)
	I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 91.0, 80.0), -90.0)
	A.done(ctx, "a_se")
	quit()
