extends SceneTree
## Piece j_rg_e660_n1000 (ring road kit, stage 1 example, 17 Nov): T-junction Glorietta Blvd x 5th St (strip arterial stem, signals).
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_t("660.0,-1000.0")
	quit()
