extends SceneTree
## Piece j_rg_se_e0_s340 (ring road kit, stage 2 half SE, 17 Nov): T-junction Ocean Blvd x Amber Ave (the divided high street meets the ring at signals; rebuilt from the core's example with the duct trench as a sealed cut)
## Built by road_rg_SE.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	SE.build_t("0.0,340.0")
	quit()
