extends SceneTree
## Piece s_br_ramp_1 (hero, bridge option A, 17 Nov): the one-way off-ramp to 3rd St, part 1 of 5 (nose -> ring).
## Built by road_bridge.gd build_ramp (every rule and its reason is written there). Run once; never when locked.
const RB := preload("res://tools/city/pilot/pieces/road_bridge.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RB.build_ramp(1)
	quit()
