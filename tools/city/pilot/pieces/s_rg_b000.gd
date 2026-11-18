extends SceneTree
## Piece s_rg_b000 (ring road kit, stage 1 library test at its real site, 17 Nov): stub: J Ave truck street from the industrial sample's own leg end (100 m) to the 1st St T.
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_stub("b000")
	quit()
