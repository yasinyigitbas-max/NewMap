extends SceneTree
## Piece j_rg_e0_s340 (ring road kit, stage 1 library test at its real site, 17 Nov): T-junction Ocean Blvd x Amber Ave (the divided high street meets the ring at signals).
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_t("0.0,340.0")
	quit()
