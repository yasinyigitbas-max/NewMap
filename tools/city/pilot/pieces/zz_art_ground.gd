extends SceneTree
## Piece zz_art_ground (art road kit, 17 Nov). PREVIEW ONLY: grass under the art review area (built in the review frame, row at [0, 0, 0]); never in the game.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.review_ground("zz_art_ground")
	quit()
