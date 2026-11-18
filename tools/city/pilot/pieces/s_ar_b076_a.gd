extends SceneTree
## Piece s_ar_b076_a (art road kit, 17 Nov). 4th St from C Ave x 4th St (pad 10) toward Amber Ave, z 22.0 -> 100.0 to the block's other leg (mid-block).
## Block b076: 200 m, rise +4 m a->b; this leg carries +4.00 m, max grade 3.9 %. Dress hill, far-side bus stop both ways at this junction.
## Pocket + arrows for the approach to C Ave; aprons at [66.0] (bus side) / [58.0].
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_leg("s_ar_b076_a", {"z0": 22.0, "z1": 100.0, "prof": [[22.0, 176.5, 4.0]], "end": "seam", "Lb": 200.0, "from_b": false, "bus": true, "apr": {-1.0: [66.0], 1.0: [58.0]}, "dress": "hill", "hyd": -1.0})
	quit()
