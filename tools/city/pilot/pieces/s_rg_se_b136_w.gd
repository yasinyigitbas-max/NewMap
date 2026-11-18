extends SceneTree
## Piece s_rg_se_b136_w (ring road kit, stage 2 half SE, 17 Nov): W transition, the waterfront W's north leg -> the 10th St T on Glorietta Blvd (biarc, s_wfd morphing into the boulevard; rises 2.65 m)
## Built by road_rg_SE.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	SE.build_w("N")
	quit()
