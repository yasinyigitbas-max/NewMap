extends SceneTree
## Piece t_w_civic: hand-placed TREES of the west fill (University session, 20 Nov; docs/TREE_PLAN.md), world frame (layout
## row (0, 0, 0): x = u, z = v, y absolute). Each tree: place, species, size, the reason it is there. Rules applied when
## the spots were chosen (OUT/trees_w.py): trunk on grass or mulch (and 1 m round it) of the piece it stands in, 4 m
## from every building, 1.5 m from fences, 2.2 m from other props, 7 m between trees; parks and courts: clumps round
## the seating; house yards: one per two houses by the patio; the beach side: palms; the ridge: pines; the gritty
## edge: one scrappy tree; industrial and the shop fronts: none; at most 8 broadleaf / 12 trees within 60 m of any
## paved point of the west fill. 46 trees.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const TREES := [
	[-337.39, -762.50, 6.210, "tree_jacaranda_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-236.49, -745.95, 6.180, "tree_coral_a", 0.85, "park: shade round the seating (park_bench)"],
	[-228.23, -752.43, 6.180, "tree_magnolia_a", 0.85, "park: shade round the seating (park_bench)"],
	[-214.80, -744.49, 6.173, "tree_ficus_a", 0.85, "park: shade round the seating (park_bench)"],
	[-215.45, -752.47, 6.175, "tree_jacaranda_b", 0.85, "park: shade round the seating (park_bench)"],
	[-374.42, -633.87, 6.190, "tree_magnolia_b", 0.85, "park: shade round the seating (play_structure)"],
	[-366.66, -639.50, 6.200, "tree_ficus_b", 0.85, "park: shade round the seating (play_structure)"],
	[-374.42, -648.34, 6.194, "tree_jacaranda_a", 0.85, "park: shade round the seating (park_bench)"],
	[-369.07, -677.33, 6.200, "tree_magnolia_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-376.38, -679.96, 6.198, "tree_ficus_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-367.96, -685.50, 6.203, "tree_jacaranda_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-359.98, -666.50, 6.200, "tree_coral_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-361.40, -675.45, 6.207, "tree_magnolia_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-356.89, -572.45, 6.198, "tree_ficus_b", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-365.62, -578.57, 6.189, "tree_jacaranda_a", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-357.00, -515.21, 6.220, "tree_coral_a", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-366.30, -520.35, 6.215, "tree_magnolia_a", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-358.37, -524.42, 6.220, "tree_ficus_a", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-356.32, -468.81, 6.230, "tree_jacaranda_b", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-365.90, -472.21, 6.226, "tree_coral_b", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-361.23, -478.47, 6.230, "tree_magnolia_b", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-83.36, -560.70, 6.180, "tree_ficus_b", 0.85, "park: shade round the seating (park_bench)"],
	[-62.06, -526.34, 6.180, "tree_jacaranda_a", 0.85, "park: shade round the seating (park_bench)"],
	[-83.16, -501.54, 6.180, "tree_coral_a", 0.85, "park: shade round the seating (park_bench)"],
	[-64.18, -465.12, 6.160, "tree_magnolia_a", 0.85, "park: shade round the seating (park_bench)"],
	[-64.42, -474.57, 6.160, "tree_ficus_a", 0.85, "park: shade round the seating (park_bench)"],
	[-86.07, -425.30, 6.174, "tree_jacaranda_b", 0.85, "park: shade round the seating (park_bench)"],
	[-230.38, -259.80, 6.172, "tree_ficus_b", 0.85, "park: shade round the seating (park_bench)"],
	[-221.62, -265.24, 6.180, "tree_jacaranda_a", 0.85, "park: shade round the seating (park_bench)"],
	[-191.98, -282.88, 6.162, "tree_coral_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-158.63, -280.88, 6.163, "tree_magnolia_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-168.35, -283.39, 6.180, "tree_ficus_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-185.69, -259.93, 6.171, "tree_coral_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-183.10, -269.49, 6.180, "tree_magnolia_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-179.94, -276.61, 6.180, "tree_magnolia_a", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-237.37, -640.50, 6.180, "tree_coral_b", 0.85, "park: shade round the seating (park_bench)"],
	[-227.84, -643.81, 6.179, "tree_magnolia_b", 0.85, "park: shade round the seating (park_bench)"],
	[-227.54, -620.88, 6.179, "tree_ficus_b", 0.85, "park: shade round the seating (park_bench)"],
	[-237.41, -623.23, 6.180, "tree_jacaranda_a", 0.85, "park: shade round the seating (park_bench)"],
	[-222.40, -627.43, 6.180, "tree_coral_a", 0.85, "park: shade round the seating (park_bench)"],
	[-222.80, -636.95, 6.180, "tree_magnolia_a", 0.85, "park: shade round the seating (park_bench)"],
	[-228.36, -679.79, 6.179, "tree_magnolia_b", 0.85, "park: shade round the seating (park_bench)"],
	[-237.43, -682.02, 6.176, "tree_ficus_b", 0.85, "park: shade round the seating (park_bench)"],
	[-118.78, -518.80, 6.180, "tree_jacaranda_a", 0.85, "park: shade round the seating (play_structure)"],
	[-125.32, -523.72, 6.180, "tree_coral_a", 0.85, "park: shade round the seating (play_structure)"],
	[-118.86, -527.32, 6.180, "tree_magnolia_a", 0.85, "park: shade round the seating (play_structure)"]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("t_w_civic")
	for t: Array in TREES:
		c.put(String(t[3]), "normal", Vector3(float(t[0]), float(t[2]), float(t[1])), c.rr.randf_range(0, 360), String(t[5]), false, float(t[4]))
	c.root.set_meta("stalls", [])
	c.props.build(c.root, L.K)
	print("t_w_civic: trees %d" % c.props.count())
	L.K.save_piece(c.root, "t_w_civic")
	quit()
