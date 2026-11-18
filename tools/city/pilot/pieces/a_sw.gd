extends SceneTree
## Piece a_sw (apartment band sample, SW). Corner: the brick corner block with a cafe downstairs (tables out front).
## A: a stucco mid-rise and a walk-up on the avenue, a Spanish court on the side street. B: a garden apartment and a
## walk-up, a dingbat facing the alley. C: a white court and a townhouse row. D: a row of tenants' garages facing the
## alley, a shared lawn with the grill and a picnic table behind them, and the dog run the whole block uses - chain-
## link with one gate, a bench, the bag-and-bin post (bin), worn grass paths along the fence. Run once; never when locked.
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := -1.0; var sz := 1.0
	var ctx := A.block("a_sw", sx, sz, {"corner": "ck/ck_brk3_corner2", "corner_label": "corner_cafe", "corner_life": "cafe",
		"a_av": ["apartments/apt_stucco3_peach", "ck/ck_apt3_row2"], "a_side": ["apartments/apt_spanish_revival"],
		"b_av": ["apartments/apt_garden_cream", "ck/ck_apt3_row2"], "b_ding": "apartments/apt_dingbat_pink",
		"a_rear": ["ck/ck_apt3_row3"], "b_rear": ["ck/ck_apt3_row3"], "c_rear": ["ck/ck_apt3_row2", "ck/ck_apt3_row3"],
		"c_side": ["apartments/apt_court_white", "apartments/apt_townhouse_modern"]})
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	var bl: Node3D = ctx.bl
	# ---- D: garages facing the u-alley
	for k in 3:
		A.place(bl, sx, sz, ["garages/double_stucco_comp", "garages/double_siding_comp", "garages/double_stucco_clay"][k], 64.0 + k * 6.3, A.AL1 + 0.4 + 3.0, "-v", "garage_%d" % k)
	paints.append(A.rect(sx, sz, 60.5, 60.0, 81.0, 60.4, "concrete"))
	# shared lawn behind the garages
	I.add(props, "prop_picnic_table", "worn", A.q(sx, sz, 66.0, 74.0), 0.0)
	I.add(props, "prop_bbq_kettle", "worn", A.q(sx, sz, 71.0, 72.0), 0.0)
	I.add(props, "prop_patio_set_4", "worn", A.q(sx, sz, 74.0, 79.0), 20.0)
	for k in 2: I.add(props, "prop_adirondack_wood", "worn", A.q(sx, sz, 64.0 + k * 1.6, 82.0), 180.0)
	I.add(props, "tree_magnolia_b", "normal", A.q(sx, sz, 78.0, 70.0), 15.0)
	I.add(props, "tree_ficus_a", "normal", A.q(sx, sz, 64.5, 95.0), 75.0)
	# ---- D: dog run (u 82-99, v 62-99)
	for seg: Array in [[82.0, 62.0, 99.0, 62.0], [99.0, 62.0, 99.0, 99.0], [99.0, 99.0, 82.0, 99.0], [82.0, 99.0, 82.0, 82.2], [82.0, 79.8, 82.0, 62.0]]:
		A.privacy(props, Vector2(sx * float(seg[0]), sz * float(seg[1])), Vector2(sx * float(seg[2]), sz * float(seg[3])), "fence_chainlink", "fence_chainlink_post")
	# (Yasin 17 Nov: the lone concrete pad at the dog-run gate, in the middle of the lawn, removed)
	I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 86.0, 92.0), 90.0)
	I.add(props, "prop_trash_receptacle", "dirty", A.q(sx, sz, 84.0, 83.2), 0.0)
	I.add(props, "prop_drinking_fountain", "worn", A.q(sx, sz, 84.0, 77.5), 0.0)
	I.add(props, "tree_coral_a", "normal", A.q(sx, sz, 94.0, 70.0), 120.0)
	I.add(props, "tree_jacaranda_b", "normal", A.q(sx, sz, 94.0, 92.0), 200.0)
	var k2 := 63.5
	while k2 < 98.0:   # dogs wear a path along the fence, the grass dies by the gate
		dec.add(14, Vector2(sx * 83.2, sz * k2), 0.0, 1.0, 3.0, A.S.walk_y, Color(1, 1, 1, 0.55)); k2 += rr.randf_range(3.0, 4.0)
	dec.add(14, Vector2(sx * 86.0, sz * 81.0), 90.0, 4.0, 3.0, A.S.walk_y, Color(1, 1, 1, 0.6))
	# audit fix (17 Nov, empty spaces): the shared lawn behind the garages is where the block hangs out - a raised
	# vegetable bed row along the garages' backs, a clothesline, a swing for the little ones, a lamp, a bench under the
	# magnolia; the dog run gets the owners' bench row, a bag bin at the gate and worn patches where dogs play
	for k in 3:
		var bu := 62.5 + k * 5.5
		paints.insert(0, A.rect(sx, sz, bu, 68.0, bu + 4.0, 70.2, "mulch"))
		for j in 2: I.add(props, ["plant_agave_americana_small", "plant_bird_of_paradise", "plant_potted_leafy"][(k + j) % 3], "normal", A.q(sx, sz, bu + 1.0 + j * 2.0, 69.1), (k + j) * 50.0)
	I.add(props, "prop_clothesline", "worn", A.q(sx, sz, 70.0, 88.0), 0.0)
	I.add(props, "prop_swing_set", "worn", A.q(sx, sz, 66.0, 90.5), 90.0)
	I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 78.0, 73.5), 0.0 if sz < 0 else 180.0)
	I.add(props, "prop_lamp_globe", "worn", A.q(sx, sz, 80.5, 86.0), 0.0)
	I.add(props, "prop_trash_cart_green", "dirty", A.q(sx, sz, 61.0, 71.5), 90.0)     # the garden's compost cart
	dec.add(14, Vector2(sx * 66.0, sz * 90.5), 0.0, 4.0, 3.0, A.S.walk_y, Color(1, 1, 1, 0.55))      # bare under the swings
	for k3 in 2: I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 97.6, 70.0 + k3 * 20.0), -90.0 * sx)
	I.add(props, "prop_trash_receptacle", "dirty", A.q(sx, sz, 97.6, 80.0), 0.0)
	for k4 in 6: dec.add(14, Vector2(sx * rr.randf_range(86.0, 97.0), sz * rr.randf_range(64.0, 97.0)), rr.randf_range(0, 180), rr.randf_range(1.5, 3.0), rr.randf_range(1.5, 3.0), A.S.walk_y, Color(1, 1, 1, 0.5))
	A.done(ctx, "a_sw")
	quit()
