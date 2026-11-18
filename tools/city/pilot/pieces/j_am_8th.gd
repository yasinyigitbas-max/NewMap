extends SceneTree
## Piece j_am_8th (amber road kit, 17 Nov): Amber Ave x 8th St, pad 6.0 (grading plan), signalised.
## Side streets: west none (T: the stadium closes it), east cc (tile edge 23.5: the side legs start there). Amber tile |z| <= 17.5.
## Kerb inlets (water arrives from): Amber north approach (neighbour pad 6 >= 6); Amber south approach (neighbour pad 6 >= 6); 8th St east approach (neighbour pad 8 >= 6).
## Built by road_amber.gd build_junction (every rule and its reason is there). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_amber.gd")
const SPEC := {"ka": 9.1, "r": 6.0, "jz": 17.5, "jx": 23.5, "xw_a": [12.5, 15.5], "stop_a": [16.7, 17.3], "xw_s": [18.3, 21.3], "stop_s": [22.5, 23.1], "w": "", "e": "cc", "poles": {"w_s": "arm", "ne": "arm", "w_n": "post"}, "names": ["w_n", "se"], "age": "old", "inlets": [[-9.1, -16.6, 90.0], [9.1, -16.6, -90.0], [-9.1, 16.6, 90.0], [9.1, 16.6, -90.0], [22.8, -3.3, 0.0], [22.8, 3.3, 180.0]], "hyd": [[22.6, -4.3, 180.0], [-9.9, 3.5, 90.0]], "extras": [["prop_trash_receptacle", "dirty", -15.5, 3.0, 0.0], ["prop_newspaper_box_red", "worn", 15.5, 16.5, -90.0]], "bollards": [[-9.65, -10.0], [-9.65, -6.6], [-9.65, -5.0], [-9.65, -3.4], [-9.65, -1.8], [-9.65, 0.0], [-9.65, 1.8], [-9.65, 5.6], [-9.65, 10.0]]}
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.build_junction("j_am_8th", SPEC)
	quit()
