extends SceneTree
## PREVIEW ONLY (never in the game): grass round the ring review T at 1st St x J Ave and its J Ave truck stub, grid
## coordinates (layout row pos [0, 0, -8000]). See road_rg.build_review_ground.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var nd: Dictionary = RG.ring()["nodes"]["-800.0,-1600.0"]
	RG.build_review_ground("zz_ring_ground_n", {"ring": [float(nd["s"]) - float(nd["em"]), float(nd["s"]) + float(nd["ep"])],
		"stems": ["-800.0,-1600.0"], "stubs": ["b000"], "box": [-880.0, -1680.0, -720.0, -1370.0]})
	quit()
