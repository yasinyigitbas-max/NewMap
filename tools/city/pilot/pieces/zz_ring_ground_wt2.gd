extends SceneTree
## PREVIEW ONLY (never in the game): grass round the ring review T at 10th St (on the curve north of the waterfront W),
## grid coordinates (layout row pos [0, 0, -8000]). See road_rg.build_review_ground.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var nd: Dictionary = RG.ring()["nodes"]["626.5,0.0"]
	RG.build_review_ground("zz_ring_ground_wt2", {"ring": [float(nd["s"]) - float(nd["em"]), float(nd["s"]) + float(nd["ep"])], "stems": ["626.5,0.0"],
		"box": [589.0, -60.0, 700.0, 60.0]})
	quit()
