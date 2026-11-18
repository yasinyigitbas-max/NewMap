extends SceneTree
## Piece s_rg_se_b161_1 (ring road kit, stage 2 half SE, 17 Nov): Ocean Blvd, B Ave -> the waterfront W's south transition (falls 2.65 m to W's pad), beach promenade, part 1 of 2
## Built by road_rg_SE.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	SE.build_boulevard("b161", 1)
	quit()
