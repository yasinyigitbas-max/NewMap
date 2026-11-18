extends SceneTree
## PREVIEW ONLY (never in the game): grass round the ring half NW, 1st St on the bay front (b163 from mid-block, b145-b150, b162 to mid-block) and its stems to 3rd St,
## in grid coordinates (layout row pos [0, 0, -8000]). See road_rg_NW.build_review_ground.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_review_ground("zz_ring_nw_ground_n", {"ring": [2700.0, 4430.0], "stems": ["500.0,-1600.0", "250.0,-1600.0", "0.0,-1600.0", "-200.0,-1600.0", "-400.0,-1600.0", "-600.0,-1600.0", "-800.0,-1600.0"], "boxes": [[-1100.0, -1720.0, 800.0, -1520.0], [-760.0, -1520.0, 440.0, -1380.0]], "no_quads": ["-800.0,-1400.0"]})
	quit()
