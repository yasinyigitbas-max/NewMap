extends SceneTree
## Piece j_rg_w800_s289 (ring road kit, stage 1 example, 17 Nov): T-junction Ocean Blvd x J Ave (residential stem, stop control), the ring's straight south side.
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_t("-800.0,288.7")
	quit()
