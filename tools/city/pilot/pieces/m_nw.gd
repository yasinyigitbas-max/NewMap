extends SceneTree
## Piece m_nw (commercial strip sample, NW): Crown Plaza, the strip mall.
## - The 79 m L-strip set back behind its lot: a stall row along the landscape strip (broken at both arterial
##   driveways), the aisle, a second row nose-in toward the shops, a drop-off lane, the covered walk with benches, bins,
##   bike racks and planters between the doors (people wait for rides here, smoke here, chain bikes here).
## - A drive-thru coffee kiosk on the corner island, its queue lane round the kiosk.
## - Behind: the service lane (delivery trucks, three block enclosures, staff parking), a tagged block wall, then a
##   gravel utility easement with the junk that collects there.
## - Side street: the bank on its own pad. Run once; never when locked.
const L := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const CC := preload("res://tools/city/pilot/pieces/cc_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := -1.0; var sz := -1.0
	var root := Node3D.new(); root.name = "m_nw"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("m_nw")
	var paints: Array = []; var stalls: Array = []
	var arrows: Array = []   # smooth drive-thru arrows, filled after the floor
	var B: Array = []
	# ---------------------------------------------------------------- the mall
	var mall := I.put(bl, props, sx, sz, "x", 19.0, 44.0, "commercial/com_strip_mall_l", "crown_plaza")
	B.append([mall, "commercial/com_strip_mall_l"])
	paints.append(L.rect(sx, sz, 19.0, 42.0, 98.0, 44.0, "concrete"))            # covered walk
	# walk furniture in the gaps between the doors (all 9 shop doors from the kit stats; mall centre u 58.5, and with
	# sx = -1 a yaw-0 building's local +x points to smaller u)
	var doors: Array = []
	for e: Array in K.building_stats("commercial/com_strip_mall_l").doors_front: doors.append(float(e[1]))
	doors.sort()
	var kinds := ["prop_park_bench", "prop_trash_receptacle", "prop_bike_rack", "prop_park_bench", "prop_newspaper_box_blue", "prop_park_bench", "prop_trash_receptacle"]
	var ki := 0
	var edges: Array = [-39.0]; edges.append_array(doors); edges.append(39.0)
	for k in edges.size() - 1:
		var a: float = edges[k]; var b: float = edges[k + 1]
		if b - a < 5.0: continue
		var lx := (a + b) * 0.5
		var base: String = kinds[ki % kinds.size()]; ki += 1
		I.add(props, base, "worn", L.q(sx, sz, 58.5 - lx, 42.4), 0.0)   # racks parallel to the shopfront
	# a planter either side of each door, skipped where it would stand in front of the neighbouring door
	for lx: float in doors:
		for side: float in [-1.0, 1.0]:
			var px := lx + side * 1.75
			var clear := true
			for o: float in doors:
				if o != lx and absf(px - o) < 2.0: clear = false
			if clear: I.add(props, "plant_potted_succulent", "normal", L.q(sx, sz, 58.5 - px, 43.3), 0.0)
	# ---------------------------------------------------------------- the lot
	for seg: Array in [[22.0, 6], [49.5, 9], [84.5, 4]]:
		L.stalls_u(paints, stalls, sx, sz, float(seg[0]), int(seg[1]), 22.8, -1.0)
	L.stalls_u(paints, stalls, sx, sz, 22.0, 13, 29.8, 1.0)
	L.stalls_u(paints, stalls, sx, sz, 61.0, 13, 29.8, 1.0)
	L.island(paints, props, rr, sx, sz, 58.2, 29.9, 60.8, 35.2, 0)
	L.island(paints, props, rr, sx, sz, 96.3, 29.9, 99.5, 35.2, 0)
	for p: Vector2 in [Vector2(59.5, 32.55), Vector2(31.0, 16.0), Vector2(70.0, 16.0), Vector2(97.9, 32.55)]:
		L.lot_light(props, sx, sz, p.x, p.y)
	# landscape strip along the arterial (broken at the driveways)
	for seg2: Array in [[12.5, 40.0], [50.0, 75.0], [85.0, 99.5]]:
		L.island(paints, props, rr, sx, sz, float(seg2[0]), 14.6, float(seg2[1]), 17.0, maxi(1, int((float(seg2[1]) - float(seg2[0])) / 9.0)))
	# drop-off lane markings in front of the shops: fire lane red kerb along the walk
	W.red_kerb(dec, Vector2(sx * 19.5, sz * 42.0), Vector2(sx * 97.5, sz * 42.0), Vector2(0.0, 1.0))
	# ---------------------------------------------------------------- coffee kiosk on the corner island
	var kio := K.building(bl, "commercial/com_kiosk", L.q(sx, sz, 14.0, 27.0), 0.0, "coffee_kiosk", 0.8)
	B.append([[kio, 4.0, 6.0], "commercial/com_kiosk"])
	paints.append(L.rect(sx, sz, 10.0, 21.5, 18.0, 33.0, "concrete"))
	paints.append(L.rect(sx, sz, 18.4, 20.0, 18.55, 38.0, "white"))
	for k in 2:
		var vv := 36.0 - k * 7.0
		var a3 := S.arrow2("through", sx * 19.9, sz * vv, sz * (vv - 3.0), false, 0.75); arrows.append(a3); paints.insert(0, (a3.box as Array) + ["-"])
	I.add(props, "prop_trash_receptacle", "dirty", L.q(sx, sz, 11.0, 32.0), 0.0)
	I.add(props, "plant_potted_succulent", "normal", L.q(sx, sz, 10.6, 22.2), 0.0)
	# kit batch 2 (17 Nov): the plaza's pylon at the arterial, the coffee drive-thru's menu board before the window
	L.pylon(props, sx, sz, 54.0)
	I.add(props, "prop_drive_thru_menu", "worn", L.q(sx, sz, 21.9, 34.0), 90.0 * sx)
	# ---------------------------------------------------------------- behind the mall
	for u: float in [30.0, 55.0, 82.0]:
		L.enclosure(props, L.q(sx, sz, u, 68.0), 180.0)
		L.enclosure_mess(props, rr, L.q(sx, sz, u, 68.0), 180.0)
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", L.q(sx, sz, 68.5, 68.5), 90.0)     # cardboard compactor bin
	L.stalls_u(paints, stalls, sx, sz, 24.0, 26, 77.0, 1.0)                          # staff parking against the wall
	var x := 19.0
	var k2 := 0
	while x < 99.0:
		I.add(props, "fence_graffiti_cmu_panel" if k2 % 4 == 1 else "fence_cmu_wall", "worn", L.q(sx, sz, x + 1.0, 84.6), 0.0)
		x += 2.03; k2 += 1
	paints.append(L.rect(sx, sz, 19.0, 85.2, 100.0, 100.0, "gravel"))
	I.add(props, "prop_utility_pole_transformer", "worn", L.q(sx, sz, 40.0, 92.0), 90.0)
	I.add(props, "prop_utility_pole", "worn", L.q(sx, sz, 74.0, 92.0), 90.0)
	for k in 3: I.add(props, "prop_k_rail", "dirty", L.q(sx, sz, 55.0 + k * 4.0, 95.0), rr.randf_range(-10, 10))
	I.add(props, "prop_water_barrier_white", "dirty", L.q(sx, sz, 90.0, 89.5), 30.0)
	I.add(props, "prop_trash_cart_blue", "worn", L.q(sx, sz, 28.0, 96.5), 70.0)
	I.lot_fence(props, Vector2(-19.0, -99.8), Vector2(-99.8, -99.8))
	# planted edge along the side street where the mall's flank and service entry meet the sidewalk (driveways open)
	for seg3: Array in [[49.5, 75.5]]:     # (Yasin 17 Nov: the short square island at v 34-40.5 removed)
		L.island(paints, props, rr, sx, sz, 9.0, float(seg3[0]), 11.6, float(seg3[1]), maxi(1, int((float(seg3[1]) - float(seg3[0])) / 8.0)))
		var hv: float = float(seg3[0]) + 2.4      # clear of the plants at the island ends
		while hv + 2.0 < float(seg3[1]) - 2.4:
			I.add(props, "hedge_boxwood_low_2m", "normal", L.q(sx, sz, 11.3, hv + 1.0), 90.0); hv += 2.0
	# ---------------------------------------------------------------- the bank on the side street
	var bank := I.put(bl, props, sx, sz, "z", 85.5, I.FRONT, "commercial/com_bank", "harbor_bank")
	B.append([bank, "commercial/com_bank"])
	I.walk_prop(props, sx, sz, "z", 84.0, "prop_trash_receptacle")
	I.walk_prop(props, sx, sz, "z", 99.0, "prop_usps_collection_box")
	# ---------------------------------------------------------------- polish: drains, bollards, fire lane, crossing
	L.drains(props, sx, sz, [Vector2(40.0, 26.3), Vector2(75.0, 26.3), Vector2(50.0, 38.6), Vector2(88.0, 38.6), Vector2(60.0, 74.0)])
	L.bollards(props, sx, sz, [Vector2(19.6, 41.6), Vector2(97.4, 41.6)])
	for u5: float in [25.0, 92.0]: I.add(props, "prop_sign_no_parking", "worn", L.q(sx, sz, u5, 41.65), 0.0)   # FIRE LANE
	L.crossing(paints, sx, sz, 57.6, 61.4, 35.3, 42.0)
	I.add(props, "prop_sign_ped_crossing", "worn", L.q(sx, sz, 59.5, 34.7), 0.0)
	# (Yasin 17 Nov: the lone hydrant in the lot is removed, not guarded)
	# ---------------------------------------------------------------- floor + wear
	K.painted_rect(g, -100.0, -100.0, -L.PROP_S, -L.PROP_A, paints, S.walk_y)
	for a4: Dictionary in arrows: K.fill_arrow(g, a4, S.walk_y)
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	L.stall_wear(dec, rr, stalls, 0.6)
	for a: float in L.APR_A: I.truck_path(dec, rr, Vector2(-a, -L.PROP_A), Vector2(-a, -38.0))
	I.truck_path(dec, rr, Vector2(-L.PROP_S, -80.0), Vector2(-95.0, -72.0))     # delivery trucks to the back doors
	for k in 8: W.oil(dec, rr, Vector2(-rr.randf_range(25.0, 95.0), -rr.randf_range(66.0, 74.0)), 90.0, S.walk_y, 0.9)
	for k in 4: W.oil(dec, rr, Vector2(-19.9, -(22.0 + k * 3.5)), 0.0, S.walk_y, 0.9)   # coffee queue
	L.aisle_wear(dec, rr, sx, sz, 20.0, 98.0, 26.3)
	L.aisle_wear(dec, rr, sx, sz, 20.0, 98.0, 38.6)
	I.yard_wear(dec, rr, sx, sz, 9.0, 17.0, 99.0, 42.0, 1.1)
	I.yard_wear(dec, rr, sx, sz, 19.0, 64.0, 99.0, 84.0, 1.4)
	L.finish(root, g, props, dec, "m_nw", stalls)
	quit()

func _arrow_v(sx: float, sz: float, u: float, v0: float, v1: float) -> Array:
	var d := signf(v1 - v0)
	var out: Array = [L.rect(sx, sz, u - 0.07, minf(v0, v1 - d * 0.8), u + 0.07, maxf(v0, v1 - d * 0.8), "white")]
	for i in 4:
		var w := 0.35 * (1.0 - float(i) / 4.0)
		var a := v1 - d * 0.8 + d * 0.8 * float(i) / 4.0; var b := v1 - d * 0.8 + d * 0.8 * float(i + 1) / 4.0
		out.append(L.rect(sx, sz, u - w, minf(a, b), u + w, maxf(a, b), "white"))
	return out

