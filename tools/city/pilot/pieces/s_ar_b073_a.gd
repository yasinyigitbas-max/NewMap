extends SceneTree
## Piece s_ar_b073_a (art road kit, 17 Nov). 4th St from J Ave x 4th St (pad 2) toward G Ave, z 22.0 -> 100.0 to the block's other leg (mid-block).
## Block b073: 200 m, rise +2 m a->b; this leg carries +2.00 m, max grade 1.9 %. Dress grt.
## Pocket + arrows for the approach to J Ave; aprons at [45.0, 80.0] (bus side) / [62.0].
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_leg("s_ar_b073_a", {"z0": 22.0, "z1": 100.0, "prof": [[22.0, 178.0, 2.0]], "end": "seam", "Lb": 200.0, "from_b": false, "bus": false, "apr": {-1.0: [45.0, 80.0], 1.0: [62.0]}, "dress": "grt", "hyd": -1.0})
	quit()
