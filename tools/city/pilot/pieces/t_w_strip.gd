extends SceneTree
## Piece t_w_strip: hand-placed TREES of the west fill (University session, 20 Nov; docs/TREE_PLAN.md), world frame (layout
## row (0, 0, 0): x = u, z = v, y absolute). Each tree: place, species, size, the reason it is there. Rules applied when
## the spots were chosen (OUT/trees_w.py): trunk on grass or mulch (and 1 m round it) of the piece it stands in, 4 m
## from every building, 1.5 m from fences, 2.2 m from other props, 7 m between trees; parks and courts: clumps round
## the seating; house yards: one per two houses by the patio; the beach side: palms; the ridge: pines; the gritty
## edge: one scrappy tree; industrial and the shop fronts: none; at most 8 broadleaf / 12 trees within 60 m of any
## paved point of the west fill. 96 trees.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const TREES := [
	[-440.20, -348.37, 6.118, "tree_magnolia_b", 0.85, "park: shade round the seating (play_structure)"],
	[-432.19, -352.48, 6.139, "tree_ficus_b", 0.85, "park: shade round the seating (play_structure)"],
	[-433.38, -334.75, 6.117, "tree_jacaranda_a", 0.85, "park: shade round the seating (park_bench)"],
	[-572.42, -355.78, 6.176, "tree_magnolia_a", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-582.50, -362.20, 6.174, "tree_ficus_a", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-573.92, -365.80, 6.182, "tree_jacaranda_b", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-520.41, -358.41, 6.163, "tree_coral_b", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-529.60, -358.39, 6.171, "tree_magnolia_b", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-524.36, -366.46, 6.169, "tree_ficus_b", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-476.51, -356.88, 6.103, "tree_jacaranda_a", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-486.50, -362.23, 6.128, "tree_coral_a", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-481.79, -246.37, 6.076, "tree_ficus_a", 0.85, "park: shade round the seating (park_bench)"],
	[-478.78, -231.34, 6.058, "tree_coral_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-476.42, -239.47, 6.048, "tree_magnolia_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-471.45, -223.25, 6.072, "tree_jacaranda_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-465.50, -227.45, 6.049, "tree_coral_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-483.16, -213.29, 6.157, "tree_magnolia_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-493.22, -215.57, 6.169, "tree_ficus_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-487.49, -223.10, 6.116, "tree_jacaranda_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-833.45, -779.41, 6.077, "tree_ficus_a", 0.85, "back yard: a yard tree by the patio"],
	[-833.00, -748.09, 5.985, "tree_jacaranda_b", 0.85, "back yard: a yard tree by the patio"],
	[-831.00, -627.16, 6.063, "tree_magnolia_b", 0.85, "back yard: a yard tree by the patio"],
	[-875.94, -630.55, 5.527, "tree_ficus_b", 0.85, "back yard: a yard tree by the patio"],
	[-833.45, -726.34, 5.958, "tree_coral_a", 0.85, "back yard: a yard tree by the patio"],
	[-969.27, -766.10, 4.285, "tree_magnolia_a", 0.85, "back yard: a yard tree by the patio"],
	[-831.30, -714.16, 5.977, "tree_ficus_a", 0.85, "back yard: a yard tree by the patio"],
	[-833.00, -682.84, 5.958, "tree_jacaranda_b", 0.85, "back yard: a yard tree by the patio"],
	[-931.94, -766.80, 4.681, "tree_coral_b", 0.85, "back yard: a yard tree by the patio"],
	[-905.06, -762.45, 5.076, "tree_magnolia_b", 0.85, "back yard: a yard tree by the patio"],
	[-831.00, -579.41, 6.050, "tree_ficus_b", 0.85, "back yard: a yard tree by the patio"],
	[-835.20, -548.09, 5.672, "tree_jacaranda_a", 0.85, "back yard: a yard tree by the patio"],
	[-833.00, -569.84, 5.934, "tree_coral_a", 0.85, "back yard: a yard tree by the patio"],
	[-833.45, -427.16, 4.269, "tree_magnolia_a", 0.85, "back yard: a yard tree by the patio"],
	[-875.94, -430.55, 4.301, "tree_ficus_a", 0.85, "back yard: a yard tree by the patio"],
	[-833.20, -557.66, 5.803, "tree_jacaranda_b", 0.85, "back yard: a yard tree by the patio"],
	[-833.45, -526.34, 5.426, "tree_coral_b", 0.85, "back yard: a yard tree by the patio"],
	[-969.27, -565.90, 4.268, "tree_magnolia_b", 0.85, "back yard: a yard tree by the patio"],
	[-831.25, -514.16, 5.280, "tree_ficus_b", 0.85, "back yard: a yard tree by the patio"],
	[-833.30, -482.84, 4.829, "tree_jacaranda_a", 0.85, "back yard: a yard tree by the patio"],
	[-931.94, -566.95, 4.613, "tree_coral_a", 0.85, "back yard: a yard tree by the patio"],
	[-905.06, -562.45, 4.948, "tree_magnolia_a", 0.85, "back yard: a yard tree by the patio"],
	[-831.00, -379.41, 4.184, "tree_ficus_a", 0.85, "back yard: a yard tree by the patio"],
	[-833.45, -348.09, 4.181, "tree_jacaranda_b", 0.85, "back yard: a yard tree by the patio"],
	[-961.06, -365.15, 4.180, "tree_coral_b", 0.85, "back yard: a yard tree by the patio"],
	[-833.00, -369.84, 4.179, "tree_magnolia_b", 0.85, "back yard: a yard tree by the patio"],
	[-831.45, -227.16, 4.166, "tree_ficus_b", 0.85, "back yard: a yard tree by the patio"],
	[-875.94, -229.85, 4.177, "tree_jacaranda_a", 0.85, "back yard: a yard tree by the patio"],
	[-831.45, -357.66, 4.180, "tree_coral_a", 0.85, "back yard: a yard tree by the patio"],
	[-835.45, -326.34, 4.183, "tree_magnolia_a", 0.85, "back yard: a yard tree by the patio"],
	[-969.27, -367.15, 4.181, "tree_ficus_a", 0.85, "back yard: a yard tree by the patio"],
	[-831.25, -314.16, 4.185, "tree_jacaranda_b", 0.85, "back yard: a yard tree by the patio"],
	[-833.30, -282.84, 4.181, "tree_coral_b", 0.85, "back yard: a yard tree by the patio"],
	[-931.94, -366.50, 4.181, "tree_magnolia_b", 0.85, "back yard: a yard tree by the patio"],
	[-834.40, -179.41, 4.192, "tree_jacaranda_b", 0.85, "back yard: a yard tree by the patio"],
	[-836.00, -148.09, 4.510, "tree_torrey_pine_a", 0.85, "back yard: a yard tree by the patio"],
	[-836.40, -169.84, 4.238, "tree_torrey_pine_b", 0.85, "back yard: a yard tree by the patio"],
	[-831.05, -27.16, 7.763, "tree_coral_a", 0.85, "back yard: a yard tree by the patio"],
	[-875.94, -30.80, 6.481, "tree_jacaranda_b", 0.85, "back yard: a yard tree by the patio"],
	[-834.00, -157.66, 4.370, "tree_torrey_pine_a", 0.85, "back yard: a yard tree by the patio"],
	[-836.75, -126.34, 4.976, "tree_torrey_pine_b", 0.85, "back yard: a yard tree by the patio"],
	[-969.27, -165.90, 4.176, "tree_coral_a", 0.85, "back yard: a yard tree by the patio"],
	[-834.05, -114.16, 5.326, "tree_jacaranda_b", 0.85, "back yard: a yard tree by the patio"],
	[-833.25, -82.84, 6.277, "tree_torrey_pine_a", 0.85, "back yard: a yard tree by the patio"],
	[-931.94, -166.10, 4.166, "tree_torrey_pine_b", 0.85, "back yard: a yard tree by the patio"],
	[-905.06, -162.45, 4.129, "tree_coral_a", 0.85, "back yard: a yard tree by the patio"],
	[-706.94, -312.45, 5.008, "tree_ficus_a", 0.85, "back yard: a yard tree by the patio"],
	[-721.44, -311.55, 4.764, "tree_jacaranda_b", 0.85, "back yard: a yard tree by the patio"],
	[-729.36, -362.05, 4.739, "tree_coral_b", 0.85, "back yard: a yard tree by the patio"],
	[-692.44, -311.75, 5.268, "tree_magnolia_b", 0.85, "back yard: a yard tree by the patio"],
	[-699.76, -364.50, 5.174, "tree_ficus_b", 0.85, "back yard: a yard tree by the patio"],
	[-779.44, -311.80, 4.210, "tree_jacaranda_a", 0.85, "back yard: a yard tree by the patio"],
	[-663.44, -311.25, 5.751, "tree_coral_a", 0.85, "back yard: a yard tree by the patio"],
	[-735.94, -310.70, 4.596, "tree_magnolia_a", 0.85, "back yard: a yard tree by the patio"],
	[-619.94, -309.60, 6.158, "tree_ficus_a", 0.85, "back yard: a yard tree by the patio"],
	[-852.65, 44.86, 6.535, "tree_torrey_pine_a", 0.85, "park: shade round the seating (park_bench)"],
	[-843.44, 44.35, 6.829, "tree_torrey_pine_b", 0.85, "park: shade round the seating (park_bench)"],
	[-856.13, 155.44, 2.717, "tree_jacaranda_b", 0.85, "park: shade round the seating (park_bench)"],
	[-865.49, 153.69, 2.711, "tree_torrey_pine_a", 0.85, "park: shade round the seating (park_bench)"],
	[-859.16, 147.10, 2.904, "tree_torrey_pine_b", 0.85, "park: shade round the seating (park_bench)"],
	[-862.31, 136.00, 3.188, "tree_coral_a", 0.85, "park: shade round the seating (play_structure)"],
	[-871.35, 135.62, 3.100, "tree_jacaranda_b", 0.85, "park: shade round the seating (play_structure)"],
	[-864.20, 128.47, 3.378, "tree_torrey_pine_a", 0.85, "park: shade round the seating (play_structure)"],
	[-948.65, 52.31, 3.976, "tree_torrey_pine_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-955.11, 49.46, 3.964, "tree_coral_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-929.05, 44.01, 4.415, "tree_torrey_pine_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-939.47, 41.10, 4.285, "tree_torrey_pine_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-931.05, 33.51, 4.576, "tree_coral_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-955.38, 69.44, 3.655, "tree_torrey_pine_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-948.29, 63.64, 3.779, "tree_torrey_pine_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-925.46, 70.38, 3.950, "tree_coral_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-934.65, 67.04, 3.863, "tree_jacaranda_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-926.55, 59.73, 4.144, "tree_torrey_pine_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-958.84, 93.21, 3.265, "tree_torrey_pine_b", 0.85, "park: shade round the seating (picnic_table)"],
	[-958.73, 83.56, 3.417, "tree_coral_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-938.50, 55.33, 4.054, "tree_jacaranda_b", 0.85, "park: shade round the seating (bbq_kettle)"],
	[-942.02, 49.17, 4.099, "tree_torrey_pine_a", 0.85, "park: shade round the seating (bbq_kettle)"]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("t_w_strip")
	for t: Array in TREES:
		c.put(String(t[3]), "normal", Vector3(float(t[0]), float(t[2]), float(t[1])), c.rr.randf_range(0, 360), String(t[5]), false, float(t[4]))
	c.root.set_meta("stalls", [])
	c.props.build(c.root, L.K)
	print("t_w_strip: trees %d" % c.props.count())
	L.K.save_piece(c.root, "t_w_strip")
	quit()
