extends SceneTree
## Piece j_am_3rd (amber road kit, 17 Nov): Amber Ave x 3rd St, pad 8.0 (grading plan), signalised.
## Side streets: west art, east art (tile edge 23.5: the side legs start there). Amber tile |z| <= 22.5.
## Kerb inlets (water arrives from): Amber south approach (neighbour pad 14 >= 8).
## Built by road_amber.gd build_junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_amber.gd")
const SPEC := {"ka": 11.5, "r": 6.0, "jz": 22.5, "jx": 23.5, "xw_a": [17.1, 20.1], "stop_a": [21.3, 21.9], "xw_s": [18.3, 21.3], "stop_s": [22.5, 23.1], "w": "art", "e": "art", "poles": {"sw": "arm", "ne": "arm", "nw": "arm", "se": "arm"}, "names": ["ne", "sw"], "age": "old", "inlets": [[-11.5, 21.200000000000003, 90.0], [11.5, 21.200000000000003, -90.0]], "hyd": [[22.6, -11.3, 180.0], [-22.6, 11.3, 0.0]], "extras": [["prop_trash_receptacle", "worn", -15.5, 21.5, 0.0], ["prop_trash_receptacle", "worn", 15.5, -21.5, 0.0], ["prop_newspaper_box_red", "worn", 15.5, 21.5, -90.0]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_junction("j_am_3rd", SPEC)
	quit()
