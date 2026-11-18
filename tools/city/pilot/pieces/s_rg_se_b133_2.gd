extends SceneTree
## Piece s_rg_se_b133_2 (ring road kit, stage 2 half SE, 17 Nov): Ocean Blvd, E Ave -> C Ave (flat), beach promenade on the coast side, part 2 of 2
## Built by road_rg_SE.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	SE.build_boulevard("b133", 2)
	quit()
