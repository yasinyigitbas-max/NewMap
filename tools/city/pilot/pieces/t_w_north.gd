extends SceneTree
## Piece t_w_north: hand-placed TREES of the west fill (University session, 20 Nov; docs/TREE_PLAN.md), world frame (layout
## row (0, 0, 0): x = u, z = v, y absolute). Each tree: place, species, size, the reason it is there. Rules applied when
## the spots were chosen (OUT/trees_w.py): trunk on grass or mulch (and 1 m round it) of the piece it stands in, 4 m
## from every building, 1.5 m from fences, 2.2 m from other props, 7 m between trees; parks and courts: clumps round
## the seating; house yards: one per two houses by the patio; the beach side: palms; the ridge: pines; the gritty
## edge: one scrappy tree; industrial and the shop fronts: none; at most 8 broadleaf / 12 trees within 60 m of any
## paved point of the west fill. 44 trees.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const TREES := [
	[-762.21, -832.36, 6.074, "tree_ficus_a", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-772.46, -833.65, 6.078, "tree_jacaranda_b", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-767.14, -841.50, 6.022, "tree_coral_b", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-724.17, -835.00, 6.074, "tree_magnolia_b", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-732.27, -837.38, 6.055, "tree_ficus_b", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-725.90, -843.49, 6.038, "tree_jacaranda_a", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-718.07, -838.98, 6.067, "tree_coral_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-720.43, -849.24, 6.036, "tree_magnolia_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-453.55, -915.48, 6.059, "tree_jacaranda_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-455.68, -900.31, 6.039, "tree_magnolia_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-445.53, -907.11, 6.044, "tree_ficus_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-446.70, -917.40, 6.059, "tree_jacaranda_b", 0.85, "court: shade round the seating (picnic_table)"],
	[-488.43, -895.02, 6.129, "tree_coral_b", 0.85, "court: shade round the seating (adirondack_white)"],
	[-496.17, -895.97, 6.134, "tree_magnolia_b", 0.85, "court: shade round the seating (adirondack_white)"],
	[-541.53, -925.40, 6.162, "tree_coral_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-513.73, -924.60, 6.180, "tree_jacaranda_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-533.10, -908.62, 6.180, "tree_magnolia_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-514.47, -911.35, 6.180, "tree_jacaranda_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-944.73, -847.44, 4.482, "tree_coral_a", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-900.43, -843.48, 4.981, "tree_ficus_a", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-835.06, -839.64, 5.809, "tree_jacaranda_b", 0.85, "court: shade round the seating (bbq_kettle)"],
	[-960.53, -835.72, 4.334, "tree_ficus_b", 0.85, "court: shade round the seating (picnic_table)"],
	[-953.00, -839.24, 4.401, "tree_jacaranda_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-841.25, -828.60, 5.858, "tree_coral_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-851.48, -831.56, 5.711, "tree_magnolia_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-846.31, -837.84, 5.700, "tree_ficus_a", 0.85, "court: shade round the seating (picnic_table)"],
	[-921.27, -918.77, 4.487, "tree_coral_b", 0.85, "park: shade round the seating (play_structure)"],
	[-923.50, -932.64, 4.417, "tree_ficus_b", 0.85, "park: shade round the seating (park_bench)"],
	[-947.99, -915.61, 4.353, "tree_jacaranda_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-957.49, -920.67, 4.302, "tree_coral_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-992.66, -1361.33, 2.247, "tree_eucalyptus_a", 0.85, "park: shade round the seating (park_bench)"],
	[-993.07, -1300.84, 2.313, "tree_eucalyptus_b", 0.85, "park: shade round the seating (park_bench)"],
	[-993.05, -1239.05, 2.394, "tree_eucalyptus_a", 0.85, "park: shade round the seating (park_bench)"],
	[-926.57, -1224.68, 2.155, "tree_coral_b", 0.85, "park: shade round the seating (park_bench)"],
	[-994.00, -1390.00, 2.201, "tree_eucalyptus_a", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1374.00, 2.228, "tree_eucalyptus_b", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1342.00, 2.278, "tree_eucalyptus_a", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1326.00, 2.296, "tree_eucalyptus_b", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1310.00, 2.313, "tree_eucalyptus_a", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1278.00, 2.326, "tree_eucalyptus_b", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1262.00, 2.346, "tree_eucalyptus_a", 0.85, "buffer: the windbreak along the ring road"],
	[-994.00, -1246.00, 2.376, "tree_eucalyptus_b", 0.85, "buffer: the windbreak along the ring road"],
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
