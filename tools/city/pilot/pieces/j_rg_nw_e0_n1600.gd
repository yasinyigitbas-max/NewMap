extends SceneTree
## Piece j_rg_nw_e0_n1600 (ring road kit, stage 2 site builder half NW, 17 Nov): T-junction 1st St (bay front) x Amber Ave (Amber Ave (the divided avenue), signals), pad 2.0. Stem section overridden (hs): see road_rg_NW.gd header.
## Built by road_rg_NW.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	NW.build_t("0.0,-1600.0")
	quit()
