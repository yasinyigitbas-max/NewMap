extends SceneTree
## Piece j_rg_w800_n1600 (ring road kit, stage 1 library test at its real site, 17 Nov): T-junction 1st St x J Ave (truck street stem, stop control) on the bay front.
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_t("-800.0,-1600.0")
	quit()
