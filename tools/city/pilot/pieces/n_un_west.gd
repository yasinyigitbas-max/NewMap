extends SceneTree
## Piece n_un_west (university campus, the science side): u -790.8 (J Ave's walk) .. -690, v -700 .. -510.
## Grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner): the sciences beside the Quad. The SCIENCE TOWER (twr_office, labs over a lobby) faces the Quad's west
## paseo, so the walk from the lecture halls runs straight to its door; the ENGINEERING LABS (civ_school_wing) north of
## it and the LAB WING (civ_school_wing) south of it face the same east walk. Behind them, off J Ave's two aprons
## (v -657 in, v -543 out), the FACULTY ROAD with the faculty's stalls along it and the labs' service aprons; between
## the road and the buildings the engineering students' SOLAR TEST FIELD (panels on gravel, fenced) and a grass yard.
## LAND (Yasin: "build according to it"): the ground follows the land (n_un_site.g), falling with J Ave toward the
## south-west; the road and the stalls follow it; each building on a level pad at its front's height.
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
	
	["prop_park_bench", "worn", -781.0, -600.0, 90.0], ["prop_park_bench", "worn", -781.0, -575.0, 90.0],
	# the east walk in front of the three doors: bike racks beside the steps, lamps, bins, planters, benches facing it
	["prop_bike_rack", "worn", -697.5, -652.0, 90.0], ["prop_bike_rack", "worn", -697.5, -668.0, 90.0],
	["prop_bike_rack", "worn", -697.5, -593.0, 90.0], ["prop_bike_rack", "worn", -697.5, -611.0, 90.0],
	["prop_bike_rack", "worn", -697.5, -537.0, 90.0], ["prop_bike_rack", "worn", -697.5, -553.0, 90.0],
	["prop_lamp_victorian", "worn", -691.2, -680.0, 0.0], ["prop_lamp_victorian", "worn", -691.2, -630.0, 0.0],
	["prop_lamp_victorian", "worn", -691.2, -575.0, 0.0], ["prop_lamp_victorian", "worn", -691.2, -525.0, 0.0],
	["prop_trash_receptacle", "worn", -691.4, -641.0, 0.0], ["prop_recycling_receptacle", "worn", -691.4, -563.0, 0.0],
	["prop_newspaper_box_red", "worn", -697.0, -616.6, 90.0], ["plant_potted_leafy", "normal", -699.0, -587.6, 0.0],
	["prop_park_bench", "worn", -691.0, -690.0, -90.0], ["prop_park_bench", "worn", -691.0, -516.0, -90.0],
	# the grass yard between the road and the buildings: trees, picnic tables for the labs' lunch, sprinklers
	
	["prop_picnic_table", "worn", -742.0, -585.0, 0.0], ["prop_picnic_table", "worn", -742.0, -565.0, 90.0],
	["prop_picnic_table", "worn", -735.0, -680.0, 0.0],
	["prop_sprinkler_impact", "normal", -745.0, -600.0, 0.0, false], ["prop_sprinkler_impact", "normal", -745.0, -530.0, 0.0, false],
	["plant_agave_americana", "normal", -726.0, -625.0, 0.0], ["plant_bird_of_paradise", "normal", -726.0, -578.0, 0.0],
]

var PY: Array = []     # pad heights (local), one per row of B: the ground at the middle of each front

## POLISH (19 Nov, Yasin: "run a polish pass on the whole zone, plenty of relevant props, lots of life"): trees on open
## lawn away from the buildings, shrubs and sprinklers nearer them, benches / picnic tables / garden chairs where people
## sit (gardens, courts, lawns), benches, planters, bins, racks, fountains and paper boxes on the wide paving; each on a
## free spot this piece already had (found by a scratch tool, OUT/py/freespots_hp.py, chosen per kind of place, frozen
## here), standing on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["plant_bird_of_paradise", "normal", -780.0, -694.8, 61.0],
	["prop_picnic_table", "worn", -747.0, -699.8, -152.0],
	["prop_park_bench", "worn", -732.0, -699.8, -151.0],
	["plant_agave_americana", "normal", -702.5, -698.8, 122.0],
	["prop_park_bench", "worn", -690.5, -692.8, 180.0],
	["plant_potted_leafy", "normal", -784.5, -685.8, 0.0],
	
	["prop_adirondack_wood", "worn", -754.0, -672.8, -91.2],
	["prop_adirondack_white", "worn", -744.5, -685.8, -96.8],
	["prop_park_bench", "worn", -733.0, -679.8, -160.7],
	["prop_picnic_table", "worn", -724.5, -671.8, -144.0],
	["prop_trash_receptacle", "worn", -697.5, -678.8, 0.0],
	["plant_bougainvillea_mound", "normal", -790.5, -663.8, 183.0],
	["prop_park_bench", "worn", -742.5, -666.8, -101.8],
	["prop_bike_rack", "worn", -691.5, -657.8, 90.0],
	["prop_sprinkler_impact", "normal", -780.0, -649.8, 244.0, false],
	["prop_adirondack_wood", "worn", -725.5, -639.8, -22.6],
	["prop_park_bench", "worn", -697.5, -636.2, 0.0],
	["plant_potted_succulent", "normal", -784.5, -621.8, 0.0],
	["prop_adirondack_white", "worn", -751.5, -619.8, -84.5],
	["prop_park_bench", "worn", -737.0, -617.8, -152.8],
	["prop_drinking_fountain", "worn", -697.5, -629.2, 180.0],
	["prop_newspaper_box_blue", "worn", -690.5, -621.8, 90.0],
	["plant_agave_americana_small", "normal", -779.5, -591.8, 305.0],
	["prop_picnic_table", "worn", -744.5, -604.8, -110.0],
	["prop_recycling_receptacle", "worn", -696.0, -602.2, 0.0],
	["prop_park_bench", "worn", -784.5, -589.2, -90.0],
	["prop_park_bench", "worn", -750.0, -587.8, -69.3],
	["prop_adirondack_wood", "worn", -739.5, -577.8, -33.1],
	["prop_adirondack_white", "worn", -730.5, -586.2, -18.7],
	["plant_bird_of_paradise", "normal", -703.0, -582.8, 6.0],
	["plant_potted_leafy", "normal", -690.5, -582.2, 0.0],
	["plant_agave_americana", "normal", -780.0, -551.2, 67.0],
	["prop_park_bench", "worn", -748.5, -568.8, -151.7],
	["prop_picnic_table", "worn", -736.0, -565.2, -142.8],
	["prop_park_bench", "worn", -725.5, -555.8, -124.8],
	["prop_sprinkler_impact", "normal", -715.0, -566.2, 128.0, false],
	["plant_iceplant_patch", "normal", -761.0, -536.2, 189.0, false],
	["prop_adirondack_wood", "worn", -749.0, -541.8, -70.3],
	["prop_adirondack_white", "worn", -737.5, -548.2, -66.6],
	["prop_park_bench", "worn", -726.5, -545.8, -122.8],
]

## SUPERCHECKER (19 Nov, Yasin: "use super checker in your entire zone and weed out the unnecessary parts ... be very
## prone to delete"): tools/city/super/sc.py check on this piece; every finding with no plainly safe place is a
## deletion (its reason on its line), lamps turned back over their road, oil where no car stands out, a collision
## box on each building column with none. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [
	["prop_park_bench", -691.0, -690.0, "no_reason (second check): prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -735.0, -680.0, "no_reason (second check): prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_trash_receptacle", -691.40002, -641.0, "bin_open: prop_trash_receptacle stands in the open (7.5 m from a wall, 38.6 m from a fence)"],
	["prop_trash_receptacle", -697.5, -678.79999, "bin_open: prop_trash_receptacle stands in the open (7.5 m from a wall, 50.6 m from a fence)"],
	["prop_recycling_receptacle", -691.40002, -563.0, "bin_open: prop_recycling_receptacle stands in the open (7.5 m from a wall, 70.5 m from a fence)"],
	["prop_recycling_receptacle", -696.0, -602.20001, "bin_open: prop_recycling_receptacle stands in the open (6.5 m from a wall, 39.3 m from a fence)"],
	["prop_solar_panel_x3", -747.20001, -637.5, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -743.59998, -637.5, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -740.0, -637.5, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -736.40002, -637.5, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -732.79999, -637.5, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -747.20001, -633.29999, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -743.59998, -633.29999, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -740.0, -633.29999, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -736.40002, -633.29999, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -732.79999, -633.29999, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -747.20001, -629.09998, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -743.59998, -629.09998, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -740.0, -629.09998, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -736.40002, -629.09998, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -732.79999, -629.09998, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -747.20001, -624.90002, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -743.59998, -624.90002, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -740.0, -624.90002, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -736.40002, -624.90002, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_solar_panel_x3", -732.79999, -624.90002, "on_path: prop_solar_panel_x3 stands in a narrow path"],
	["prop_park_bench", -781.0, -600.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -781.0, -575.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -691.0, -516.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -732.0, -699.79999, "over_edge: prop_park_bench hangs over the edge of its block (1 of its 4 corners)"],
	["prop_park_bench", -690.5, -692.79999, "over_edge: prop_park_bench hangs over the edge of its block (2 of its 4 corners)"],
	["prop_park_bench", -742.5, -666.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -697.5, -636.20001, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -737.0, -617.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -784.5, -589.20001, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -750.0, -587.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -748.5, -568.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -725.5, -555.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -726.5, -545.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["plant_potted_leafy", -784.5, -685.79999, "walk_narrow: plant_potted_leafy leaves 0.9 m of a 2.8 m wide walk"],
	["plant_potted_leafy", -690.5, -582.20001, "over_edge: plant_potted_leafy hangs over the edge of its block (2 of its 4 corners)"],
	["prop_picnic_table", -742.0, -585.0, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -742.0, -565.0, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -747.0, -699.79999, "over_edge: prop_picnic_table hangs over the edge of its block (2 of its 4 corners)"],
	["prop_picnic_table", -724.5, -671.79999, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -744.5, -604.79999, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -736.0, -565.20001, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["plant_agave_americana", -702.5, -698.79999, "over_edge: plant_agave_americana hangs over the edge of its block (1 of its 4 corners)"],
	["prop_adirondack_wood", -754.0, -672.79999, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_wood", -725.5, -639.79999, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_wood", -739.5, -577.79999, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_wood", -749.0, -541.79999, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_white", -744.5, -685.79999, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_white", -751.5, -619.79999, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_white", -730.5, -586.20001, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_white", -737.5, -548.20001, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["plant_bougainvillea_mound", -790.5, -663.79999, "over_edge: plant_bougainvillea_mound hangs over the edge of its block (2 of its 4 corners)"],
	["prop_park_bench", -733.0, -679.79999, "stray_bench: a bench stands beside a picnic table (the table has its own seats)"],
 ],
 "turn": [

 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/eng_labs", [0.8998880386352539, 1.6999541819095612, 5.699800491333008, 0.16, 2.800045669078827, 0.16]],
	["Buildings/lab_wing", [0.8998880386352539, 1.6999541819095612, 5.699800491333008, 0.16, 2.800045669078827, 0.16]],
 ],
}

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
	var yb := func(x: float, z: float) -> float: return U.y(x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var yf := H.graded(yb, pe)
	var lot: Array = []
	for s: Array in STALLS:
		var z := -652.0
		while z <= -548.0 + 0.01: lot.append([float(s[0]), z - 0.05, float(s[1]), z + 0.05, "white"]); z += 2.7
	var sol: Array = []
	for r in 4:
		sol.append([SOLAR[0] + 1.0, SOLAR[1] + 1.5 + 4.2 * r, SOLAR[2] - 1.0, SOLAR[1] + 3.5 + 4.2 * r, "concrete"])   # the panel rows' footings
	var paints: Array = []
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
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
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	for i in B.size():
		var b: Array = B[i]
		var sill := float(b[5])
		var f := fp(b); var gy: float = yf.call(f[2], float(b[3])); var top := float(PY[i]) + sill
		if top - gy > 0.03:
			H.steps_x2(g, float(b[3]), 4.0, f[2] + ceilf((top - gy) / 0.17) * H.TREAD, f[2], gy, top, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.polish(props, g, POLISH)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_un_west")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
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
