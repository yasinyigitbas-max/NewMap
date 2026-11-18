extends SceneTree
## Piece j_rs_2l2r_opp_a (resstd road kit, 17 Nov): a lined street (11th St: std to the east, the high street's centre
## line to the west) crossing a residential avenue. Canonical legs N/E/S/W = LrLr ('L' lined, 'r' residential, '-'
## closed). Sites: (250, 200).
## Built by road_resstd.gd junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.junction("j_rs_2l2r_opp_a", "LrLr")
	quit()
