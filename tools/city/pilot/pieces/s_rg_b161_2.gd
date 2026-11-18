extends SceneTree
## Piece s_rg_b161_2 (ring road kit, stage 1 library test at its real site, 17 Nov): Ocean Blvd's last piece before
## the W transition (its promenade ends against the transition's walk). Built by road_rg.gd. Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_boulevard("b161", 2)
	quit()
