extends SceneTree
## Piece s_rg_nw_b064 (ring road kit, stage 2 site builder half NW, 17 Nov): stub b064, 3rd St (section ind): z0=100.0 -> z1=121.39 along +z from the lattice node, pad 2.0->2.0. Truck street: continues the industrial sample I's west leg (s_ind ends at 100) to the ring (stop control).
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_stub("b064")
	quit()
