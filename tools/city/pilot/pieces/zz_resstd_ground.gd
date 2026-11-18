extends SceneTree
## PREVIEW ONLY (resstd review area, never in the game): grass under the family's street network at its pad heights
## (Coons patch per street block between the property lines), so shots do not look into a void. Built by
## road_resstd.gd review_ground from review/sites.json + review/resstd_sites.json. Run once.
const R := preload("res://tools/city/pilot/pieces/road_resstd.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.review_ground("zz_resstd_ground")
	quit()
