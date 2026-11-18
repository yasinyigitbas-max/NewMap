extends SceneTree
## PREVIEW ONLY (never in the game): grass round the ring half NW, Alameda Blvd along the base fence (b162 from mid-block to b158 part 1) and its stems to J Ave,
## in grid coordinates (layout row pos [0, 0, -8000]). See road_rg_NW.build_review_ground.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_review_ground("zz_ring_nw_ground_w", {"ring": [4430.0, 6023.8], "stems": ["-950.9,-1400.0", "-951.8,-1200.0", "-993.8,-1000.0", "-1000.0,-800.0", "-1000.0,-600.0", "-1000.0,-400.0", "-1000.0,-200.0", "-1000.0,0.0"], "boxes": [[-1100.0, -1520.0, -760.0, 60.0]]})
	quit()
