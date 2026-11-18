extends SceneTree
## Piece m_sw (commercial strip sample, SW): the Sea Breeze motor court and the strip's parking garage.
## - The motel: the two-storey wing at the back faces the arterial, the second wing runs down the west side; rooms
##   look onto a court where guests park nose-in at their own doors, around a palm garden with tables, a grill, a
##   sail and chairs behind a wrought-iron fence. The motel's roadside sign stands over the arterial frontage.
## - Side street: a donut shop and a check-cashing office on the sidewalk, a small shared lot behind them, then the
##   parking garage (its ramp on the side-street driveway) that the whole strip and the bus riders use.
## - Behind the motel: a fenced gravel storage yard (portable storage containers, k-rails).
## Run once; never when locked.
const L := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const CC := preload("res://tools/city/pilot/pieces/cc_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := -1.0; var sz := 1.0
	var root := Node3D.new(); root.name = "m_sw"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("m_sw")
	var paints: Array = []; var stalls: Array = []
	var B: Array = []
	# ---------------------------------------------------------------- the motel
	var crown := I.put(bl, props, sx, sz, "x", 50.0, 62.0, "extras/ext_motel_crown", "sea_breeze_motel")
	B.append([crown, "extras/ext_motel_crown"])
	var inn := K.building(bl, "extras/motel_inn_court", L.q(sx, sz, 45.0, 48.0), -90.0, "sea_breeze_west_wing", 0.85)   # faces +u (the court)
	CC.back_of_house(props, inn, "extras/motel_inn_court")
	B.append([[inn, 36.0, 10.0], "extras/motel_inn_court"])
	L.stalls_u(paints, stalls, sx, sz, 59.5, 12, 52.4, 1.0)      # nose-in at the room doors
	L.stalls_v(paints, stalls, sx, sz, 31.0, 8, 58.6, -1.0)
	# the garden (u 66-92, v 30-44)
	paints.append(L.rect(sx, sz, 66.0, 30.0, 92.0, 44.0, "grass"))
	paints.append(L.rect(sx, sz, 74.0, 34.0, 84.0, 40.0, "paving"))
	# fence: 1.98 m wrought-iron panels with a post at every joint, one gate (west side, toward the rooms), a low
	# boxwood hedge just inside, closed except at the gate (Yasin: an enclosure has ONE apparent entrance)
	var runs := [[66.2, 30.2, 92.0, 30.2], [92.0, 30.2, 92.0, 44.0], [92.0, 44.0, 66.2, 44.0], [66.2, 44.0, 66.2, 37.6], [66.2, 36.4, 66.2, 30.2]]
	for f: Array in runs:
		_iron_run(props, Vector2(sx * float(f[0]), sz * float(f[1])), Vector2(sx * float(f[2]), sz * float(f[3])))
	I.add(props, "fence_gate_wrought_iron", "worn", L.q(sx, sz, 66.75, 36.4 + 0.5), 60.0)   # leaf swung open inward
	for hr: Array in [[67.4, 31.4, 90.8, 31.4], [90.8, 32.5, 90.8, 41.7], [90.8, 42.8, 67.4, 42.8], [67.4, 41.7, 67.4, 39.0], [67.4, 35.0, 67.4, 32.5]]:
		_hedge_run(props, Vector2(sx * float(hr[0]), sz * float(hr[1])), Vector2(sx * float(hr[2]), sz * float(hr[3])))
	paints.append(L.rect(sx, sz, 66.2, 35.6, 74.0, 38.4, "paving"))           # path from the gate to the patio
	for p: Vector2 in [Vector2(70.0, 34.0), Vector2(88.5, 34.0), Vector2(70.0, 40.5), Vector2(88.5, 40.5)]:
		I.add(props, "palm_canary_date_a" if int(p.x + p.y) % 2 == 0 else "palm_canary_date_b", "normal", L.q(sx, sz, p.x, p.y), p.x * 31.0)
	# the patio: two sails over the tables, a grill, a fountain, lounge chairs on the lawn facing the sun, planters
	I.add(props, "prop_shade_sail", "worn", L.q(sx, sz, 77.0, 37.0), 0.0)
	I.add(props, "prop_shade_sail", "worn", L.q(sx, sz, 82.5, 37.0), 0.0)
	for k in 2: I.add(props, "prop_picnic_table", "worn", L.q(sx, sz, 76.5 + k * 5.5, 37.0), 90.0)
	I.add(props, "prop_bbq_gas_cart", "worn", L.q(sx, sz, 85.6, 35.0), -90.0)
	I.add(props, "prop_bbq_kettle", "worn", L.q(sx, sz, 85.6, 39.2), 0.0)
	I.add(props, "prop_drinking_fountain", "worn", L.q(sx, sz, 74.6, 39.3), 0.0)
	for k in 4: I.add(props, "prop_adirondack_white" if k % 2 == 0 else "prop_adirondack_wood", "worn", L.q(sx, sz, 72.0 + k * 1.6, 33.0), 180.0 + (k - 2) * 8.0)
	for k in 3: I.add(props, "prop_adirondack_wood", "worn", L.q(sx, sz, 79.0 + k * 1.6, 41.4), (k - 1) * 10.0)
	I.add(props, "prop_trash_receptacle", "worn", L.q(sx, sz, 73.4, 35.0), 0.0)
	I.add(props, "prop_recycling_receptacle", "worn", L.q(sx, sz, 73.4, 36.0), 0.0)
	for p4: Vector2 in [Vector2(80.0, 32.6), Vector2(86.0, 41.6), Vector2(76.0, 41.6)]:
		I.add(props, "plant_bird_of_paradise", "normal", L.q(sx, sz, p4.x, p4.y), p4.y * 17.0)
	for k in 2: I.add(props, "prop_lamp_globe", "worn", L.q(sx, sz, 71.0 + k * 16.0, 37.0), 0.0)
	# the motel's maintenance cart by the office, towels / ice / vending are missing kit props
	I.add(props, "prop_golf_cart_white", "worn", L.q(sx, sz, 53.6, 57.4), 0.0)
	# kit batch 2 (17 Nov): the motel's soda and snack machines and the ice chest against the west wing, by the rooms
	# against the wing's end wall, clear of the room doors AND of the outdoor stair's foot (Yasin 17 Nov: "something is
	# blocking the stairs"): the machines sit at the far end of the wall, 2.5 m clear of the bottom step
	I.add(props, "prop_ice_chest", "worn", L.q(sx, sz, 40.0, 29.2), 180.0)
	I.add(props, "prop_vending_soda", "worn", L.q(sx, sz, 41.5, 29.2), 180.0)
	I.add(props, "prop_vending_snack", "worn", L.q(sx, sz, 42.8, 29.2), 180.0)
	# roadside: the motel sign (billboard frame) over the frontage, a low brick wall with palms, the drive-in gap
	I.add(props, "prop_billboard", "worn", L.q(sx, sz, 66.0, 15.8), 180.0)
	var x := 51.0
	while x < 99.0:
		if absf(x - 80.0) > 6.0: I.add(props, "fence_brick_wall", "worn", L.q(sx, sz, x, 17.6), 0.0)
		x += 2.0
	for seg: Array in [[12.5, 40.0], [50.0, 75.0], [85.0, 99.5]]:
		L.island(paints, props, rr, sx, sz, float(seg[0]), 14.6, float(seg[1]), 17.0, maxi(1, int((float(seg[1]) - float(seg[0])) / 9.0)))
	for p2: Vector2 in [Vector2(57.0, 16.0), Vector2(97.0, 47.0), Vector2(55.5, 55.5)]:
		L.lot_light(props, sx, sz, p2.x, p2.y)
	# guests' life at the doors: ice / vending are missing props; a chair and a pot by a few doors at the wing ends
	I.add(props, "prop_adirondack_wood", "worn", L.q(sx, sz, 91.2, 59.4), 180.0)
	I.add(props, "plant_potted_leafy", "normal", L.q(sx, sz, 51.0, 59.6), 0.0)
	# ---------------------------------------------------------------- side street: donuts, check cashing, small lot
	B.append([I.put(bl, props, sx, sz, "z", 20.0, I.FRONT, "commercial/com_bakery", "donut_shop"), "commercial/com_bakery"])
	B.append([I.put(bl, props, sx, sz, "z", 31.0, I.FRONT, "commercial/com_realty", "check_cashing"), "commercial/com_realty"])
	I.walk_prop(props, sx, sz, "z", 29.8, "prop_newspaper_box_red", "dirty")
	I.walk_prop(props, sx, sz, "z", 38.5, "prop_trash_receptacle", "dirty")
	L.stalls_u(paints, stalls, sx, sz, 24.5, 5, 41.5, -1.0)
	L.stalls_u(paints, stalls, sx, sz, 12.0, 9, 48.5, 1.0)
	L.enclosure(props, L.q(sx, sz, 31.0, 58.0), 180.0)
	I.add(props, "prop_utility_pole_transformer", "worn", L.q(sx, sz, 14.0, 58.5), 0.0)
	# ---------------------------------------------------------------- the parking garage
	var gar := I.put(bl, props, sx, sz, "z", 63.0, I.FRONT, "extras/ext_parking_garage", "strip_garage", false)
	B.append([gar, "extras/ext_parking_garage"])
	I.walk_prop(props, sx, sz, "z", 61.5, "prop_pay_station")
	# ---------------------------------------------------------------- storage yard behind the motel
	paints.append(L.rect(sx, sz, 42.0, 73.5, 99.8, 99.8, "gravel"))
	I.lot_fence(props, Vector2(-42.0, 73.5), Vector2(-99.8, 73.5)); I.lot_fence(props, Vector2(-99.8, 73.5), Vector2(-99.8, 99.8))
	I.lot_fence(props, Vector2(-42.0, 99.8), Vector2(-99.8, 99.8)); I.lot_fence(props, Vector2(-42.0, 73.5), Vector2(-42.0, 80.0))
	I.lot_fence(props, Vector2(-42.0, 86.0), Vector2(-42.0, 99.8))
	I.add(props, "fence_gate_rolling_chainlink", "worn", L.q(sx, sz, 42.4, 89.0), 90.0)
	I.containers(props, sx, sz, 50.0, 80.0, 6, false, rr, 0.0)
	I.containers(props, sx, sz, 72.0, 91.0, 5, false, rr, 0.0)
	for k in 3: I.add(props, "prop_k_rail", "dirty", L.q(sx, sz, 88.0 + k * 3.9, 78.0), 0.0)
	L.enclosure(props, L.q(sx, sz, 96.5, 57.0), 90.0)     # the motel's bins, off the court's east end
	# ---------------------------------------------------------------- polish: drains, the office's papers, wheel stops' wear
	L.drains(props, sx, sz, [Vector2(62.0, 48.0), Vector2(80.0, 48.0), Vector2(30.0, 45.0), Vector2(62.0, 24.0)])
	I.add(props, "prop_newspaper_box_red", "worn", L.q(sx, sz, 93.0, 61.4), 180.0)
	I.add(props, "prop_newspaper_box_blue", "worn", L.q(sx, sz, 93.7, 61.4), 180.0)
	I.add(props, "prop_trash_receptacle", "worn", L.q(sx, sz, 52.5, 51.0), 0.0)
	# ---------------------------------------------------------------- floor + wear
	K.painted_rect(g, -100.0, L.PROP_A, -L.PROP_S, 100.0, paints, S.walk_y)
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	L.stall_wear(dec, rr, stalls, 0.7)
	I.truck_path(dec, rr, Vector2(-45.0, L.PROP_A), Vector2(-45.0, 26.0))
	I.truck_path(dec, rr, Vector2(-45.0, 26.0), Vector2(-62.0, 48.0))
	I.truck_path(dec, rr, Vector2(-80.0, L.PROP_A), Vector2(-80.0, 48.0))
	I.truck_path(dec, rr, Vector2(-L.PROP_S, 80.0), Vector2(-40.0, 80.0))
	L.aisle_wear(dec, rr, sx, sz, 52.0, 92.0, 48.2)
	L.aisle_wear(dec, rr, sx, sz, 40.0, 92.0, 24.0)
	L.aisle_wear(dec, rr, sx, sz, 10.0, 38.0, 45.0)
	I.yard_wear(dec, rr, sx, sz, 50.0, 17.0, 99.0, 30.0, 1.0)
	I.yard_wear(dec, rr, sx, sz, 52.0, 44.0, 99.0, 58.0, 1.2)
	I.yard_wear(dec, rr, sx, sz, 10.0, 38.0, 40.0, 62.0, 1.2)
	L.finish(root, g, props, dec, "m_sw", stalls)
	quit()

func _iron_run(props: K.Props, a: Vector2, b: Vector2) -> void:
	var L2 := a.distance_to(b); var n := maxi(1, int(ceil(L2 / 1.98 - 0.02)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	for i in n:
		var m := a.lerp(b, (i + 0.5) / n)
		I.add(props, "fence_wrought_iron", "worn", Vector3(m.x, S.walk_y(0.0), m.y), yaw)
	for i in n + 1:
		var e := a.lerp(b, float(i) / n)
		I.add(props, "fence_post_wrought_iron", "worn", Vector3(e.x, S.walk_y(0.0), e.y), yaw)

func _hedge_run(props: K.Props, a: Vector2, b: Vector2) -> void:
	var L2 := a.distance_to(b); var n := maxi(1, int(floor(L2 / 2.0)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	for i in n:
		var m := a.lerp(b, (i + 0.5) / n)
		I.add(props, "hedge_boxwood_low_2m", "normal", Vector3(m.x, S.walk_y(0.0), m.y), yaw)
