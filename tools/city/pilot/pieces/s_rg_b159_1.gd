extends SceneTree
## Piece s_rg_b159_1 (ring road kit, stage 1 example, 17 Nov): Ocean Blvd, block b159 part 1: the SW corner of the island (78 deg curve), beach promenade outside.
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_boulevard("b159", 1)
	quit()
