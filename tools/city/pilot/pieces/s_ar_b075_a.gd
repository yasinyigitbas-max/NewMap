extends SceneTree
## Piece s_ar_b075_a (art road kit, 17 Nov). 4th St from E Ave x 4th St (pad 4) toward C Ave, z 22.0 -> 100.0 to the block's other leg (mid-block).
## Block b075: 200 m, rise +6 m a->b; this leg carries +6.00 m, max grade 5.8 %. Dress hill.
## Pocket + arrows for the approach to E Ave; aprons at [66.0] (bus side) / [58.0].
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_leg("s_ar_b075_a", {"z0": 22.0, "z1": 100.0, "prof": [[22.0, 178.0, 6.0]], "end": "seam", "Lb": 200.0, "from_b": false, "bus": false, "apr": {-1.0: [66.0], 1.0: [58.0]}, "dress": "hill", "hyd": -1.0})
	quit()
