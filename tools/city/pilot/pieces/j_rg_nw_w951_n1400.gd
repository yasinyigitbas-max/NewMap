extends SceneTree
## Piece j_rg_nw_w951_n1400 (ring road kit, stage 2 site builder half NW, 17 Nov): T-junction 1st St (bay front) / Alameda Blvd (base fence) x 3rd St (a truck street, stop sign on the stem), pad 2.0. Stem section overridden (ind): see road_rg_NW.gd header.
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_t("-950.9,-1400.0")
	quit()
