extends SceneTree
## Piece j_rs_t_lrl_a (resstd road kit, 17 Nov): T at the campus edge: the lined collector runs through, a residential
## street ends on it. Canonical legs N/E/S/W = -LrL ('L' lined, 'r' residential, '-' closed). Sites: (-600, -400).
## Built by road_resstd.gd junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.junction("j_rs_t_lrl_a", "-LrL")
	quit()
