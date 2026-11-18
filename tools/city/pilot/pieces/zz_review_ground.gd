extends SceneTree
## PREVIEW ONLY (never in the game): grass hill ground under the group-1 review street, see road_lib.review_ground.
## Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.review_ground("zz_review_ground", 8.0)
	quit()
