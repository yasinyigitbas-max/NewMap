extends SceneTree
## Piece s_rg_nw_b144_1 (ring road kit, stage 2 site builder half NW, 17 Nov): Glorietta Blvd, block b144 part 1, s 2409.5..2484.0 (golf course side: the plain 2 m walk (nobody strolls along a fairway), rise -2.0 m over the block).
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_boulevard("b144", 1)
	quit()
