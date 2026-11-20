extends SceneTree
## Piece n_eb_sw (eb fill, the east shore beyond the ring, south-west): GLORIETTA MEADOW and the KNOLL LOOKOUT.
## u 667.6 .. 674 (the ring's east walk) .. 960, v -800 .. -500. Placed at grid [0, 0, 0], yaw 0 (x = u, z = v,
## y = world height). Run once; never when locked.
##
## WHY (planner): the green between the ring and the beach park, across the ring from the Glorietta rec center and
## mews (n_fe_r5 / r7). People cross at the ring's -600 junction (no car can come in: no apron on this side) and take
## the GLORIETTA WALK east to the promenade and the beach (on in n_eb_se); the walk from the Meadow (u 760, from
## n_eb_nw's Meadow Walk) joins it. The land is flat at 4.2 - 4.6 and rises in the south-east to a knoll (6.2 at
## u 900, v -520, on into n_eb's southern neighbour): on its top the KNOLL LOOKOUT, a level paved terrace with a rail,
## benches facing the sea over the beach. In the meadow a BANDSTAND (shade, music on summer evenings) with benches
## round it, two picnic groves with their grills, rail fences at the ring gate (the bins stand against them), lamps
## along the walks, bike racks at the gate. Trees only from the hand list zoning/trees/eb_sw.json.
## LAND: the ground follows it (n_eb_site.g); the lookout terrace stands level at the highest ground under it, the
## knoll graded up to it at 6 %, faces where it stands proud.
const S := preload("res://tools/city/pilot/pieces/n_eb_site.gd")

const RECT := [600.0, -800.0, 960.0, -500.0]
const B := []
const TERR := [
	[890.0, -540.0, 912.0, -526.0],                # KNOLL LOOKOUT: level paved terrace on the knoll's top
]
const PAVE := [
	[674.0, -607.5, 960.0, -604.5, "plaza"],       # GLORIETTA WALK from the ring's -600 junction east (on in n_eb_se)
	[758.5, -800.0, 761.5, -607.5, "plaza"],       # the MEADOW path (u 760) from n_eb_nw's Meadow Walk down to it
	[898.5, -604.5, 901.5, -540.0, "plaza"],       # the path up the knoll to the lookout
]
const FENCES := [
	["fence_vinyl_canal_rail", "fence_post_vinyl", 676.5, -622.0, 676.5, -611.0, "worn"],    # the ring gate's rails, either side
	["fence_vinyl_canal_rail", "fence_post_vinyl", 676.5, -601.0, 676.5, -591.0, "worn"],    # of the walk's mouth
	["fence_vinyl_canal_rail", "fence_post_vinyl", 911.4, -539.6, 911.4, -526.4, "worn"],    # the lookout's rail on its east (sea) edge
]
const ITEMS := [
	# ---- the RING GATE (v -606): bins against the north rail, a bike rack beside the walk, the gate lamp
	["prop_trash_receptacle", "worn", 677.4, -616.0, 90.0],
	["prop_recycling_receptacle", "worn", 677.4, -617.2, 90.0],
	["prop_bike_rack", "worn", 690.0, -610.0, 0.0],
	["prop_lamp_victorian", "worn", 680.0, -602.4, 0.0],
	# ---- lamps: the Glorietta Walk (south side, on the grass), the Meadow path (east side), the knoll path (east side)
	["prop_lamp_victorian", "worn", 720.0, -602.4, 0.0], ["prop_lamp_victorian", "worn", 790.0, -602.4, 0.0],
	["prop_lamp_victorian", "worn", 850.0, -602.4, 0.0], ["prop_lamp_victorian", "worn", 940.0, -602.4, 0.0],
	["prop_lamp_victorian", "worn", 762.6, -780.0, 0.0], ["prop_lamp_victorian", "worn", 762.6, -735.0, 0.0],
	["prop_lamp_victorian", "worn", 762.6, -690.0, 0.0], ["prop_lamp_victorian", "worn", 762.6, -645.0, 0.0],
	["prop_lamp_victorian", "worn", 902.6, -590.0, 0.0], ["prop_lamp_victorian", "worn", 902.6, -560.0, 0.0],
	# ---- the KNOLL LOOKOUT: two benches facing the sea (3.4 m short of the rail), bins against the rail, its lamp
	["prop_park_bench", "worn", 908.0, -535.0, 90.0], ["prop_park_bench", "worn", 908.0, -531.6, 90.0],
	["prop_trash_receptacle", "worn", 910.7, -528.2, 90.0],
	["prop_lamp_victorian", "worn", 891.4, -538.6, 0.0],
	# ---- the BANDSTAND in the meadow east of the Meadow path: shade and summer music; benches facing it from the
	#      north and the west
	["prop_bandstand", "worn", 815.0, -700.0, 0.0],
	["prop_park_bench", "worn", 812.0, -688.0, 180.0], ["prop_park_bench", "worn", 815.4, -688.0, 180.0],
	["prop_park_bench", "worn", 803.6, -701.6, 90.0], ["prop_park_bench", "worn", 803.6, -698.2, 90.0],
	# ---- WEST PICNIC GROVE (between the gate and the Meadow path): tables with their grills
	["prop_picnic_table", "worn", 720.0, -760.0, 0.0], ["prop_bbq_kettle", "worn", 723.2, -760.0, 0.0],
	["prop_picnic_table", "worn", 735.0, -752.0, 90.0], ["prop_bbq_gas_cart", "worn", 735.0, -748.0, 0.0],
	# ---- KNOLL PICNIC GROVE (on the knoll's foot, north of the lookout path's start)
	["prop_picnic_table", "worn", 850.0, -650.0, 0.0], ["prop_bbq_kettle", "worn", 853.2, -650.0, 0.0],
	["prop_picnic_table", "worn", 862.0, -642.0, 90.0], ["prop_bbq_kettle", "worn", 862.0, -638.6, 0.0],
	# ---- benches in pairs: on the Meadow path (east of it, facing west over the meadow), on the Glorietta Walk (south
	#      of it, facing it and the meadow)
	["prop_park_bench", "worn", 764.0, -760.0, -90.0], ["prop_park_bench", "worn", 764.0, -756.6, -90.0],
	["prop_park_bench", "worn", 880.0, -602.6, 180.0], ["prop_park_bench", "worn", 883.4, -602.6, 180.0],
	# ---- sprinklers (no collider)
	["prop_sprinkler_impact", "normal", 720.0, -680.0, 0.0, false], ["prop_sprinkler_impact", "normal", 880.0, -720.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 800.0, -560.0, 0.0, false],
]
const SC := {"out": [], "turn": [], "decals": [], "boxes": []}

func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.run_piece("n_eb_sw", RECT, "", B, TERR, PAVE, FENCES, ITEMS, SC)
	quit()
