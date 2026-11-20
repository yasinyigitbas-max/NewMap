extends SceneTree
## Piece n_ea_south (ea fill): APPROACH GREEN - the lawn between the ring's outer walk (u 674), the bridge approach
## (s_br_appr_1..4, north) and v -1100 (eb's area goes on south). Placed at grid [0, 0, 0], yaw 0 (x = u, z = v,
## y = world height). Run once.
##
## WHY (planner): a 200 x 85 m wedge of high, flat land (4.0 - 4.9 m) beside the bridge approach, reached from the
## v -1200 ring junction's south-east corner (the crossing from the strip and the apartment band) and along the ring
## walk; south of it eb's part of the shore. The bridge traffic passes on its north side, so nothing here faces the
## road: the GREEN WALK runs from the junction's corner south-east through the middle toward eb's land (lamps on its
## south side, bench pairs on its north side looking over the lawn), two PICNIC tables with grills on the lawn, one of
## them under a shade sail (the afternoon sun), the rest open lawn with sprinklers.
## LAND: 4.0 at the ring rising to 4.9 m at the east end (0.5 %); the ground follows it (n_ea_site.g).
## No trees here (hand list zoning/trees/ea_south.json, t_ea_south).
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_ea_site.gd")
const NAME := "n_ea_south"

const WALK := [Vector2(674.3, -1180.0), Vector2(700.0, -1170.0), Vector2(740.0, -1158.0), Vector2(780.0, -1143.0),
	Vector2(815.0, -1125.0), Vector2(840.0, -1108.0), Vector2(851.0, -1099.0)]

const ITEMS := [
	# ---- the green walk: lamps on its south side every 30 m facing it, bench pairs on its north side facing the lawn
	["prop_lamp_victorian", "worn", 687.5, -1172.5, 159.0], ["prop_lamp_victorian", "worn", 716.1, -1162.9, 163.0],
	["prop_lamp_victorian", "worn", 744.5, -1154.0, 159.0], ["prop_lamp_victorian", "worn", 772.6, -1143.4, 159.0],
	["prop_lamp_victorian", "worn", 799.4, -1130.6, 153.0], ["prop_lamp_victorian", "worn", 825.0, -1115.5, 146.0],
	["prop_park_bench", "worn", 729.8, -1163.6, -17.0], ["prop_park_bench", "worn", 732.1, -1162.9, -17.0],
	["prop_park_bench", "worn", 788.2, -1141.5, -27.0], ["prop_park_bench", "worn", 790.3, -1140.4, -27.0],
	# ---- picnic on the lawn south of the walk: a table with its grill, a second under a shade sail with its grill
	["prop_picnic_table", "worn", 712.0, -1146.0, 15.0], ["prop_bbq_kettle", "worn", 714.8, -1143.6, 0.0],
	["prop_picnic_table", "worn", 762.0, -1126.0, 20.0], ["prop_bbq_kettle", "worn", 765.4, -1123.2, 0.0],
	["prop_shade_sail", "worn", 762.0, -1126.0, 20.0, false],
	# ---- the lawn: sprinklers
	["prop_sprinkler_impact", "clean", 700.0, -1125.0, 0.0, false], ["prop_sprinkler_impact", "clean", 740.0, -1115.0, 0.0, false],
	["prop_sprinkler_impact", "clean", 800.0, -1110.0, 0.0, false],
]

## SUPERCHECKER (20 Nov, Yasin via the coordinator: "be MUCH more prone to delete ... any prop or road/ground mark
## with any finding or any doubt is deleted with its reason"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/ea/area.json); every finding on an item is a deletion here with the checker's reason; a collision box on
## each building column the checker measured. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [

 ],
 "turn": [
 ],
 "decals": [

 ],
 "boxes": [

 ],
}

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = NAME
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var yf := func(x: float, z: float) -> float: return S.g(x, z)
	S.fill(g, S.outline("south"), [[S.strip(WALK, 3.0), "plaza"]], S.rectp(600.0, -1300.0, 1000.0, -1000.0), yf)     # all lawn
	# the free edge at v -1100 (eb's area goes on south): a skirt under it
	H.skirt(g, Vector2(674.3, -1100.0), Vector2(881.8, -1100.0), yf, "grass")
	if PASS >= 2:
		for it: Array in ITEMS:
			S.put(props, yf, String(it[0]), String(it[1]), float(it[2]), float(it[3]), float(it[4]), bool(it[5]) if it.size() > 5 else true)
		H.sc_apply(root, props, dec, SC)
	print("%s: holes %d" % [NAME, S.holes_seen])
	H.finish(root, g, props, dec, NAME)
	quit()
