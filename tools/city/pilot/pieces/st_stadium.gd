extends SceneTree
## Piece st_stadium (civic + parks band, sub-chapter: the STADIUM). The kit stadium (154 x 117 m) on its own 210 x 200 m
## site, south of the band (Yasin 17 Nov: "we dont have any gyms or the staduim yet ... use them in transitional
## areas"): a stadium is the city's big transition piece - between neighbourhoods, with the parking that keeps match
## traffic off the residential streets. Frame: site centre at the origin, x along the long side, the entry from the
## north (-z, where the band's south street ends).
## - A 6 m forecourt ring round the stands (people queue and circulate here), the GATE PLAZA on the north: ticket
##   kiosks, food kiosks, bins and recycling every few metres, benches facing the street, bike racks along the plaza
##   edge, a bollard line against cars, Type I barricades and water barriers stacked ready for crowd control, a
##   billboard for the next match facing the arriving traffic.
## - The entry drive from the north with two bus bays (red kerb, benches), drop-off for taxis.
## - Parking on all four sides: rows of stalls round aisles, a planted island with a fan palm every ten stalls and at
##   each row end, lot lights, drains; a ring drive between the lots and the forecourt.
## - A chain-link perimeter with the entry gaps; a rolling gate on the service side (south) for the team buses.
## - Wear: oil under every stall (match-day full), aisle wheel paths, tyre marks at the entries, litter-grime at the
##   gates and kiosks, cracks and patches over the whole asphalt.
## (17 Nov) The entry avenue continues the civic band's south street; a tennis centre fills the south strip.
## Run once; never when locked.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const C := preload("res://tools/city/pilot/pieces/civ_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const HX := 105.0
const HZ := 100.0                     # north half depth (the site's north edge meets the band's south street end)
const HZS := 160.0                    # south extent: the tennis centre behind the stadium (Yasin 17 Nov)
const SC := Vector2(0.0, 6.0)        # stadium centre
const SHX := 77.0                     # stadium half extents (mesh)
const SHZ := 58.5
const RING := 6.0                     # forecourt
const DRIVE := 7.0
func _init() -> void: _run.call_deferred()

func q(x: float, z: float, y := 0.0) -> Vector3: return Vector3(x, S.walk_y(0.0) + y, z)

func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "st_stadium"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var pk := Node3D.new(); pk.name = "Parks"; root.add_child(pk)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("st_stadium")
	var paints: Array = []; var stalls: Array = []
	var fx0 := SC.x - SHX - RING; var fx1 := SC.x + SHX + RING
	var fz0 := SC.y - SHZ - RING; var fz1 := SC.y + SHZ + RING
	# ---- the stadium
	var st := K.building(bl, "public/pub_stadium", q(SC.x, SC.y), 0.0, "stadium", 0.7)
	paints.append([fx0, fz0, fx1, fz1, "plaza"])
	# gate plaza on the north, out to the entry drive
	var pz0 := fz0 - 12.0
	paints.append([-38.0, pz0, 38.0, fz0, "plaza"])
	# ---- islands FIRST (first paint wins), then stall rows. West and east: one row each side of an aisle along z.
	var lots := []   # [axis, s0, s1, edge, dir]
	for side: float in [-1.0, 1.0]:
		var x_edge := side * (SHX + RING + DRIVE)          # stalls start at the ring drive's outer edge
		var z := -HZ + 4.0
		while z + 10 * SL.STALL_W <= HZ - 4.0:
			lots.append(["v", z, 10, x_edge, side])
			z += 10 * SL.STALL_W
			if z + 2.6 + SL.STALL_W <= HZ - 4.0:
				SL.island(paints, props, rr, 1.0, 1.0, minf(x_edge, x_edge + side * SL.STALL_D), z, maxf(x_edge, x_edge + side * SL.STALL_D), z + 2.6, 1)
				z += 2.6
	# north lots: two rows round an aisle along x, either side of the entry drive
	for side: float in [-1.0, 1.0]:
		var xa := 12.0 if side > 0 else -86.0
		lots.append(["u", xa, 27, -84.0, -1.0])
		lots.append(["u", xa, 27, -77.0, 1.0])
		SL.island(paints, props, rr, 1.0, 1.0, xa - 2.6, -84.0 - SL.STALL_D, xa, -77.0 + SL.STALL_D, 1)
	# south lot: two rows round an aisle along x (staff, media vans), team bus apron in the middle
	for xa2: float in [-80.0, 18.0]:
		lots.append(["u", xa2, 23, fz1 + DRIVE + SL.STALL_D, -1.0])
		lots.append(["u", xa2, 23, fz1 + DRIVE + SL.STALL_D + 7.0, 1.0])
	for l: Array in lots:
		if String(l[0]) == "v": SL.stalls_v(paints, stalls, 1.0, 1.0, float(l[1]), int(l[2]), float(l[3]), float(l[4]))
		else: SL.stalls_u(paints, stalls, 1.0, 1.0, float(l[1]), int(l[2]), float(l[3]), float(l[4]))
	# ---- the ENTRY AVENUE (Yasin 17 Nov: "there aren't roads leading to this stadium"): the civic band's south street
	# (s_apt section: 1+1 lanes, parking to the kerb at 5.7, grass parkway to 7.2, sidewalk to 9.2) carries on through
	# the site edge to a drop-off kerb at the gate plaza. Driveway aprons ramp into the north lots' aisle; the bus
	# stops in the parking lane by the plaza (red kerb, benches at the back of the sidewalk facing the road).
	paints.insert(0, [-9.2, -HZ, 9.2, pz0, "-"])         # the avenue is drawn on its own below
	var av: Array = [[-0.2, -HZ, -0.1, pz0 - 1.0, "yellow"], [0.1, -HZ, 0.2, pz0 - 1.0, "yellow"]]
	for sx2: float in [-1.0, 1.0]:
		for e3: float in [-HZ + 1.0, -HZ + 7.5]:
			av.append([minf(sx2 * 3.3, sx2 * 3.9), e3 - 0.05, maxf(sx2 * 3.3, sx2 * 3.9), e3 + 0.05, "white"])
	av.append([-3.3, pz0 - 1.8, 3.3, pz0 - 1.2, "white"])           # give way to the crossing at the plaza
	K.painted_rect(g, -5.7, -HZ, 5.7, pz0, av, S.road_y)
	g.wall_line("curb", PackedVector2Array([Vector2(-5.7, pz0), Vector2(5.7, pz0)]), S.road_y, S.walk_y, 1.0)   # drop-off kerb
	var apron_c := -80.5
	for sx3: float in [-1.0, 1.0]:
		S.sidewalk_strip(g, "z", sx3 * 5.7, sx3 * 7.2, -HZ, apron_c - 5.5, [], "grass")
		S.sidewalk_strip(g, "z", sx3 * 5.7, sx3 * 9.2, apron_c - 5.5, apron_c + 5.5, [[apron_c, 7.0]], "concrete", 3.5, 1.5, 0.0)
		S.sidewalk_strip(g, "z", sx3 * 5.7, sx3 * 7.2, apron_c + 5.5, pz0, [], "grass")
		g.rect("concrete", minf(sx3 * 7.2, sx3 * 9.2), -HZ, maxf(sx3 * 7.2, sx3 * 9.2), apron_c - 5.5, S.walk_y)
		g.rect("concrete", minf(sx3 * 7.2, sx3 * 9.2), apron_c + 5.5, maxf(sx3 * 7.2, sx3 * 9.2), pz0, S.walk_y)
		for pzz: float in [-95.0, -68.0 - 6.0]:
			I.add(props, "palm_mexican_fan_b" if sx3 > 0 else "palm_mexican_fan_c", "normal", q(sx3 * 6.45, pzz), pzz * 7.0)
		I.add(props, "prop_lamp_globe", "worn", q(sx3 * 6.3, -88.0), 0.0)
		I.add(props, "prop_bench_bus_stop", "worn", q(sx3 * 8.75, -78.0 + 6.0), -90.0 * sx3)
		I.add(props, "prop_trash_receptacle", "dirty", q(sx3 * 8.75, -74.8), 0.0)
		dec.add(14, Vector2(sx3 * 8.2, -72.0), 0.0, 1.6, 4.0, S.walk_y, Color(1, 1, 1, 0.55))
		W.red_kerb(dec, Vector2(sx3 * 5.7, -76.0), Vector2(sx3 * 5.7, pz0), Vector2(-sx3, 0.0))
		I.add(props, "prop_sign_no_parking", "worn", q(sx3 * 6.1, -76.5), -90.0 * sx3)
		for k5 in 3: W.oil(dec, rr, Vector2(sx3 * 4.5, -97.0 + k5 * 6.5), 0.0, S.road_y, 0.8)     # cars parked at the kerb
	W.lane_wear(dec, rr, -1.65, -HZ, pz0, true, S.road_y); W.lane_wear(dec, rr, 1.65, -HZ, pz0, true, S.road_y)
	for k6 in 4: dec.add(8, Vector2(rr.randf_range(-4.0, 4.0), pz0 - 3.0), rr.randf_range(60, 120), 0.6, 6.0, S.road_y, Color(1, 1, 1, 0.5))   # drop-off swings
	# ---- the gate plaza life
	for k3 in 2:
		var kx := -20.0 + k3 * 40.0
		var kb := K.building(bl, "commercial/com_kiosk", q(kx, pz0 + 5.0), 180.0, "ticket_kiosk_%d" % k3, 0.7)
	for k4 in 2:
		var fxk := -48.0 + k4 * 96.0
		K.building(bl, "commercial/com_kiosk", q(fxk, fz0 + 3.6), 0.0, "food_kiosk_%d" % k4, 0.75)
		for t in 2: I.add(props, "prop_picnic_table", "worn", q(fxk + (t * 2 - 1) * 4.0, fz0 + 1.5), 90.0)
		I.add(props, "prop_trash_receptacle", "dirty", q(fxk + 2.6, fz0 + 0.6), 0.0)
		I.add(props, "prop_recycling_receptacle", "worn", q(fxk + 6.8, fz0 + 0.6), 0.0)
	var bx := -34.0
	while bx <= 34.0:
		if absf(bx) > 9.0 and absf(absf(bx) - 20.0) > 2.2: I.add(props, "prop_bollard_concrete", "worn", q(bx, pz0 + 0.5), 0.0)   # gaps at the ticket windows
		bx += 2.5
	for k5 in 6: I.add(props, "prop_trash_receptacle", "dirty" if k5 % 2 else "worn", q(-30.0 + k5 * 12.0, fz0 - 1.0), 0.0)
	for k6 in 4: I.add(props, "prop_park_bench", "worn", q(-32.0 + k6 * 21.0, pz0 + 2.0), 180.0)   # facing the street and the arrivals
	for k7 in 4: I.add(props, "prop_bike_rack", "worn", q(24.0 + k7 * 3.0, pz0 + 9.0), 0.0)
	for k8 in 8: I.add(props, "prop_barricade_type1", "worn", q(-13.0 + (k8 % 4) * 1.1, fz0 - 6.5 + (k8 / 4) * 1.5), 90.0)    # parked in rows by the gate, ready for match day
	for k9 in 3: I.add(props, "prop_water_barrier_white", "dirty", q(10.0 + k9 * 2.1, fz0 - 6.5), 0.0)
	I.add(props, "prop_newspaper_box_red", "worn", q(-4.0, pz0 + 1.2), 180.0)
	I.add(props, "prop_newspaper_box_blue", "worn", q(-3.2, pz0 + 1.2), 180.0)
	I.add(props, "prop_billboard", "worn", q(-24.0, -HZ + 6.0), 180.0)          # next match, facing the arriving traffic
	for p: Vector2 in [Vector2(-38.0, pz0 + 1.5), Vector2(38.0, pz0 + 1.5)]: I.add(props, "palm_mexican_fan_a", "normal", q(p.x, p.y), p.x * 3.0)
	paints.insert(0, [-39.5, pz0, -36.5, pz0 + 3.0, "grass"]); paints.insert(0, [36.5, pz0, 39.5, pz0 + 3.0, "grass"])
	# ---- lot lights, drains, south service gate
	for lx: float in [-60.0, -25.0, 25.0, 60.0]:
		SL.lot_light(props, 1.0, 1.0, lx, -80.5)
		SL.lot_light(props, 1.0, 1.0, lx, fz1 + DRIVE + SL.STALL_D + 3.5)
	for lz: float in [-50.0, -10.0, 30.0, 70.0]:
		SL.lot_light(props, 1.0, 1.0, -(SHX + RING + DRIVE * 0.5), lz)
		SL.lot_light(props, 1.0, 1.0, SHX + RING + DRIVE * 0.5, lz)
	SL.drains(props, 1.0, 1.0, [Vector2(-50.0, -80.5), Vector2(50.0, -80.5), Vector2(-90.0, 0.0), Vector2(90.0, 0.0), Vector2(0.0, 90.0)])
	# ---- the TENNIS CENTRE behind the stadium (Yasin 17 Nov: "add some more tennis courts on the backsides, lots of
	# props and life"): four kit tennis parks in a row on the south strip, gates toward a paved promenade along the
	# staff lot (players park there); between the court pairs: the pro shop kiosk, picnic tables under sails, the
	# fountain and bins; benches along the promenade facing the courts (people watch the games); bike racks; lot lights
	# for evening play; a screen of trees along the south fence. Worn paths at every gate, scuffs where players wait.
	var tctx := {"sx": 1.0, "sz": 1.0, "pk": pk, "paints": paints, "props": props, "rr": rr, "dec": dec}
	for tx: float in [-75.0, -25.0, 25.0, 75.0]:
		C.park(tctx, "park_tennis_courts", tx, 126.0, "-v")
	paints.append([-HX, 100.0, HX, 104.5, "plaza"])                   # promenade
	paints.insert(0, [-HX, 147.5, HX, HZS, "grass"])                  # tree screen strip
	for tx2: float in [-75.0, -25.0, 25.0, 75.0]:
		paints.append([tx2 - 1.5, 104.5, tx2 + 1.5, 108.0, "plaza"])  # walk to each gate
		for o: float in [-11.0, 11.0]:
			I.add(props, "prop_park_bench", "worn", q(tx2 + o, 103.6), 0.0)      # facing the courts
		I.add(props, "prop_trash_receptacle", "worn", q(tx2 + 5.0, 103.8), 0.0)
		dec.add(14, Vector2(tx2, 105.5), 0.0, 3.0, 2.5, S.walk_y, Color(1, 1, 1, 0.55))
	for gx: float in [-50.0, 0.0, 50.0]:       # the 10 m gaps between court fences
		if gx == 0.0:
			K.building(bl, "commercial/com_kiosk", q(0.0, 113.0), 180.0, "pro_shop", 0.7)
			I.add(props, "prop_drinking_fountain", "worn", q(-2.6, 108.5), 0.0)
			I.add(props, "prop_recycling_receptacle", "worn", q(2.6, 108.5), 0.0)
			for k7 in 2: I.add(props, "prop_bike_rack", "worn", q(-3.0 + k7 * 3.0, 141.0), 0.0)
		else:
			paints.insert(0, [gx - 4.5, 108.0, gx + 4.5, 145.0, "grass"])
			# (17 Nov, Yasin: "remove those tables and sails from between the courts") - a planted strip with its tree
			I.add(props, "tree_jacaranda_a" if gx < 0 else "tree_coral_a", "normal", q(gx, 136.0), gx * 3.0)
			I.add(props, "prop_drinking_fountain", "worn", q(gx - 2.2, 110.5), 0.0)
			SL.lot_light(props, 1.0, 1.0, gx, 141.5)
	for lx2: float in [-100.0, 100.0]: SL.lot_light(props, 1.0, 1.0, lx2, 108.0)
	var tz := -100.0
	while tz <= 100.0:
		I.add(props, ["tree_ficus_a", "tree_eucalyptus_a", "tree_ficus_b", "tree_eucalyptus_b"][int(tz + 100.0) / 12 % 4], "normal", q(tz, 154.0), tz * 5.0)
		tz += 12.0
	for k8 in 2: I.add(props, "prop_bike_rack", "worn", q(-60.0 + k8 * 120.0, 103.6), 0.0)
	# ---- the stadium's four entrances (Yasin 17 Nov: "no doors, just open cut outs"; then: the gates missed the
	# openings - the kit mesh's bounds include a 4 m roof overhang, the WALLS are at z = centre +- 54.45 and
	# x = +-72.95). Measured by raycasts on the kit mesh: openings 6.5 m (long sides) / 6.7 m (ends) wide, ~2.9 m high.
	# Each is closed completely (match days are scripted events), set 0.3 m inside the wall face.
	var WZ := 54.45; var WX := 72.95
	var gates := [[Vector3(SC.x, 0.0, SC.y - WZ + 0.3), 0.0, 6.5], [Vector3(SC.x, 0.0, SC.y + WZ - 0.3), 0.0, 6.5],
		[Vector3(SC.x + WX - 0.3, 0.0, SC.y), 90.0, 6.7], [Vector3(SC.x - WX + 0.3, 0.0, SC.y), 90.0, 6.7]]
	# service lanes (17 Nov, Yasin: "extend those asphalt patches in front of the entrances to make them meet the car
	# park asphalt"): each opening's pad continues as an asphalt lane of the same width across the forecourt ring to the
	# ring drive / lots (north: across the gate plaza to the drive)
	paints.insert(0, [SC.x - 3.25, pz0, SC.x + 3.25, SC.y - WZ, "asphalt"])
	paints.insert(0, [SC.x - 3.25, SC.y + WZ, SC.x + 3.25, fz1, "asphalt"])
	paints.insert(0, [SC.x + WX, SC.y - 3.35, fx1, SC.y + 3.35, "asphalt"])
	paints.insert(0, [fx0, SC.y - 3.35, SC.x - WX, SC.y + 3.35, "asphalt"])
	# (17 Nov, Yasin: "close those gates entirely" / "close both sides") each opening is shut by a solid roll-down steel
	# shutter: one box per opening, 0.12 m thick, inside the 0.45 m wall. The kit's MID tier cuts a 9.5 m opening where
	# the near tier cuts 6.5 m, so the shutter is 9.9 m wide and 3.4 m tall: it closes the wider mid opening and simply
	# hides inside the wall around the narrower near one (the far tier has no opening). Weathered
	# dark steel, with a collider. One shared material, no texture page: 4 small boxes.
	var shut_mat := StandardMaterial3D.new()
	shut_mat.albedo_color = Color(0.36, 0.37, 0.38); shut_mat.roughness = 0.55; shut_mat.metallic = 0.35
	var shutters := Node3D.new(); shutters.name = "gates"; root.add_child(shutters)
	for gt: Array in gates:
		var c3: Vector3 = gt[0]; var gy: float = gt[1]; var gw: float = gt[2]
		var bm := BoxMesh.new(); bm.size = Vector3(9.9, 3.4, 0.12); bm.material = shut_mat
		var mi2 := MeshInstance3D.new(); mi2.mesh = bm
		mi2.position = q(c3.x, c3.z, 1.7); mi2.rotation_degrees.y = gy
		mi2.visibility_range_end = 230.0     # the far tier (from 218 m) is a closed wall
		shutters.add_child(mi2)
		var sb := StaticBody3D.new(); var cs2 := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = bm.size
		cs2.shape = bs; sb.add_child(cs2); sb.position = mi2.position; sb.rotation_degrees.y = gy; shutters.add_child(sb)
	# ---- new kit props (batch 2): bus-stop signs at the stops, vending by the food kiosks, wheel stops in every stall
	for sx4: float in [-1.0, 1.0]:
		I.add(props, "prop_bus_stop_sign", "worn", q(sx4 * 6.2, -71.6), -90.0 * sx4)   # head of the bus zone, clear of the lot apron
	for k10 in 2:
		var fx2 := -48.0 + k10 * 96.0
		I.add(props, "prop_vending_soda", "worn", q(fx2 - 3.0, fz0 + 5.5), 180.0)    # beside the kiosk, facing the plaza
		I.add(props, "prop_vending_snack", "worn", q(fx2 + 3.0, fz0 + 5.5), 180.0)
	SL.wheel_stops(props, rr, stalls)
	# ---- perimeter: chain-link with posts, the entry gap on the north, a rolling gate on the south service side
	var e0 := Vector2(-HX + 0.3, -HZ + 0.3); var e1 := Vector2(HX - 0.3, -HZ + 0.3)
	var e2 := Vector2(HX - 0.3, HZS - 0.3); var e3 := Vector2(-HX + 0.3, HZS - 0.3)
	I.lot_fence(props, e0, Vector2(-9.4, -HZ + 0.3)); I.lot_fence(props, Vector2(9.4, -HZ + 0.3), e1)
	I.lot_fence(props, e1, e2); I.lot_fence(props, e3, e0)
	I.lot_fence(props, e2, Vector2(4.0, HZS - 0.3)); I.lot_fence(props, Vector2(-4.0, HZS - 0.3), e3)
	I.add(props, "fence_gate_rolling_chainlink", "worn", q(-6.9, HZS - 0.8), 0.0)
	# ---- floor + wear
	# the floor in five regions: a paint line only splits the region it is in (one rect: 26k tris, 17 Nov)
	var ex := SHX + RING + DRIVE + 0.01
	for rg: Array in [[-HX, -HZ, -ex, HZ], [ex, -HZ, HX, HZ], [-ex, -HZ, ex, pz0], [-ex, fz1, ex, HZ], [-ex, pz0, ex, fz1], [-HX, HZ, HX, HZS]]:
		K.painted_rect(g, float(rg[0]), float(rg[1]), float(rg[2]), float(rg[3]), paints, S.walk_y, "asphalt")
	SL.stall_wear(dec, rr, stalls, 0.8)
	SL.aisle_wear(dec, rr, 1.0, 1.0, -86.0, -12.0, -80.5)
	SL.aisle_wear(dec, rr, 1.0, 1.0, 12.0, 86.0, -80.5)
	for side3: float in [-1.0, 1.0]:
		var dx := side3 * (SHX + RING + DRIVE * 0.5)
		var zz := -90.0
		while zz < 90.0:
			for o: float in [-0.9, 0.9]: dec.add(14, Vector2(dx + o, zz + 3.0), 0.0, 0.6, 6.0, S.walk_y, Color(1, 1, 1, 0.3))
			zz += rr.randf_range(7.0, 10.0)
	
	# lots only (17 Nov, Yasin: "the dark patches on the ground in front of the stadium look terrible, clean them"):
	# no wear marks on the forecourt ring and the gate plaza
	for rg2: Array in [[-HX, -HZ, -ex, HZ], [ex, -HZ, HX, HZ], [-ex, -HZ, -9.2, pz0], [9.2, -HZ, ex, pz0], [-ex, fz1, ex, HZ]]:
		I.yard_wear(dec, rr, 1.0, 1.0, float(rg2[0]), float(rg2[1]), float(rg2[2]), float(rg2[3]), 0.35)
	root.set_meta("stalls", stalls)
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("st_stadium: ground tris %d, props %d, stalls %d" % [g.tri_count(), props.count(), stalls.size()])
	K.save_piece(root, "st_stadium")
	quit()
