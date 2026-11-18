extends SceneTree
## Piece s_am_b037_a (amber road kit, 17 Nov): Amber Ave, b037.
## Section res, z 22.5-100.0 (seam), height smoothstep [[22.5, 177.5, 6.0]].
## Bus: southbound stop at 3rd St: transfer to the bridge buses on 3rd, busiest residential stop (plaza, zone 26.5-51.5).
## Built by road_amber.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_amber.gd")
const SPEC := {"sec": "res", "z0": 22.5, "z1": 100.0, "lines": {"app": [[22.5, 42.5], [51.5, 54.5], [63.5, 66.5], [75.5, 78.5], [87.5, 90.5], [99.5, 100.0]], "dep": [[37.5, 40.5], [49.5, 52.5], [61.5, 64.5], [73.5, 76.5], [85.5, 88.5], [97.5, 100.0]]}, "prof": [[22.5, 177.5, 6.0]], "nose": true, "age": "old", "arrows": ["left_through", "through_right"], "bus": {"a": 26.5, "b": 51.5, "kind": "plaza"}, "palms": [31.0, 43.0, 55.0, 67.0, 79.0, 91.0], "fan": 0.12, "lamps": [[27.5, -1.0], [48.5, 1.0], [69.5, -1.0], [90.5, 1.0]], "hyd": [64.0, 1.0], "trees_to": 94.5, "mulch": 0.12, "carriage": 0.25, "extras": [["prop_sign_no_parking", "worn", 1.0, 47.0, 0.35, "street"], ["prop_sign_no_parking", "worn", -1.0, 81.0, 0.35, "street"], ["prop_sign_speed25", "worn", -1.0, 67.5, 0.35, "street"], ["prop_newspaper_box_blue", "worn", -1.0, 37.9, -0.5, "street"], ["prop_usps_collection_box", "worn", -1.0, 36.7, -0.5, "street"]], "inlets": [[60.0, 1.0], [72.0, -1.0]], "manholes": [[-7.4, 46.0], [7.4, 78.0]], "trenches": [[-5.8, 66.0, 6.4]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_am_b037_a", SPEC)
	quit()
