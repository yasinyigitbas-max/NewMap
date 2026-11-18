extends SceneTree
## Piece s_ar_b065_b (art road kit, 17 Nov). 3rd St from G Ave x 3rd St (pad 2) toward J Ave, z 22.0 -> 100.0 to the industrial sample's truck street s_ind (u -700).
## Block b065: 200 m, rise +0 m a->b; this leg carries +0.00 m, max grade 0.0 %. Dress grt.
## Pocket + arrows for the approach to G Ave; aprons at [38.0] (bus side) / [38.0].
## Between 50 and 90 m the arterial becomes the industrial sample's truck street (turn lane closes, outer lanes end into the shoulder, kerb 10.3 -> 6.7, walk to 8.7).
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_leg("s_ar_b065_b", {"z0": 22.0, "z1": 100.0, "prof": [], "end": "ind", "Lb": 200.0, "from_b": true, "bus": false, "apr": {-1.0: [38.0], 1.0: [38.0]}, "dress": "grt", "hyd": 1.0})
	quit()
