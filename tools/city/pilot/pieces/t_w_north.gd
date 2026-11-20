extends SceneTree
## Piece t_w_north: hand-placed TREES of the west fill (University session, 20 Nov; docs/TREE_PLAN.md), world frame (layout
## row (0, 0, 0): x = u, z = v, y absolute). Each tree: place, species, size, the reason it is there. Rules applied when
## the spots were chosen (OUT/trees_w.py): trunk on grass or mulch (and 1 m round it) of the piece it stands in, 4 m
## from every building, 1.5 m from fences, 2.2 m from other props, 7 m between trees; parks and courts: clumps round
## the seating; house yards: one per two houses by the patio; the beach side: palms; the ridge: pines; the gritty
## edge: one scrappy tree; industrial and the shop fronts: none; at most 8 broadleaf / 12 trees within 60 m of any
## paved point of the west fill. 51 trees.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const TREES := [
	[-772.24, -833.79, 6.078, "tree_ficus_a", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-766.43, -841.24, 6.020, "tree_jacaranda_b", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-722.03, -834.75, 6.076, "tree_coral_b", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-732.17, -838.81, 6.048, "tree_magnolia_b", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-760.36, -846.79, 5.979, "tree_jacaranda_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-716.21, -841.50, 6.064, "tree_coral_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-717.96, -849.48, 6.042, "tree_magnolia_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-706.45, -839.90, 6.081, "tree_jacaranda_b", 0.85, "court: shade round the seating (adirondack_wood)"],
	[-454.17, -915.99, 6.060, "tree_coral_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-455.43, -902.02, 6.038, "tree_jacaranda_b", 0.85, "court: shade round the seating (picnic_table)"],
	[-446.00, -908.84, 6.047, "tree_coral_b", 0.85, "court: shade round the seating (picnic_table)"],
	[-446.47, -916.56, 6.059, "tree_magnolia_b", 0.85, "court: shade round the seating (picnic_table)"],
	[-489.22, -895.13, 6.134, "tree_ficus_b", 0.85, "court: shade round the seating (adirondack_white)"],
	[-415.89, -932.70, 6.160, "tree_jacaranda_a", 0.85, "court: shade round the seating (park_bench)"],
	[-542.47, -923.35, 6.160, "tree_magnolia_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-532.96, -929.97, 6.180, "tree_ficus_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-514.33, -925.42, 6.180, "tree_coral_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-534.51, -910.03, 6.180, "tree_ficus_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-542.49, -912.67, 6.160, "tree_jacaranda_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-514.23, -910.75, 6.180, "tree_magnolia_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-941.57, -838.48, 4.506, "tree_coral_a", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-950.53, -843.72, 4.423, "tree_magnolia_a", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-943.00, -847.24, 4.497, "tree_ficus_a", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-901.48, -839.56, 4.987, "tree_coral_b", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-832.74, -837.18, 5.860, "tree_ficus_b", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-841.27, -841.77, 5.713, "tree_jacaranda_a", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-836.22, -847.48, 5.707, "tree_coral_a", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-961.50, -834.24, 4.326, "tree_magnolia_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-841.99, -830.61, 5.829, "tree_ficus_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-851.49, -835.67, 5.662, "tree_jacaranda_b", 0.85, "court: shade round the seating (picnic_table)"],
	[-912.89, -924.18, 4.512, "tree_ficus_b", 0.85, "park: shade round the seating (play_structure)"],
	[-923.47, -933.24, 4.415, "tree_jacaranda_a", 0.85, "park: shade round the seating (park_bench)"],
	[-950.92, -914.98, 4.346, "tree_coral_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-957.45, -918.05, 4.308, "tree_magnolia_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-992.82, -1361.01, 2.247, "tree_eucalyptus_a", 0.85, "park: shade round the seating (park_bench)"],
	[-993.05, -1298.00, 2.314, "tree_eucalyptus_b", 0.85, "park: shade round the seating (park_bench)"],
	[-993.03, -1237.02, 2.401, "tree_eucalyptus_a", 0.85, "park: shade round the seating (park_bench)"],
	[-988.09, -1245.35, 2.329, "tree_eucalyptus_b", 0.85, "park: shade round the seating (park_bench)"],
	[-934.07, -1216.59, 2.151, "tree_jacaranda_a", 0.85, "park: shade round the seating (park_bench)"],
	[-927.42, -1224.88, 2.155, "tree_coral_a", 0.85, "park: shade round the seating (park_bench)"],
	[-665.03, -923.29, 6.162, "tree_magnolia_a", 0.85, "park: shade round the seating (park_bench)"],
	[-675.10, -924.75, 6.160, "tree_ficus_a", 0.85, "park: shade round the seating (park_bench)"],
	[-994.00, -1390.00, 2.201, "tree_eucalyptus_b", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1374.00, 2.228, "tree_eucalyptus_a", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1342.00, 2.278, "tree_eucalyptus_b", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1326.00, 2.296, "tree_eucalyptus_a", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1310.00, 2.313, "tree_eucalyptus_b", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1278.00, 2.326, "tree_eucalyptus_a", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1262.00, 2.346, "tree_eucalyptus_b", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1230.00, 2.428, "tree_eucalyptus_a", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1214.00, 2.487, "tree_eucalyptus_b", 0.85, "buffer: the windbreak along the ring road"]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("t_w_north")
	for t: Array in TREES:
		c.put(String(t[3]), "normal", Vector3(float(t[0]), float(t[2]), float(t[1])), c.rr.randf_range(0, 360), String(t[5]), false, float(t[4]))
	c.root.set_meta("stalls", [])
	c.props.build(c.root, L.K)
	print("t_w_north: trees %d" % c.props.count())
	L.K.save_piece(c.root, "t_w_north")
	quit()
