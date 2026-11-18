extends SceneTree
## Piece j_rs_2l2r_adj_a (resstd road kit, 17 Nov): two lined legs on adjacent sides (a std street turning the corner
## of the apartment band) and two residential legs. Canonical legs N/E/S/W = LLrr ('L' lined, 'r' residential, '-'
## closed). Sites: (500, -800), (500, -400).
## Built by road_resstd.gd junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.junction("j_rs_2l2r_adj_a", "LLrr")
	quit()
