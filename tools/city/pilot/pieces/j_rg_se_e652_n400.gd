extends SceneTree
## Piece j_rg_se_e652_n400 (ring road kit, stage 2 half SE, 17 Nov): T-junction Glorietta Blvd x 8th St (residential stem, stop sign)
## Built by road_rg_SE.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	SE.build_t("652.0,-400.0")
	quit()
