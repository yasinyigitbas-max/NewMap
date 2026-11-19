extends SceneTree
## Piece n_cc_b1_court (city-centre fill, block 1, THE COURTHOUSE AND THE GARAGE; claude/fill-city-centre 19 Nov).
## Layout row (0, 6.0, -600), grid frame u = x, v = z - 600. Covers u -140..-50, v -740..-700 and the arm
## u -100..-50, v -700..-609.7 down to 7th St, between the civic block (city hall, west) and c_nw (east).
## LAND: flat. Land 5.97..6.10 m; the 7th St walk (s_rs_b098_fill), v_ne's edge, c_nw's alley and floor measured at
## 6.15: one pad at 6.15, flush on every side.
## PLANNER (the plan's MUST site "courthouse on the centre square, next to the police"): the courthouse faces 7th St on
## its own square, beside city hall (v_ne, 20 m west) and across 7th St from the police station (v_se): the civic heart
## is these three plus the memorial green. People: jurors, lawyers, defendants, families waiting outside, staff on a
## break. Parking: the district's public GARAGE (4 levels) in the middle of the block, entered from alley C (cars come
## from 6th St or C Ave down the alleys, never across Amber's walks): it serves the courthouse, city hall, the library
## and the Amber shops (the centre has no parking lanes). A pedestrian walk runs behind the garage to the court green,
## a small lawn between the garage and the law offices (lawyers' offices always cluster opposite a court), which face
## the green; their service backs are on alley A. A secure lane from alley C leads down the civic block's edge to the
## courthouse's walled sally port (prisoner transport and judges' cars), never through the public square.
## ARCHITECT: courthouse 12 m, 2 tall storeys, its steps on the square; garage 14 m; brick 3-storey law offices.
## EXTERIOR: the square: trees in wells, benches facing across the square, planters flanking the steps, globe lamps,
## steel bollards on the 7th St edge with a gap on the court's axis, papers, bins, bike racks, a drinking fountain.
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b1_court")
	# ---- ground: two pads (the block part and the arm) at the same level
	c.pad(-140.0, -140.0, -50.0, -100.0)
	c.pad(-100.0, -100.0, -50.0, -9.7)
	for w: Vector2 in [Vector2(-95.0, -24.0), Vector2(-95.0, -14.0), Vector2(-55.0, -24.0), Vector2(-55.0, -14.0)]: c.well(w.x, w.y)
	c.paint("plaza", -140.0, -108.0, -100.0, -100.0)                 # the garage walk to the court green
	c.paint("plaza", -94.0, -140.0, -68.0, -136.0)                   # green: walk along alley C
	c.paint("plaza", -94.0, -104.0, -68.0, -100.0)                   # green: walk from the garage walk
	c.paint("plaza", -72.0, -136.0, -68.0, -104.0)                   # green: walk in front of the law offices
	c.paint("grass", -94.0, -136.0, -72.0, -104.0)                   # the court green
	c.paint("grass", -100.0, -51.4, -90.2, -28.0)                    # courthouse west lawn
	c.paint("grass", -59.8, -75.0, -50.0, -28.0)                     # courthouse east lawn
	c.paint("plaza", -100.0, -28.0, -50.0, -9.7)                     # the courthouse square
	var tp := PackedVector2Array([Vector2(-88.0, -9.7)])
	for e: Vector2 in [Vector2(-89.0, -9.69), Vector2(-90.0, -9.663), Vector2(-91.0, -9.622), Vector2(-92.0, -9.57), Vector2(-93.0, -9.512), Vector2(-94.0, -9.45), Vector2(-95.0, -9.388), Vector2(-96.0, -9.33), Vector2(-97.0, -9.278), Vector2(-98.0, -9.237), Vector2(-99.0, -9.21), Vector2(-100.0, -9.2)]: tp.append(e)
	tp.append(Vector2(-100.0, -9.7))
	c.edge_poly("plaza", tp)
	c.build_floor(L.rect_edges(-140.0, -140.0, -50.0, -100.0) + L.rect_edges(-100.0, -100.0, -50.0, -9.7))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["c_nw", Vector3(0, 6, -600), 0.0], ["d_cc", Vector3(0, 6, -600), 0.0], ["v_ne", Vector3(-200, 6, -600), 0.0], ["s_rs_b098_fill", Vector3(0, 6, -600), 90.0], ["s_cc_10th", Vector3(0, 6, -600), 0.0]], O)
	var y := c.y0
	# ---- buildings
	var G := c.bld("extras/ext_parking_garage", Vector2(-120.45, -139.0), "n")
	var L1 := c.bld("ck/ck_brk3_row2_fe", Vector2(-68.0, -133.35), "w")
	var L2 := c.bld("ck/ck_brk3_row2", Vector2(-68.0, -120.97), "w")
	var L3 := c.bld("ck/ck_apt3_row2", Vector2(-68.0, -108.4), "w")
	var AN := c.bld("ck/ck_brk3_row2", Vector2(-59.0, -100.0), "n")
	var CH := c.bld("urban/urb_courthouse", Vector2(-75.0, -28.0), "s", true)
	# ---- garage mouth on alley C: pay station by the pedestrian side, bollards guarding the corners, wear
	c.put("prop_pay_station", "worn", Vector3(-112.6, y, -139.5), 180.0, "garage: pay station by the way out on foot")
	for bx: float in [-125.2, -115.7]: c.put("prop_bollard_concrete", "worn", Vector3(bx, y, -139.5), 0.0, "garage: bollards guard the door frame from cars cutting in")
	c.put("prop_sign_no_parking", "worn", Vector3(-110.8, y, -139.6), 180.0, "garage: no stopping in front of the gate")
	for k in 3: c.tyre(Vector2(-121.5 + k * 1.6, -139.5), 10.0 - k * 10.0, 3.0, 0.4)
	c.oil(Vector2(-120.5, -139.5), 0.0, 0.6)
	c.services(G, -12.0, 2, false, "left")
	# ---- the garage walk and the court green (who: people from the garage to the court, office staff at lunch)
	for bx2: float in [-136.0, -131.0]: c.put("prop_bike_rack", "worn", Vector3(bx2, y, -101.0), 0.0, "garage walk: bikes along the civic block's edge")
	c.put("prop_lamp_globe", "worn", Vector3(-128.0, y, -101.0), 0.0, "garage walk: lit at night")
	c.put("prop_lamp_globe", "worn", Vector3(-108.0, y, -101.0), 0.0, "garage walk: lit at night")
	c.put("plant_potted_leafy", "normal", Vector3(-102.0, y, -104.0), 0.0, "garage walk: planter where it meets the lane (keeps people off it)")
	for t: Array in [[-88.0, -130.0, "tree_ficus_a", 0.9], [-79.0, -119.0, "tree_jacaranda_a", 1.0], [-89.0, -109.0, "tree_coral_b", 0.9]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), y, float(t[1])), c.rr.randf_range(0, 360), "court green: shade trees in the lawn", true, float(t[3]))
	c.put("prop_park_bench", "worn", Vector3(-73.0, y, -126.5), -90.0, "court green: bench on the walk facing the lawn")
	c.put("prop_park_bench", "worn", Vector3(-73.0, y, -114.0), -90.0, "court green: bench on the walk facing the lawn")
	c.put("prop_picnic_table", "worn", Vector3(-84.0, y, -112.0), 0.0, "court green: lunch table on the lawn")
	c.put("prop_trash_receptacle", "worn", Vector3(-70.6, y, -104.6), 0.0, "court green: bin on the walk")
	c.put("prop_lamp_globe", "worn", Vector3(-70.5, y, -136.6), 0.0, "court green: lamp at the walk's corner")
	for r: Dictionary in [L1, L2]:
		for dr: Array in r.doors:
			if String(dr[0]) != "shopdoor": continue
			var dp: Vector3 = dr[1]
			for s: float in [-1.2, 1.2]: c.put("plant_potted_succulent", "normal", Vector3(dp.x - 0.4, y, dp.z + s * 1.08), 0.0, "law offices: pots by the door")
	# ---- law offices' service sides on alley A (their backs), the annex's on the east lawn
	c.services(L1, 3.0, 1, false); c.services(L2, 3.0, 1, false); c.services(L3, -2.0, 1, true)
	# (no dumpster: the offices' backs stand on alley A with no yard; their bins are the carts inside)
	c.services(AN, 3.0, 1, false)
	# ---- the secure lane and the sally port (walled, one rolling gate on the lane)
	_cmu(c, Vector2(-94.0, -72.0), Vector2(-68.2, -72.0), "sally port: block wall")
	_cmu(c, Vector2(-68.2, -72.0), Vector2(-68.2, -51.4), "sally port: block wall")
	_cmu(c, Vector2(-94.0, -72.0), Vector2(-94.0, -65.1), "sally port: block wall")
	c.put("fence_gate_rolling_chainlink", "worn", Vector3(-94.0, y, -62.0), 90.0, "sally port: the one gate, on the secure lane", false)
	_cmu(c, Vector2(-94.0, -58.9), Vector2(-94.0, -51.4), "sally port: block wall")
	_cmu(c, Vector2(-94.0, -51.4), Vector2(-89.8, -51.4), "sally port: block wall to the courthouse corner")
	c.stalls.append([-85.0, -63.0, 90.0]); c.stalls.append([-78.0, -63.0, 90.0])
	c.oil(Vector2(-85.0, -63.0), 90.0); c.oil(Vector2(-78.0, -63.0), 90.0)
	c.tyre(Vector2(-96.5, -62.0), 70.0, 5.0, 0.4)
	c.put("prop_tank_horizontal_propane", "worn", Vector3(-72.0, y, -68.0), 0.0, "sally port: fuel for the courthouse's standby generator")
	c.put("prop_switch_rack", "worn", Vector3(-71.6, y, -56.2), 90.0, "sally port: the courthouse's switchgear, out of public reach")
	c.services(CH, -8.0, 3, false)
	c.put("prop_transformer_substation", "worn", Vector3(-97.0, y, -80.0), 90.0, "courthouse: its transformer beside the secure lane")
	c.put("prop_sign_no_parking", "worn", Vector3(-99.6, y, -138.4), 0.0, "secure lane: authorised vehicles only")
	c.cracks(-99.6, -138.0, -94.4, -56.0, 12, 0.6)
	# east lawn: staff on a break (the annex's back door and the courthouse's side)
	c.put("prop_park_bench", "worn", Vector3(-52.0, y, -60.0), -90.0, "east lawn: staff on a break, facing the lawn")
	c.put("prop_trash_receptacle", "worn", Vector3(-52.0, y, -63.4), 0.0, "east lawn: the smokers' bin by the bench")
	c.put("tree_magnolia_b", "normal", Vector3(-55.0, y, -44.0), 40.0, "east lawn: shade tree", true, 0.9)
	c.put("tree_ficus_b", "normal", Vector3(-95.5, y, -44.0), 200.0, "west lawn: shade tree", true, 0.9)
	# ---- the courthouse square on 7th St
	for i in 4:
		var w2: Vector2 = [Vector2(-95.0, -24.0), Vector2(-95.0, -14.0), Vector2(-55.0, -24.0), Vector2(-55.0, -14.0)][i]
		c.put(["tree_jacaranda_a", "tree_ficus_a", "tree_ficus_b", "tree_jacaranda_b"][i], "normal", Vector3(w2.x, y - 0.06, w2.y), w2.x * 3.0 + w2.y, "square: shade trees in wells", false)
	c.put("prop_park_bench", "worn", Vector3(-95.4, y, -19.0), 90.0, "square: bench between the trees, facing across the square")
	c.put("prop_park_bench", "worn", Vector3(-54.6, y, -19.0), -90.0, "square: bench between the trees, facing across the square")
	c.put("prop_park_bench", "worn", Vector3(-89.0, y, -25.8), 0.0, "square: families wait for a hearing, facing the street")
	c.put("prop_park_bench", "worn", Vector3(-61.0, y, -25.8), 0.0, "square: families wait for a hearing, facing the street")
	for px: float in [-84.5, -65.5]: c.put("plant_potted_leafy", "normal", Vector3(px, y, -23.0), 0.0, "square: planters flanking the steps")
	for lp: Vector2 in [Vector2(-88.0, -15.0), Vector2(-62.0, -15.0), Vector2(-98.5, -30.5), Vector2(-51.5, -30.5)]:
		c.put("prop_lamp_globe", "worn", Vector3(lp.x, y, lp.y), 0.0, "square: globe lamps")
	var bxx := -99.0
	while bxx < -50.5:
		if absf(bxx + 75.0) > 5.5: c.put("prop_bollard_steel", "worn", Vector3(bxx, y, -10.4), 0.0, "square: bollards keep cars off the paving, a gap on the court's axis")
		bxx += 2.4
	c.put("prop_newspaper_box_red", "worn", Vector3(-82.2, y, -11.6), 0.0, "square: papers where people come up from the street")
	c.put("prop_newspaper_box_blue", "worn", Vector3(-81.4, y, -11.6), 0.0, "square: papers where people come up from the street")
	c.put("prop_trash_receptacle", "worn", Vector3(-68.2, y, -11.6), 0.0, "square: bin by the way in")
	c.put("prop_recycling_receptacle", "worn", Vector3(-67.4, y, -11.6), 0.0, "square: recycling beside the bin")
	for bx3: float in [-60.0, -56.0]: c.put("prop_bike_rack", "worn", Vector3(bx3, y, -12.0), 0.0, "square: bikes along the street edge, parallel to it")
	c.put("prop_drinking_fountain", "worn", Vector3(-98.8, y, -27.0), 90.0, "square: a fountain at the square's side")
	c.grime(Vector2(-75.0, -21.0), 0.0, 6.0, 2.4, 0.4)     # the foot of the steps: everyone stands here
	for gx: float in [-95.4, -54.6]: c.grime(Vector2(gx, -19.0), 0.0, 1.6, 2.0, 0.35)
	# ---- roofs
	# (the courthouse has a hipped roof: its HVAC stands on the ground in the sally port, see services above)
	c.roof_plant(G, [[-14.0, -12.0, "prop_vent_box"], [14.0, -12.0, "prop_vent_box"]], "garage: stair-tower exhaust")
	for r2: Dictionary in [L1, L2, L3, AN]:
		c.roof_plant(r2, [[-3.0, -3.0, "prop_ac_condenser_compact"], [3.0, -3.0, "prop_vent_plumbing"], [0.0, 2.0, "prop_vent_turbine"]], "roof plant (old brick offices)")
	c.finish()
	quit()

## CMU block wall from a to b: 2.03 m panels, the overlap shared (walls carry no posts)
static func _cmu(c, a: Vector2, b: Vector2, reason: String) -> void:
	var L2 := a.distance_to(b); var n := maxi(1, int(ceil(L2 / 2.03)))
	var dir := (b - a).normalized()
	var yaw := rad_to_deg(atan2(dir.x, dir.y)) + 90.0
	for i in n:
		var m: Vector2 = a + dir * (1.015 + (L2 - 2.03) * float(i) / float(n - 1)) if n > 1 else a.lerp(b, 0.5)
		c.put("fence_graffiti_cmu_panel" if i % 5 == 2 else "fence_cmu_wall", "worn", Vector3(m.x, c.y0, m.y), yaw, reason, false)
