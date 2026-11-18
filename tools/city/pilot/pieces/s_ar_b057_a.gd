extends SceneTree
## Piece s_ar_b057_a (art road kit, 17 Nov). Adela Ave from 3rd St (AD3, pad 2) south to the strip sample's north leg (pad 4): the whole +2 m rise is in
## this leg (the sample's legs are flat), 26 -> 100 m, 4.1 % max. The hospital campus is across 3rd St, so the
## kerb parking is metered (a pay station each side); queen palms, jacarandas and corals in the wells.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.side_leg("s_ar_b057_a", {"z0": 26.0, "z1": 100.0, "prof": [[26.0, 100.0, 2.0]], "apr": [45.0, 80.0], "wells": {-1.0: [33.0, 57.0, 69.0, 92.0], 1.0: [34.0, 55.0, 71.0, 93.0]}, "trees": ["palm_queen_a", "tree_jacaranda_a", "tree_coral_b", "palm_queen_b", "tree_jacaranda_b"], "lamps": [52.0, 86.0], "hyd": [1.0, 62.0], "pay": true, "pay_z": [38.0, 66.5]})
	quit()
