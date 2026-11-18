extends SceneTree
## Piece s_am_b037_b (amber road kit, 17 Nov): Amber Ave, b037.
## Section res, z 22.5-100.0 (seam), height smoothstep [[22.5, 177.5, -6.0]].
## Bus: northbound stop at 4th St on the crest: transfer to 4th St's buses (plaza, zone 26.5-51.5).
## Built by road_amber.gd build_leg (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_amber.gd")
const SPEC := {"sec": "res", "z0": 22.5, "z1": 100.0, "lines": {"app": [[22.5, 42.5], [51.5, 54.5], [63.5, 66.5], [75.5, 78.5], [87.5, 90.5], [99.5, 100.0]], "dep": [[37.5, 40.5], [49.5, 52.5], [61.5, 64.5], [73.5, 76.5], [85.5, 88.5], [97.5, 100.0]]}, "prof": [[22.5, 177.5, -6.0]], "nose": true, "age": "new", "arrows": ["left_through", "through_right"], "bus": {"a": 26.5, "b": 51.5, "kind": "plaza"}, "palms": [37.0, 49.0, 61.0, 73.0, 85.0, 97.0], "fan": 0.12, "lamps": [[88.5, 1.0], [67.5, -1.0], [46.5, 1.0]], "hyd": [72.0, -1.0], "trees_to": 94.5, "mulch": 0.12, "carriage": 0.25, "extras": [["prop_sign_no_parking", "worn", 1.0, 52.0, 0.35, "street"], ["prop_sign_no_parking", "worn", -1.0, 86.0, 0.35, "street"], ["prop_sign_speed25", "worn", -1.0, 67.5, 0.35, "street"], ["prop_newspaper_box_blue", "worn", -1.0, 37.9, -0.5, "street"]], "inlets": [[60.0, 1.0], [72.0, -1.0]], "manholes": [[-7.4, 46.0], [7.4, 78.0]], "trenches": [[5.8, 69.0, 6.4]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_leg("s_am_b037_b", SPEC)
	quit()
