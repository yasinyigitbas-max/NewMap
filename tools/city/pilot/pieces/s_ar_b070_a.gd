extends SceneTree
## Piece s_ar_b070_a (art road kit, 17 Nov). 3rd St from B Ave x 3rd St (pad 2) toward Adela Ave, z 22.0 -> 125.0 to the block's other leg (mid-block).
## Block b070: 250 m, rise +0 m a->b; this leg carries +0.00 m, max grade 0.0 %. Dress strip, far-side bus stop both ways at this junction.
## Pocket + arrows for the approach to B Ave; aprons at [56.0, 85.0, 112.0] (bus side) / [45.0, 80.0, 112.0].
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_leg("s_ar_b070_a", {"z0": 22.0, "z1": 125.0, "prof": [], "end": "seam", "Lb": 250.0, "from_b": false, "bus": true, "apr": {-1.0: [56.0, 85.0, 112.0], 1.0: [45.0, 80.0, 112.0]}, "dress": "strip", "hyd": -1.0})
	quit()
