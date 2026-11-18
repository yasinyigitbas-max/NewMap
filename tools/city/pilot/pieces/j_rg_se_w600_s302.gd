extends SceneTree
## Piece j_rg_se_w600_s302 (ring road kit, stage 2 half SE, 17 Nov): T-junction Ocean Blvd x G Ave (residential stem, stop sign; the ring never stops)
## Built by road_rg_SE.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	SE.build_t("-600.0,302.0")
	quit()
