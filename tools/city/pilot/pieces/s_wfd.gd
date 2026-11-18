extends SceneTree
## Piece s_wfd (17 Nov audit #5: one street piece dressed four zones): the waterfront's drives: fan and queen palms, pier lamps like the promenade, beach parking meters, sand in the gutters and on the walks.
## Same cross-section, stalls, alley aprons, hydrant and bus stop as s_apt (road_lib.apt_street), so it replaces
## s_apt in the sample's layout rows without touching any block. Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.apt_street("s_wfd", "wfd")
	quit()
