extends SceneTree
## Piece s_rg_nw_b153_1 (ring road kit, stage 2 site builder half NW, 17 Nov): Alameda Blvd (base fence), block b153 part 1, s 4932.4..5019.3 (base fence side: the plain 2 m walk on both sides (nobody strolls along a fence), rise +0.0 m over the block).
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_boulevard("b153", 1)
	quit()
