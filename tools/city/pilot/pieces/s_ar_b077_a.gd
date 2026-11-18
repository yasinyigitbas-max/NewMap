extends SceneTree
## Piece s_ar_b077_a (art road kit, 17 Nov). 4th St from Amber Ave x 4th St (pad 14) toward B Ave, z 23.5 -> 125.0 to the block's other leg (mid-block).
## Block b077: 250 m, rise -6 m a->b; this leg carries -6.00 m, max grade 4.4 %. Dress hill.
## Pocket + arrows for the approach to Amber Ave; aprons at [66.0, 108.0] (bus side) / [58.0, 112.0].
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_leg("s_ar_b077_a", {"z0": 23.5, "z1": 125.0, "prof": [[23.5, 228.0, -6.0]], "end": "seam", "Lb": 250.0, "from_b": false, "bus": false, "apr": {-1.0: [66.0, 108.0], 1.0: [58.0, 112.0]}, "dress": "hill", "hyd": -1.0})
	quit()
