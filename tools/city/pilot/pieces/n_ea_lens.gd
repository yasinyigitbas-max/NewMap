extends SceneTree
## Piece n_ea_lens (ea fill): BRIDGE MEADOW - the park between the bridge ramp (s_br_ramp_5..1, north and east), the
## bridge approach (s_br_appr_1..4, south) and the ring's outer walk (u 674, west), v -1392 .. -1100.
## Placed at grid [0, 0, 0], yaw 0 (x = u, z = v, y = world height). Run once.
##
## WHY (planner): this land is closed in by the two bridge roads, so it has no beach and no view of the water from the
## ground: it is the neighbourhood park of the shore, reached on foot from the two ring junctions' corners (v -1400's
## south-east corner, v -1200's north-east corner: the crossings from the city and the strip). So: the MEADOW WALK joins
## the two corners in a long loop round the meadow (dog walkers, joggers, people cutting from one junction to the other),
## lamps on its meadow side, bench pairs on its outer side looking across it; by the north corner a fenced PLAYGROUND
## (sand on a level pad, its gate on a short path from the walk, benches inside for the parents, the bin outside the
## gate) - the nearest one for the families on the beach; a PICNIC GROVE of tables with grills on the lawn east of it;
## on the high ground in the south-east the BANDSTAND on its pad (summer evening concerts, the lawn round it to sit on),
## benches facing it, a path to it from the walk. The rest is open lawn (sprinklers), the place to throw a ball.
## LAND: 2.0 m at the north corner rising to 4.1 - 5.0 m in the south-east (1.5 %); the ground follows it (n_ea_site.g,
## eased onto every street walk within 12 m); the playground and the bandstand on level pads, the lawn graded to them.
## No trees here (hand list zoning/trees/ea_lens.json, t_ea_lens).
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_ea_site.gd")
const NAME := "n_ea_lens"

const WALK := [Vector2(674.3, -1384.0), Vector2(700.0, -1376.0), Vector2(735.0, -1358.0), Vector2(770.0, -1335.0),
	Vector2(800.0, -1305.0), Vector2(815.0, -1272.0), Vector2(812.0, -1240.0), Vector2(790.0, -1222.0), Vector2(750.0, -1218.0),
	Vector2(710.0, -1219.0), Vector2(674.3, -1220.0)]
const PLAY := [712.0, -1350.0, 734.0, -1334.0]             # the playground's sand pad
const PF := [712.4, -1349.6, 733.6, -1334.4]               # its picket fence (inset 0.4 m), gate at u 723 on the north side
const PLAYPATH := [Vector2(723.0, -1364.0), Vector2(723.0, -1349.0)]
const BAND := [839.0, -1241.0, 851.0, -1229.0]             # the bandstand's pad
const BANDPATH := [Vector2(810.5, -1236.0), Vector2(839.0, -1236.0)]

const ITEMS := [
	# ---- the meadow walk: lamps on its meadow side every 30 m, facing the walk
	["prop_lamp_victorian", "worn", 692.7, -1376.0, 163.0], ["prop_lamp_victorian", "worn", 719.5, -1363.5, 153.0],
	["prop_lamp_victorian", "worn", 745.3, -1348.6, 147.0], ["prop_lamp_victorian", "worn", 769.7, -1332.1, 135.0],
	["prop_lamp_victorian", "worn", 791.0, -1310.9, 135.0], ["prop_lamp_victorian", "worn", 806.0, -1286.4, 114.0],
	["prop_lamp_victorian", "worn", 811.6, -1259.1, 85.0], ["prop_lamp_victorian", "worn", 802.1, -1234.7, 39.0],
	["prop_lamp_victorian", "worn", 777.2, -1222.9, 6.0], ["prop_lamp_victorian", "worn", 747.7, -1220.3, -1.0],
	["prop_lamp_victorian", "worn", 717.7, -1221.0, -1.0],
	# ---- bench pairs on its outer side, looking across the walk into the meadow
	["prop_park_bench", "worn", 732.3, -1362.1, -27.0], ["prop_park_bench", "worn", 734.4, -1361.0, -27.0],
	["prop_park_bench", "worn", 785.7, -1322.7, -45.0], ["prop_park_bench", "worn", 787.4, -1321.0, -45.0],
	["prop_park_bench", "worn", 814.9, -1244.7, -95.0], ["prop_park_bench", "worn", 814.6, -1242.3, -95.0],
	["prop_park_bench", "worn", 762.8, -1216.9, -174.0], ["prop_park_bench", "worn", 760.4, -1216.6, -174.0],
	# ---- the playground (inside its fence, on sand): the climbing frame, swings and slide close together, the parents'
	#      benches along the south fence facing the play, the bin outside the gate against the fence
	["prop_play_structure", "worn", 723.0, -1342.0, 0.0], ["prop_swing_set", "worn", 727.4, -1341.0, 90.0],
	["prop_slide", "worn", 718.8, -1342.0, 0.0],
	["prop_park_bench", "worn", 721.8, -1337.0, 180.0], ["prop_park_bench", "worn", 724.2, -1337.0, 180.0],
	["prop_trash_receptacle", "dirty", 725.8, -1350.3, 0.0],
	# ---- the picnic grove east of the playground: each table with its grill
	["prop_picnic_table", "worn", 765.0, -1318.0, 30.0], ["prop_bbq_kettle", "worn", 767.6, -1315.6, 0.0],
	["prop_picnic_table", "worn", 776.0, -1309.0, 30.0], ["prop_bbq_kettle", "worn", 778.6, -1306.6, 0.0],
	["prop_picnic_table", "worn", 768.0, -1298.0, 30.0], ["prop_bbq_kettle", "worn", 770.6, -1295.6, 0.0],
	# ---- the bandstand's benches: two pairs facing it across the lawn, either side of its path
	["prop_park_bench", "worn", 832.0, -1241.0, 90.0], ["prop_park_bench", "worn", 832.0, -1238.6, 90.0],
	["prop_park_bench", "worn", 832.0, -1233.4, 90.0], ["prop_park_bench", "worn", 832.0, -1231.0, 90.0],
	# ---- the open lawn: sprinklers
	["prop_sprinkler_impact", "clean", 720.0, -1300.0, 0.0, false], ["prop_sprinkler_impact", "clean", 740.0, -1260.0, 0.0, false],
	["prop_sprinkler_impact", "clean", 780.0, -1260.0, 0.0, false], ["prop_sprinkler_impact", "clean", 850.0, -1290.0, 0.0, false],
	["prop_sprinkler_impact", "clean", 870.0, -1200.0, 0.0, false],
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
	var yb := func(x: float, z: float) -> float: return S.g(x, z)
	var py := H.pad_height([PLAY[0], PLAY[1], PLAY[2], PLAY[3]], 180.0, yb, 0.0)
	var by := H.pad_height([BAND[0], BAND[1], BAND[2], BAND[3]], -90.0, yb, 0.0)
	var yf := H.graded(yb, [[PLAY[0], PLAY[1], PLAY[2], PLAY[3], py], [BAND[0], BAND[1], BAND[2], BAND[3], by]])
	var regions: Array = [
		[S.rectp(PLAY[0], PLAY[1], PLAY[2], PLAY[3]), "-"], [S.rectp(BAND[0], BAND[1], BAND[2], BAND[3]), "-"],
		[S.strip(WALK, 3.0), "plaza"], [S.strip(PLAYPATH, 2.0), "plaza"], [S.strip(BANDPATH, 2.5), "plaza"]]
	S.fill(g, S.outline("lens"), regions, S.rectp(600.0, -1500.0, 1000.0, -1000.0), yf)     # all lawn: no sand here
	H.level_pad(g, "sand", PLAY[0], PLAY[1], PLAY[2], PLAY[3], py, yf)
	H.level_pad(g, "concrete", BAND[0], BAND[1], BAND[2], BAND[3], by, yf)
	if PASS >= 2:
		var pady := func(x: float, z: float) -> float:
			if x >= PLAY[0] and x <= PLAY[2] and z >= PLAY[1] and z <= PLAY[3]: return py
			return float(yf.call(x, z))
		for it: Array in ITEMS:
			S.put(props, pady, String(it[0]), String(it[1]), float(it[2]), float(it[3]), float(it[4]), bool(it[5]) if it.size() > 5 else true)
		props.add("prop_bandstand", "worn", Vector3((BAND[0] + BAND[2]) * 0.5, by, (BAND[1] + BAND[3]) * 0.5), -90.0)
		# the playground's picket fence on its pad: a post at every joint, the gate (1.11 m) in the north side at u 723
		var fy := func(_x: float, _z: float) -> float: return py
		H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(PF[0], PF[1]), Vector2(722.445, PF[1]), fy, 2.0, "worn")
		H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(723.555, PF[1]), Vector2(PF[2], PF[1]), fy, 2.0, "worn")
		H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(PF[2], PF[1]), Vector2(PF[2], PF[3]), fy, 2.0, "worn")
		H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(PF[2], PF[3]), Vector2(PF[0], PF[3]), fy, 2.0, "worn")
		H.fence(props, "fence_picket_white", "fence_post_picket", Vector2(PF[0], PF[3]), Vector2(PF[0], PF[1]), fy, 2.0, "worn")
		props.add("fence_gate_picket", "worn", Vector3(723.0, py - 0.02, PF[1]), 0.0)
		H.sc_apply(root, props, dec, SC)
	print("%s: holes %d, play pad %.2f, bandstand pad %.2f" % [NAME, S.holes_seen, py, by])
	H.finish(root, g, props, dec, NAME)
	quit()

