extends SceneTree
## Piece j_rs_t_lrr_a (resstd road kit, 17 Nov): T by the stadium: 9th St runs through (lined toward the high street),
## C Ave ends on it. Canonical legs N/E/S/W = -Lrr ('L' lined, 'r' residential, '-' closed). Sites: (-200, -200).
## Built by road_resstd.gd junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.junction("j_rs_t_lrr_a", "-Lrr")
	quit()
