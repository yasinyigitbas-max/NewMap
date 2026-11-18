extends SceneTree
## Piece s_rg_nw_b145_2 (ring road kit, stage 2 site builder half NW, 17 Nov): 1st St (bay front), block b145 part 2, s 2956.6..3012.3 (bay front: promenade (4 m walk + planting strip with bench bays facing the water) on the coast side, rise +0.0 m over the block). Split round the 45 m ferry gap (hero piece).
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_boulevard("b145", 2)
	quit()
