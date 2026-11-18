extends SceneTree
## Piece s_ar_b078_a (art road kit, 17 Nov). 4th St from B Ave x 4th St (pad 8) toward Adela Ave, z 22.0 -> 150.0 to the strip sample's s_strip_art (u 400).
## Block b078: 250 m, rise -4 m a->b; this leg carries -4.00 m, max grade 4.7 %. Dress strip, far-side bus stop both ways at this junction.
## Pocket + arrows for the approach to B Ave; aprons at [56.0, 85.0, 112.0, 140.0] (bus side) / [45.0, 80.0, 112.0, 140.0].
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_leg("s_ar_b078_a", {"z0": 22.0, "z1": 150.0, "prof": [[22.0, 150.0, -4.0]], "end": "strip_art", "Lb": 250.0, "from_b": false, "bus": true, "apr": {-1.0: [56.0, 85.0, 112.0, 140.0], 1.0: [45.0, 80.0, 112.0, 140.0]}, "dress": "strip", "hyd": -1.0})
	quit()
