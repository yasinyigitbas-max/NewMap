extends SceneTree
## Piece j_rg_nw_e657_n800 (ring road kit, stage 2 site builder half NW, 17 Nov): T-junction Glorietta Blvd x 6th St (a residential street, stop sign on the stem), pad 4.0.
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_t("657.3,-800.0")
	quit()
