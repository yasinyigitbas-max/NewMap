extends SceneTree
## Piece s_grt (17 Nov audit #5: one street piece dressed four zones): the gritty edge's streets: trees in only some slots (stump marks where the rest died), worn gravel parkway, cobra lamps, tow-away signs at the alley mouth, an abandoned cart, heavier grime and patched slabs.
## Same cross-section, stalls, alley aprons, hydrant and bus stop as s_apt (road_lib.apt_street), so it replaces
## s_apt in the sample's layout rows without touching any block. Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.apt_street("s_grt", "grt")
	quit()
