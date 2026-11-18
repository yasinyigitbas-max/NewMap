extends SceneTree
## Piece s_rg_b136_w (ring road kit, stage 1, 17 Nov): the transition between the boulevard and the waterfront
## sample W's own s_wfd leg (north, toward the 10th St T): a biarc with the section morphing from the
## boulevard to s_apt. Built by road_rg.gd (build_w_transition; every rule and its reason is there). Run once.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_w_transition("N")
	quit()
