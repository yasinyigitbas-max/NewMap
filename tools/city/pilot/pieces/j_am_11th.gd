extends SceneTree
## Piece j_am_11th (amber road kit, 17 Nov): Amber Ave x 11th St, pad 4.0 (grading plan), signalised.
## Side streets: west hs, east hs (tile edge 23.5: the side legs start there). Amber tile |z| <= 17.5.
## Kerb inlets (water arrives from): Amber north approach (neighbour pad 4 >= 4); 11th St east approach (neighbour pad 6 >= 4).
## Built by road_amber.gd build_junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_amber.gd")
const SPEC := {"ka": 11.5, "r": 6.0, "jz": 17.5, "jx": 23.5, "xw_a": [12.5, 15.5], "stop_a": [16.7, 17.3], "xw_s": [18.3, 21.3], "stop_s": [22.5, 23.1], "w": "hs", "e": "hs", "poles": {"sw": "arm", "ne": "arm", "nw": "post", "se": "post"}, "names": ["nw", "se"], "age": "mid", "inlets": [[-11.5, -16.6, 90.0], [11.5, -16.6, -90.0], [22.8, -5.7, 0.0], [22.8, 5.7, 180.0]], "hyd": [[22.6, -6.7, 180.0], [-22.6, 6.7, 0.0]], "extras": [["prop_trash_receptacle", "worn", 15.5, -16.5, 0.0], ["prop_recycling_receptacle", "worn", 15.5, -15.7, 0.0], ["prop_trash_receptacle", "worn", -15.5, 16.5, 0.0], ["prop_newspaper_box_blue", "worn", -15.5, 15.7, 90.0]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_junction("j_am_11th", SPEC)
	quit()
