extends SceneTree
## Piece s_am_b042_b (amber road kit, 17 Nov): Amber Ave, b042.
## Section res, z 17.5-100.0 (seam), height flat.
## Bus: northbound stop at 9th St, where the high street begins (bench, zone 21.5-46.5).
## Built by road_amber.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_amber.gd")
const SPEC := {"sec": "res", "z0": 17.5, "z1": 100.0, "lines": {"app": [[17.5, 37.5], [46.5, 49.5], [58.5, 61.5], [70.5, 73.5], [82.5, 85.5], [94.5, 97.5]], "dep": [[30.5, 33.5], [42.5, 45.5], [54.5, 57.5], [66.5, 69.5], [78.5, 81.5], [90.5, 93.5]]}, "prof": [], "nose": true, "age": "old", "arrows": ["left_through", "through_right"], "bus": {"a": 21.5, "b": 46.5, "kind": "bench"}, "palms": [30.0, 42.0, 54.0, 66.0, 78.0, 90.0], "fan": 0.05, "lamps": [[93.5, 1.0], [72.5, -1.0], [51.5, 1.0], [30.5, -1.0]], "hyd": [72.0, -1.0], "trees_to": 94.5, "mulch": 0.1, "carriage": 0.3, "extras": [["prop_sign_no_parking", "worn", 1.0, 52.0, 0.35, "street"], ["prop_sign_no_parking", "worn", -1.0, 86.0, 0.35, "street"], ["prop_sign_speed25", "worn", -1.0, 62.5, 0.35, "street"]], "inlets": [[60.0, 1.0], [72.0, -1.0]], "manholes": [[-7.4, 41.0], [7.4, 78.0]], "trenches": [[5.8, 69.0, 6.4]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_am_b042_b", SPEC)
	quit()
