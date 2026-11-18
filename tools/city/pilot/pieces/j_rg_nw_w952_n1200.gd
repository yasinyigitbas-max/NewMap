extends SceneTree
## Piece j_rg_nw_w952_n1200 (ring road kit, stage 2 site builder half NW, 17 Nov): T-junction Alameda Blvd (base fence) x 4th St (the 3rd / 4th St arterial, signals), pad 2.0.
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_t("-951.8,-1200.0")
	quit()
