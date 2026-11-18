extends SceneTree
## Piece j_rs_4r_d (resstd road kit, 17 Nov): residential all-way stop (j_res geometry; a dress variant so 10
## residential corners are not one copy). Canonical legs N/E/S/W = rrrr ('L' lined, 'r' residential, '-' closed).
## Sites: (-400, 200), (250, -1000).
## Built by road_resstd.gd junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.junction("j_rs_4r_d", "rrrr")
	quit()
