extends SceneTree
## Piece n_un_north (university campus, the north row): u -790.8 (J Ave's walk) .. -409.2 (the east street's walk),
## v -790.8 (the north street's walk) .. -700 (the Quad, n_un_quad, and the side pieces). Grid [0, 4.0, 0], yaw 0.
##
## WHY (planner): the campus's front on the north street, where visitors arrive.
##  - UNIVERSITY CIRCLE (middle): the formal entrance. In at the north street's apron u -660, out at u -546 (one way,
##    anticlockwise); between the legs FOUNDERS GREEN with an avenue of canary palms and the founders' benches. On the
##    circle's south side the visitors' stalls and the drop-off opposite the walk to Founders Hall's back door (the
##    Quad beyond); the UNIVERSITY ART MUSEUM (pub_museum) and the CAMPUS CHAPEL (pub_chapel) face the circle from the
##    two ends of that side, their walks through gaps in the stalls.
##  - RECREATION (north-west): the CAMPUS REC CENTER (civ_rec_center) with its door on the north street (the
##    neighbourhood uses it too), its car park off J Ave's apron (v -746), two tennis courts and the rec field beside it.
##  - PARKING (north-east): the CAMPUS GARAGE (ext_parking_garage), its ramp on a short road from the east street's
##    apron (v -746), and the surface lot north of that road, reached also from the north street's apron (u -460).
## LAND: flat (6.150 = local 2.15). Raised doors (museum 0, chapel 0, rec center 0.3) get steps.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const Wr := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const U := preload("res://tools/city/pilot/pieces/n_un_site.gd")

const X0 := -790.8
const X1 := -409.2
const Z0 := -790.8
const Z1 := -700.0
## [label, folder, centre u, centre v, yaw, door sill]
const B := [
	["rec", "civic/civ_rec_center", -720.0, -771.05, 180.0, 0.3],          # front (door u -720) on the north street at v -782
	["museum", "public/pub_museum", -670.0, -712.6, 180.0, 0.0],           # front (door u -670) on the circle at v -727
	["chapel", "public/pub_chapel", -530.0, -716.9, 180.0, 0.0],           # front on the circle at v -727
	["garage", "extras/ext_parking_garage", -432.0, -723.7, 180.0, 0.0],   # front (ramp u -432) on the garage road at v -739
]
## University Circle: west leg, east leg, south cross road (v -743 .. -735)
const CW := [-661.0, -653.0]
const CE := [-547.0, -539.0]
const CS := [-743.0, -735.0]
const CSX := [-686.0, -512.0]          # the cross road runs on past both legs to the end stalls
## visitors' stalls on the circle's south side (heads south), with gaps for the museum's and the chapel's walks and
## the drop-off opposite the walk to Founders Hall
const VSTALL := [[-686.0, -673.0], [-667.0, -612.0], [-588.0, -536.0], [-524.0, -512.0]]
## rec: the drive from J Ave's apron, its car park (two aisles running north), tennis courts, the field
const RDRIVE := [-747.0, -739.0]
const RAISLES := [[-772.0, -765.0], [-752.0, -745.0]]
const COURTS := [[-786.0, -736.0, -769.0, -702.0], [-769.0, -736.0, -752.0, -702.0]]
const FIELD := [-744.0, -735.0, -694.0, -704.0]
## garage road (from the east apron) and the lot north of it
const GROAD := [-747.0, -739.0]
const LROWS := [[-752.5, -747.0], [-758.0, -752.5], [-770.5, -765.0]]
const LAISLE := [-765.0, -758.0]
const NAISLE := [-461.0, -453.0]
## the patches painted on their own: [u0, v0, u1, v1, base]
const REGIONS := [
	[-777.5, -783.0, -739.5, -747.0, "asphalt"],        # the rec car park
	[-686.0, -735.0, -512.0, -729.5, "asphalt"],        # the visitors' stalls
	[-500.0, -770.5, -415.0, -747.0, "asphalt"],        # the lot's rows and aisle
	[-786.0, -736.0, -752.0, -702.0, "concrete"],       # the tennis courts
	[-744.0, -735.0, -694.0, -704.0, "grass"],          # the rec field
]

const ITEMS := [
	# Founders Green: two rows of canary palms down the green, benches facing in, the university's flagless gateway
	# of two monuments at the green's street end, sprinklers
	["palm_canary_date_a", "normal", -630.0, -785.0, 0.0, false], ["palm_canary_date_b", "normal", -570.0, -785.0, 0.0, false],
	["palm_canary_date_b", "normal", -630.0, -770.0, 40.0, false], ["palm_canary_date_a", "normal", -570.0, -770.0, 40.0, false],
	["palm_canary_date_a", "normal", -630.0, -755.0, 80.0, false], ["palm_canary_date_b", "normal", -570.0, -755.0, 80.0, false],
	["prop_obelisk_monument", "worn", -612.0, -787.5, 0.0], ["prop_obelisk_monument", "worn", -588.0, -787.5, 0.0],
	["prop_park_bench", "worn", -622.0, -765.0, 90.0], ["prop_park_bench", "worn", -578.0, -765.0, -90.0],
	["prop_park_bench", "worn", -622.0, -755.0, 90.0], ["prop_park_bench", "worn", -578.0, -755.0, -90.0],
	["plant_bird_of_paradise", "normal", -640.0, -750.0, 0.0, false], ["plant_bird_of_paradise", "normal", -560.0, -750.0, 0.0, false],
	["prop_sprinkler_impact", "normal", -640.0, -770.0, 0.0, false], ["prop_sprinkler_impact", "normal", -560.0, -770.0, 0.0, false],
	["tree_jacaranda_a", "normal", -648.0, -786.0, 0.0, false], ["tree_jacaranda_b", "normal", -552.0, -786.0, 0.0, false],
	# the strip behind the visitors' stalls (v -729.5 .. -700): trees, a bench at the Founders walk
	["tree_magnolia_a", "normal", -640.0, -712.0, 0.0, false], ["tree_magnolia_b", "normal", -622.0, -712.0, 60.0, false],
	["tree_magnolia_b", "normal", -578.0, -712.0, 120.0, false], ["tree_magnolia_a", "normal", -560.0, -712.0, 180.0, false],
	["tree_coral_a", "normal", -515.0, -712.0, 0.0, false], ["tree_coral_b", "normal", -690.0, -704.0, 0.0, false],
	["prop_park_bench", "worn", -608.6, -716.0, 90.0], ["prop_park_bench", "worn", -591.4, -716.0, -90.0],
	["prop_trash_receptacle", "worn", -607.2, -727.6, 0.0], ["prop_lamp_victorian", "worn", -592.6, -727.6, 0.0],
	# rec: trees along J Ave, round the car park; the field's benches and a fountain; picnic tables by the courts
	["tree_eucalyptus_a", "normal", -788.6, -775.0, 0.0, false], ["tree_eucalyptus_b", "normal", -788.6, -760.0, 0.0, false],
	["tree_eucalyptus_a", "normal", -788.6, -725.0, 0.0, false], ["tree_eucalyptus_b", "normal", -788.6, -710.0, 0.0, false],
	["prop_park_bench", "worn", -720.0, -736.5, 0.0], ["prop_park_bench", "worn", -705.0, -736.5, 0.0],
	["prop_drinking_fountain", "worn", -712.5, -736.6, 0.0], ["prop_trash_receptacle", "worn", -726.0, -736.6, 0.0],
	["prop_picnic_table", "worn", -748.0, -712.0, 90.0], ["prop_picnic_table", "worn", -748.0, -722.0, 90.0],
	["tree_ficus_a", "normal", -748.0, -704.0, 0.0, false],
	# the garage and the lot: trees in the lot's island strip and the north buffer, the east street's palms
	["tree_jacaranda_b", "normal", -495.0, -785.0, 0.0, false], ["tree_jacaranda_a", "normal", -475.0, -785.0, 50.0, false],
	["tree_jacaranda_b", "normal", -440.0, -785.0, 100.0, false], ["tree_jacaranda_a", "normal", -420.0, -785.0, 150.0, false],
	["palm_mexican_fan_a", "normal", -411.4, -770.0, 0.0, false], ["palm_mexican_fan_b", "normal", -411.4, -720.0, 0.0, false],
	["palm_mexican_fan_c", "normal", -411.4, -705.0, 0.0, false],
	["tree_coral_a", "normal", -500.0, -704.0, 0.0, false], ["tree_coral_b", "normal", -470.0, -704.0, 0.0, false],
]

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]
	return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]     # all yaw 180 here

func _run() -> void:
	var root := Node3D.new(); root.name = "n_un_north"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := Wr.rng_for("n_un_north")
	var yf := func(x: float, z: float) -> float: return U.y(x, z)
	var paints: Array = []
	# stall lines: visitors (heads south, v -735 .. -729.5), rec car park (rows along its aisles), the lot's rows
	for s: Array in VSTALL:
		var x := float(s[0])
		while x <= float(s[1]) + 0.01: paints.append([x - 0.05, CS[1], x + 0.05, -729.5, "white"]); x += 2.7
	for a: Array in RAISLES:
		var z := -783.0
		while z <= -748.0 + 0.01:
			paints.append([float(a[0]) - 5.5, z - 0.05, float(a[0]), z + 0.05, "white"]); paints.append([float(a[1]), z - 0.05, float(a[1]) + 5.5, z + 0.05, "white"])
			z += 2.7
	for r: Array in LROWS:
		for seg: Array in [[-500.0, NAISLE[0]], [NAISLE[1], -415.0]]:
			var x := float(seg[0])
			while x <= float(seg[1]) + 0.01: paints.append([x - 0.05, float(r[0]), x + 0.05, float(r[1]), "white"]); x += 2.7
	# tennis courts: white boundary lines and the net line; the field's touch lines and halfway line
	for c: Array in COURTS:
		var cx := (float(c[0]) + float(c[2])) * 0.5; var cz := (float(c[1]) + float(c[3])) * 0.5
		for ln: Array in [[cx - 5.5, cz - 11.9, cx + 5.5, cz - 11.8], [cx - 5.5, cz + 11.8, cx + 5.5, cz + 11.9], [cx - 5.5, cz - 11.9, cx - 5.4, cz + 11.9],
				[cx + 5.4, cz - 11.9, cx + 5.5, cz + 11.9], [cx - 5.5, cz - 0.05, cx + 5.5, cz + 0.05], [cx - 0.05, cz - 6.4, cx + 0.05, cz + 6.4],
				[cx - 4.2, cz - 6.45, cx + 4.2, cz - 6.35], [cx - 4.2, cz + 6.35, cx + 4.2, cz + 6.45]]:
			paints.append([ln[0], ln[1], ln[2], ln[3], "white"])
	paints.append_array([[FIELD[0], FIELD[1], FIELD[2], FIELD[1] + 0.12, "white"], [FIELD[0], FIELD[3] - 0.12, FIELD[2], FIELD[3], "white"],
		[FIELD[0], FIELD[1], FIELD[0] + 0.12, FIELD[3], "white"], [FIELD[2] - 0.12, FIELD[1], FIELD[2], FIELD[3], "white"],
		[(FIELD[0] + FIELD[2]) * 0.5 - 0.06, FIELD[1], (FIELD[0] + FIELD[2]) * 0.5 + 0.06, FIELD[3], "white"]])
	paints.append([-657.08, -790.8, -656.92, -743.0, "white"]); paints.append([-543.08, -790.8, -542.92, -743.0, "white"])   # lane edge marks
	for b: Array in B:
		var f := fp(b); paints.append([f[0], f[1], f[2], f[3], "concrete"])
	paints.append_array([
		# University Circle
		[CW[0], Z0, CW[1], CS[1], "asphalt"], [CE[0], Z0, CE[1], CS[1], "asphalt"], [CSX[0], CS[0], CSX[1], CS[1], "asphalt"],
		[-612.0, CS[1], -588.0, -731.0, "asphalt"],                    # the drop-off lay-by
		[-612.0, -731.0, -588.0, -729.5, "plaza"], [-606.0, -729.5, -594.0, Z1, "plaza"],    # the walk to Founders Hall
		[-673.0, CS[1], -667.0, -729.5, "plaza"], [-536.0, CS[1], -524.0, -729.5, "plaza"],  # museum's and chapel's walks
		[-673.0, -729.5, -667.0, -727.0, "plaza"], [-536.0, -729.5, -524.0, -727.0, "plaza"],
		[-686.0, CS[1], -512.0, -729.5, "asphalt"],                    # the visitors' stalls
		[-653.0, -789.0, -547.0, -787.0, "plaza"],                     # the green's front walk between the monuments
		[-603.0, -787.0, -597.0, CS[0], "plaza"],                      # ... and down the green to the circle
		# recreation
		[X0, RDRIVE[0], -745.0, RDRIVE[1], "asphalt"],
		[RAISLES[0][0] - 5.5, -783.0, RAISLES[0][1] + 5.5, RDRIVE[0], "asphalt"],
		[RAISLES[1][0] - 5.5, -783.0, RAISLES[1][1] + 5.5, RDRIVE[0], "asphalt"],
		[COURTS[0][0], COURTS[0][1], COURTS[1][2], COURTS[0][3], "concrete"],
		[-745.0, -783.0, -732.45, -779.0, "plaza"],                    # the walk from the car park to the rec center's door
		[-732.45, -790.8, -707.28, -782.0, "plaza"],                   # the rec center's forecourt on the street
		[-744.0, -738.0, -694.0, -735.0, "plaza"],                     # the walk along the field
		# parking
		[-475.0, GROAD[0], X1, GROAD[1], "asphalt"],                   # the garage road
		[NAISLE[0], Z0, NAISLE[1], GROAD[0], "asphalt"],               # the lot's aisle from the north apron
		[-500.0, LAISLE[0], -415.0, LAISLE[1], "asphalt"],
		[-500.0, -770.5, -415.0, -747.0, "asphalt"],                   # the lot's rows
		[-450.45, -708.25, -413.55, -705.0, "plaza"], [-448.0, -705.0, -445.0, Z1, "plaza"],   # the garage's back door walk south
	])
	# (phone budget) the car parks, the courts and the field are painted as their own patches, so their stall and court
	# lines cut only their own patch, not the whole piece; the rest of the piece leaves them as holes
	var main: Array = []
	for r: Array in REGIONS: main.append([r[0], r[1], r[2], r[3], "-"])
	var subs: Array = []
	for r: Array in REGIONS: subs.append([])
	for p: Array in paints:
		var put := false
		for i in REGIONS.size():
			var r: Array = REGIONS[i]
			if float(p[0]) >= float(r[0]) - 0.01 and float(p[2]) <= float(r[2]) + 0.01 and float(p[1]) >= float(r[1]) - 0.01 and float(p[3]) <= float(r[3]) + 0.01:
				subs[i].append(p); put = true; break
		if not put: main.append(p)
	for i in REGIONS.size():
		var r: Array = REGIONS[i]
		H.paint(g, r[0], r[1], r[2], r[3], subs[i], String(r[4]), yf)
	H.paint(g, X0, Z0, X1, Z1, main, "grass", yf)
	for b: Array in B:
		var sill := float(b[5])
		if sill > 0.03:
			var f := fp(b); var gy := U.y(float(b[2]), float(b[3]))
			H.steps_z(g, float(b[2]), 4.0, f[1] - ceilf(sill / 0.17) * 0.3, f[1], gy, gy + sill)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	H.finish(root, g, props, dec, "n_un_north")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for b: Array in B: K.building(bl, String(b[1]), Vector3(b[2], U.y(float(b[2]), float(b[3])), b[3]), float(b[4]), String(b[0]))
	# ---- the circle: one-way, so a no-entry for the exit leg is a stop sign at its mouth; lamps on the green's edge,
	#      wheel stops in the visitors' stalls, a pay station at the drop-off
	P.call("prop_sign_stop", "worn", -537.6, -789.4, 0.0)
	for z: float in [-780.0, -760.0]:
		P.call("prop_lamp_cobra", "worn", -651.0, z, 90.0); P.call("prop_lamp_cobra", "worn", -549.0, z, -90.0)
	for s: Array in VSTALL:
		var x := float(s[0]) + 1.35
		while x < float(s[1]):
			P.call("prop_wheel_stop_concrete", "worn", x, -730.1, 0.0); x += 2.7
	P.call("prop_pay_station", "worn", -610.0, -730.2, 0.0)
	P.call("prop_sign_no_parking", "worn", -590.0, -730.2, 0.0)
	Wr.lane_wear(dec, rr, -739.0, CW[0], CE[1], false, yf)
	# ---- the museum's and the chapel's forecourts: a bench each side, planters
	P.call("plant_potted_leafy", "normal", -674.6, -727.6, 0.0, false); P.call("plant_potted_leafy", "normal", -665.4, -727.6, 0.0, false)
	P.call("plant_potted_succulent", "normal", -537.6, -727.6, 0.0, false); P.call("plant_potted_succulent", "normal", -522.4, -727.6, 0.0, false)
	# ---- recreation: wheel stops, a lot light, the courts' fences (a gate gap on the walk side), nets, benches by the
	#      courts, a bike rack and the bins at the rec center's door, the field's bench row
	for a: Array in RAISLES:
		var z := -783.0 + 1.35
		while z < -748.0:
			P.call("prop_wheel_stop_concrete", "worn", float(a[0]) - 4.9, z, 90.0); P.call("prop_wheel_stop_concrete", "worn", float(a[1]) + 4.9, z, 90.0)
			z += 2.7
	P.call("prop_lot_light_pole", "worn", -758.5, -766.0, 90.0)
	var ct := [COURTS[0][0], COURTS[0][1], COURTS[1][2], COURTS[0][3]]
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(ct[0], ct[1]), Vector2(ct[2], ct[1]), yf, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(ct[0], ct[3]), Vector2(ct[2], ct[3]), yf, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(ct[0], ct[1]), Vector2(ct[0], ct[3]), yf, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(ct[2], ct[1]), Vector2(ct[2], -721.0), yf, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(ct[2], -717.0), Vector2(ct[2], ct[3]), yf, 2.0)
	for c: Array in COURTS: P.call("prop_tennis_net", "worn", (float(c[0]) + float(c[2])) * 0.5, (float(c[1]) + float(c[3])) * 0.5, 0.0)
	P.call("prop_bike_rack", "worn", -712.0, -784.5, 0.0)
	P.call("prop_trash_receptacle", "worn", -727.0, -784.2, 0.0)
	P.call("prop_recycling_receptacle", "worn", -713.0, -786.5, 0.0)
	P.call("prop_lamp_victorian", "worn", -734.0, -788.4, 0.0)
	P.call("prop_ac_condenser", "worn", -705.8, -770.0, -90.0); P.call("prop_ac_condenser", "worn", -705.8, -772.0, -90.0)
	P.call("prop_dumpster_3yd_green", "worn", -734.2, -765.0, 90.0)
	# ---- parking: wheel stops in the lot's rows, lot lights in the island strip, the garage's pay station and sign
	for r: Array in LROWS:
		var head := float(r[0]) + 0.6 if absf(float(r[0]) - (-752.5)) < 0.1 or absf(float(r[0]) - (-770.5)) < 0.1 else float(r[1]) - 0.6
		for seg: Array in [[-500.0, NAISLE[0]], [NAISLE[1], -415.0]]:
			var x := float(seg[0]) + 1.35
			while x < float(seg[1]):
				P.call("prop_wheel_stop_concrete", "worn", x, head, 0.0); x += 2.7
	for x: float in [-490.0, -468.0, -440.0, -420.0]: P.call("prop_lot_light_pole", "worn", x - 0.35, -752.5, 0.0)
	P.call("prop_pay_station", "worn", -452.0, -737.6, 0.0)
	P.call("prop_sign_no_parking", "worn", -411.0, -738.0, 0.0)
	Wr.lane_wear(dec, rr, -743.0, -470.0, X1, false, yf)
	for x: float in [-485.0, -446.0, -430.0]: Wr.oil(dec, rr, Vector2(x, -755.25), 0.0, yf, 0.5)
