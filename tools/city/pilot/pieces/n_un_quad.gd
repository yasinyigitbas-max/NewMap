extends SceneTree
## Piece n_un_quad (university campus, the middle): THE QUAD of CROWN BAY UNIVERSITY. u -690 .. -510, v -700 .. -510.
## Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner / architect): the campus's heart, where every student crosses several times a day. A lawn quad
## (120 m) framed by the walks every building opens onto: FOUNDERS HALL (pub_university: admissions and the
## president's office) at its north head, the UNIVERSITY LIBRARY (civ_library) facing it from the south, two lecture-hall
## wings (civ_school_wing) down each side. Cross walks meet at the founders' memorial in the middle; paseos between the
## wings lead out to the science side (west) and the student union (east). Students sit on the lawn (adirondack chairs,
## picnic tables at the corners), on benches along the walks facing the grass, cycle in and park at the racks by every
## door. Lamps along the frame walk, bins and recycling at the crossings, fountains, the student paper's boxes.
## LAND (Yasin: "build according to it"): the ground follows the land (n_un_site.g, 6.0 - 6.3 here); each building on a
## level pad at its front's height; the doors sit 0.3 m (wings, library) and 0.6 m (Founders Hall) over it: steps.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const Wr := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const U := preload("res://tools/city/pilot/pieces/n_un_site.gd")

const X0 := -690.0
const X1 := -510.0
const Z0 := -700.0
const Z1 := -510.0
const LAWN := [-660.0, -660.0, -540.0, -540.0]
const FRAME := [-668.0, -668.0, -532.0, -532.0]      # the frame walk's outer line (the building fronts)
## [label, folder, centre u, centre v, yaw, door sill over the ground]
const B := [
	["founders", "public/pub_university", -600.0, -681.3, 0.0, 0.6],     # front (door u -600) on the quad at v -668
	["library", "civic/civ_library", -600.0, -520.05, 180.0, 0.3],        # front (door u -600) on the quad at v -532
	["wing_nw", "civic/civ_school_wing", -677.95, -632.0, 90.0, 0.3],     # front (door v -632) on the quad at u -668
	["wing_sw", "civic/civ_school_wing", -677.95, -572.0, 90.0, 0.3],
	["wing_ne", "civic/civ_school_wing", -522.05, -632.0, -90.0, 0.3],    # front (door v -632) on the quad at u -532
	["wing_se", "civic/civ_school_wing", -522.05, -572.0, -90.0, 0.3],
]

## hand list: [base, cond, u, v, yaw(, collide)], stood on the ground as built (hs_fill_lib.polish)
const ITEMS := [
	# the founders' memorial in the middle of the cross walks, benches round it facing it
	["prop_obelisk_monument", "worn", -600.0, -600.0, 0.0],
	["prop_park_bench", "worn", -600.0, -606.2, 0.0], ["prop_park_bench", "worn", -600.0, -593.8, 180.0],
	["prop_park_bench", "worn", -606.2, -600.0, 90.0], ["prop_park_bench", "worn", -593.8, -600.0, -90.0],
	# jacarandas along the lawn's edge (in the grass, 1.5 m in), torrey pines at its four corners
	["tree_jacaranda_a", "normal", -645.0, -658.5, 0.0, false], ["tree_jacaranda_b", "normal", -620.0, -658.5, 40.0, false],
	["tree_jacaranda_a", "normal", -580.0, -658.5, 80.0, false], ["tree_jacaranda_b", "normal", -555.0, -658.5, 120.0, false],
	["tree_jacaranda_b", "normal", -645.0, -541.5, 160.0, false], ["tree_jacaranda_a", "normal", -620.0, -541.5, 200.0, false],
	["tree_jacaranda_b", "normal", -580.0, -541.5, 240.0, false], ["tree_jacaranda_a", "normal", -555.0, -541.5, 280.0, false],
	["tree_magnolia_a", "normal", -658.5, -645.0, 0.0, false], ["tree_magnolia_b", "normal", -658.5, -555.0, 60.0, false],
	["tree_magnolia_b", "normal", -541.5, -645.0, 120.0, false], ["tree_magnolia_a", "normal", -541.5, -555.0, 180.0, false],
	["tree_torrey_pine_a", "normal", -655.0, -655.0, 0.0, false], ["tree_torrey_pine_b", "normal", -545.0, -655.0, 90.0, false],
	["tree_torrey_pine_b", "normal", -655.0, -545.0, 180.0, false], ["tree_torrey_pine_a", "normal", -545.0, -545.0, 270.0, false],
	# students on the lawn: adirondack chairs in loose groups, picnic tables in the quarters
	["prop_adirondack_white", "worn", -630.0, -630.0, 30.0], ["prop_adirondack_white", "worn", -627.5, -631.5, 345.0],
	["prop_adirondack_wood", "worn", -628.5, -627.0, 160.0],
	["prop_adirondack_wood", "worn", -570.0, -628.0, 200.0], ["prop_adirondack_white", "worn", -567.0, -629.0, 230.0],
	["prop_adirondack_white", "worn", -632.0, -570.0, 60.0], ["prop_adirondack_wood", "worn", -629.5, -572.5, 20.0],
	["prop_adirondack_wood", "worn", -572.0, -568.0, 300.0], ["prop_adirondack_white", "worn", -569.0, -570.5, 260.0],
	["prop_adirondack_white", "worn", -566.5, -566.5, 220.0],
	["prop_picnic_table", "worn", -645.0, -615.0, 0.0], ["prop_picnic_table", "worn", -555.0, -615.0, 90.0],
	["prop_picnic_table", "worn", -645.0, -585.0, 90.0], ["prop_picnic_table", "worn", -555.0, -585.0, 0.0],
	["prop_picnic_table", "worn", -615.0, -645.0, 15.0], ["prop_picnic_table", "worn", -585.0, -555.0, 75.0],
	# benches along the frame walk, on its lawn side, facing the grass
	["prop_park_bench", "worn", -635.0, -661.0, 0.0], ["prop_park_bench", "worn", -565.0, -661.0, 0.0],
	["prop_park_bench", "worn", -635.0, -539.0, 180.0], ["prop_park_bench", "worn", -565.0, -539.0, 180.0],
	["prop_park_bench", "worn", -661.0, -615.0, 90.0], ["prop_park_bench", "worn", -661.0, -585.0, 90.0],
	["prop_park_bench", "worn", -539.0, -615.0, -90.0], ["prop_park_bench", "worn", -539.0, -585.0, -90.0],
	# lamps on the frame walk's outer side (between the doors), bins and recycling at the cross walks' ends
	["prop_lamp_victorian", "worn", -650.0, -666.8, 0.0], ["prop_lamp_victorian", "worn", -625.0, -666.8, 0.0],
	["prop_lamp_victorian", "worn", -575.0, -666.8, 0.0], ["prop_lamp_victorian", "worn", -550.0, -666.8, 0.0],
	["prop_lamp_victorian", "worn", -650.0, -533.2, 0.0], ["prop_lamp_victorian", "worn", -625.0, -533.2, 0.0],
	["prop_lamp_victorian", "worn", -575.0, -533.2, 0.0], ["prop_lamp_victorian", "worn", -550.0, -533.2, 0.0],
	["prop_lamp_victorian", "worn", -666.8, -655.0, 0.0], ["prop_lamp_victorian", "worn", -666.8, -602.0, 0.0],
	["prop_lamp_victorian", "worn", -666.8, -545.0, 0.0], ["prop_lamp_victorian", "worn", -533.2, -655.0, 0.0],
	["prop_lamp_victorian", "worn", -533.2, -602.0, 0.0], ["prop_lamp_victorian", "worn", -533.2, -545.0, 0.0],
	["prop_trash_receptacle", "worn", -604.0, -661.5, 0.0], ["prop_recycling_receptacle", "worn", -596.0, -661.5, 0.0],
	["prop_trash_receptacle", "worn", -604.0, -538.5, 0.0], ["prop_recycling_receptacle", "worn", -596.0, -538.5, 0.0],
	["prop_trash_receptacle", "worn", -661.5, -596.0, 0.0], ["prop_trash_receptacle", "worn", -538.5, -604.0, 0.0],
	["prop_drinking_fountain", "worn", -607.0, -609.0, 0.0], ["prop_drinking_fountain", "worn", -593.0, -591.0, 180.0],
	# the student paper's boxes and the bike racks by each door (beside the steps, never in front of them)
	["prop_newspaper_box_red", "worn", -606.0, -666.6, 0.0], ["prop_newspaper_box_blue", "worn", -594.0, -533.4, 180.0],
	["prop_bike_rack", "worn", -611.0, -665.5, 0.0], ["prop_bike_rack", "worn", -589.0, -665.5, 0.0],
	["prop_bike_rack", "worn", -611.0, -534.5, 0.0], ["prop_bike_rack", "worn", -589.0, -534.5, 0.0],
	["prop_bike_rack", "worn", -665.5, -640.0, 90.0], ["prop_bike_rack", "worn", -665.5, -580.0, 90.0],
	["prop_bike_rack", "worn", -534.5, -640.0, 90.0], ["prop_bike_rack", "worn", -534.5, -580.0, 90.0],
	# the paseos between the wings (v -616 .. -588): planters and a bench each side, a lamp
	["plant_potted_leafy", "normal", -684.0, -613.5, 0.0, false], ["plant_potted_leafy", "normal", -684.0, -590.5, 0.0, false],
	["plant_potted_leafy", "normal", -516.0, -613.5, 0.0, false], ["plant_potted_leafy", "normal", -516.0, -590.5, 0.0, false],
	["prop_park_bench", "worn", -676.0, -612.6, 0.0], ["prop_park_bench", "worn", -524.0, -591.4, 180.0],
	["prop_lamp_globe", "worn", -680.0, -596.0, 0.0], ["prop_lamp_globe", "worn", -520.0, -604.0, 0.0],
	# the corners outside the frame: low planting, sprinklers in the lawn
	["plant_agave_americana", "normal", -686.0, -696.0, 0.0, false], ["plant_agave_americana", "normal", -514.0, -696.0, 0.0, false],
	["plant_bougainvillea_mound", "normal", -686.0, -514.0, 0.0, false], ["plant_bougainvillea_mound", "normal", -514.0, -514.0, 0.0, false],
	["prop_sprinkler_impact", "normal", -630.0, -645.0, 0.0, false], ["prop_sprinkler_impact", "normal", -570.0, -645.0, 0.0, false],
	["prop_sprinkler_impact", "normal", -630.0, -555.0, 0.0, false], ["prop_sprinkler_impact", "normal", -570.0, -555.0, 0.0, false],
]

var PY: Array = []     # pad heights (local), one per row of B: the ground at the middle of each front

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(yaw - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]       # yaw -90

func _run() -> void:
	var root := Node3D.new(); root.name = "n_un_quad"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := Wr.rng_for("n_un_quad")
	var yb := func(x: float, z: float) -> float: return U.y(x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var yf := H.graded(yb, pe)
	var paints: Array = []
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	paints.append_array([
		[-607.0, -607.0, -593.0, -593.0, "plaza"],               # the memorial's square
		[-603.0, LAWN[1], -597.0, LAWN[3], "plaza"],             # the cross walks
		[LAWN[0], -603.0, LAWN[2], -597.0, "plaza"],
		[LAWN[0], LAWN[1], LAWN[2], LAWN[3], "grass"],           # the lawn
		[FRAME[0], FRAME[1], FRAME[2], FRAME[3], "plaza"],       # the frame walk round it (the building fronts)
		[X0, -616.0, FRAME[0], -588.0, "plaza"],                 # the west paseo between the wings
		[FRAME[2], -616.0, X1, -588.0, "plaza"],                 # the east paseo
		[-606.0, Z0, -594.0, -692.4, "plaza"],                   # past Founders Hall's back door to the entrance circle
		[-606.0, -510.55, -594.0, Z1, "plaza"],                  # past the library's back door to the south plaza
		[X0, -692.0, -616.62, -688.0, "plaza"], [-583.38, -692.0, X1, -688.0, "plaza"],    # the walk along the north side
	])
	H.paint(g, X0, Z0, X1, Z1, paints, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	# steps up to each front door (the building's door sill over its pad)
	for i in B.size():
		var b: Array = B[i]
		var f := fp(b); var fm := H.front_mid(f, float(b[4]))
		var gy: float = yf.call(fm.x, fm.y); var top := float(PY[i]) + float(b[5]); var n := ceilf((top - gy) / 0.17) * 0.3
		match int(b[4]):
			0: H.steps_z(g, float(b[2]), 4.0, f[3] + n, f[3], gy, top)
			180: H.steps_z(g, float(b[2]), 4.0, f[1] - n, f[1], gy, top)
			90: H.steps_x(g, float(b[3]), 4.0, f[2] + n, f[2], gy, top)
			-90: H.steps_x(g, float(b[3]), 4.0, f[0] - n, f[0], gy, top)
	if PASS >= 2:
		for i in B.size():
			var b: Array = B[i]
			K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
		H.polish(props, g, ITEMS)
		# wear: the cross walks' paving patched where the service carts run
		Wr.pale_patch(dec, rr, Vector2(-600.0, -630.0), 0.0, 2.0, 3.0, yf, 0.5)
		Wr.pale_patch(dec, rr, Vector2(-575.0, -600.0), 90.0, 1.6, 2.4, yf, 0.45)
	H.finish(root, g, props, dec, "n_un_quad")
	quit()
