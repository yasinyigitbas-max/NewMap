extends SceneTree
## PREVIEW ONLY (never in the game): grass round the ring review T at Ocean Blvd x Amber Ave and its Amber stub, grid
## coordinates (layout row pos [0, 0, -8000]). See road_rg.build_review_ground.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var nd: Dictionary = RG.ring()["nodes"]["0.0,340.0"]
	RG.build_review_ground("zz_ring_ground_s", {"ring": [float(nd["s"]) - float(nd["em"]), float(nd["s"]) + float(nd["ep"])],
		"stems": ["0.0,340.0"], "stubs": ["b045"], "box": [-90.0, 170.0, 90.0, 420.0]})
	quit()
