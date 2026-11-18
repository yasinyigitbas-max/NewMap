extends SceneTree
## Piece j_rg_e627_s0 (ring road kit, stage 1 library test at its real site, 17 Nov): T-junction of the ring and 10th
## St (residential stem, stop control) lying ON a curve of the ring, skewed 13 deg. Built by road_rg.gd. Run once.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_t("626.5,0.0")
	quit()
