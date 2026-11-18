extends SceneTree
## Piece m_ne (commercial strip sample, NE): the corner every driver sees from both streets.
## - Crown Fuel on the corner pad (kiosk at the back, canopy toward the arterial), entered from both streets.
## - A drive-thru burger place: 7 stalls in front, a patio with tables and a sail on the west side, the drive-thru lane
##   wrapping the east side and the back, its bins in a block enclosure behind.
## - A tyre & lube shop (bays to the arterial, customers' cars along the east edge), its billboard over the corner of
##   the lot facing the arterial traffic.
## - Side street: the small local shops (laundromat + pharmacy, a tap room, an insurance office) right on the sidewalk.
## - Behind: self-storage rows inside a chain-link compound, gate off the side-street driveway.
## Every building gets its back-of-house services; wear follows the traffic. Run once; never when locked.
const L := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const CC := preload("res://tools/city/pilot/pieces/cc_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := 1.0; var sz := -1.0
	var root := Node3D.new(); root.name = "m_ne"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("m_ne")
	var paints: Array = []; var stalls: Array = []
	var arrows: Array = []   # smooth drive-thru arrows, filled after the floor
	var B: Array = []
	# ---------------------------------------------------------------- Crown Fuel (corner pad)
	var gas := K.building(bl, "commercial/com_gas_station", L.q(sx, sz, 24.0, 36.0), 0.0, "crown_fuel", 0.85)
	CC.back_of_house(props, gas, "commercial/com_gas_station")
	B.append([[gas, 10.0, 9.0], "commercial/com_gas_station"])
	paints.append(L.rect(sx, sz, 14.0, 21.0, 31.0, 33.0, "concrete"))           # the forecourt slab under the canopy
	for k in 4: I.add(props, "prop_propane_cylinder_100lb", "rusty", L.q(sx, sz, 31.6 + k * 0.45, 38.5), 0.0)   # exchange cage spot
	I.add(props, "prop_trash_receptacle", "dirty", L.q(sx, sz, 30.6, 31.0), 0.0)
	I.add(props, "prop_newspaper_box_red", "worn", L.q(sx, sz, 31.6, 31.0), 0.0)
	L.enclosure(props, L.q(sx, sz, 26.0, 47.5), 0.0)
	L.enclosure_mess(props, rr, L.q(sx, sz, 26.0, 47.5), 0.0)
	# ---------------------------------------------------------------- burger drive-thru
	var ff := I.put(bl, props, sx, sz, "x", 48.0, 32.0, "ck/mod_fastfood", "burger_barn")
	B.append([ff, "ck/mod_fastfood"])
	paints.append(L.rect(sx, sz, 47.0, 30.0, 61.0, 32.0, "concrete"))           # walk along the front
	L.stalls_u(paints, stalls, sx, sz, 41.0, 7, 24.5, 1.0)
	# drive-thru lane: up the east side, along the back, out on the west; painted edge lines and arrows
	paints.append(L.rect(sx, sz, 61.4, 26.0, 61.55, 45.4, "white"))
	paints.append(L.rect(sx, sz, 46.5, 45.4, 61.55, 45.55, "white"))
	for k in 3:
		var vv := 30.0 + k * 6.0
		var a3 := S.arrow2("through", sx * 63.2, sz * vv, sz * (vv + 3.0), false, 0.75); arrows.append(a3); paints.insert(0, (a3.box as Array) + ["-"])
	paints.append(L.rect(sx, sz, 65.5, 38.5, 67.5, 41.0, "concrete"))          # menu-board pad (board itself: missing prop)
	# patio on the west side: tables, a sail, a bin
	paints.append(L.rect(sx, sz, 41.5, 33.0, 47.6, 43.5, "concrete"))
	for k in 2: I.add(props, "prop_picnic_table", "worn", L.q(sx, sz, 44.4, 35.5 + k * 4.6), 90.0)
	for k in 2: I.add(props, "prop_shade_sail", "worn", L.q(sx, sz, 44.4, 35.5 + k * 4.6), 0.0)   # one sail OVER each table (Yasin 17 Nov: one sail between two tables shaded neither)
	I.add(props, "prop_trash_receptacle", "dirty", L.q(sx, sz, 46.9, 42.8), 0.0)
	I.add(props, "plant_potted_succulent", "normal", L.q(sx, sz, 42.0, 33.5), 0.0)
	I.add(props, "plant_potted_succulent", "normal", L.q(sx, sz, 42.0, 43.0), 0.0)
	I.add(props, "prop_bike_rack", "worn", L.q(sx, sz, 43.0, 30.4), 0.0)   # parallel to the front walk
	L.enclosure(props, L.q(sx, sz, 54.0, 53.5), 0.0)
	I.add(props, "prop_dumpster_3yd_green", "rusty", L.q(sx, sz, 59.5, 52.5), 0.0)       # grease bin overflow
	# ---------------------------------------------------------------- tyre & lube
	var ty := I.put(bl, props, sx, sz, "x", 74.0, 36.0, "industrial/ind_repair", "tyre_lube")
	B.append([ty, "industrial/ind_repair"])
	L.stalls_v(paints, stalls, sx, sz, 19.0, 5, 93.5, 1.0)                       # customers' cars along the east edge
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", L.q(sx, sz, 96.0, 47.0), 90.0)   # old tyres
	for k in 3: I.add(props, "prop_channelizer_drum", "dirty", L.q(sx, sz, 72.2, 40.0 + k * 0.85), 0.0)   # waste oil
	I.add(props, "prop_water_barrier_orange", "dirty", L.q(sx, sz, 72.5, 47.0), 90.0)
	I.add(props, "prop_billboard", "worn", L.q(sx, sz, 96.5, 55.0), 0.0)       # over the lot corner, facing the arterial
	# ---------------------------------------------------------------- side street: the small local shops
	B.append([I.put(bl, props, sx, sz, "z", 52.0, I.FRONT, "ck/ck_svc_bank_pharm", "bank_pharmacy"), "ck/ck_svc_bank_pharm"])  # audit fix 17 Nov (#9): was mod_svc_row, whose pharmacy + laundromat fronts repeated 13 times
	B.append([I.put(bl, props, sx, sz, "z", 66.0, I.FRONT, "commercial/com_bakery", "corner_bakery"), "commercial/com_bakery"])  # audit fix (#9): the 5th Crown bar became a bakery
	B.append([I.put(bl, props, sx, sz, "z", 86.5, I.FRONT, "commercial/com_realty", "insurance_office"), "commercial/com_realty"])
	I.walk_prop(props, sx, sz, "z", 64.6, "prop_newspaper_box_blue")
	I.walk_prop(props, sx, sz, "z", 76.0, "prop_bike_rack", "rusty")
	L.enclosure(props, L.q(sx, sz, 28.5, 60.0), -90.0)                            # the shops' shared bins, behind them
	# ---------------------------------------------------------------- self-storage compound
	for k in 3:
		var n := K.building(bl, "ck/mod_stg_row_roofed", L.q(sx, sz, 49.0 + k * 19.0, 66.0), 180.0, "storage_a%d" % k, 0.85)
		B.append([[n, 18.0, 12.0], "ck/mod_stg_row_roofed"])
		B.append([I.put(bl, props, sx, sz, "x", 40.0 + k * 19.0, 84.0, "ck/mod_stg_row_roofed", "storage_b%d" % k, false), "ck/mod_stg_row_roofed"])
	I.lot_fence(props, Vector2(36.0, -58.0), Vector2(99.8, -58.0))
	I.lot_fence(props, Vector2(36.0, -58.0), Vector2(36.0, -76.0)); I.lot_fence(props, Vector2(36.0, -84.0), Vector2(36.0, -99.8))
	I.add(props, "fence_gate_rolling_chainlink", "worn", L.q(sx, sz, 36.4, 87.0), 90.0)     # open, slid back inside
	I.lot_fence(props, Vector2(99.8, -58.0), Vector2(99.8, -99.8)); I.lot_fence(props, Vector2(36.0, -99.8), Vector2(99.8, -99.8))
	I.add(props, "prop_utility_pole_transformer", "worn", L.q(sx, sz, 37.5, 55.5), 0.0)
	# ---------------------------------------------------------------- landscape strip along the arterial, lights
	for seg: Array in [[12.5, 40.0], [50.0, 75.0], [85.0, 92.5]]:
		L.island(paints, props, rr, sx, sz, float(seg[0]), 14.6, float(seg[1]), 17.3, maxi(1, int((float(seg[1]) - float(seg[0])) / 9.0)))
	for p: Vector2 in [Vector2(35.5, 16.0), Vector2(67.5, 16.0), Vector2(96.0, 40.0), Vector2(30.0, 54.0), Vector2(66.0, 79.0)]:
		L.lot_light(props, sx, sz, p.x, p.y)
	# ---------------------------------------------------------------- polish: drains, bollards, signs, bins
	L.drains(props, sx, sz, [Vector2(52.0, 21.0), Vector2(84.0, 26.0), Vector2(20.0, 44.5), Vector2(70.0, 79.0)])
	L.bollards(props, sx, sz, [Vector2(47.4, 30.6), Vector2(60.6, 30.6)])
	L.bollards(props, sx, sz, [Vector2(31.2, 37.6), Vector2(33.8, 37.6)], "prop_bollard_steel")
	I.add(props, "prop_recycling_receptacle", "worn", L.q(sx, sz, 45.9, 42.8), 0.0)
	I.add(props, "prop_sign_no_parking", "worn", L.q(sx, sz, 66.2, 27.0), 0.0)
	# (Yasin 17 Nov: the lone hydrant in the lot is removed, not guarded)
	# ---------------------------------------------------------------- kit batch 2 (17 Nov): signs, menu board, ice chest
	L.pylon(props, sx, sz, 16.1)            # Crown Fuel prices, on the corner
	L.pylon(props, sx, sz, 54.0)            # Burger Barn
	I.add(props, "prop_drive_thru_menu", "worn", L.q(sx, sz, 66.5, 39.75), -90.0 * sx)    # on its pad, facing the lane
	I.add(props, "prop_ice_chest", "worn", L.q(sx, sz, 17.4, 32.4), 0.0)                 # by the shop's front corner
	# ---------------------------------------------------------------- floor + wear
	K.painted_rect(g, L.PROP_S, -100.0, 100.0, -L.PROP_A, paints, S.walk_y)
	for a4: Dictionary in arrows: K.fill_arrow(g, a4, S.walk_y)
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	L.stall_wear(dec, rr, stalls, 0.65)
	for k in 10: W.oil(dec, rr, Vector2(rr.randf_range(16.0, 29.0), -rr.randf_range(23.0, 31.0)), rr.randf_range(0, 180), S.walk_y, 0.95)   # pumps
	I.truck_path(dec, rr, Vector2(45.0, -L.PROP_A), Vector2(45.0, -22.0))
	I.truck_path(dec, rr, Vector2(80.0, -L.PROP_A), Vector2(80.0, -32.0))
	I.truck_path(dec, rr, Vector2(L.PROP_S, -45.0), Vector2(30.0, -45.0))
	I.truck_path(dec, rr, Vector2(L.PROP_S, -80.0), Vector2(40.0, -80.0))
	for k in 5: W.oil(dec, rr, Vector2(63.2, -(28.0 + k * 3.6)), 0.0, S.walk_y, 0.9)   # idling in the drive-thru queue
	L.aisle_wear(dec, rr, sx, sz, 40.0, 72.0, 21.0)
	L.aisle_wear(dec, rr, sx, sz, 36.0, 99.0, 78.0)
	I.yard_wear(dec, rr, sx, sz, 9.0, 17.5, 99.0, 50.0, 1.1)
	I.yard_wear(dec, rr, sx, sz, 22.0, 50.0, 99.0, 99.0, 0.8)
	L.finish(root, g, props, dec, "m_ne", stalls)
	quit()

## a small direction arrow along v (drive-thru lane), from v0 to v1 at u
func _arrow_v(sx: float, sz: float, u: float, v0: float, v1: float) -> Array:
	var out: Array = [L.rect(sx, sz, u - 0.07, v0, u + 0.07, v1 - 0.8, "white")]
	for i in 4:
		var w := 0.35 * (1.0 - float(i) / 4.0)
		var a := v1 - 0.8 + 0.8 * float(i) / 4.0; var b := v1 - 0.8 + 0.8 * float(i + 1) / 4.0
		out.append(L.rect(sx, sz, u - w, a, u + w, b, "white"))
	return out

