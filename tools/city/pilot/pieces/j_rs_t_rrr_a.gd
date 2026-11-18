extends SceneTree
## Piece j_rs_t_rrr_a (resstd road kit, 17 Nov): residential T (Adela Ave ends on 10th St). Canonical legs N/E/S/W =
## -rrr ('L' lined, 'r' residential, '-' closed). Sites: (500, 0).
## Built by road_resstd.gd junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.junction("j_rs_t_rrr_a", "-rrr")
	quit()
