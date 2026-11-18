extends SceneTree
## Piece j_rs_3l1r_b (resstd road kit, 17 Nov): a std collector crossing (or meeting) a residential street:
## centre-line stubs and continental crosswalks on the three lined legs, a plain two-line crosswalk on the quiet one.
## Canonical legs N/E/S/W = LLLr ('L' lined, 'r' residential, '-' closed). Sites: (-800, -400), (-200, -1000).
## Built by road_resstd.gd junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.junction("j_rs_3l1r_b", "LLLr")
	quit()
