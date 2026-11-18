extends SceneTree
## PREVIEW ONLY (never in the game): grass round the ring half NW, the north end of Glorietta Blvd (b141 to the 3rd St T, with the bridge gap) and its stems to the Adela lattice,
## in grid coordinates (layout row pos [0, 0, -8000]). See road_rg_NW.build_review_ground.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_review_ground("zz_ring_nw_ground_e", {"ring": [1967.0, 2700.0], "stems": ["657.3,-800.0", "660.0,-1000.0", "660.0,-1200.0", "660.0,-1400.0"], "boxes": [[440.0, -1520.0, 800.0, -770.0]], "no_quads": ["500.0,-1400.0"]})
	quit()
