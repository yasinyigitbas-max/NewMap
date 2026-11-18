extends SceneTree
## Piece s_rg_nw_b088 (ring road kit, stage 2 site builder half NW, 17 Nov): stub b088, 6th St (section std): z0=20.0 -> z1=174.50 along +z from the lattice node, pad 6.0->4.0.
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_stub("b088")
	quit()
