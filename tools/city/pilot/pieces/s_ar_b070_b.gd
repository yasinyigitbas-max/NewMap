extends SceneTree
## Piece s_ar_b070_b (art road kit, 17 Nov). 3rd St from Adela Ave x 3rd St (pad 2) toward B Ave, z 22.0 -> 125.0 to the block's other leg (mid-block).
## Block b070: 250 m, rise +0 m a->b; this leg carries +0.00 m, max grade 0.0 %. Dress strip.
## Pocket + arrows for the approach to Adela Ave; aprons at [45.0, 80.0, 112.0] (bus side) / [45.0, 80.0, 112.0].
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_leg("s_ar_b070_b", {"z0": 22.0, "z1": 125.0, "prof": [], "end": "seam", "Lb": 250.0, "from_b": true, "bus": false, "apr": {-1.0: [45.0, 80.0, 112.0], 1.0: [45.0, 80.0, 112.0]}, "dress": "strip", "hyd": 1.0})
	quit()
