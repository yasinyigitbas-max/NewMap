extends SceneTree
## Piece s_rg_nw_b162_2 (ring road kit, stage 2 site builder half NW, 17 Nov): 1st St (bay front), block b162 part 2, s 4302.1..4398.4 (bay front: promenade (4 m walk + planting strip with bench bays facing the water) on the coast side, rise +0.0 m over the block).
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_boulevard("b162", 2)
	quit()
