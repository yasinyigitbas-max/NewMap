extends SceneTree
## Piece s_res_dn8 (road kit group 1, 17 Nov): see road_lib.gd (residential road kit) for every rule and its reason.
## Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.res_street("s_res_dn8", -8.0, "mix")
	quit()
