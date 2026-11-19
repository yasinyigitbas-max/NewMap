extends SceneTree
## Piece n_un_south (university campus, the south row): u -790.8 (J Ave's walk) .. -409.2 (the east street's walk),
## v -510 (the Quad / the side pieces) .. -409.2 (the south street's walk). Grid [0, 4.0, 0], yaw 0.
##
## WHY (planner): where the students live, and the campus's back door.
##  - WEST DORMS (south-west, the campus's low corner): two residence halls (apt_court_white, apt_garden_mint) with
##    their doors on the south street, each on its own level terrace at its front's height; their courtyard behind
##    (grills, tables, washing lines, bike racks); their car park on a drive from J Ave's apron (v -457).
##  - SOUTH LOOP (middle): in at the south street's apron u -657, out at u -543; on its north side the CAMPUS SHUTTLE
##    STOP (two shelters on a platform) and the LIBRARY PLAZA up to the library's back door; inside the loop the South
##    Green; two more halls (apt_spanish_revival) face the loop's legs.
##  - EAST DORMS (south-east): two student apartment blocks (apt_stucco3) on the south street, their car park on a drive
##    from the east street's apron (v -457) and the south street's (u -457).
## LAND: the campus's SW corner: the ground falls from 6.15 to 4.15 at (-790.8, -409.2) (n_un_site.g, at most 1.65 %);
## the drives, stalls and lawns follow it; every building stands on a level pad at its front's height with a retaining
## face round the pad where the field is higher or lower.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const Wr := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const U := preload("res://tools/city/pilot/pieces/n_un_site.gd")

const X0 := -790.8
const X1 := -409.2
const Z0 := -510.0
const Z1 := -409.2
## [label, folder, centre u, centre v, yaw]: residence halls, doors not walk-in
const B := [
	["dorm_w1", "apartments/apt_court_white", -768.0, -420.1, 0.0],        # front on the south street at v -414
	["dorm_w2", "apartments/apt_garden_mint", -720.0, -420.1, 0.0],
	["hall_lw", "apartments/apt_spanish_revival", -671.5, -440.0, 90.0],   # front on the loop's west leg at u -665
	["hall_le", "apartments/apt_spanish_revival", -528.5, -440.0, -90.0],  # front on the loop's east leg at u -535
	["apts_e1", "apartments/apt_stucco3_cream", -490.0, -422.1, 0.0],      # front on the south street at v -414
	["apts_e2", "apartments/apt_stucco3_peach", -430.0, -422.1, 0.0],
]
const WDRIVE := [-461.0, -453.0]        # west dorms' drive from J Ave (v), stalls both sides u -785 .. -737
const LW := [-661.0, -653.0]
const LE := [-547.0, -539.0]
const LX := [-486.0, -478.0]            # the loop's cross road (v)
const EDRIVE := [-461.0, -453.0]        # east dorms' drive from the east street (v), u -505 .. -409.2
const ELEG := [-461.0, -453.0]          # ... and its leg to the south street's apron (u)

const ITEMS := [
	# west dorms' courtyard (behind the halls): grills, tables, washing lines, racks; trees in the lawn
	["prop_bbq_kettle", "worn", -775.0, -433.0, 0.0], ["prop_picnic_table", "worn", -768.0, -435.0, 0.0],
	["prop_picnic_table", "worn", -726.0, -436.0, 90.0], ["prop_bbq_gas_cart", "worn", -716.0, -432.0, 180.0],
	["prop_clothesline", "worn", -745.0, -436.0, 0.0], ["prop_adirondack_wood", "worn", -705.0, -437.0, 200.0],
	["prop_adirondack_white", "worn", -702.5, -438.5, 160.0],
	["prop_bike_rack", "worn", -757.0, -428.6, 0.0], ["prop_bike_rack", "worn", -735.0, -428.6, 0.0],
	["tree_jacaranda_a", "normal", -786.0, -440.0, 0.0, false], ["tree_coral_b", "normal", -750.0, -442.0, 0.0, false],
	["tree_magnolia_a", "normal", -696.0, -442.0, 0.0, false],
	["prop_trash_cart_black", "worn", -779.2, -426.0, 90.0], ["prop_trash_cart_blue", "worn", -779.2, -424.9, 90.0],
	["prop_trash_cart_green", "worn", -706.2, -426.0, -90.0],
	# the south street front of the west dorms: low planting between the door paths, palms at the ends
	["palm_queen_a", "normal", -786.5, -411.5, 0.0, false], ["palm_queen_b", "normal", -744.0, -411.5, 0.0, false],
	["palm_queen_a", "normal", -697.0, -411.5, 0.0, false],
	# the South Loop: shuttle platform's racks and bins; the South Green's trees, benches, picnic tables
	["prop_bike_rack", "worn", -624.0, -493.0, 90.0], ["prop_bike_rack", "worn", -576.0, -493.0, 90.0],
	["tree_torrey_pine_a", "normal", -640.0, -465.0, 0.0, false], ["tree_torrey_pine_b", "normal", -560.0, -465.0, 0.0, false],
	["tree_jacaranda_b", "normal", -620.0, -430.0, 0.0, false], ["tree_jacaranda_a", "normal", -580.0, -430.0, 0.0, false],
	["prop_park_bench", "worn", -615.0, -455.0, 0.0], ["prop_park_bench", "worn", -585.0, -455.0, 0.0],
	["prop_picnic_table", "worn", -635.0, -440.0, 30.0], ["prop_picnic_table", "worn", -565.0, -440.0, 150.0],
	["prop_sprinkler_impact", "normal", -600.0, -445.0, 0.0, false], ["plant_bougainvillea_mound", "normal", -608.0, -418.0, 0.0, false],
	["prop_garden_arbor", "normal", -600.0, -411.0, 0.0],
	# the library plaza: benches facing the shuttle stop, planters
	["prop_park_bench", "worn", -612.0, -504.0, 180.0], ["prop_park_bench", "worn", -588.0, -504.0, 180.0],
	["plant_potted_leafy", "normal", -596.0, -508.6, 0.0, false], ["plant_potted_leafy", "normal", -586.0, -508.6, 0.0, false],
	# the loop halls' fronts: bike racks, bins
	["prop_bike_rack", "worn", -663.4, -452.0, 90.0], ["prop_bike_rack", "worn", -536.6, -452.0, 90.0],
	["prop_trash_cart_black", "worn", -679.0, -452.0, 0.0], ["prop_trash_cart_blue", "worn", -521.0, -452.0, 0.0],
	# east dorms: courtyard behind them, the strip on the east street
	["prop_picnic_table", "worn", -490.0, -437.0, 0.0], ["prop_bbq_kettle", "worn", -482.0, -436.0, 0.0],
	["prop_picnic_table", "worn", -430.0, -437.0, 90.0], ["prop_clothesline", "worn", -440.0, -440.5, 0.0],
	["prop_bike_rack", "worn", -500.0, -432.0, 0.0], ["prop_bike_rack", "worn", -420.0, -432.0, 0.0],
	["tree_coral_a", "normal", -470.0, -440.0, 0.0, false], ["tree_ficus_b", "normal", -505.0, -490.0, 0.0, false],
	["tree_jacaranda_b", "normal", -430.0, -490.0, 0.0, false], ["tree_magnolia_b", "normal", -470.0, -500.0, 0.0, false],
	["palm_mexican_fan_a", "normal", -411.4, -490.0, 0.0, false], ["palm_mexican_fan_b", "normal", -411.4, -425.0, 0.0, false],
]

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]
## a building's pad height (local): the ground at the middle of its front
static func pad_y(b: Array) -> float:
	var f := fp(b); var yaw: float = b[4]
	if absf(yaw) < 1.0: return U.y(float(b[2]), f[3])
	if absf(yaw - 90.0) < 1.0: return U.y(f[2], float(b[3]))
	return U.y(f[0], float(b[3]))

func _run() -> void:
	var root := Node3D.new(); root.name = "n_un_south"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := Wr.rng_for("n_un_south")
	var yf := func(x: float, z: float) -> float: return U.y(x, z)
	# patches with their stall lines: the west dorms' drive, the east dorms' drive
	var wl: Array = []; var el: Array = []
	var x := -785.0
	while x <= -737.0 + 0.01: wl.append([x - 0.05, -466.5, x + 0.05, -461.0, "white"]); wl.append([x - 0.05, -453.0, x + 0.05, -447.5, "white"]); x += 2.7
	for seg: Array in [[-505.0, -462.0], [-452.0, -415.0]]:
		x = float(seg[0])
		while x <= float(seg[1]) + 0.01: el.append([x - 0.05, -466.5, x + 0.05, -461.0, "white"]); el.append([x - 0.05, -453.0, x + 0.05, -447.5, "white"]); x += 2.7
	var regions := [[X0, -466.5, -735.0, -447.5, "asphalt", wl], [-505.0, -466.5, X1, -447.5, "asphalt", el]]
	var pads: Array = []
	for b: Array in B:
		var f := fp(b); pads.append([f[0] - 0.5, f[1] - 0.5, f[2] + 0.5, f[3] + 0.5, pad_y(b)])
	var main: Array = []
	for r: Array in regions: main.append([r[0], r[1], r[2], r[3], "-"])
	for p: Array in pads: main.append([p[0], p[1], p[2], p[3], "-"])
	main.append_array([
		[ELEG[0], -447.5, ELEG[1], Z1, "asphalt"],                     # the east dorms' leg to the south apron
		[LW[0], LX[0], LW[1], Z1, "asphalt"], [LE[0], LX[0], LE[1], Z1, "asphalt"], [LW[0], LX[0], LE[1], LX[1], "asphalt"],
		[-620.0, -490.0, -580.0, LX[0], "asphalt"],                    # the shuttle's lay-by
		[-622.0, -496.0, -578.0, -490.0, "plaza"],                     # the platform
		[-620.0, Z0, -580.0, -496.0, "plaza"],                         # the library plaza (back door u -591)
		[-603.0, LX[1], -597.0, -413.0, "plaza"],                      # the South Green's walk to the street
		[-665.0, -449.45, -661.0, -430.28, "plaza"], [-539.0, -449.72, -535.0, -430.55, "plaza"],   # the loop halls' front walks
		[X0, -414.0, -697.0, -412.0, "plaza"],                         # the west dorms' front walk
		[-505.0, -414.0, X1, -412.0, "plaza"],                         # the east dorms' front walk
	])
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf)
	H.paint(g, X0, Z0, X1, Z1, main, "grass", yf)
	# the pads: level at the front's height, faces to the field round them
	for p: Array in pads:
		H.level_pad(g, "concrete", p[0], p[1], p[2], p[3], float(p[4]), yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	H.finish(root, g, props, dec, "n_un_south")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for b: Array in B: K.building(bl, String(b[1]), Vector3(b[2], pad_y(b), b[3]), float(b[4]), String(b[0]))
	# ---- the dorms' drives: wheel stops at every stall, a lot light each, stop signs at the mouths
	var x := -785.0 + 1.35
	while x < -737.0:
		P.call("prop_wheel_stop_concrete", "worn", x, -465.9, 0.0); P.call("prop_wheel_stop_concrete", "worn", x, -448.1, 0.0); x += 2.7
	for seg: Array in [[-505.0, -462.0], [-452.0, -415.0]]:
		x = float(seg[0]) + 1.35
		while x < float(seg[1]):
			P.call("prop_wheel_stop_concrete", "worn", x, -465.9, 0.0); P.call("prop_wheel_stop_concrete", "worn", x, -448.1, 0.0); x += 2.7
	P.call("prop_lot_light_pole", "worn", -760.0, -468.4, 0.0)
	P.call("prop_lot_light_pole", "worn", -485.0, -468.4, 0.0)
	P.call("prop_sign_stop", "worn", -788.6, -451.6, 90.0)
	P.call("prop_sign_stop", "worn", -411.4, -451.6, -90.0)
	P.call("prop_sign_stop", "worn", -451.6, -411.4, 180.0)
	P.call("prop_dumpster_3yd_green", "worn", -733.6, -470.0, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", -507.0, -470.0, 90.0)
	for xx: float in [-770.0, -748.0]: Wr.oil(dec, rr, Vector2(xx, -463.7), 0.0, yf, 0.5)
	for xx: float in [-490.0, -437.0]: Wr.oil(dec, rr, Vector2(xx, -450.2), 0.0, yf, 0.5)
	# ---- the shuttle stop: two shelters facing the lay-by, the stop sign at the front bay, a bench between, lamps
	P.call("prop_bus_shelter", "worn", -611.0, -492.6, 0.0)
	P.call("prop_bus_shelter", "worn", -589.0, -492.6, 0.0)
	P.call("prop_bus_stop_sign", "worn", -582.0, -490.6, 0.0)
	P.call("prop_bench_bus_stop", "worn", -600.0, -492.8, 0.0)
	P.call("prop_trash_receptacle", "worn", -604.0, -494.8, 0.0)
	P.call("prop_lamp_victorian", "worn", -621.0, -497.0, 0.0)
	P.call("prop_lamp_victorian", "worn", -579.0, -497.0, 0.0)
	Wr.lane_wear(dec, rr, -482.0, LW[0], LE[1], false, yf)
	# ---- the loop: one-way: the exit's stop sign, lamps on the green's edge
	P.call("prop_sign_stop", "worn", -537.0, -411.4, 180.0)
	for z: float in [-465.0, -425.0]:
		P.call("prop_lamp_cobra", "worn", -651.0, z, 90.0); P.call("prop_lamp_cobra", "worn", -549.0, z, -90.0)
