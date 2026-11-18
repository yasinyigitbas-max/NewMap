extends SceneTree
## Piece s_am_b039_b (amber road kit, 17 Nov): Amber Ave, b039.
## Section res, z 17.5-100.0 (seam), height smoothstep [[17.5, 182.5, 6.0]].
## Kerb extension (centre junction behind): kerb 9.1 to 19.5, smoothstep to 11.5 at 31.5; parking after it.
## Bus: northbound stop at 6th St, just past the kerb extension where the centre ends (bench, zone 32.0-57.0).
## Built by road_amber.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_amber.gd")
const SPEC := {"sec": "res", "z0": 17.5, "z1": 100.0, "lines": {"app": [[17.5, 37.5], [46.5, 49.5], [58.5, 61.5], [70.5, 73.5], [82.5, 85.5], [94.5, 97.5]], "dep": [[30.5, 33.5], [42.5, 45.5], [54.5, 57.5], [66.5, 69.5], [78.5, 81.5], [90.5, 93.5]]}, "prof": [[17.5, 182.5, 6.0]], "nose": true, "age": "old", "arrows": ["left_through", "through_right"], "taper": [19.5, 31.5], "bus": {"a": 32.0, "b": 57.0, "kind": "bench"}, "palms": [30.0, 42.0, 54.0, 66.0, 78.0, 90.0], "fan": 0.12, "lamps": [[93.5, 1.0], [72.5, -1.0], [51.5, 1.0], [32.5, -1.0]], "hyd": [72.0, -1.0], "trees_to": 94.5, "mulch": 0.15, "carriage": 0.2, "extras": [["prop_sign_no_parking", "worn", 1.0, 52.0, 0.35, "street"], ["prop_sign_no_parking", "worn", -1.0, 86.0, 0.35, "street"], ["prop_sign_speed25", "worn", -1.0, 73.0, 0.35, "street"]], "inlets": [[60.0, 1.0], [72.0, -1.0]], "manholes": [[-7.4, 41.0], [7.4, 78.0]], "trenches": [[5.8, 69.0, 6.4]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_am_b039_b", SPEC)
	quit()
