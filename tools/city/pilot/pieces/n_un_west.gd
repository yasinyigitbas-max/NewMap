extends SceneTree
## Piece n_un_west (university campus, the science side): u -790.8 (J Ave's walk) .. -690, v -700 .. -510.
## Grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner): the sciences beside the Quad. The SCIENCE TOWER (twr_office, labs over a lobby) faces the Quad's west
## paseo, so the walk from the lecture halls runs straight to its door; the ENGINEERING LABS (civ_school_wing) north of
## it and the LAB WING (civ_school_wing) south of it face the same east walk. Behind them, off J Ave's two aprons
## (v -657 in, v -543 out), the FACULTY ROAD with the faculty's stalls along it and the labs' service aprons; between
## the road and the buildings the engineering students' SOLAR TEST FIELD (panels on gravel, fenced) and a grass yard.
## LAND: flat at 6.150 except the south-west corner, which falls with J Ave to 5.33 at (-790.8, -510): the road and the
## stalls follow the surface (at most 1.65 %); the buildings stand where it is flat.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const Wr := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const U := preload("res://tools/city/pilot/pieces/n_un_site.gd")

const X0 := -790.8
const X1 := -690.0
const Z0 := -700.0
const Z1 := -510.0
## [label, folder, centre u, centre v, yaw, door sill]; all face east (yaw 90): front at u -700
const B := [
	["science", "urban/twr_office", -712.5, -602.0, 90.0, 0.0],
	["eng_labs", "civic/civ_school_wing", -709.95, -660.0, 90.0, 0.3],
	["lab_wing", "civic/civ_school_wing", -709.95, -545.0, 90.0, 0.3],
]
const ROAD := [-768.0, -760.0]          # the faculty road (u), from v -660 to -540
const IN := [-660.0, -654.0]             # J Ave's aprons
const OUT := [-546.0, -540.0]
const STALLS := [[-773.5, -768.0], [-760.0, -754.5]]
const SOLAR := [-750.0, -640.0, -730.0, -622.0]

const ITEMS := [
	# J Ave's strip: eucalyptus (the campus edge streets' trees), the edge walk's benches
	["tree_eucalyptus_a", "normal", -788.0, -690.0, 0.0, false], ["tree_eucalyptus_b", "normal", -788.0, -675.0, 0.0, false],
	["tree_eucalyptus_a", "normal", -788.0, -630.0, 0.0, false], ["tree_eucalyptus_b", "normal", -788.0, -615.0, 0.0, false],
	["tree_eucalyptus_a", "normal", -788.0, -585.0, 0.0, false], ["tree_eucalyptus_b", "normal", -788.0, -520.0, 0.0, false],
	["prop_park_bench", "worn", -781.0, -600.0, 90.0], ["prop_park_bench", "worn", -781.0, -575.0, 90.0],
	# the east walk in front of the three doors: bike racks beside the steps, lamps, bins, planters, benches facing it
	["prop_bike_rack", "worn", -697.5, -652.0, 90.0], ["prop_bike_rack", "worn", -697.5, -668.0, 90.0],
	["prop_bike_rack", "worn", -697.5, -593.0, 90.0], ["prop_bike_rack", "worn", -697.5, -611.0, 90.0],
	["prop_bike_rack", "worn", -697.5, -537.0, 90.0], ["prop_bike_rack", "worn", -697.5, -553.0, 90.0],
	["prop_lamp_victorian", "worn", -691.2, -680.0, 0.0], ["prop_lamp_victorian", "worn", -691.2, -630.0, 0.0],
	["prop_lamp_victorian", "worn", -691.2, -575.0, 0.0], ["prop_lamp_victorian", "worn", -691.2, -525.0, 0.0],
	["prop_trash_receptacle", "worn", -691.4, -641.0, 0.0], ["prop_recycling_receptacle", "worn", -691.4, -563.0, 0.0],
	["prop_newspaper_box_red", "worn", -697.0, -616.6, 90.0], ["plant_potted_leafy", "normal", -699.0, -587.6, 0.0, false],
	["prop_park_bench", "worn", -691.0, -690.0, -90.0], ["prop_park_bench", "worn", -691.0, -516.0, -90.0],
	# the grass yard between the road and the buildings: trees, picnic tables for the labs' lunch, sprinklers
	["tree_ficus_a", "normal", -742.0, -690.0, 0.0, false], ["tree_coral_a", "normal", -738.0, -575.0, 0.0, false],
	["tree_coral_b", "normal", -742.0, -520.0, 0.0, false], ["tree_jacaranda_b", "normal", -735.0, -610.0, 0.0, false],
	["prop_picnic_table", "worn", -742.0, -585.0, 0.0], ["prop_picnic_table", "worn", -742.0, -565.0, 90.0],
	["prop_picnic_table", "worn", -735.0, -680.0, 0.0],
	["prop_sprinkler_impact", "normal", -745.0, -600.0, 0.0, false], ["prop_sprinkler_impact", "normal", -745.0, -530.0, 0.0, false],
	["plant_agave_americana", "normal", -726.0, -625.0, 0.0, false], ["plant_bird_of_paradise", "normal", -726.0, -578.0, 0.0, false],
]

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]
	return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]     # yaw 90

func _run() -> void:
	var root := Node3D.new(); root.name = "n_un_west"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := Wr.rng_for("n_un_west")
	var yf := func(x: float, z: float) -> float: return U.y(x, z)
	var lot: Array = []
	for s: Array in STALLS:
		var z := -652.0
		while z <= -548.0 + 0.01: lot.append([float(s[0]), z - 0.05, float(s[1]), z + 0.05, "white"]); z += 2.7
	var sol: Array = []
	for r in 4:
		sol.append([SOLAR[0] + 1.0, SOLAR[1] + 1.5 + 4.2 * r, SOLAR[2] - 1.0, SOLAR[1] + 3.5 + 4.2 * r, "concrete"])   # the panel rows' footings
	var paints: Array = []
	for b: Array in B:
		var f := fp(b); paints.append([f[0], f[1], f[2], f[3], "concrete"])
	paints.append_array([
		[X0, IN[0] - 1.0, ROAD[1], IN[1] + 1.0, "asphalt"],           # in from J Ave
		[X0, OUT[0] - 1.0, ROAD[1], OUT[1] + 1.0, "asphalt"],         # out to J Ave
		[-754.5, -600.0, -724.0, -592.0, "asphalt"],                  # the science tower's service apron (door v -596)
		[-760.0, -664.0, -717.45, -644.0, "asphalt"],                 # the labs' service apron (back door v -648)
		[-700.0, Z0, X1, Z1, "plaza"],                                # the east walk the doors open onto
		[-717.45, -616.0, -700.0, -588.0, "plaza"],                   # the tower's forecourt on the paseo line
		[-786.0, Z0, -783.0, Z1, "plaza"],                            # the edge walk along J Ave
	])
	# patches: the road with its stalls, the solar field
	var regions := [[STALLS[0][0], -654.0, STALLS[1][1], -546.0, "asphalt", lot], [SOLAR[0], SOLAR[1], SOLAR[2], SOLAR[3], "gravel", sol]]
	var main: Array = []
	for r: Array in regions: main.append([r[0], r[1], r[2], r[3], "-"])
	main.append_array(paints)
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf)
	H.paint(g, X0, Z0, X1, Z1, main, "grass", yf)
	for b: Array in B:
		var sill := float(b[5])
		if sill > 0.03:
			var f := fp(b); var gy := U.y(float(b[2]), float(b[3]))
			H.steps_x(g, float(b[3]), 4.0, f[2] + ceilf(sill / 0.17) * 0.3, f[2], gy, gy + sill)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	H.finish(root, g, props, dec, "n_un_west")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for b: Array in B: K.building(bl, String(b[1]), Vector3(b[2], U.y(float(b[2]), float(b[3])), b[3]), float(b[4]), String(b[0]))
	# ---- the faculty road: wheel stops at the stalls' heads, two lot lights, the exit's stop sign, a no-entry at the exit
	var z := -652.0 + 1.35
	while z < -548.0:
		P.call("prop_wheel_stop_concrete", "worn", STALLS[0][0] + 0.6, z, 90.0); P.call("prop_wheel_stop_concrete", "worn", STALLS[1][1] - 0.6, z, 90.0)
		z += 2.7
	P.call("prop_lot_light_pole", "worn", -752.6, -630.0, 90.0)
	P.call("prop_lot_light_pole", "worn", -752.6, -570.0, 90.0)
	P.call("prop_sign_stop", "worn", -788.6, -538.4, 90.0)
	P.call("prop_sign_no_parking", "worn", -788.6, -661.8, 90.0)
	Wr.lane_wear(dec, rr, -764.0, -654.0, -546.0, true, yf)
	for zz: float in [-640.0, -601.0, -569.0]: Wr.oil(dec, rr, Vector2(-771.0, zz), 90.0, yf, 0.5)
	# ---- the service aprons: dumpsters against the walls beside the doors, condensers, the tower's transformer
	P.call("prop_dumpster_3yd_green", "worn", -725.4, -589.0, 90.0)
	P.call("prop_dumpster_3yd_blue", "worn", -725.4, -603.0, 90.0)
	P.call("prop_transformer_substation", "worn", -728.0, -610.5, 0.0)
	P.call("prop_dumpster_3yd_green", "worn", -718.8, -669.0, 90.0)
	for zz: float in [-674.4, -672.4]: P.call("prop_ac_condenser", "worn", -718.6, zz, 90.0)
	for zz: float in [-535.0, -533.0, -531.0]: P.call("prop_ac_condenser", "worn", -718.6, zz, 90.0)
	# ---- the solar test field: four rows of panels on their footings, a chain-link fence round it, gate on the yard side
	for r in 4:
		for k in 5: P.call("prop_solar_panel_x3", "worn", SOLAR[0] + 2.8 + 3.6 * k, SOLAR[1] + 2.5 + 4.2 * r, 0.0, false)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(SOLAR[0], SOLAR[1]), Vector2(SOLAR[2], SOLAR[1]), yf, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(SOLAR[0], SOLAR[3]), Vector2(SOLAR[2], SOLAR[3]), yf, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(SOLAR[0], SOLAR[1]), Vector2(SOLAR[0], SOLAR[3]), yf, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(SOLAR[2], SOLAR[1]), Vector2(SOLAR[2], -633.0), yf, 2.0)
	P.call("fence_gate_wrought_iron", "worn", SOLAR[2], -632.45, 90.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(SOLAR[2], -631.9), Vector2(SOLAR[2], SOLAR[3]), yf, 2.0)
