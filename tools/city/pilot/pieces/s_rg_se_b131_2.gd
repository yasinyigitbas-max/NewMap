extends SceneTree
## Piece s_rg_se_b131_2 (ring road kit, stage 2 half SE, 17 Nov): Ocean Blvd, J Ave -> G Ave (rises 2 m), beach promenade, part 2 of 2 (rebuilt from the core's example: sealed utility cut)
## Built by road_rg_SE.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	SE.build_boulevard("b131", 2)
	quit()
