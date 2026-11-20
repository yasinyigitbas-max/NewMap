extends SceneTree
## Piece n_ea_shore (ea fill, the east shore v -1460 .. -1100 seaward of the bridge ramp): BRIDGE BEACH - the grass band
## along the ramp with the promenade, and the beach below it from the ring junction's corner round to v -1100.
## The land with no piece between the ramp s_br_ramp_5..1 (its seaward walk), the v -1400 ring junction's north-east
## corner and the sea, v -1460 (n_ea_cape) .. -1100 (eb's area), out to 25 m past the 0 m line. Placed at grid
## [0, 0, 0], yaw 0 (x = u, z = v, y = world height). Run once.
##
## WHY (planner): the v -1400 ring junction is where the city's arterial (s_rg_nw_b071, from the u 500 junction)
## meets the ring and the bridge ramp: people cross to its north-east corner, the BRIDGE BEACH ENTRY (bike racks,
## water, the rules), and walk the promenade north to North Beach (n_ea_cape) or south-east along the ramp. The beach is
## very wide in the north (low land) and narrows south where the land rises to the 5 m crest beside the bridge: so the
## VOLLEYBALL courts go on the wide north sand, the towers every ~140 m face the water, umbrellas between them; on the
## high grass in the south the promenade passes BRIDGE POINT SCOOPS (ice cream, its forecourt on the promenade) and the
## CREST LOOKOUT (a level deck on the high ground by the bridge, benches and rails, the view down the whole beach); the
## picnic tables with grills stand on the grass between the ramp and the promenade; the DOG BEACH (fenced, a gate on
## its land side, the dog rules, bins against its fence) is at the far south end, away from the swimmers. Four
## accesses cross the dune (boardwalks, one paved path across the wide south grass), a shower at each.
## LAND: 1.9 - 2.4 m along the ramp in the north, 2.5 - 5 m in the south (the crest u 925 - 945, v -1200 .. -1100);
## the ground follows it (n_ea_site.g); the shop and the lookout on level pads at the highest ground under them.
## No trees here (hand list zoning/trees/ea_shore.json, t_ea_shore).
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_ea_site.gd")
const NAME := "n_ea_shore"

const B := [
	["scoops", "commercial/com_surf_shop", 970.5, -1170.0, -90.0],      # BRIDGE POINT SCOOPS: front (door v -1173.3) on the promenade
]
## the lookout deck on the crest (level, paved) and the paths
const LOOK := [930.0, -1137.0, 942.0, -1123.0]
const CORNER := [674.3, -1425.5, 690.0, -1408.0]           # the entry at the junction's north-east corner
const FORE := [957.0, -1181.0, 962.6, -1159.0]             # the ice cream forecourt (between the promenade and its front)
const LINK := [Vector2(688.0, -1417.0), Vector2(712.0, -1426.5)]          # entry -> promenade
const LOOKPATH := [Vector2(941.0, -1130.0), Vector2(959.0, -1130.0)]      # lookout -> promenade
const B4PATH := [Vector2(959.0, -1145.0), Vector2(992.5, -1145.0)]        # the south access across the wide grass
const DOG := [1016.0, -1128.0, 1048.0, -1104.0]            # the dog beach (picket fence, gate on its west side at v -1116)
const DECKS := [
	# B1 from the promenade (its 70 m point) to the north-east
	[742.28, -1420.67, 50.0], [744.85, -1423.74, 50.0], [747.42, -1426.80, 50.0], [749.99, -1429.87, 50.0],
	# B2 (its 195 m point)
	[856.16, -1371.40, 53.0], [858.57, -1374.59, 53.0], [860.98, -1377.79, 53.0], [863.39, -1380.98, 53.0], [865.79, -1384.18, 53.0],
	# B3 (its 310 m point)
	[929.76, -1282.19, 28.0], [933.30, -1284.06, 28.0], [936.83, -1285.94, 28.0], [940.36, -1287.82, 28.0], [943.89, -1289.70, 28.0],
	# B4: the end of the paved path over the dune (dune at u 996)
	[994.5, -1145.0, 0.0], [998.5, -1145.0, 0.0],
]

const ITEMS := [
	# ---- the entry at the junction's corner: bike racks along the junction's walk, water, the rules, a bench pair
	#      facing the beach
	["prop_bike_rack", "worn", 680.0, -1409.6, 0.0], ["prop_bike_rack", "worn", 685.0, -1409.6, 0.0],
	["prop_drinking_fountain", "worn", 676.0, -1422.0, 90.0], ["prop_beach_sign_rules", "worn", 689.2, -1421.0, 120.0],
	["prop_park_bench", "worn", 683.0, -1423.8, 150.0], ["prop_park_bench", "worn", 685.2, -1423.0, 150.0],
	# ---- the promenade: lamps on its land side every ~30 m, facing the walk
	["prop_lamp_victorian", "worn", 698.8, -1435.2, 130.0], ["prop_lamp_victorian", "worn", 725.0, -1420.2, 163.0],
	["prop_lamp_victorian", "worn", 753.9, -1411.8, 165.0], ["prop_lamp_victorian", "worn", 782.1, -1402.6, 158.0],
	["prop_lamp_victorian", "worn", 809.6, -1390.9, 155.0], ["prop_lamp_victorian", "worn", 835.9, -1377.4, 147.0],
	["prop_lamp_victorian", "worn", 860.1, -1360.4, 139.0], ["prop_lamp_victorian", "worn", 881.7, -1340.1, 131.0],
	["prop_lamp_victorian", "worn", 900.5, -1317.1, 124.0], ["prop_lamp_victorian", "worn", 916.9, -1292.2, 121.0],
	["prop_lamp_victorian", "worn", 930.9, -1266.2, 112.0], ["prop_lamp_victorian", "worn", 941.3, -1238.4, 105.0],
	["prop_lamp_victorian", "worn", 948.5, -1209.5, 99.0], ["prop_lamp_victorian", "worn", 953.1, -1180.0, 96.0],
	["prop_lamp_victorian", "worn", 955.9, -1150.2, 94.0], ["prop_lamp_victorian", "worn", 957.8, -1120.4, 92.0],
	# ---- benches in pairs on its sea side, facing the sea
	["prop_park_bench", "worn", 712.2, -1429.4, 163.0], ["prop_park_bench", "worn", 714.4, -1428.7, 163.0],
	["prop_park_bench", "worn", 769.7, -1412.8, 165.0], ["prop_park_bench", "worn", 772.2, -1411.9, 158.0],
	["prop_park_bench", "worn", 825.3, -1389.1, 155.0], ["prop_park_bench", "worn", 827.4, -1388.1, 155.0],
	["prop_park_bench", "worn", 874.7, -1354.3, 139.0], ["prop_park_bench", "worn", 876.5, -1352.8, 139.0],
	["prop_park_bench", "worn", 913.0, -1307.5, 124.0], ["prop_park_bench", "worn", 914.3, -1305.6, 124.0],
	["prop_park_bench", "worn", 941.2, -1254.1, 112.0], ["prop_park_bench", "worn", 942.0, -1252.0, 112.0],
	["prop_park_bench", "worn", 955.9, -1195.5, 99.0], ["prop_park_bench", "worn", 956.3, -1193.3, 99.0],
	# ---- the access feet: a shower beside each, the rules at each head
	["prop_beach_shower", "clean", 749.91, -1433.2, 0.0], ["prop_beach_shower", "clean", 865.54, -1387.5, 0.0],
	["prop_beach_shower", "clean", 945.07, -1292.81, 0.0], ["prop_beach_shower", "clean", 1001.6, -1142.6, 0.0],
	["prop_beach_sign_rules", "worn", 743.28, -1418.14, 140.0], ["prop_beach_sign_rules", "worn", 857.3, -1368.92, 143.0],
	["prop_beach_sign_rules", "worn", 929.74, -1279.46, 118.0], ["prop_beach_sign_rules", "worn", 961.0, -1147.6, 90.0],
	# ---- the grass between the ramp and the promenade: picnic tables with their grills
	["prop_picnic_table", "worn", 757.0, -1405.6, 15.0], ["prop_bbq_kettle", "worn", 760.2, -1404.6, 0.0],
	["prop_picnic_table", "worn", 936.0, -1236.0, 15.0], ["prop_bbq_kettle", "worn", 937.0, -1232.6, 0.0],
	["prop_picnic_table", "worn", 933.0, -1205.0, 0.0], ["prop_bbq_kettle", "worn", 933.6, -1201.6, 0.0],
	["prop_picnic_table", "worn", 936.0, -1172.0, 0.0], ["prop_bbq_kettle", "worn", 936.6, -1168.6, 0.0],
	["prop_sprinkler_impact", "clean", 945.0, -1160.0, 0.0, false], ["prop_sprinkler_impact", "clean", 975.0, -1210.0, 0.0, false],
	["prop_sprinkler_impact", "clean", 935.0, -1220.0, 0.0, false],
	# ---- the crest lookout: a bench pair facing the beach behind the rails, a lamp at its corner
	["prop_park_bench", "worn", 938.4, -1135.0, 90.0], ["prop_park_bench", "worn", 938.4, -1132.6, 90.0],
	["prop_lamp_victorian", "worn", 931.0, -1124.0, 90.0],
	# ---- BRIDGE POINT SCOOPS: tables on its forecourt (kept 9 m off the door), a bike rack along the promenade
	["prop_patio_set_4", "worn", 960.4, -1163.0, 0.0], ["prop_patio_set_4", "worn", 960.4, -1179.2, 0.0],
	["prop_bike_rack", "worn", 959.6, -1158.4, 90.0],
	# ---- the dune line: iceplant and agave where the grass ends (clear of the accesses)
	["plant_iceplant_patch", "normal", 716.0, -1443.5, 0.0, false], ["plant_iceplant_patch", "normal", 737.0, -1431.5, 0.0, false],
	["plant_agave_americana_small", "normal", 775.0, -1419.5, 0.0], ["plant_iceplant_patch", "normal", 805.0, -1409.0, 0.0, false],
	["plant_iceplant_patch", "normal", 834.0, -1396.5, 0.0, false], ["plant_iceplant_patch", "normal", 880.0, -1364.5, 0.0, false],
	["plant_agave_americana_small", "normal", 902.0, -1341.5, 0.0], ["plant_iceplant_patch", "normal", 921.0, -1319.0, 0.0, false],
	["plant_iceplant_patch", "normal", 952.0, -1270.5, 0.0, false], ["plant_iceplant_patch", "normal", 966.0, -1244.5, 0.0, false],
	["plant_agave_americana_small", "normal", 977.0, -1210.0, 0.0], ["plant_iceplant_patch", "normal", 986.0, -1182.0, 0.0, false],
	["plant_iceplant_patch", "normal", 994.0, -1158.0, 0.0, false], ["plant_iceplant_patch", "normal", 1000.0, -1122.0, 0.0, false],
	# ---- the wide north sand: two volleyball courts (nets east - west)
	["prop_volleyball_net", "clean", 870.0, -1428.0, 0.0], ["prop_volleyball_net", "clean", 896.0, -1416.0, 0.0],
	# ---- three lifeguard towers 22 m up from the water facing it, a life ring beside each
	["prop_lifeguard_tower", "worn", 946.0, -1388.9, 130.0], ["prop_lifering_stand", "clean", 947.9, -1386.6, 130.0],
	["prop_lifeguard_tower", "worn", 1007.8, -1274.5, 106.0], ["prop_lifering_stand", "clean", 1008.6, -1271.6, 106.0],
	["prop_lifeguard_tower", "worn", 1034.6, -1159.3, 102.0], ["prop_lifering_stand", "clean", 1035.2, -1156.4, 102.0],
	# ---- rip-current warnings near the water, read from the beach
	["prop_beach_sign_rip", "worn", 988.5, -1349.0, -60.0], ["prop_beach_sign_rip", "worn", 1034.2, -1220.7, -78.0],
	# ---- families under umbrellas between the towers
	["prop_beach_umbrella", "clean", 963.4, -1378.6, 15.0], ["prop_beach_umbrella", "clean", 967.6, -1371.0, 60.0],
	["prop_beach_umbrella_closed", "clean", 958.5, -1383.5, 0.0], ["prop_ice_chest", "clean", 962.0, -1385.6, 127.0],
	["prop_beach_umbrella", "clean", 1001.3, -1312.4, 30.0], ["prop_beach_umbrella", "clean", 1004.0, -1305.0, 75.0],
	["prop_beach_umbrella_closed", "clean", 998.0, -1320.0, 0.0],
	["prop_beach_umbrella", "clean", 1025.0, -1238.6, 20.0], ["prop_beach_umbrella", "clean", 1027.0, -1230.0, 55.0],
	["prop_ice_chest", "clean", 1022.0, -1246.0, 104.0],
	["prop_beach_umbrella", "clean", 1033.3, -1200.2, 40.0], ["prop_beach_umbrella_closed", "clean", 1035.0, -1192.0, 0.0],
	# ---- the dog beach: the dog rules and water by its gate (outside), a bin against its fence by the gate, a bench
	#      pair inside facing the water
	["prop_beach_sign_dog", "worn", 1013.6, -1112.6, -90.0], ["prop_drinking_fountain", "worn", 1014.8, -1120.4, -90.0],
	["prop_trash_receptacle", "dirty", 1015.3, -1123.6, -90.0],
	["prop_park_bench", "worn", 1030.0, -1123.0, 90.0], ["prop_park_bench", "worn", 1030.0, -1120.6, 90.0],
]
## the shop's service side: its condenser behind it, bins against its north wall
const SERVICE := [
	["prop_ac_condenser", "worn", 978.8, -1166.0, 90.0],
	["prop_trash_receptacle", "dirty", 966.0, -1175.6, 0.0], ["prop_recycling_receptacle", "worn", 967.2, -1175.6, 0.0],
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
	["Buildings/scoops", [2.036573886871338, 1.4999818801879883, 6.879859924316406, 0.16, 2.9999637603759766, 0.16]],
 ],
}

var PY: Array = []

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array:
	var st := K.building_stats(f)
	if st.has("near") and (st.near as Dictionary).has("bbox"): return (st.near as Dictionary).bbox
	var wd: Array = st.footprint_wd
	return [[-float(wd[0]) * 0.5, 0.0, -float(wd[1]) * 0.5], [float(wd[0]) * 0.5, float(st.get("height", 6.0)), float(wd[1]) * 0.5]]
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(yaw - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]

func _run() -> void:
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var yb := func(x: float, z: float) -> float: return S.g(x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	# the lookout: level at the highest ground under it
	var ly := H.pad_height([LOOK[0], LOOK[1], LOOK[2], LOOK[3]], 90.0, yb, 0.0)
	pe.append([LOOK[0], LOOK[1], LOOK[2], LOOK[3], ly])
	var yf := H.graded(yb, pe)
	var regions: Array = []
	for b: Array in B:
		var r: Array = H.pad_rect(fp(b)); regions.append([S.rectp(r[0], r[1], r[2], r[3]), "-"])
	regions.append([S.rectp(LOOK[0], LOOK[1], LOOK[2], LOOK[3]), "-"])
	regions.append([S.rectp(CORNER[0], CORNER[1], CORNER[2], CORNER[3]), "plaza"])
	regions.append([S.rectp(FORE[0], FORE[1], FORE[2], FORE[3]), "plaza"])
	regions.append([S.strip(S.PROM, S.PROM_W), "plaza"])
	regions.append([S.strip(LINK, 3.0), "plaza"])
	regions.append([S.strip(LOOKPATH, 2.5), "plaza"])
	regions.append([S.strip(B4PATH, 2.5), "plaza"])
	S.fill(g, S.outline("shore"), regions, S.grass_poly(), yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	H.level_pad(g, "plaza", LOOK[0], LOOK[1], LOOK[2], LOOK[3], ly, yf)
	# the free edge at v -1100 (eb's area goes on south): a skirt under it
	H.skirt(g, Vector2(925.9, -1100.0), Vector2(1003.0, -1100.0), yf, "grass")
	H.skirt(g, Vector2(1003.0, -1100.0), Vector2(1098.8, -1100.0), yf, "sand")
	if PASS >= 2:
		for i in B.size():
			var b: Array = B[i]
			K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
		for d: Array in DECKS: S.deck(props, yf, float(d[0]), float(d[1]), float(d[2]))
		for it: Array in ITEMS + SERVICE:
			S.put(props, yf, String(it[0]), String(it[1]), float(it[2]), float(it[3]), float(it[4]), bool(it[5]) if it.size() > 5 else true)
		# the lookout's rails on its beach (east) edge, an opening at v -1130 where its path leaves for the promenade
		for rv: float in [-1135.0, -1125.0]: props.add("prop_prom_rail", "clean", Vector3(942.1, ly, rv), 90.0)
		# the dog beach's picket fence: a post at every joint, the gate (1.11 m) in its west side at v -1116
		var fy := func(x: float, z: float) -> float: return float(yf.call(x, z))
		H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(DOG[0], DOG[1]), Vector2(DOG[2], DOG[1]), fy, 2.0, "worn")
		H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(DOG[2], DOG[1]), Vector2(DOG[2], DOG[3]), fy, 2.0, "worn")
		H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(DOG[2], DOG[3]), Vector2(DOG[0], DOG[3]), fy, 2.0, "worn")
		H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(DOG[0], DOG[3]), Vector2(DOG[0], -1115.445), fy, 2.0, "worn")
		H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(DOG[0], -1116.555), Vector2(DOG[0], DOG[1]), fy, 2.0, "worn")
		props.add("fence_gate_picket", "worn", Vector3(DOG[0], float(yf.call(DOG[0], -1116.0)) - 0.02, -1116.0), 90.0)
		H.sc_apply(root, props, dec, SC)
	print("%s: dune holes %d, lookout at %.2f" % [NAME, S.holes_seen, ly])
	H.finish(root, g, props, dec, NAME)
	quit()
