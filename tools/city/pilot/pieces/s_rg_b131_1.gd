extends SceneTree
## Piece s_rg_b131_1 (ring road kit, stage 1 example, 17 Nov): Ocean Blvd, block b131 part 1 (straight, rising 2 m toward G Ave; beach promenade on the coast side).
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_boulevard("b131", 1)
	quit()
