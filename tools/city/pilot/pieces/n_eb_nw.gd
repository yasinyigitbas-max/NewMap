extends SceneTree
## Piece n_eb_nw (eb fill, the east shore beyond the ring, north-west): RINGSIDE MEADOW.
## u 674.3 (the ring's east walk) .. 960, v -1100 .. -800, less the bridge approach (s_br_appr_3/4) that crosses its
## north-east corner and the land north-east of the bridge (n_eb_site NCUT: that goes to n_eb_ne). Placed at grid [0, 0, 0],
## yaw 0 (x = u, z = v, y = world height). Run once; never when locked.
##
## WHY (planner): the first green beyond the ring, between the boulevard and the beach park. The apartment band and the
## ring strip (n_fe_*) are across the ring; their people cross at the ring's junctions at v -1000 and v -800 (no car can
## come in: the ring has no apron on this side, the bridge approach none either) and walk east to the sea. The land rises
## gently from 4.2 at the ring to 5.5 under the bridge's verge: a quiet MEADOW for picnics and an evening walk, its paths
## leading on to the beach: the MEADOW WALK from the -800 junction (on through n_eb_ne to the promenade) and the RING
## GATE loop from the -1000 junction down to it. Picnic groves with their grills, benches in pairs, park lamps, bike
## racks for the riders off the ring path at the two gates. The bridge's verge is kept
## clear. Trees come only from the hand list zoning/trees/eb_nw.json.
## LAND: the ground follows it (n_eb_site.g): 5 cm over it, eased onto the ring's walk (4.15) and the bridge's edge
## within 12 m; no buildings here.
const S := preload("res://tools/city/pilot/pieces/n_eb_site.gd")

const RECT := [600.0, -1100.0, 960.0, -800.0]
const B := []
const TERR := []
const PAVE := [
	[674.0, -1007.5, 831.5, -1004.5, "plaza"],     # RING GATE walk: from the ring's walk at the -1000 junction east into the meadow
	[828.5, -1004.5, 831.5, -807.5, "plaza"],      # its south leg down to the Meadow Walk (the loop)
	[674.0, -807.5, 960.0, -804.5, "plaza"],       # MEADOW WALK: from the -800 junction east (on in n_eb_ne to the promenade)
	[758.5, -804.5, 761.5, -800.0, "plaza"],       # the link south into n_eb_sw's Glorietta path (u 760)
]
## (check_life, 20 Nov: the open rails planned at the two gates had ends "leading nowhere"; they went, and the bins that
## stood against them with them: a bin in the open is a fault; Yasin: delete when unsure)
const FENCES := []
const ITEMS := [
	# ---- RING GATE (v -1006): a bike rack beside the walk for the ring path's riders
	["prop_bike_rack", "worn", 688.0, -1010.0, 0.0],
	["prop_lamp_victorian", "worn", 680.0, -1002.6, 0.0],              # lights the gate
	# ---- MEADOW GATE (v -806): a rack
	["prop_bike_rack", "worn", 690.0, -810.0, 0.0],
	["prop_lamp_victorian", "worn", 680.0, -802.8, 0.0],
	# ---- lamps along the Ring Gate walk (north side, on the grass 1.1 m off its edge) and its south leg (east side)
	["prop_lamp_victorian", "worn", 720.0, -1008.6, 0.0], ["prop_lamp_victorian", "worn", 765.0, -1008.6, 0.0],
	["prop_lamp_victorian", "worn", 810.0, -1008.6, 0.0],
	["prop_lamp_victorian", "worn", 832.6, -965.0, 0.0], ["prop_lamp_victorian", "worn", 832.6, -920.0, 0.0],
	["prop_lamp_victorian", "worn", 832.6, -875.0, 0.0], ["prop_lamp_victorian", "worn", 832.6, -835.0, 0.0],
	# ---- lamps along the Meadow Walk (north side)
	["prop_lamp_victorian", "worn", 725.0, -808.6, 0.0], ["prop_lamp_victorian", "worn", 790.0, -808.6, 0.0],
	["prop_lamp_victorian", "worn", 870.0, -808.6, 0.0], ["prop_lamp_victorian", "worn", 915.0, -808.6, 0.0],
	# ---- the loop's corner: a drinking fountain where the two legs meet, a bench pair looking down the meadow
	["prop_drinking_fountain", "worn", 833.2, -1009.2, 0.0],
	["prop_park_bench", "worn", 760.0, -1010.0, 0.0], ["prop_park_bench", "worn", 763.2, -1010.0, 0.0],   # north of the walk, facing south over it to the meadow
	# ---- NORTH PICNIC GROVE (inside the loop's corner, on the high ground toward the bridge): tables with a grill each
	["prop_picnic_table", "worn", 850.0, -1022.0, 0.0], ["prop_bbq_kettle", "worn", 853.2, -1022.0, 0.0],
	["prop_picnic_table", "worn", 862.0, -1030.0, 30.0], ["prop_bbq_kettle", "worn", 865.0, -1031.8, 0.0],
	# ---- MEADOW PICNIC GROVE (in the middle of the meadow, west of the loop)
	["prop_picnic_table", "worn", 760.0, -905.0, 0.0], ["prop_bbq_kettle", "worn", 763.2, -905.0, 0.0],
	["prop_picnic_table", "worn", 772.0, -912.0, 90.0], ["prop_bbq_gas_cart", "worn", 772.0, -916.0, 0.0],
	["prop_picnic_table", "worn", 748.0, -916.0, 90.0], ["prop_bbq_kettle", "worn", 748.0, -919.4, 0.0],
	# ---- benches in pairs along the loop's south leg (east of it, facing west over the meadow) and the Meadow Walk
	["prop_park_bench", "worn", 834.4, -900.0, -90.0], ["prop_park_bench", "worn", 834.4, -896.6, -90.0],
	["prop_park_bench", "worn", 900.0, -810.4, 0.0], ["prop_park_bench", "worn", 903.2, -810.4, 0.0],
	["prop_park_bench", "worn", 740.0, -810.4, 0.0], ["prop_park_bench", "worn", 743.2, -810.4, 0.0],
	# ---- sprinklers keep the meadow green (no collider: walked over)
	["prop_sprinkler_impact", "normal", 760.0, -960.0, 0.0, false], ["prop_sprinkler_impact", "normal", 900.0, -880.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 720.0, -860.0, 0.0, false],
]
const SC := {"out": [], "turn": [], "decals": [], "boxes": []}

func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.run_piece("n_eb_nw", RECT, "minus_ncut", B, TERR, PAVE, FENCES, ITEMS, SC)
	quit()
