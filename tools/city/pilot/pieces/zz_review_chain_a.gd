extends SceneTree
## Piece zz_review_chain_a (road kit, rise classes from the grading plan zoning/grading.json): PREVIEW ONLY ground under review chain A (pads 0, 4, 10, 12). See road_lib.gd (residential
## road kit). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.review_ground_chain("zz_review_chain_a", [0.0, 4.0, 10.0, 12.0])
	quit()
