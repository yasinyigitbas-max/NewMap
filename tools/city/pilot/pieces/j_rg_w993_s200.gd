extends SceneTree
## Piece j_rg_w993_s200 (ring road kit, stage 1 library test at its real site, 17 Nov): T-junction Alameda / Ocean Blvd x 11th St (residential stem, stop control, skewed): where the base-fence side turns into the beach side.
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_t("-992.5,200.0")
	quit()
