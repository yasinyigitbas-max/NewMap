extends SceneTree
## Piece s_br_appr_4 (hero, bridge option A, 17 Nov): the divided bridge approach, part 4 of 6 (gateway -> deck).
## Built by road_bridge.gd build_approach (every rule and its reason is written there). Run once; never when locked.
const RB := preload("res://tools/city/pilot/pieces/road_bridge.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RB.build_approach(4)
	quit()
