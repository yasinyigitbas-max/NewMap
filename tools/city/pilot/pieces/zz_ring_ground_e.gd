extends SceneTree
## PREVIEW ONLY (never in the game): grass round the ring review T at Glorietta Blvd x 5th St and its 5th St stub, grid coordinates
## (layout row pos [0, 0, -8000]). See road_rg.build_review_ground.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var nd: Dictionary = RG.ring()["nodes"]["660.0,-1000.0"]
	RG.build_review_ground("zz_ring_ground_e", {"ring": [float(nd["s"]) - float(nd["em"]), float(nd["s"]) + float(nd["ep"])],
		"stems": ["660.0,-1000.0"], "stubs": ["b087"], "box": [470.0, -1080.0, 760.0, -920.0]})
	quit()
