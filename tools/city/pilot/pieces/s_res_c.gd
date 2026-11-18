extends SceneTree
## Piece s_res_c (road kit group 1): flat residential leg, mixed street trees (variant c: its own planting, so
## neighbouring legs never repeat). See road_lib.gd (residential road kit). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.res_street("s_res_c", 0.0, "mix")
	quit()
