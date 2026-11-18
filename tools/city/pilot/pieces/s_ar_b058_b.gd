extends SceneTree
## Piece s_ar_b058_b (art road kit, 17 Nov). Adela Ave from 5th St (AD5, pad 4) north to the strip sample's south leg (pad 4): flat, 26 -> 100 m.
## Free kerb parking for the small shops' customers and workers; jacarandas, magnolias, palms in the wells.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.side_leg("s_ar_b058_b", {"z0": 26.0, "z1": 100.0, "prof": [], "apr": [45.0, 80.0], "wells": {-1.0: [35.0, 58.0, 71.0, 91.0], 1.0: [33.0, 57.0, 70.0, 94.0]}, "trees": ["tree_jacaranda_b", "tree_magnolia_a", "palm_queen_a", "tree_coral_a", "tree_jacaranda_a"], "lamps": [86.0, 52.0], "hyd": [-1.0, 64.0], "pay": false})
	quit()
