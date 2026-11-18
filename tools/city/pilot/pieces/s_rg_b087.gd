extends SceneTree
## Piece s_rg_b087 (ring road kit, stage 1 library test at its real site, 17 Nov): stub: 5th St (strip arterial) from Adela Ave (tile edge 22 m) to the Glorietta Blvd T.
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_stub("b087")
	quit()
