extends SceneTree
## Piece s_rg_nw_b148_1 (ring road kit, stage 2 site builder half NW, 17 Nov): 1st St (bay front), block b148 part 1, s 3600.8..3684.8 (bay front: promenade (4 m walk + planting strip with bench bays facing the water) on the coast side, rise +0.0 m over the block).
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_boulevard("b148", 1)
	quit()
