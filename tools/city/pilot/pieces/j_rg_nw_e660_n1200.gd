extends SceneTree
## Piece j_rg_nw_e660_n1200 (hero, bridge option A, 17 Nov): 4-way 4th St x Glorietta Blvd x the bridge approach (option A, the island's gateway), signals, pad 4.0.
## Built by road_bridge.gd build_cross over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RB := preload("res://tools/city/pilot/pieces/road_bridge.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RB.build_cross("660.0,-1200.0")
	quit()
