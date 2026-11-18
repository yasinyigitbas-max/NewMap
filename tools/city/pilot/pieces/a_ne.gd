extends SceneTree
## Piece a_ne (apartment band sample, NE). Corner: the corner market (papers, propane cage, bins out back). A: a
## 3-storey walk-up and a Spanish Revival court on the avenue, townhouses on the side street. B: a stucco mid-rise and
## a Spanish court, a dingbat facing the alley with cars under it. C: a garden apartment and a brick walk-up on the
## side street. D (inside the alleys): the neighbourhood's pocket playground - iron fence, ONE gate off the alley,
## bark under the play structure, swings, slide, picnic tables under a sail, benches facing the play area (parents
## watch kids, not walls), a fountain, bins, shade trees. Run once; never when locked.
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := 1.0; var sz := -1.0
	var ctx := A.block("a_ne", sx, sz, {"corner": "commercial/com_orange_corner", "corner_label": "corner_market", "corner_life": "market",
		"a_av": ["ck/ck_apt3_row2", "apartments/apt_spanish_revival"], "a_side": ["apartments/apt_townhouse_modern"],
		"b_av": ["apartments/apt_stucco3_peach", "apartments/apt_spanish_white"], "b_ding": "apartments/apt_dingbat_pink",
		"a_rear": ["ck/ck_apt3_row3"], "b_rear": ["ck/ck_apt3_row2"], "c_rear": ["ck/ck_apt3_row3", "ck/ck_apt3_row2"],
		"c_side": ["apartments/apt_garden_cream", "ck/ck_brk3_row2"]})
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	# ---- D: pocket playground
	paints.append(A.rect(sx, sz, 66.0, 66.0, 94.0, 86.0, "mulch"))
	paints.append(A.rect(sx, sz, 60.5, 76.0, 66.0, 78.0, "concrete"))
	paints.append(A.rect(sx, sz, 66.0, 88.0, 86.0, 96.0, "concrete"))
	A.privacy(props, Vector2(sx * 61.0, sz * 61.0), Vector2(sx * 99.0, sz * 61.0), "fence_wrought_iron", "fence_post_wrought_iron")
	A.privacy(props, Vector2(sx * 99.0, sz * 61.0), Vector2(sx * 99.0, sz * 99.0), "fence_wrought_iron", "fence_post_wrought_iron")
	A.privacy(props, Vector2(sx * 99.0, sz * 99.0), Vector2(sx * 61.0, sz * 99.0), "fence_wrought_iron", "fence_post_wrought_iron")
	A.privacy(props, Vector2(sx * 61.0, sz * 99.0), Vector2(sx * 61.0, sz * 78.2), "fence_wrought_iron", "fence_post_wrought_iron")
	A.privacy(props, Vector2(sx * 61.0, sz * 75.8), Vector2(sx * 61.0, sz * 61.0), "fence_wrought_iron", "fence_post_wrought_iron")
	I.add(props, "fence_gate_wrought_iron", "worn", A.q(sx, sz, 61.6, 76.2), 30.0)
	I.add(props, "prop_play_structure", "worn", A.q(sx, sz, 80.0, 76.0), 0.0)
	I.add(props, "prop_swing_set", "worn", A.q(sx, sz, 71.0, 70.0), 90.0)
	I.add(props, "prop_slide", "worn", A.q(sx, sz, 89.5, 70.0), 0.0)
	for k in 2: I.add(props, "prop_picnic_table", "worn", A.q(sx, sz, 71.0 + k * 9.0, 92.0), 0.0)
	for k in 2: I.add(props, "prop_shade_sail", "worn", A.q(sx, sz, 71.0 + k * 9.0, 92.0), 0.0)   # one sail OVER each table (Yasin 17 Nov: one sail between two tables shaded neither)
	for e: Array in [[68.0, 87.2, 0.0], [84.0, 87.2, 0.0], [95.4, 76.0, -90.0]]:
		I.add(props, "prop_park_bench", "worn", A.q(sx, sz, float(e[0]), float(e[1])), (180.0 if sz < 0 else 0.0) + float(e[2]))
	I.add(props, "prop_drinking_fountain", "worn", A.q(sx, sz, 64.0, 80.5), 0.0)
	I.add(props, "prop_trash_receptacle", "worn", A.q(sx, sz, 63.5, 73.6), 0.0)
	I.add(props, "prop_recycling_receptacle", "worn", A.q(sx, sz, 64.5, 73.6), 0.0)
	for t: Array in [["tree_coral_a", 95.0, 95.0], ["tree_ficus_a", 90.0, 95.0], ["tree_jacaranda_a", 95.0, 64.5], ["tree_ficus_b", 64.5, 95.0]]:
		I.add(props, String(t[0]), "normal", A.q(sx, sz, float(t[1]), float(t[2])), float(t[1]) * 11.0)
	for lp: Vector2 in [Vector2(66.0, 66.0), Vector2(93.0, 87.0)]: I.add(props, "prop_lamp_globe", "worn", A.q(sx, sz, lp.x, lp.y), 0.0)
	# worn paths where kids run between the gate and the slide; scuffed bark under the swings
	dec.add(14, Vector2(sx * 68.0, sz * 77.0), 90.0, 2.0, 5.0, A.S.walk_y, Color(1, 1, 1, 0.5))
	dec.add(14, Vector2(sx * 71.0, sz * 70.0), 0.0, 3.0, 2.0, A.S.walk_y, Color(1, 1, 1, 0.6))
	A.done(ctx, "a_ne")
	quit()
