extends SceneTree
## Piece s_res_dn2_a (road kit, rise classes from the grading plan zoning/grading.json): residential leg from the upper junction, its block falls 2 m (variant a). See road_lib.gd (residential
## road kit). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.res_street("s_res_dn2_a", -2.0, "mix")
	quit()
