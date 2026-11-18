extends SceneTree
## Piece j_rg_se_e627_s0 (ring road kit, stage 2 half SE, 17 Nov): T-junction Glorietta Blvd x 10th St on the curve north of W (residential stem, stop sign; rebuilt from the core's example: no signal duct trench at a stop T)
## Built by road_rg_SE.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	SE.build_t("626.5,0.0")
	quit()
