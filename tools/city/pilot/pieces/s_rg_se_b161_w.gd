extends SceneTree
## Piece s_rg_se_b161_w (ring road kit, stage 2 half SE, 17 Nov): W transition, Ocean Blvd's end -> the waterfront W's south leg (biarc, the boulevard section morphing into W's s_wfd; flat at W's pad 1.35)
## Built by road_rg_SE.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	SE.build_w("S")
	quit()
