extends SceneTree
## Piece s_rg_nw_b146_2 (ring road kit, stage 2 site builder half NW, 17 Nov): 1st St (bay front), block b146 part 2, s 3254.3..3357.8 (bay front: promenade (4 m walk + planting strip with bench bays facing the water) on the coast side, rise +2.0 m over the block).
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_boulevard("b146", 2)
	quit()
