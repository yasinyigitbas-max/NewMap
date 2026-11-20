extends SceneTree
## Piece t_w_edge: hand-placed TREES of the west fill (University session, 20 Nov; docs/TREE_PLAN.md), world frame (layout
## row (0, 0, 0): x = u, z = v, y absolute). Each tree: place, species, size, the reason it is there. Rules applied when
## the spots were chosen (OUT/trees_w.py): trunk on grass or mulch (and 1 m round it) of the piece it stands in, 4 m
## from every building, 1.5 m from fences, 2.2 m from other props, 7 m between trees; parks and courts: clumps round
## the seating; house yards: one per two houses by the patio; the beach side: palms; the ridge: pines; the gritty
## edge: one scrappy tree; industrial and the shop fronts: none; at most 8 broadleaf / 12 trees within 60 m of any
## paved point of the west fill. 20 trees.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const TREES := [
	[-920.30, 240.05, 2.183, "palm_queen_b", 1.00, "back yard: a yard tree by the patio"],
	[-905.30, 239.55, 2.175, "palm_mexican_fan_a", 1.00, "back yard: a yard tree by the patio"],
	[-837.60, 240.05, 2.060, "palm_queen_a", 1.00, "back yard: a yard tree by the patio"],
	[-875.30, 240.05, 2.130, "palm_queen_b", 1.00, "back yard: a yard tree by the patio"],
	[-953.15, 215.06, 2.187, "tree_magnolia_a", 0.85, "park: shade round the seating (park_bench)"],
	[-958.92, 233.62, 2.159, "tree_ficus_a", 0.85, "park: shade round the seating (picnic_table)"],
	[-781.77, 237.05, 2.170, "palm_queen_b", 1.00, "back yard: a yard tree by the patio"],
	[-768.43, 236.55, 2.223, "palm_mexican_fan_a", 1.00, "back yard: a yard tree by the patio"],
	[-729.36, 237.05, 2.611, "palm_queen_a", 1.00, "back yard: a yard tree by the patio"],
	[-699.76, 236.95, 3.080, "palm_queen_b", 1.00, "back yard: a yard tree by the patio"],
	[-630.43, 236.55, 4.007, "palm_mexican_fan_a", 1.00, "back yard: a yard tree by the patio"],
	[-581.77, 241.95, 4.103, "palm_queen_a", 1.00, "back yard: a yard tree by the patio"],
	[-568.43, 242.05, 3.945, "palm_queen_b", 1.00, "back yard: a yard tree by the patio"],
	[-529.36, 243.70, 3.415, "palm_mexican_fan_a", 1.00, "back yard: a yard tree by the patio"],
	[-499.76, 241.50, 2.950, "palm_queen_a", 1.00, "back yard: a yard tree by the patio"],
	[-430.43, 241.95, 2.162, "palm_queen_b", 1.00, "back yard: a yard tree by the patio"],
	[-381.77, 246.55, 2.186, "palm_mexican_fan_a", 1.00, "back yard: a yard tree by the patio"],
	[-368.43, 247.05, 2.181, "palm_queen_a", 1.00, "back yard: a yard tree by the patio"],
	[-329.36, 247.05, 2.188, "palm_queen_b", 1.00, "back yard: a yard tree by the patio"],
	[-299.76, 249.60, 2.195, "palm_mexican_fan_a", 1.00, "back yard: a yard tree by the patio"]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("t_w_edge")
	for t: Array in TREES:
		c.put(String(t[3]), "normal", Vector3(float(t[0]), float(t[2]), float(t[1])), c.rr.randf_range(0, 360), String(t[5]), false, float(t[4]))
	c.root.set_meta("stalls", [])
	c.props.build(c.root, L.K)
	print("t_w_edge: trees %d" % c.props.count())
	L.K.save_piece(c.root, "t_w_edge")
	quit()
