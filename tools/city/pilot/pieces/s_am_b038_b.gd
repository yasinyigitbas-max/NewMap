extends SceneTree
## Piece s_am_b038_b (amber road kit, 17 Nov): Amber Ave, b038.
## Section res, z 17.5-100.0 (seam), height smoothstep [[17.5, 177.5, 2.0]].
## Bus: northbound stop at 5th St: a quiet residential stop, bench at the back of the walk (bench, zone 21.5-46.5).
## Built by road_amber.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_amber.gd")
const SPEC := {"sec": "res", "z0": 17.5, "z1": 100.0, "lines": {"app": [[17.5, 37.5], [46.5, 49.5], [58.5, 61.5], [70.5, 73.5], [82.5, 85.5], [94.5, 97.5]], "dep": [[25.5, 28.5], [37.5, 40.5], [49.5, 52.5], [61.5, 64.5], [73.5, 76.5], [85.5, 88.5], [97.5, 100.0]]}, "prof": [[17.5, 177.5, 2.0]], "nose": true, "age": "mid", "arrows": ["left_through", "through_right"], "bus": {"a": 21.5, "b": 46.5, "kind": "bench"}, "palms": [37.0, 49.0, 61.0, 73.0, 85.0, 97.0], "fan": 0.12, "lamps": [[88.5, 1.0], [67.5, -1.0], [46.5, 1.0], [25.5, -1.0]], "hyd": [72.0, -1.0], "trees_to": 94.5, "mulch": 0.2, "carriage": 0.15, "extras": [["prop_sign_no_parking", "worn", 1.0, 52.0, 0.35, "street"], ["prop_sign_no_parking", "worn", -1.0, 86.0, 0.35, "street"], ["prop_sign_speed25", "worn", -1.0, 62.5, 0.35, "street"]], "inlets": [[60.0, 1.0], [72.0, -1.0]], "manholes": [[-7.4, 41.0], [7.4, 78.0]], "trenches": [[5.8, 69.0, 6.4]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_am_b038_b", SPEC)
	quit()
