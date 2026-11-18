extends SceneTree
## Piece j_rg_se_e647_n200 (ring road kit, stage 2 half SE, 17 Nov): T-junction Glorietta Blvd x 9th St (residential stem, stop sign; far-side bus stops both ways)
## Built by road_rg_SE.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	SE.build_t("647.0,-200.0")
	quit()
