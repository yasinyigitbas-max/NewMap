extends SceneTree
## Piece j_rs_1l3r_c (resstd road kit, 17 Nov): a residential crossing where one leg carries a centre line (a
## high-street side street or a std collector ending here). Canonical legs N/E/S/W = Lrrr ('L' lined, 'r' residential,
## '-' closed). Sites: (250, 0).
## Built by road_resstd.gd junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.junction("j_rs_1l3r_c", "Lrrr")
	quit()
