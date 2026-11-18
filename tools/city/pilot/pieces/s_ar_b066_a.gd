extends SceneTree
## Piece s_ar_b066_a (art road kit, 17 Nov). 3rd St from G Ave x 3rd St (pad 2) toward E Ave, z 22.0 -> 100.0 to the block's other leg (mid-block).
## Block b066: 200 m, rise +0 m a->b; this leg carries +0.00 m, max grade 0.0 %. Dress grt.
## Pocket + arrows for the approach to G Ave; aprons at [45.0, 80.0] (bus side) / [62.0].
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_leg("s_ar_b066_a", {"z0": 22.0, "z1": 100.0, "prof": [], "end": "seam", "Lb": 200.0, "from_b": false, "bus": false, "apr": {-1.0: [45.0, 80.0], 1.0: [62.0]}, "dress": "grt", "hyd": -1.0})
	quit()
