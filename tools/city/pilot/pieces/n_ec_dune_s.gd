extends SceneTree
## Piece n_ec_dune_s (ec fill, the east shore beyond the ring, south half, u 932 .. 1200, v -250 .. 0): the park's east
## lawn, the BEACH PROMENADE, the GRASS > SAND dune edge and the top of the sand, the DUNE CAFE and SOUTH BEACH RENTALS.
## Placed at grid [0, 0, 0], yaw 0 (x = u, z = v, y = world). Run once; never when locked.
##
## WHY (planner): two beach walks arrive here from the city: A200 (from the v -200 junction corner over the hill's
## south shoulder) and A0 (from the v 0 junction corner, the way the people from the waterfront and Glorietta Point
## come). Each ends at the PROMENADE (3 m paved along the dune line, lamps on its land side, bench pairs facing the sea)
## and goes on across the dune onto the sand (shower, rules and rip-current signs at the end of the paving).
## At A200: the DUNE CAFE (com_cafe_seaside, door to the promenade, terrace with tables under a sail by the walk).
## At A0: SOUTH BEACH RENTALS (com_surf_shop: kayaks, paddle boards, umbrellas), its kayak racks and closed umbrellas in
## its yard by the walk, bins on its walls, a bike rack on the forecourt. The dune edge: the grass turns to sand along
## the curving line (n_ec_site.DUNE: the 2.5 m contour bending west with the hill's foot, then held at u ~1003 on the
## low south flat), sand blown onto the grass, iceplant, dry dune grass and agaves on the first metres of sand.
## On the sand: volleyball courts at both accesses, umbrellas near A0. On the lawn: picnic tables with grills, beach
## chairs, sprinklers.
## LAND: 7.4 - 9 m at u 932 in the north falling to 2.6 at the dune line; on the south flat 1.1 - 1.5 m; 0.7 - 1.2 m at
## u 1200; the ground follows it (n_ec_site.g); both buildings on level pads, the field graded up to them.
## AFTER THE SUPERCHECKER PASS (20 Nov, delete when unsure): the cafe terrace's sail and bins, the dry dune-grass patches
## (banned grass tufts) and every wear mark on grass / sand (sand on the grass, footpaths, wet sand at the showers) are OUT
## (see SC and _wear).
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_ec_site.gd")

const Z0 := -250.0
const Z1 := 0.0
const B := [
	["cafe", "commercial/com_cafe_seaside", 1062.8, -214.0, 90.0],      # shop door at v -212.24 on the promenade side
	["rentals", "commercial/com_surf_shop", 983.05, -24.0, 90.0],       # shop door at v -20.74 on the promenade side
]
const A200 := [932.0, -201.5, 1090.0, -198.5]     # the beach walk on across the dune (dune line 1078 at v -200)
const A0 := [932.0, -9.5, 1016.0, -6.5]           # the beach walk on across the dune (dune line 1003.3 at v -8)
const FORE_C := [1071.0, -221.0, 1076.5, -201.5]  # the cafe's forecourt between its front and the promenade
const TERR_C := [1055.0, -209.6, 1071.0, -201.5]  # the cafe's terrace on its south side, down to A200
const FORE_R := [991.0, -33.0, 996.5, -9.5]       # the rental shop's forecourt to the promenade
const YARD_R := [975.0, -18.75, 991.0, -9.5]      # the rental shop's yard (racks) on its south side, down to A0

const ITEMS := [
	# the cafe's terrace: two tables with chairs under a sail (its staff door at u 1057.8 stays clear)
	["prop_patio_set_4", "worn", 1061.5, -205.5, 0.0], ["prop_patio_set_4", "worn", 1066.0, -205.5, 0.0],
	["prop_shade_sail", "worn", 1063.75, -205.5, 0.0],
	# its bins against the terrace wall, a bike rack and a lamp on its forecourt
	["prop_trash_receptacle", "dirty", 1069.0, -209.25, 0.0], ["prop_recycling_receptacle", "worn", 1068.1, -209.25, 0.0],
	["prop_bike_rack", "worn", 1073.5, -219.5, 90.0],
	["prop_lamp_victorian", "worn", 1071.6, -220.6, 0.0],
	# the rental shop's yard: two kayak racks against its south wall, closed umbrellas for hire by the door corner
	["prop_kayak_rack", "worn", 979.6, -17.6, 0.0], ["prop_kayak_rack", "worn", 984.6, -17.6, 0.0],
	["prop_beach_umbrella_closed", "worn", 988.6, -18.3, 0.0], ["prop_beach_umbrella_closed", "worn", 989.5, -18.3, 0.0],
	# its bins against the north wall, a bike rack and a lamp on the forecourt
	["prop_trash_receptacle", "dirty", 985.0, -29.6, 0.0], ["prop_recycling_receptacle", "worn", 986.0, -29.6, 0.0],
	["prop_bike_rack", "worn", 993.5, -31.0, 90.0],
	["prop_lamp_victorian", "worn", 991.6, -32.4, 0.0],
	# the accesses' ends on the sand: showers north of the paving, rules and rip-current signs facing people walking out
	["prop_beach_shower", "worn", 1088.5, -203.2, 0.0],
	["prop_beach_sign_rules", "worn", 1091.6, -197.0, -90.0], ["prop_beach_sign_rip", "worn", 1091.6, -203.0, -90.0],
	["prop_beach_shower", "worn", 1013.5, -11.2, 0.0],
	["prop_beach_sign_rules", "worn", 1016.6, -5.0, -90.0], ["prop_beach_sign_rip", "worn", 1016.6, -11.0, -90.0],
	# A200 and A0 on the lawn: lamps on their north side
	["prop_lamp_victorian", "worn", 960.0, -202.4, 0.0], ["prop_lamp_victorian", "worn", 1000.0, -202.4, 0.0],
	["prop_lamp_victorian", "worn", 1040.0, -202.4, 0.0],
	["prop_lamp_victorian", "worn", 960.0, -10.4, 0.0],
	# picnic tables with a kettle grill on the lawn near the cafe and near the rental shop
	["prop_picnic_table", "worn", 1040.0, -232.0, 0.0], ["prop_bbq_kettle", "worn", 1043.2, -232.0, 0.0],
	["prop_picnic_table", "worn", 1030.0, -186.0, 0.0], ["prop_bbq_kettle", "worn", 1033.2, -186.0, 0.0],
	["prop_picnic_table", "worn", 962.0, -40.0, 0.0], ["prop_bbq_kettle", "worn", 965.2, -40.0, 0.0],
	["prop_picnic_table", "worn", 970.0, -110.0, 90.0], ["prop_bbq_kettle", "worn", 970.0, -113.4, 0.0],
	# beach chairs in pairs on the lawn's lower edge, facing the sea
	["prop_adirondack_wood", "worn", 1020.0, -150.0, 100.0], ["prop_adirondack_white", "worn", 1020.0, -147.6, 105.0],
	["prop_adirondack_white", "worn", 985.0, -70.0, 95.0], ["prop_adirondack_wood", "worn", 985.0, -67.6, 100.0],
	# volleyball courts on the sand: two at A200 (north of it), two at A0 (north of it), nets along the beach
	["prop_volleyball_net", "worn", 1136.0, -212.0, 95.0], ["prop_volleyball_net", "worn", 1138.0, -232.0, 95.0],
	["prop_volleyball_net", "worn", 1062.0, -30.0, 90.0], ["prop_volleyball_net", "worn", 1062.0, -50.0, 90.0],
	# umbrellas on the sand near A0 (families from the waterfront who stop near the shop)
	["prop_beach_umbrella", "worn", 1040.0, -18.0, 25.0], ["prop_beach_umbrella", "worn", 1046.0, -12.5, 110.0],
	["prop_beach_umbrella", "worn", 1100.0, -20.0, 70.0], ["prop_beach_umbrella_closed", "worn", 1104.0, -26.0, 0.0],
	["prop_beach_umbrella", "worn", 1150.0, -180.0, 160.0], ["prop_beach_umbrella", "worn", 1156.0, -186.0, 45.0],
	# lawn sprinklers (no collision)
	["prop_sprinkler_impact", "normal", 980.0, -230.0, 0.0, false], ["prop_sprinkler_impact", "normal", 1000.0, -160.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 960.0, -80.0, 0.0, false], ["prop_sprinkler_impact", "normal", 950.0, -150.0, 0.0, false],
]
## items placed against the dune line: [base, cond, offset (u, + = seaward), v, yaw ("dune" or degrees), collide]
const ALONG := [
	# promenade lamps on its land side, every ~35 m, clear of the accesses and the forecourts
	["prop_pier_lamp", "worn", -9.7, -244.0, 0.0, true], ["prop_pier_lamp", "worn", -9.7, -190.0, 0.0, true],
	["prop_pier_lamp", "worn", -9.7, -155.0, 0.0, true], ["prop_pier_lamp", "worn", -9.7, -120.0, 0.0, true],
	["prop_pier_lamp", "worn", -9.7, -85.0, 0.0, true], ["prop_pier_lamp", "worn", -9.7, -50.0, 0.0, true],
	["prop_pier_lamp", "worn", -9.7, -3.0, 0.0, true],
	# pairs of benches on the grass strip between the promenade and the dune, facing the sea
	["prop_park_bench", "worn", -4.3, -244.0, "dune", true], ["prop_park_bench", "worn", -4.3, -240.4, "dune", true],
	["prop_park_bench", "worn", -4.3, -176.0, "dune", true], ["prop_park_bench", "worn", -4.3, -172.4, "dune", true],
	["prop_park_bench", "worn", -4.3, -141.0, "dune", true], ["prop_park_bench", "worn", -4.3, -137.4, "dune", true],
	["prop_park_bench", "worn", -4.3, -106.0, "dune", true], ["prop_park_bench", "worn", -4.3, -102.4, "dune", true],
	["prop_park_bench", "worn", -4.3, -71.0, "dune", true], ["prop_park_bench", "worn", -4.3, -67.4, "dune", true],
	["prop_park_bench", "worn", -4.3, -42.0, "dune", true], ["prop_park_bench", "worn", -4.3, -38.4, "dune", true],
	# iceplant mats on the first metres of sand (ground cover)
	["plant_iceplant_patch", "normal", 2.0, -246.0, 10.0, false], ["plant_iceplant_patch", "normal", 1.8, -232.0, 70.0, false],
	["plant_iceplant_patch", "normal", 2.2, -218.0, 130.0, false], ["plant_iceplant_patch", "normal", 1.6, -188.0, 40.0, false],
	["plant_iceplant_patch", "normal", 2.3, -173.0, 100.0, false], ["plant_iceplant_patch", "normal", 1.9, -158.0, 160.0, false],
	["plant_iceplant_patch", "normal", 2.1, -143.0, 20.0, false], ["plant_iceplant_patch", "normal", 1.7, -128.0, 80.0, false],
	["plant_iceplant_patch", "normal", 2.4, -113.0, 140.0, false], ["plant_iceplant_patch", "normal", 1.8, -98.0, 50.0, false],
	["plant_iceplant_patch", "normal", 2.2, -83.0, 110.0, false], ["plant_iceplant_patch", "normal", 1.9, -68.0, 170.0, false],
	["plant_iceplant_patch", "normal", 2.0, -53.0, 30.0, false], ["plant_iceplant_patch", "normal", 2.3, -38.0, 90.0, false],
	["plant_iceplant_patch", "normal", 1.7, -23.0, 150.0, false],
	# agaves where the dune is widest (with collision)
	["plant_agave_americana_small", "normal", 6.8, -164.0, 0.0, true], ["plant_agave_americana", "normal", 7.0, -96.0, 30.0, true],
	["plant_agave_americana_small", "normal", 6.4, -59.0, 60.0, true],
]

## SUPERCHECKER (20 Nov, Yasin: "be much more prone to delete a prop or road mark"): tools/city/super/sc.py check on
## this piece against the area layout OUT/fill/ec/area.json (through the scratch wrapper OUT/fill/fw/sc_fw.py); every
## finding on an item is a deletion here with the checker's reason; a collision box on each building column it measured.
## (The marks on grass and sand it found are out at the source, see _wear; the banned dry lawn patches are out of ALONG.)
const SC := {
 "out": [
	["prop_trash_receptacle", 1069.000, -209.250, "bin_open: prop_trash_receptacle stands in the open (1.8 m from a wall, 235.0 m from a fence)"],
	["prop_recycling_receptacle", 1068.100, -209.250, "bin_open: prop_recycling_receptacle stands in the open (1.8 m from a wall, 235.7 m from a fence)"],
	["prop_shade_sail", 1063.750, -205.500, "sail_over_nothing: a shade sail with no table, seat or play item under it"],
 ],
 "turn": [
 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/cafe", [1.02491, 1.49998, 6.87996, 0.16, 2.99996, 0.16]],
	["Buildings/rentals", [2.03657, 1.49998, 6.87986, 0.16, 2.99996, 0.16]],
 ],
}

var PY: Array = []

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "n_ec_dune_s"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_ec_dune_s")
	var yb := func(x: float, z: float) -> float: return S.g(x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(S.fp(b), float(b[4]), yb)); pe.append(H.pad_entry(S.fp(b), float(PY[PY.size() - 1])))
	var yf := H.graded(yb, pe)
	var paints: Array = []
	for b: Array in B: paints.append(H.pad_rect(S.fp(b)))
	paints.append_array([
		[A200[0], A200[1], A200[2], A200[3], "plaza"],
		[A0[0], A0[1], A0[2], A0[3], "plaza"],
		[FORE_C[0], FORE_C[1], FORE_C[2], FORE_C[3], "plaza"],
		[TERR_C[0], TERR_C[1], TERR_C[2], TERR_C[3], "plaza"],
		[FORE_R[0], FORE_R[1], FORE_R[2], FORE_R[3], "plaza"],
		[YARD_R[0], YARD_R[1], YARD_R[2], YARD_R[3], "plaza"],
	])
	var pw := func(z: float) -> float: return S.prom_w(z)
	var pe2 := func(z: float) -> float: return S.prom_e(z)
	var du := func(z: float) -> float: return S.dune_u(z)
	S.rows(g, Z0, Z1, [S.U_W, pw, pe2, du, S.U_E], ["grass", "plaza", "grass", "sand"], paints, yf)
	for i in B.size(): H.pad_at(g, S.fp(B[i]), float(PY[i]), yf)
	H.skirt(g, Vector2(S.U_W, Z1), Vector2(S.U_E, Z1), yf, "grass")
	if PASS >= 2:
		for i in B.size():
			var b: Array = B[i]
			K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
		var items: Array = ITEMS.duplicate()
		for a: Array in ALONG:
			var v := float(a[3])
			items.append([a[0], a[1], S.dune_u(v) + float(a[2]), v, S.dune_yaw(v) if a[4] is String else float(a[4]), a[5]])
		H.polish(props, g, items)
		_wear(dec, rr, yf)
		H.sc_apply(root, props, dec, SC)
	print("n_ec_dune_s pads %s" % [PY])
	H.finish(root, g, props, dec, "n_ec_dune_s")
	quit()

## wear: the queues worn at the two shop doors (on the forecourts' paving). SUPERCHECKER PASS (20 Nov, "be much more
## prone to delete a prop or road mark"): every mark on sand or grass had a finding (379 marks) and is out at the
## source: the sand blown onto the grass along the dune line, the footpaths across the sand from the two accesses, the
## wet sand under the two showers.
func _wear(dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	dec.add(14, Vector2(1072.6, -212.2), 0.0, 2.0, 3.0, yf, Color(1, 1, 1, 0.45))
	dec.add(14, Vector2(992.6, -20.7), 0.0, 2.0, 3.0, yf, Color(1, 1, 1, 0.45))
