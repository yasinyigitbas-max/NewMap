extends SceneTree
## Piece s_rg_b045 (ring road kit, stage 1 library test at its real site, 17 Nov): stub: Amber Ave (divided high street) from 11th St (tile edge 17.5 m) down to the Ocean Blvd T.
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_stub("b045")
	quit()
