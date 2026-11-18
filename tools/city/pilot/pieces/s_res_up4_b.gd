extends SceneTree
## Piece s_res_up4_b (road kit, rise classes from the grading plan zoning/grading.json): residential leg, its block rises 4 m (variant b). See road_lib.gd (residential
## road kit). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.res_street("s_res_up4_b", 4.0, "mix")
	quit()
