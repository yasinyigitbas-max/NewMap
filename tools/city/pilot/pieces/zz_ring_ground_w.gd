extends SceneTree
## PREVIEW ONLY (never in the game): grass round the ring review cluster west (b158's last piece, the 11th St T, b159, the J Ave T, b131, the J Ave stub),
## in grid coordinates (layout row pos [0, 0, -8000]). See road_rg.build_review_ground.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var R := RG.ring()
	var pl: Array = RG.block_plan("b158")
	RG.build_review_ground("zz_ring_ground_w", {"ring": [float(pl[pl.size() - 1]["s0"]), float(R["blocks"]["b131"]["r1"])],
		"stems": ["-800.0,288.7", "-992.5,200.0"], "stubs": ["b009"], "box": [-1080.0, 60.0, -520.0, 400.0]})
	quit()
