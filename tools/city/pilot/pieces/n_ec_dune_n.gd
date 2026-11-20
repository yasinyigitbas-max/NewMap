extends SceneTree
## Piece n_ec_dune_n (ec fill, the east shore beyond the ring, north half, u 932 .. 1200, v -500 .. -250): the park's
## east lawn, the BEACH PROMENADE, the GRASS > SAND dune edge, the top of the sand, and the SHORELINE SNACK BAR.
## Placed at grid [0, 0, 0], yaw 0 (x = u, z = v, y = world). Run once; never when locked.
##
## WHY (planner): the beach walk A400 (from the v -400 junction corner, over the hill in n_ec_hill_n) comes down the
## lawn to the PROMENADE, the 3 m paved walk that follows the dune line the whole length of the shore (9 .. 6 m west of
## it), lamps on its land side, pairs of benches on the grass strip between it and the dune facing the sea. Where A400
## meets the promenade: the SHORELINE SNACK BAR (com_cafe_seaside, door to the promenade, a terrace with tables under a
## sail on its south side by the walk, bins on its walls, a bike rack on its forecourt for the beach cruisers). A400
## goes on across the dune onto the sand (the beach access): an outdoor shower and the beach rules / rip current signs
## where the paving ends. The dune edge: the grass turns to sand along the curving line (n_ec_site.DUNE: the land's
## 2.5 m contour here), sand blown onto the last metres of grass, iceplant and dry dune-grass patches and a few agaves
## holding the sand. On the sand: two VOLLEYBALL courts near the access (nets along the beach), a few umbrellas.
## On the lawn: picnic tables with grills near the snack bar, beach chairs, sprinklers.
## LAND: 7 - 10 m at u 932 falling to 2.4 - 2.6 m at the dune line and 1.3 - 1.8 m at u 1200 (3 - 4 %); the ground
## follows it (n_ec_site.g); the snack bar on a level pad at the highest ground under it, the field graded up to it.
## AFTER THE SUPERCHECKER PASS (20 Nov, delete when unsure): the terrace's sail and both bins, the dry dune-grass patches
## (banned grass tufts) and every wear mark on grass / sand (the sand blown onto the grass, the footpath, the wet sand)
## are OUT (see SC and _wear): the dune edge is the grass / sand line itself, iceplant and agaves.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_ec_site.gd")

const Z0 := -500.0
const Z1 := -250.0
const B := [
	["snackbar", "commercial/com_cafe_seaside", 1099.8, -414.0, 90.0],   # front (shop door at v -412.24) to the promenade
]
const A400 := [932.0, -401.5, 1131.0, -398.5]     # the beach walk, on across the dune to the sand (dune line 1119)
const FORE := [1108.0, -421.0, 1113.5, -401.5]    # the snack bar's forecourt between its front and the promenade
const TERR := [1092.0, -409.6, 1108.0, -401.5]    # its terrace on the south side, down to A400

const ITEMS := [
	# the snack bar's terrace: two tables with chairs under one shade sail (its staff door at u 1094.8 stays clear)
	["prop_patio_set_4", "worn", 1099.0, -405.5, 0.0], ["prop_patio_set_4", "worn", 1103.5, -405.5, 0.0],
	["prop_shade_sail", "worn", 1101.25, -405.5, 0.0],
	# its bins against the terrace wall by the walk, a trash and a recycling bin
	["prop_trash_receptacle", "dirty", 1106.0, -409.25, 0.0], ["prop_recycling_receptacle", "worn", 1105.1, -409.25, 0.0],
	# a bike rack on the forecourt, along the promenade (people ride down the walk on beach cruisers)
	["prop_bike_rack", "worn", 1110.0, -419.5, 90.0],
	# a lamp on the forecourt's north corner (evening customers)
	["prop_lamp_victorian", "worn", 1108.6, -420.6, 0.0],
	# the beach access's end on the sand: the shower (rinse the sand off) north of the path, the rules and the rip
	# current signs facing the people walking out
	["prop_beach_shower", "worn", 1129.5, -403.2, 0.0],
	["prop_beach_sign_rules", "worn", 1132.6, -397.0, -90.0], ["prop_beach_sign_rip", "worn", 1132.6, -403.0, -90.0],
	# A400 on the lawn: lamps on its north side
	["prop_lamp_victorian", "worn", 960.0, -402.4, 0.0], ["prop_lamp_victorian", "worn", 1000.0, -402.4, 0.0],
	["prop_lamp_victorian", "worn", 1040.0, -402.4, 0.0], ["prop_lamp_victorian", "worn", 1080.0, -402.4, 0.0],
	# picnic tables with a kettle grill on the lawn near the snack bar (they buy a drink and stay)
	["prop_picnic_table", "worn", 1078.0, -432.0, 0.0], ["prop_bbq_kettle", "worn", 1081.2, -432.0, 0.0],
	["prop_picnic_table", "worn", 1072.0, -388.0, 0.0], ["prop_bbq_kettle", "worn", 1075.2, -388.0, 0.0],
	["prop_picnic_table", "worn", 1060.0, -470.0, 90.0], ["prop_bbq_kettle", "worn", 1060.0, -473.4, 0.0],
	# beach chairs in pairs on the lawn's lower edge, facing the sea
	["prop_adirondack_wood", "worn", 1050.0, -340.0, 90.0], ["prop_adirondack_white", "worn", 1050.0, -337.6, 95.0],
	["prop_adirondack_white", "worn", 1030.0, -300.0, 85.0], ["prop_adirondack_wood", "worn", 1030.0, -297.6, 90.0],
	# the volleyball courts on the sand south of the access, nets along the beach (courts run down to the water)
	["prop_volleyball_net", "worn", 1166.0, -440.0, 90.0], ["prop_volleyball_net", "worn", 1166.0, -462.0, 90.0],
	# umbrellas on the sand north of the access (people who do not walk all the way to the water)
	["prop_beach_umbrella", "worn", 1150.0, -392.0, 30.0], ["prop_beach_umbrella", "worn", 1157.0, -386.5, 80.0],
	["prop_beach_umbrella_closed", "worn", 1146.0, -380.0, 0.0], ["prop_beach_umbrella", "worn", 1176.0, -350.0, 140.0],
	["prop_beach_umbrella", "worn", 1182.0, -343.0, 15.0],
	# lawn sprinklers (no collision)
	["prop_sprinkler_impact", "normal", 980.0, -460.0, 0.0, false], ["prop_sprinkler_impact", "normal", 1020.0, -380.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 1060.0, -300.0, 0.0, false], ["prop_sprinkler_impact", "normal", 990.0, -280.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 1040.0, -440.0, 0.0, false], ["prop_sprinkler_impact", "normal", 960.0, -350.0, 0.0, false],
]
## items placed against the dune line: [base, cond, offset from the dune line (u, + = seaward), v, yaw ("dune" = facing
## the sea across the dune, else degrees), collide]
const ALONG := [
	# promenade lamps on its land side (prom_w - 0.7 = dune - 9.7), every ~35 m, clear of the access
	["prop_pier_lamp", "worn", -9.7, -492.0, 0.0, true], ["prop_pier_lamp", "worn", -9.7, -457.0, 0.0, true],
	["prop_pier_lamp", "worn", -9.7, -424.0, 0.0, true], ["prop_pier_lamp", "worn", -9.7, -390.0, 0.0, true],
	["prop_pier_lamp", "worn", -9.7, -355.0, 0.0, true], ["prop_pier_lamp", "worn", -9.7, -320.0, 0.0, true],
	["prop_pier_lamp", "worn", -9.7, -285.0, 0.0, true],
	# pairs of benches on the grass strip between the promenade and the dune, facing the sea
	["prop_park_bench", "worn", -4.3, -481.0, "dune", true], ["prop_park_bench", "worn", -4.3, -477.4, "dune", true],
	["prop_park_bench", "worn", -4.3, -446.0, "dune", true], ["prop_park_bench", "worn", -4.3, -442.4, "dune", true],
	["prop_park_bench", "worn", -4.3, -372.0, "dune", true], ["prop_park_bench", "worn", -4.3, -368.4, "dune", true],
	["prop_park_bench", "worn", -4.3, -334.0, "dune", true], ["prop_park_bench", "worn", -4.3, -330.4, "dune", true],
	["prop_park_bench", "worn", -4.3, -297.0, "dune", true], ["prop_park_bench", "worn", -4.3, -293.4, "dune", true],
	["prop_park_bench", "worn", -4.3, -268.0, "dune", true], ["prop_park_bench", "worn", -4.3, -264.4, "dune", true],
	# the dune: iceplant mats on the first metres of sand (ground cover, no collision)
	["plant_iceplant_patch", "normal", 1.8, -495.0, 10.0, false], ["plant_iceplant_patch", "normal", 2.2, -483.0, 70.0, false],
	["plant_iceplant_patch", "normal", 1.6, -468.0, 130.0, false], ["plant_iceplant_patch", "normal", 2.4, -452.0, 40.0, false],
	["plant_iceplant_patch", "normal", 1.9, -437.0, 100.0, false], ["plant_iceplant_patch", "normal", 2.1, -425.0, 160.0, false],
	["plant_iceplant_patch", "normal", 2.0, -389.0, 20.0, false], ["plant_iceplant_patch", "normal", 1.7, -377.0, 80.0, false],
	["plant_iceplant_patch", "normal", 2.3, -362.0, 140.0, false], ["plant_iceplant_patch", "normal", 1.8, -347.0, 50.0, false],
	["plant_iceplant_patch", "normal", 2.2, -318.0, 110.0, false], ["plant_iceplant_patch", "normal", 1.9, -303.0, 170.0, false],
	["plant_iceplant_patch", "normal", 2.0, -288.0, 30.0, false], ["plant_iceplant_patch", "normal", 2.4, -272.0, 90.0, false],
	["plant_iceplant_patch", "normal", 1.7, -257.0, 150.0, false],
	# agaves where the dune is widest (they hold the sand; with collision)
	["plant_agave_americana_small", "normal", 6.5, -430.0, 0.0, true], ["plant_agave_americana_small", "normal", 7.2, -321.0, 40.0, true],
	["plant_agave_americana", "normal", 7.0, -276.0, 20.0, true],
]

## SUPERCHECKER (20 Nov, Yasin: "be much more prone to delete a prop or road mark"): tools/city/super/sc.py check on
## this piece against the area layout OUT/fill/ec/area.json (through the scratch wrapper OUT/fill/fw/sc_fw.py); every
## finding on an item is a deletion here with the checker's reason; a collision box on each building column it measured.
## (The marks on grass and sand it found are out at the source, see _wear; the banned dry lawn patches are out of ALONG.)
const SC := {
 "out": [
	["prop_trash_receptacle", 1106.000, -409.250, "bin_open: prop_trash_receptacle stands in the open (1.8 m from a wall, 391.4 m from a fence)"],
	["prop_recycling_receptacle", 1105.100, -409.250, "bin_open: prop_recycling_receptacle stands in the open (1.8 m from a wall, 391.7 m from a fence)"],
	["prop_shade_sail", 1101.250, -405.500, "sail_over_nothing: a shade sail with no table, seat or play item under it"],
 ],
 "turn": [
 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/snackbar", [1.02491, 1.49998, 6.87996, 0.16, 2.99996, 0.16]],
 ],
}

var PY: Array = []

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "n_ec_dune_n"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_ec_dune_n")
	var yb := func(x: float, z: float) -> float: return S.g(x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(S.fp(b), float(b[4]), yb)); pe.append(H.pad_entry(S.fp(b), float(PY[PY.size() - 1])))
	var yf := H.graded(yb, pe)
	var paints: Array = []
	for b: Array in B: paints.append(H.pad_rect(S.fp(b)))
	paints.append_array([
		[A400[0], A400[1], A400[2], A400[3], "plaza"],
		[FORE[0], FORE[1], FORE[2], FORE[3], "plaza"],
		[TERR[0], TERR[1], TERR[2], TERR[3], "plaza"],
	])
	var pw := func(z: float) -> float: return S.prom_w(z)
	var pe2 := func(z: float) -> float: return S.prom_e(z)
	var du := func(z: float) -> float: return S.dune_u(z)
	S.rows(g, Z0, Z1, [S.U_W, pw, pe2, du, S.U_E], ["grass", "plaza", "grass", "sand"], paints, yf)
	for i in B.size(): H.pad_at(g, S.fp(B[i]), float(PY[i]), yf)
	H.skirt(g, Vector2(S.U_W, Z0), Vector2(S.U_E, Z0), yf, "grass")
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
	print("n_ec_dune_n pads %s" % [PY])
	H.finish(root, g, props, dec, "n_ec_dune_n")
	quit()

## wear: the snack bar's queue worn at its door (on the forecourt's paving). SUPERCHECKER PASS (20 Nov, "be much more
## prone to delete a prop or road mark"): every mark on sand or grass had a finding ("grime / pale patch mark lies on
## grass / sand": 328 marks) and is out at the source: the sand blown onto the grass along the dune line (311), the
## footpath worn across the sand from the access (16), the wet sand under the shower (1). The dune edge now reads by the
## grass / sand line itself and its iceplant and agaves.
func _wear(dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	dec.add(14, Vector2(1109.6, -412.2), 0.0, 2.0, 3.0, yf, Color(1, 1, 1, 0.45))
