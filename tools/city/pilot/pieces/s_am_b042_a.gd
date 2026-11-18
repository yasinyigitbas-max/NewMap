extends SceneTree
## Piece s_am_b042_a (amber road kit, 17 Nov): Amber Ave, b042.
## Section res, z 17.5-100.0 (seam), height flat.
## Kerb extension (centre junction behind): kerb 9.1 to 19.5, smoothstep to 11.5 at 31.5; parking after it.
## Bus: southbound stop at 8th St: the stadium stop (crowds on game nights), shelter on a paved plaza (plaza, zone 32.0-57.0).
## Built by road_amber.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_amber.gd")
const SPEC := {"sec": "res", "z0": 17.5, "z1": 100.0, "lines": {"app": [[17.5, 37.5], [46.5, 49.5], [58.5, 61.5], [70.5, 73.5], [82.5, 85.5], [94.5, 97.5]], "dep": [[30.5, 33.5], [42.5, 45.5], [54.5, 57.5], [66.5, 69.5], [78.5, 81.5], [90.5, 93.5]]}, "prof": [], "nose": true, "age": "mid", "arrows": ["through", "through_right"], "taper": [19.5, 31.5], "bus": {"a": 32.0, "b": 57.0, "kind": "plaza"}, "palms": [26.0, 38.0, 50.0, 62.0, 74.0, 86.0, 98.0], "fan": 0.05, "lamps": [[32.5, -1.0], [43.5, 1.0], [64.5, -1.0], [85.5, 1.0]], "hyd": [64.0, 1.0], "trees_to": 94.5, "mulch": 0.1, "carriage": 0.3, "extras": [["prop_sign_no_parking", "worn", 1.0, 47.0, 0.35, "street"], ["prop_sign_no_parking", "worn", -1.0, 81.0, 0.35, "street"], ["prop_sign_speed25", "worn", -1.0, 73.0, 0.35, "street"], ["prop_newspaper_box_blue", "worn", -1.0, 43.4, -0.5, "street"]], "inlets": [[60.0, 1.0], [72.0, -1.0]], "manholes": [[-7.4, 41.0], [7.4, 78.0]], "trenches": [[-5.8, 66.0, 6.4]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_am_b042_a", SPEC)
	quit()
