extends SceneTree
## Piece n_un_east (university campus, the student side): u -510 .. -409.2 (the east street's walk), v -700 .. -510.
## Grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner): where students eat, buy books and hang out, at the end of the Quad's east paseo. UNION PLAZA runs
## along the buildings' fronts: the STUDENT UNION (civ_community_center, its COMMUNITY CENTER sign painted on: the
## food court inside) on the paseo line, the CAMPUS CAFE (com_cafe_seaside) north of it, the BOOKSTORE
## (ck_svc_trade_1d) south of it, tables with umbrellas between them. North of the cafe the UNION LAWN with the
## BANDSTAND for lunchtime concerts; south the SAND VOLLEYBALL court by the dorms. Behind, off the east street's two
## aprons (v -657 in, v -543 out), the SERVICE ROAD with the staff's stalls and the three buildings' delivery aprons.
## LAND (Yasin: "build according to it"): the ground follows the land (n_un_site.g); buildings on level pads at their fronts' height. The union's door is 0.3 m up: steps.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const Wr := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const U := preload("res://tools/city/pilot/pieces/n_un_site.gd")

const X0 := -510.0
const X1 := -409.2
const Z0 := -700.0
const Z1 := -510.0
## all face west (yaw -90), fronts on the plaza at u -500
const B := [
	["union", "civic/civ_community_center", -489.05, -602.0, -90.0, 0.3],   # door v -602 (the paseo's line)
	["cafe", "commercial/com_cafe_seaside", -491.83, -645.0, -90.0, 0.0],   # door v -646.76
	["bookstore", "ck/ck_svc_trade_1d", -494.0, -560.0, -90.0, 0.0],        # door v -563
]
const ROAD := [-440.0, -432.0]
const STALL := [-432.0, -426.5]
const SAND := [-474.0, -535.0, -454.0, -521.0]

const ITEMS := [
	# Union Plaza: tables with umbrellas between the buildings, benches along the paseo edge, bins, racks, a fountain
	["prop_patio_set_4", "worn", -494.0, -628.0, 0.0],
	["prop_patio_set_4", "worn", -487.0, -624.0, 30.0],
	["prop_patio_set_4", "worn", -494.0, -620.0, 60.0],
	["prop_patio_set_4", "worn", -480.0, -630.0, 15.0],
	["prop_patio_set_4", "worn", -494.0, -582.0, 0.0],
	["prop_patio_set_4", "worn", -486.0, -578.0, 45.0],
	["prop_park_bench", "worn", -508.6, -640.0, 90.0], ["prop_park_bench", "worn", -508.6, -625.0, 90.0],
	["prop_park_bench", "worn", -508.6, -580.0, 90.0], ["prop_park_bench", "worn", -508.6, -565.0, 90.0],
	["prop_trash_receptacle", "worn", -501.0, -617.0, 0.0], ["prop_recycling_receptacle", "worn", -501.0, -587.0, 0.0],
	["prop_trash_receptacle", "worn", -476.0, -636.0, 0.0], ["prop_trash_receptacle", "worn", -501.0, -655.0, 0.0],
	["prop_bike_rack", "worn", -503.5, -594.0, 90.0], ["prop_bike_rack", "worn", -503.5, -610.0, 90.0],
	["prop_bike_rack", "worn", -503.5, -655.0, 90.0], ["prop_bike_rack", "worn", -503.5, -570.0, 90.0],
	["prop_vending_soda", "worn", -481.4, -616.3, 0.0], ["prop_drinking_fountain", "worn", -478.5, -616.6, 0.0],
	["prop_newspaper_box_red", "worn", -501.2, -598.4, -90.0], ["prop_newspaper_box_blue", "worn", -501.2, -606.0, -90.0],
	["prop_usps_collection_box", "worn", -501.2, -570.0, -90.0],
	["prop_lamp_victorian", "worn", -509.2, -660.0, 0.0], ["prop_lamp_victorian", "worn", -509.2, -632.0, 0.0],
	["prop_lamp_victorian", "worn", -509.2, -572.0, 0.0], ["prop_lamp_victorian", "worn", -509.2, -540.0, 0.0],
	# Union Lawn: the bandstand at its east end facing west over the lawn; students on the grass; trees round it
	["prop_bandstand", "worn", -462.0, -680.0, -90.0],
	["prop_adirondack_white", "worn", -490.0, -682.0, 80.0], ["prop_adirondack_wood", "worn", -489.0, -679.0, 110.0],
	["prop_adirondack_white", "worn", -484.0, -688.0, 60.0], ["prop_adirondack_wood", "worn", -482.0, -672.0, 120.0],
	["prop_picnic_table", "worn", -495.0, -692.0, 0.0], ["prop_picnic_table", "worn", -495.0, -666.0, 0.0],
	["prop_sprinkler_impact", "normal", -475.0, -685.0, 0.0, false],
	# the volleyball court: benches either side, a bin; trees beyond
	["prop_park_bench", "worn", -464.0, -537.0, 0.0], ["prop_park_bench", "worn", -464.0, -519.0, 180.0],
	["prop_trash_receptacle", "worn", -476.0, -537.4, 0.0], 
	# the east street's strip: palms; the service road's end trees
	
	
]

var PY: Array = []     # pad heights (local), one per row of B: the ground at the middle of each front

## POLISH (19 Nov, Yasin: "run a polish pass on the whole zone, plenty of relevant props, lots of life"): trees on open
## lawn away from the buildings, shrubs and sprinklers nearer them, benches / picnic tables / garden chairs where people
## sit (gardens, courts, lawns), benches, planters, bins, racks, fountains and paper boxes on the wide paving; each on a
## free spot this piece already had (found by a scratch tool, OUT/py/freespots_hp.py, chosen per kind of place, frozen
## here), standing on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["prop_picnic_table", "worn", -509.8, -699.8, -176.8],
	["prop_park_bench", "worn", -488.2, -693.2, 175.7],
	["prop_adirondack_wood", "worn", -469.8, -699.8, 173.1],
	["prop_adirondack_white", "worn", -451.8, -690.2, 168.5],
	
	["prop_park_bench", "worn", -505.8, -670.2, -181.0],
	["prop_picnic_table", "worn", -493.8, -688.8, -192.4],
	["prop_park_bench", "worn", -484.2, -686.8, 169.7],
	["prop_adirondack_wood", "worn", -472.8, -680.2, 166.6],
	["prop_adirondack_white", "worn", -449.8, -680.2, 159.9],
	
	["prop_park_bench", "worn", -509.8, -658.2, -90.0],
	["prop_park_bench", "worn", -493.2, -662.8, -205.6],
	
	["prop_picnic_table", "worn", -448.2, -661.8, 96.1],
	["prop_trash_receptacle", "worn", -493.2, -637.2, 0.0],
	["plant_bird_of_paradise", "normal", -465.2, -639.2, 61.0],
	["plant_agave_americana", "normal", -442.8, -633.2, 122.0],
	["prop_bike_rack", "worn", -509.8, -612.2, -90.0],
	["prop_park_bench", "worn", -492.2, -617.8, -180.0],
	["plant_potted_succulent", "normal", -473.2, -629.2, 0.0],
	
	["prop_drinking_fountain", "worn", -503.8, -596.2, -90.0],
	["plant_bougainvillea_mound", "normal", -459.8, -603.2, 183.0],
	["prop_sprinkler_impact", "normal", -442.8, -591.8, 244.0, false],
	["prop_newspaper_box_blue", "worn", -509.8, -570.8, -90.0],
	["prop_recycling_receptacle", "worn", -494.8, -577.8, 0.0],
	["prop_park_bench", "worn", -481.8, -580.8, 0.0],
	["plant_agave_americana_small", "normal", -466.8, -572.8, 305.0],
	["plant_bird_of_paradise", "normal", -442.8, -583.8, 6.0],
	["plant_potted_leafy", "normal", -509.8, -560.8, 0.0],
	["plant_agave_americana", "normal", -468.8, -563.8, 67.0],
	["prop_sprinkler_impact", "normal", -442.8, -563.8, 128.0, false],
	["prop_trash_receptacle", "worn", -509.8, -538.2, 0.0],
	["plant_iceplant_patch", "normal", -496.8, -549.2, 189.0, false],
	
	
	["plant_agave_americana_small", "normal", -409.8, -548.8, 250.0],
	["prop_park_bench", "worn", -502.8, -517.2, 0.0],
]

## SUPERCHECKER (19 Nov, Yasin: "use super checker in your entire zone and weed out the unnecessary parts ... be very
## prone to delete"): tools/city/super/sc.py check on this piece; every finding with no plainly safe place is a
## deletion (its reason on its line), lamps turned back over their road, oil where no car stands out, a collision
## box on each building column with none. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [
	["prop_trash_receptacle", -501.0, -617.0, "bin_open: prop_trash_receptacle stands in the open (5.8 m from a wall, 265.0 m from a fence)"],
	["prop_trash_receptacle", -476.0, -636.0, "bin_open: prop_trash_receptacle stands in the open (10.7 m from a wall, 283.8 m from a fence)"],
	["prop_trash_receptacle", -501.0, -655.0, "bin_open: prop_trash_receptacle stands in the open (7.3 m from a wall, 255.4 m from a fence)"],
	["prop_trash_receptacle", -476.0, -537.40002, "bin_open: prop_trash_receptacle stands in the open (20.5 m from a wall, 321.4 m from a fence)"],
	["prop_trash_receptacle", -493.20001, -637.20001, "bin_open: prop_trash_receptacle stands in the open (4.8 m from a wall, 266.8 m from a fence)"],
	["prop_trash_receptacle", -509.79999, -538.20001, "bin_open: prop_trash_receptacle stands in the open (18.6 m from a wall, 292.4 m from a fence)"],
	["prop_recycling_receptacle", -501.0, -587.0, "bin_open: prop_recycling_receptacle stands in the open (5.8 m from a wall, 276.1 m from a fence)"],
	["prop_recycling_receptacle", -494.79999, -577.79999, "bin_open: prop_recycling_receptacle stands in the open (11.8 m from a wall, 285.6 m from a fence)"],
	["prop_patio_set_4", -494.0, -628.0, "no_reason: prop_patio_set_4 stands alone: no door within 18 m, no wall within 8 m, nothing to sit wit"],
	["prop_patio_set_4", -487.0, -624.0, "no_reason: prop_patio_set_4 stands alone: no door within 18 m, no wall within 8 m, nothing to sit wit"],
	["prop_patio_set_4", -480.0, -630.0, "no_reason: prop_patio_set_4 stands alone: no door within 18 m, no wall within 8 m, nothing to sit wit"],
	["prop_patio_set_4", -494.0, -582.0, "no_reason: prop_patio_set_4 stands alone: no door within 18 m, no wall within 8 m, nothing to sit wit"],
	["prop_patio_set_4", -486.0, -578.0, "no_reason: prop_patio_set_4 stands alone: no door within 18 m, no wall within 8 m, nothing to sit wit"],
	["prop_park_bench", -464.0, -537.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -464.0, -519.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -488.20001, -693.20001, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -505.79999, -670.20001, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -509.79999, -658.20001, "over_edge: prop_park_bench hangs over the edge of its block (2 of its 4 corners)"],
	["prop_park_bench", -481.79999, -580.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -502.79999, -517.20001, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_newspaper_box_blue", -509.79999, -570.79999, "over_edge: prop_newspaper_box_blue hangs over the edge of its block (2 of its 4 corners)"],
	["prop_adirondack_white", -451.79999, -690.20001, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_white", -449.79999, -680.20001, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_wood", -482.0, -672.0, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_wood", -469.79999, -699.79999, "over_edge: prop_adirondack_wood hangs over the edge of its block (2 of its 4 corners)"],
	["prop_adirondack_wood", -472.79999, -680.20001, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_picnic_table", -509.79999, -699.79999, "over_edge: prop_picnic_table hangs over the edge of its block (3 of its 4 corners)"],
	["prop_picnic_table", -448.20001, -661.79999, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["plant_agave_americana_small", -409.79999, -548.79999, "over_edge: plant_agave_americana_small hangs over the edge of its block (1 of its 4 corners)"],
	["plant_potted_leafy", -509.79999, -560.79999, "over_edge: plant_potted_leafy hangs over the edge of its block (2 of its 4 corners)"],
 ],
 "turn": [

 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/union", [0.839634895324707, 1.6999541819095612, 6.701925754547119, 0.16054443359375, 2.800045669078827, 0.16]],
	["Buildings/cafe", [1.0249133110046387, 1.4999818801879883, 6.8799638748168945, 0.16, 2.9999637603759766, 0.16]],
	["Buildings/bookstore", [-3.9000229835510254, 1.499967098236084, 5.650000095367432, 0.16, 2.999934196472168, 0.16]],
	["Buildings/bookstore", [-1.0400550365447998, 1.514954686164856, 7.659996747970581, 0.20003656387329102, 3.029909372329712, 0.19999937057495118]],
	["Buildings/bookstore", [-4.960036516189575, 1.514954686164856, 7.659996747970581, 0.20003656387329102, 3.029909372329712, 0.19999937057495118]],
	["Buildings/bookstore", [-2.1000688076019287, 1.499967098236084, 5.650000095367432, 0.16, 2.999934196472168, 0.16]],
 ],
}

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array:
	var st := K.building_stats(f)
	if st.has("near"): return (st.near as Dictionary).bbox
	var wd: Array = st.footprint_wd
	return [[-float(wd[0]) * 0.5, 0.0, -float(wd[1]) * 0.5], [float(wd[0]) * 0.5, 6.0, float(wd[1]) * 0.5]]
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]       # yaw -90

func _run() -> void:
	var root := Node3D.new(); root.name = "n_un_east"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := Wr.rng_for("n_un_east")
	var yb := func(x: float, z: float) -> float: return U.y(x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var yf := H.graded(yb, pe)
	var lot: Array = []
	var z := -650.0
	while z <= -550.0 + 0.01: lot.append([STALL[0], z - 0.05, STALL[1], z + 0.05, "white"]); z += 2.7
	var paints: Array = []
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	paints.append_array([
		[ROAD[0], -660.0, X1, -654.0, "asphalt"], [ROAD[0], -546.0, X1, -540.0, "asphalt"],    # in / out at the aprons
		[-480.55, -616.0, ROAD[0], -606.0, "asphalt"],                 # the union's delivery apron (back door v -611)
		[-484.38, -650.0, ROAD[0], -642.0, "asphalt"],                 # the cafe's (back door v -646.2)
		[-488.0, -561.0, ROAD[0], -553.0, "asphalt"],                  # the bookstore's (service door v -557)
		[X0, Z0 + 40.0, -500.0, Z1, "plaza"],                          # the plaza walk along the fronts
		[-500.0, -641.28, -470.0, -614.72, "plaza"],                   # the dining court north of the union
		[-500.0, -589.4, -470.0, -566.0, "plaza"],                     # ... and south of it
		[X0, Z0, -500.0, Z0 + 40.0, "grass"],
	])
	var regions := [[ROAD[0], -654.0, STALL[1], -546.0, "asphalt", lot], [SAND[0], SAND[1], SAND[2], SAND[3], "sand", []]]
	var main: Array = []
	for r: Array in regions: main.append([r[0], r[1], r[2], r[3], "-"])
	main.append_array(paints)
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf)
	H.paint(g, X0, Z0, X1, Z1, main, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	for i in B.size():
		var b: Array = B[i]
		var sill := float(b[5])
		var f := fp(b); var gy: float = yf.call(f[0], float(b[3])); var top := float(PY[i]) + sill
		if top - gy > 0.03:
			H.steps_x2(g, float(b[3]), 4.0, f[0] - ceilf((top - gy) / 0.17) * H.TREAD, f[0], gy, top, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.polish(props, g, POLISH)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_un_east")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the service road: wheel stops, a light, the exit's stop sign; dumpsters beside the delivery doors, condensers
	var z := -650.0 + 1.35
	while z < -550.0:
		P.call("prop_wheel_stop_concrete", "worn", STALL[1] - 0.6, z, 90.0); z += 2.7
	P.call("prop_lot_light_pole", "worn", -424.6, -600.0, 90.0)
	P.call("prop_sign_stop", "worn", -411.4, -538.6, -90.0)
	P.call("prop_sign_no_parking", "worn", -411.4, -661.6, -90.0)
	P.call("prop_dumpster_3yd_green", "worn", -479.2, -599.5, 90.0)
	P.call("prop_dumpster_3yd_blue", "worn", -479.2, -603.0, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", -482.6, -651.4, 90.0)
	P.call("prop_dumpster_3yd_blue", "worn", -486.6, -551.0, 90.0)
	for zz: float in [-596.0, -594.0, -592.0]: P.call("prop_ac_condenser", "worn", -479.8, zz, 90.0)
	Wr.lane_wear(dec, rr, -436.0, -654.0, -546.0, true, yf)
	for zz: float in [-611.0, -646.0, -557.0]: Wr.oil(dec, rr, Vector2(-452.0, zz), 90.0, yf, 0.5)
	# ---- the volleyball court: its net across the middle
	P.call("prop_volleyball_net", "worn", (SAND[0] + SAND[2]) * 0.5, (SAND[1] + SAND[3]) * 0.5, 90.0)
