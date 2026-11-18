extends SceneTree
## Piece s_rg_b131_2 (ring road kit, stage 1 example, 17 Nov): Ocean Blvd, block b131 part 2.
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_boulevard("b131", 2)
	quit()
